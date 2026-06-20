import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';

/// Kontrak penyimpanan data. UI & controller bergantung pada abstraksi ini,
/// bukan pada implementasi konkret — sehingga implementasi lokal sekarang
/// bisa ditukar dengan Firestore (Fase 5) tanpa mengubah UI.
abstract class StorageBackend {
  Future<AppState> load();
  Future<void> save(AppState state);

  /// Hapus seluruh data tersimpan (untuk hapus akun / reset).
  Future<void> clear();
}

/// Implementasi lokal: menyimpan seluruh state sebagai satu blob JSON
/// di SharedPreferences. Cukup untuk data pribadi berukuran wajar dan
/// jalan di web maupun mobile tanpa setup tambahan.
class LocalStorage implements StorageBackend {
  LocalStorage({this.key = 'moneywork_state_v1'});

  final String key;

  @override
  Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const AppState();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (_) {
      // Data korup/format lama — mulai bersih daripada crash.
      return const AppState();
    }
  }

  @override
  Future<void> save(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
