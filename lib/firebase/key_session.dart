import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/auth.dart';
import 'key_manager.dart';

/// Menahan status pembukaan kunci E2EE selama sesi.
///
/// Sandi yang diketik pengguna di layar login/daftar/lengkapi-akun dimasukkan
/// ke sini (transien, tak persisten) agar [KeyManager] bisa memakainya untuk
/// membuka / menyiapkan kunci tanpa meminta sandi lagi. Setelah dipakai, sandi
/// dibersihkan dari memori.
class KeySession {
  KeySession();

  /// Sandi yang baru saja diketik (transien). Dibersihkan setelah dipakai.
  String? _pendingPassword;
  String? get pendingPassword => _pendingPassword;

  /// ID pengguna yang sudah di-unlock kuncinya (untuk membedakan perangkat/
  /// sesi). `null` bila belum ada sesi yang di-unlock.
  String? _unlockedUid;
  bool isUnlocked(String? uid) =>
      KeyManager.instance.isUnlocked && _unlockedUid == uid;

  void setPendingPassword(String password) => _pendingPassword = password;

  void clearPendingPassword() => _pendingPassword = null;

  /// Tandai bahwa kunci pengguna [uid] sudah berhasil dibuka.
  void markUnlocked(String uid) => _unlockedUid = uid;

  /// Kunci sesi: hapus DEK memori + cache pengguna. Dipakai saat logout.
  Future<void> lock(String uid) async {
    _unlockedUid = null;
    _pendingPassword = null;
    await KeyManager.instance.lock(uid);
  }
}

final keySessionProvider = Provider<KeySession>((ref) => KeySession());

/// Status keamanan E2EE pengguna aktif. Menggerakkan gerbang
/// upgrade/unlock di [_AuthGate].
///
///   [SecurityStatus.needsUpgrade] → pengguna punya sandi tapi belum setup
///     kunci (data lama masih plaintext). Wajib setup + recovery key.
///   [SecurityStatus.locked]       → sudah setup, tapi DEK belum dibuka di
///     perangkat ini (perangkat baru / setelah logout). Wajib input sandi.
///   [SecurityStatus.ready]        → kunci sudah dibuka, data terenkripsi siap
///     dimuat.
///   [SecurityStatus.disabled]     → Firebase nonaktif / pengguna lokal.
enum SecurityStatus { disabled, needsUpgrade, locked, ready }

final securityStatusProvider =
    FutureProvider<SecurityStatus>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null || auth.isLocal || !auth.hasPassword) {
    return SecurityStatus.disabled;
  }
  // Kunci perangkat yang sudah tersimpan cukup untuk membaca salinan offline.
  // Jangan meminta Firestore sebelum mencoba cache ini.
  final fromCache = await KeyManager.instance.tryUnlockFromCache(auth.uid);
  if (fromCache) {
    ref.read(keySessionProvider).markUnlocked(auth.uid);
    return SecurityStatus.ready;
  }
  final hasBlob = await KeyManager.instance.hasKeyBlob(auth.uid);
  if (!hasBlob) return SecurityStatus.needsUpgrade;
  // Ada blob tapi belum di-unlocked → cek apakah sandi tertahan dari login
  // barusan (mis. login email+sandi di sesi ini).
  final session = ref.read(keySessionProvider);
  final pending = session.pendingPassword;
  if (pending != null && pending.isNotEmpty) {
    try {
      await KeyManager.instance.unlockWithPassword(
          uid: auth.uid, password: pending);
      session.markUnlocked(auth.uid);
      session.clearPendingPassword();
      return SecurityStatus.ready;
    } catch (_) {
      // Sandi tak cocok (mis. akun dipulihkan). Lanjut ke layar unlock.
    }
  }
  return SecurityStatus.locked;
});
