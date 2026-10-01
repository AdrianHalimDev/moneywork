import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '../data/app_state.dart';
import '../data/storage.dart';
import 'crypto_service.dart';
import 'key_manager.dart';
import 'offline_snapshot.dart';
import 'record_codec.dart';

/// Perubahan pada dokumen yang sama dari perangkat lain tidak boleh diam-diam
/// ditimpa. Pengguna dapat memuat ulang lalu mengulangi tindakan tersebut.
class SyncConflictException implements Exception {
  const SyncConflictException(this.message);
  final String message;

  @override
  String toString() => message;
}

class OfflineDataUnavailableException implements Exception {
  const OfflineDataUnavailableException();

  @override
  String toString() =>
      'Belum ada salinan data di perangkat ini. Sambungkan internet dan buka aplikasi sekali untuk menyiapkan mode offline.';
}

/// Penyimpanan E2EE v2: satu dokumen per entitas, ditulis sebagai delta.
///
/// `users/{uid}/records/{encoded-key}` berisi ciphertext, nonce, MAC, dan
/// revisi. Satu simpan tidak menimpa seluruh riwayat. Perubahan bersamaan
/// pada akun atau kewajiban yang sama memakai transaksi Firestore dengan
/// pemeriksaan revisi; saat konflik, simpan gagal secara terlihat.
/// `users/{uid}/data/schema` menandai migrasi dari dokumen `data/state` v1.
class FirestoreStorage implements StorageBackend {
  FirestoreStorage(this.uid, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _offline = OfflineSnapshotStore(uid,
            keyProvider: KeyManager.instance.requireDek);

  final String uid;
  final FirebaseFirestore _firestore;
  final OfflineSnapshotStore _offline;

  DocumentReference<Map<String, dynamic>> get _legacy => _firestore
      .collection('users')
      .doc(uid)
      .collection('data')
      .doc('state');
  DocumentReference<Map<String, dynamic>> get _schema => _firestore
      .collection('users')
      .doc(uid)
      .collection('data')
      .doc('schema');
  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('users').doc(uid).collection('records');

  DocumentReference<Map<String, dynamic>> _record(String key) =>
      _records.doc(Uri.encodeComponent(key));

  Map<String, Map<String, dynamic>>? _baseline;
  final Map<String, int> _revisions = {};
  Map<String, dynamic>? _legacySource;
  bool _needsMigration = false;
  bool lastReadFromCache = false;
  bool hasPendingLocalChanges = false;
  AppState? _latestLocalState;
  Future<void> _cacheWriteTail = Future.value();

  @override
  Future<AppState> load() async {
    if (!KeyManager.instance.isUnlocked) return const AppState();
    final local = await _offline.load();
    // Perubahan yang belum dikirim selalu didahulukan. Memuat server lebih
    // dahulu akan menghilangkan pekerjaan offline saat aplikasi dibuka lagi.
    if (local?.pending == true) return _restoreOffline(local!);
    try {
      return await _load(const GetOptions(source: Source.server));
    } on FirebaseException catch (error) {
      if (error.code != 'unavailable' && error.code != 'deadline-exceeded') {
        rethrow;
      }
      if (local == null) throw const OfflineDataUnavailableException();
      return _restoreOffline(local);
    }
  }

  /// Saat pengguna sengaja mengganti perubahan lokal dengan versi cloud,
  /// jangan diam-diam memakai cache offline yang mungkin usang.
  Future<AppState> loadFromServer() =>
      _load(const GetOptions(source: Source.server));

  AppState _restoreOffline(OfflineSnapshot snapshot) {
    _baseline = Map<String, Map<String, dynamic>>.from(snapshot.baseline);
    _revisions
      ..clear()
      ..addAll(snapshot.revisions);
    _legacySource = snapshot.legacySource;
    _needsMigration = snapshot.needsMigration;
    hasPendingLocalChanges = snapshot.pending;
    _latestLocalState = snapshot.pending ? snapshot.state : null;
    lastReadFromCache = true;
    return snapshot.state;
  }

  Future<void> _storeOffline(AppState state, {required bool pending}) async {
    final baseline = _baseline;
    if (baseline == null) throw StateError('Data belum dimuat.');
    final snapshot = OfflineSnapshot(
      state: state,
      baseline: Map<String, Map<String, dynamic>>.from(baseline),
      revisions: Map<String, int>.from(_revisions),
      pending: pending,
      needsMigration: _needsMigration,
      legacySource: _legacySource,
    );
    final write = _cacheWriteTail.catchError((Object _) {}).then(
          (_) => _offline.save(snapshot),
        );
    _cacheWriteTail = write;
    await write;
    hasPendingLocalChanges = pending;
  }

  /// Tulis perubahan lokal terenkripsi sebelum UI menganggapnya berhasil.
  Future<void> stageLocalState(AppState state) async {
    if (_baseline == null) await load();
    _latestLocalState = state;
    await _storeOffline(state, pending: true);
  }

  Future<AppState> _load(GetOptions options) async {
    // Gerbang kunci memuat ulang controller setelah DEK tersedia. Jangan
    // pernah menafsirkan ciphertext yang terkunci sebagai state kosong untuk
    // kemudian ditulis kembali.
    if (!KeyManager.instance.isUnlocked) return const AppState();
    final schema = await _schema.get(options);
    lastReadFromCache = schema.metadata.isFromCache;
    if (schema.data()?['version'] == 2) {
      final dek = await KeyManager.instance.requireDek();
      final snap = await _records.get(options);
      lastReadFromCache |= snap.metadata.isFromCache;
      final records = <String, Map<String, dynamic>>{};
      final revisions = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final key = data['key'];
        final encrypted = data['encrypted'];
        if (key is! String || encrypted is! Map) {
          throw FormatException('Dokumen sinkronisasi tidak valid: ${doc.id}');
        }
        records[key] = await CryptoService.instance.decrypt(
          EncryptedPayload.fromJson(Map<String, dynamic>.from(encrypted)),
          dek,
        );
        revisions[key] = (data['revision'] as num?)?.toInt() ?? 0;
      }
      _baseline = records;
      _revisions
        ..clear()
        ..addAll(revisions);
      _legacySource = null;
      _needsMigration = false;
      final state = RecordCodec.decode(records);
      _latestLocalState = null;
      await _storeOffline(state, pending: false);
      lastReadFromCache = false;
      return state;
    }

    final legacy = await _legacy.get(options);
    lastReadFromCache |= legacy.metadata.isFromCache;
    final data = legacy.data();
    AppState state;
    if (data == null || data.isEmpty) {
      state = const AppState();
    } else if (data['accounts'] != null) {
      // Format lama sebelum E2EE. Data ini hanya dibaca untuk migrasi.
      state = AppState.fromJson(data);
    } else {
      final encrypted = data['encrypted'];
      if (encrypted is! Map) {
        throw const FormatException('Dokumen data lama tidak valid.');
      }
      final dek = await KeyManager.instance.requireDek();
      final json = await CryptoService.instance.decrypt(
        EncryptedPayload.fromJson(Map<String, dynamic>.from(encrypted)),
        dek,
      );
      state = AppState.fromJson(json);
    }
    _baseline = RecordCodec.encode(state);
    _revisions.clear();
    _legacySource = data;
    _needsMigration = true;
    _latestLocalState = null;
    await _storeOffline(state, pending: false);
    lastReadFromCache = false;
    return state;
  }

