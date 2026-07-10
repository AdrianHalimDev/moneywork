import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto_service.dart';
import 'firebase_config.dart';

/// Mengelola kunci enkripsi end-to-end per pengguna.
///
/// Tiga lapisan:
///   1. **Blob kunci** di Firestore (`users/{uid}/data/keys`): DEK yang sudah
///      dibungkus (wrapped) oleh password & oleh recovery key. Aman di server.
///   2. **DEK di memori** ([_dek]): hanya ada setelah dibuka. Hilang saat app
///      ditutup/logout.
///   3. **Cache DEK di secure storage** perangkat (Keystore/Keychain): agar
///      sesi yang masih hidup tak perlu minta sandi tiap buka app.
///
/// Developer yang punya akses Firestore hanya melihat blob (tak berguna).
/// Sandi & recovery key tak pernah meninggalkan perangkat / layar pengguna.
class KeyManager {
  KeyManager._();
  static final KeyManager instance = KeyManager._();

  final _crypto = CryptoService.instance;
  final _secure = const FlutterSecureStorage();

  // DEK aktif di memori (per sesi). `null` berarti belum dibuka.
  SecretKey? _dek;
  bool get isUnlocked => _dek != null;

  DocumentReference<Map<String, dynamic>> _keysDoc(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('data')
          .doc('keys');

  /// Apakah pengguna sudah punya blob kunci di server (sudah setup E2EE)?
  Future<bool> hasKeyBlob(String uid) async {
    if (!useFirebase) return false;
    final snap = await _keysDoc(uid).get();
    final data = snap.data();
    if (data == null) return false;
    return data['passwordBlob'] != null;
  }

  /// Setup awal: generate DEK baru, bungkus dengan [password] & [recoveryKey],
  /// simpan blob ke server + cache DEK di perangkat. Kembalikan recovery key
  /// agar ditampilkan sekali ke pengguna.
  ///
  /// [recoveryKey] boleh null — jika null, di-generate baru di sini.
  Future<String> setup({
    required String uid,
    required String password,
    String? recoveryKey,
  }) async {
    final dek = await _crypto.generateDek();
    final recovery = recoveryKey ?? await _crypto.generateRecoveryKey();
    final passBlob = await _crypto.wrapDek(dek, password);
    final recBlob =
        await _crypto.wrapDek(dek, CryptoService.normalizeRecoveryKey(recovery));

    if (useFirebase) {
      await _keysDoc(uid).set({
        'passwordBlob': passBlob.toJson(),
        'recoveryBlob': recBlob.toJson(),
      });
    }
    _dek = dek;
    await _cacheDek(uid, dek);
    return recovery;
  }

  /// Buka DEK dengan password. Dipakai di layar unlock (perangkat baru /
  /// setelah logout). Berhasil → DEK ada di memori & di-cache perangkat.
  /// Lempar [WrongKeyException] bila password salah.
  Future<void> unlockWithPassword({required String uid, required String password}) async {
    final blob = await _readPasswordBlob(uid);
    if (blob == null) {
      // Belum setup — panggilan harusnya lewat setup(), bukan unlock.
      throw StateError('Belum ada kunci untuk pengguna ini.');
    }
    _dek = await _crypto.unwrapDek(blob, password);
    await _cacheDek(uid, _dek!);
  }

  /// Buka DEK dengan recovery key (jalur pemulihan saat lupa password).
  Future<void> unlockWithRecoveryKey({
    required String uid,
    required String recoveryKey,
    required String newPassword,
  }) async {
    final blob = await _readRecoveryBlob(uid);
    if (blob == null) {
      throw StateError('Belum ada kunci untuk pengguna ini.');
    }
    _dek = await _crypto.unwrapDek(blob, CryptoService.normalizeRecoveryKey(recoveryKey));
    // Recovery berhasil → segera re-bungkus DEK dengan password baru agar
    // jalur password kembali bisa dipakai.
    await rewrapWithPassword(uid: uid, password: newPassword);
    await _cacheDek(uid, _dek!);
  }

  /// Coba buka DEK dari cache secure storage. Berhasil bila sesi sebelumnya
  /// sudah setup di perangkat ini (tak perlu minta sandi tiap buka app).
  Future<bool> tryUnlockFromCache(String uid) async {
    if (_dek != null) return true;
    final cached = await _readCachedDek(uid);
    if (cached == null) return false;
    _dek = SecretKey(cached);
    return true;
  }

  /// Ganti password: re-bungkus DEK yang sudah terbuka dengan password baru.
  /// Wajib dipanggil setelah [isUnlocked] benar (DEK ada di memori).
  Future<void> rewrapWithPassword({
    required String uid,
    required String password,
  }) async {
    if (_dek == null) {
      throw StateError('DEK belum dibuka; tidak bisa re-bungkus.');
    }
    final passBlob = await _crypto.wrapDek(_dek!, password);
    if (useFirebase) {
      await _keysDoc(uid).set({
        'passwordBlob': passBlob.toJson(),
      }, SetOptions(merge: true));
    }
    await _cacheDek(uid, _dek!);
  }

  /// Ambil DEK aktif. Lempar bila belum dibuka.
  Future<SecretKey> requireDek() async {
    if (_dek == null) {
      throw StateError('Kunci data belum dibuka.');
    }
    return _dek!;
  }

  /// Hapus DEK dari memori & cache perangkat. Dipanggil saat logout.
  Future<void> lock(String uid) async {
    _dek = null;
    await _secure.delete(key: _cacheKey(uid));
  }

  /// Hapus blob kunci di server + cache. Dipanggil saat hapus akun.
  Future<void> destroy(String uid) async {
    _dek = null;
    await _secure.delete(key: _cacheKey(uid));
    if (useFirebase) {
      await _keysDoc(uid).delete();
    }
  }

  // --- internal ---

  String _cacheKey(String uid) => 'mw_dek_$uid';

  Future<KeyBlob?> _readPasswordBlob(String uid) async {
    if (!useFirebase) return null;
    final data = (await _keysDoc(uid).get()).data();
    final raw = data?['passwordBlob'];
    if (raw is Map) return KeyBlob.fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  Future<KeyBlob?> _readRecoveryBlob(String uid) async {
    if (!useFirebase) return null;
    final data = (await _keysDoc(uid).get()).data();
    final raw = data?['recoveryBlob'];
    if (raw is Map) return KeyBlob.fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  Future<void> _cacheDek(String uid, SecretKey dek) async {
    final bytes = await dek.extractBytes();
    await _secure.write(
      key: _cacheKey(uid),
      value: bytes.join(','),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  Future<List<int>?> _readCachedDek(String uid) async {
    final raw = await _secure.read(
      key: _cacheKey(uid),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    if (raw == null || raw.isEmpty) return null;
    try {
      return raw.split(',').map((e) => int.parse(e.trim())).toList();
    } catch (_) {
      return null;
    }
  }
}
