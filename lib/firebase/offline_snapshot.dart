import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_state.dart';
import 'crypto_service.dart';

/// Salinan perangkat untuk satu pengguna. Seluruh isi, termasuk metadata
/// revisi, dienkripsi dengan DEK yang sama dengan data cloud.
class OfflineSnapshot {
  const OfflineSnapshot({
    required this.state,
    required this.baseline,
    required this.revisions,
    required this.pending,
    required this.needsMigration,
    this.legacySource,
  });

  final AppState state;
  final Map<String, Map<String, dynamic>> baseline;
  final Map<String, int> revisions;
  final bool pending;
  final bool needsMigration;
  final Map<String, dynamic>? legacySource;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'state': state.toJson(),
        'baseline': baseline,
        'revisions': revisions,
        'pending': pending,
        'needsMigration': needsMigration,
        'legacySource': legacySource,
      };

  factory OfflineSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['state'] is! Map ||
        json['baseline'] is! Map || json['revisions'] is! Map ||
        json['pending'] is! bool || json['needsMigration'] is! bool) {
      throw const FormatException('Salinan offline tidak valid.');
    }
    return OfflineSnapshot(
      state: AppState.fromJson(Map<String, dynamic>.from(json['state'] as Map)),
      baseline: (json['baseline'] as Map).map((key, value) => MapEntry(
            key as String,
            Map<String, dynamic>.from(value as Map),
          )),
      revisions: (json['revisions'] as Map).map((key, value) =>
          MapEntry(key as String, (value as num).toInt())),
      pending: json['pending'] as bool,
      needsMigration: json['needsMigration'] as bool,
      legacySource: json['legacySource'] == null
          ? null
          : Map<String, dynamic>.from(json['legacySource'] as Map),
    );
  }
}

class OfflineSnapshotStore {
  OfflineSnapshotStore(this.uid, {required this.keyProvider});

  final String uid;
  final Future<SecretKey> Function() keyProvider;

  String get _storageKey => 'mw_offline_v1_$uid';

  Future<OfflineSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      final encoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final payload = EncryptedPayload(
        nonce: base64Decode(encoded['nonce'] as String),
        ciphertext: base64Decode(encoded['ciphertext'] as String),
        mac: base64Decode(encoded['mac'] as String),
      );
      final json = await CryptoService.instance.decrypt(
          payload, await keyProvider());
      return OfflineSnapshot.fromJson(json);
    } catch (error) {
      throw FormatException(
        'Salinan offline tidak dapat dibaca. Data asli tetap disimpan.', error);
    }
  }

  Future<void> save(OfflineSnapshot snapshot) async {
    final payload = await CryptoService.instance.encrypt(
        snapshot.toJson(), await keyProvider());
    final raw = jsonEncode({
      'nonce': base64Encode(payload.nonce),
      'ciphertext': base64Encode(payload.ciphertext),
      'mac': base64Encode(payload.mac),
    });
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_storageKey, raw)) {
      throw StateError('Salinan offline gagal disimpan di perangkat.');
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(_storageKey)) {
      throw StateError('Salinan offline gagal dihapus.');
    }
  }
}