  Future<void> _migrate() async {
    if (!_needsMigration) return;
    final baseline = _baseline;
    if (baseline == null) throw StateError('Data belum dimuat.');
    final dek = await KeyManager.instance.requireDek();
    final entries = baseline.entries.toList();
    // Satu transaksi menulis paling banyak 100 record agar tetap di bawah
    // batas operasi dan ukuran transaksi Firestore.
    for (var start = 0; start < entries.length; start += 100) {
      final chunk = entries.skip(start).take(100).toList();
      final payloads = <String, Map<String, dynamic>>{};
      for (final entry in chunk) {
        payloads[entry.key] =
            (await CryptoService.instance.encrypt(entry.value, dek)).toJson();
      }
      await _firestore.runTransaction((transaction) async {
        final marker = await transaction.get(_schema);
        if (marker.data()?['version'] == 2) {
          throw const SyncConflictException(
            'Data sudah dimigrasikan perangkat lain. Muat ulang untuk menyinkronkan.',
          );
        }
        // Jika aplikasi versi lama menulis ulang state sewaktu migrasi,
        // hentikan proses. Retry membaca sumber baru dan menulis ulang semua
        // record yang mungkin tersisa dari percobaan migrasi sebelumnya.
        final source = await transaction.get(_legacy);
        if (!const DeepCollectionEquality()
            .equals(source.data(), _legacySource)) {
          throw const SyncConflictException(
            'Data lama berubah selama migrasi. Muat ulang sebelum menyimpan.',
          );
        }
        for (final entry in chunk) {
          transaction.set(_record(entry.key), {
            'key': entry.key,
            'encrypted': payloads[entry.key],
            'revision': 1,
          });
        }
      });
    }
    // Migrasi yang sempat terputus bisa menyisakan record dari versi legacy
    // sebelumnya. Hapus ID yang tidak ada lagi di snapshot legacy terbaru,
    // agar transaksi yang telah dihapus tidak muncul kembali.
    final existing = await _records.get(
        const GetOptions(source: Source.server));
    final stale = existing.docs.where((doc) {
      final key = doc.data()['key'];
      return key is! String || !baseline.containsKey(key);
    }).toList();
    for (var start = 0; start < stale.length; start += 100) {
      final chunk = stale.skip(start).take(100);
      await _firestore.runTransaction((transaction) async {
        final marker = await transaction.get(_schema);
        final source = await transaction.get(_legacy);
        if (marker.data()?['version'] == 2 ||
            !const DeepCollectionEquality()
                .equals(source.data(), _legacySource)) {
          throw const SyncConflictException(
            'Data berubah selama migrasi. Muat ulang sebelum menyimpan.',
          );
        }
        for (final doc in chunk) {
          transaction.delete(doc.reference);
        }
      });
    }
    await _firestore.runTransaction((transaction) async {
      final marker = await transaction.get(_schema);
      if (marker.data()?['version'] == 2) {
        throw const SyncConflictException(
          'Data sudah dimigrasikan perangkat lain. Muat ulang untuk menyinkronkan.',
        );
      }
      final source = await transaction.get(_legacy);
      if (!const DeepCollectionEquality()
          .equals(source.data(), _legacySource)) {
        throw const SyncConflictException(
          'Data lama berubah selama migrasi. Muat ulang sebelum menyimpan.',
        );
      }
      transaction.set(_schema, {'version': 2});
      transaction.delete(_legacy);
    });
    _needsMigration = false;
    _legacySource = null;
    _revisions.addEntries(baseline.keys.map((key) => MapEntry(key, 1)));
    await _storeOffline(_latestLocalState ?? RecordCodec.decode(baseline),
        pending: true);
  }

  @override
  Future<void> save(AppState state) async {
    if (!KeyManager.instance.isUnlocked) {
      throw StateError('Kunci data belum dibuka; tulis dibatalkan.');
    }
    if (_baseline == null) await load();
    _latestLocalState ??= state;
    await _storeOffline(_latestLocalState!, pending: true);
    await _migrate();

    final desired = RecordCodec.encode(state);
    final changes = RecordCodec.changedKeys(_baseline!, desired).toList();
    if (changes.isEmpty) {
      await _finishOfflineSave(state);
      return;
    }
    // Perubahan satu kewajiban atau penghapusan akun harus atomik dengan
    // transaksi terkait. Jangan pecah pembayaran menjadi beberapa commit.
    if (changes.length > 90 && changes.any((key) =>
        key.startsWith('debts/') ||
        key.startsWith('receivables/') ||
        key.startsWith('accounts/'))) {
      throw StateError(
          'Perubahan terlalu banyak untuk disimpan sekaligus dengan aman. '
          'Selesaikan sinkronisasi sebelum melanjutkan.');
    }
    final dek = await KeyManager.instance.requireDek();
    for (var start = 0; start < changes.length; start += 90) {
      final chunk = changes.skip(start).take(90).toList();
      final guardedAccounts =
          RecordCodec.affectedAccountKeys(_baseline!, desired, chunk);
      final operationKeys = <String>{...chunk, ...guardedAccounts}.toList();
      if (operationKeys.length > 100) {
        throw StateError('Terlalu banyak akun berubah dalam satu penyimpanan.');
      }
      final encrypted = <String, Map<String, dynamic>>{};
      for (final key in operationKeys) {
        final value = desired[key];
        if (value != null) {
          encrypted[key] =
              (await CryptoService.instance.encrypt(value, dek)).toJson();
        }
      }
      await _firestore.runTransaction((transaction) async {
        final schema = await transaction.get(_schema);
        if (schema.data()?['version'] != 2) {
          throw const SyncConflictException(
            'Versi data berubah. Muat ulang sebelum menyimpan.',
          );
        }
        final remote = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final key in operationKeys) {
          remote[key] = await transaction.get(_record(key));
        }
        for (final key in operationKeys) {
          final expected = _revisions[key];
          final current = remote[key]!.data()?['revision'];
          if (expected == null ? remote[key]!.exists : current != expected) {
            throw SyncConflictException(
              'Data $key berubah di perangkat lain. Muat ulang sebelum mengulangi perubahan.',
            );
          }
        }
        for (final key in operationKeys) {
          if (desired[key] == null) {
            transaction.delete(_record(key));
          } else {
            transaction.set(_record(key), {
              'key': key,
              'encrypted': encrypted[key],
              'revision': (_revisions[key] ?? 0) + 1,
            });
          }
        }
      });
      // Perbarui baseline per chunk: jika chunk berikut gagal, coba lagi tidak
      // mencoba menimpa chunk yang sudah diakui server.
      for (final key in operationKeys) {
        if (desired[key] == null) {
          _baseline!.remove(key);
          _revisions.remove(key);
        } else {
          _baseline![key] = desired[key]!;
          _revisions[key] = (_revisions[key] ?? 0) + 1;
        }
      }
      await _storeOffline(_latestLocalState ?? state, pending: true);
    }
    await _finishOfflineSave(state);
  }

  Future<void> _finishOfflineSave(AppState saved) async {
    final latest = _latestLocalState;
    final isLatest = latest == null || const DeepCollectionEquality()
        .equals(latest.toJson(), saved.toJson());
    await _storeOffline(isLatest ? saved : latest, pending: !isLatest);
    if (isLatest && identical(_latestLocalState, latest)) {
      _latestLocalState = null;
    }
  }

  @override
  Future<void> clear() async {
    await _cacheWriteTail;
    final snap = await _records.get();
    for (var start = 0; start < snap.docs.length; start += 400) {
      final batch = _firestore.batch();
      for (final doc in snap.docs.skip(start).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    final batch = _firestore.batch();
    batch.delete(_schema);
    batch.delete(_legacy);
    await batch.commit();
    _baseline = RecordCodec.encode(const AppState());
    _revisions.clear();
    _legacySource = null;
    _needsMigration = true;
    await _offline.clear();
    hasPendingLocalChanges = false;
    _latestLocalState = null;
  }
}
