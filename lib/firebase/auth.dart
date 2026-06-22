import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_config.dart';

/// Identitas pengguna aktif.
///
/// Pada mode lokal (Firebase nonaktif) selalu ada satu pengguna sintetis
/// [AppUser.local] sehingga aplikasi tidak pernah menahan di layar login.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.hasPassword = true,
  }) : isLocal = false;

  const AppUser.local()
      : uid = 'local',
        email = '',
        displayName = '',
        hasPassword = true,
        isLocal = true;

  final String uid;
  final String email;
  final String displayName;

  /// Apakah akun sudah punya metode kata sandi (provider `password`).
  /// Akun yang login hanya via Google bernilai `false` sampai kata sandi dibuat.
  final bool hasPassword;
  final bool isLocal;

  /// Nama untuk ditampilkan; jatuh ke bagian depan email bila nama kosong.
  String get label {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (email.contains('@')) return email.split('@').first;
    return 'Pengguna';
  }

  /// Inisial untuk avatar (maks. 2 huruf).
  String get initials {
    final src = label.trim();
    if (src.isEmpty) return '?';
    final parts = src.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return src.substring(0, src.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// Aliran status autentikasi.
///
/// - Mode lokal: langsung memancarkan [AppUser.local].
/// - Mode Firebase: mengikuti `userChanges()` agar perubahan profil (mis. nama)
///   ikut terpancar, bukan hanya login/logout. `null` berarti belum login.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  if (!useFirebase) {
    return Stream<AppUser?>.value(const AppUser.local());
  }
  return FirebaseAuth.instance.userChanges().map(
        (u) => u == null
            ? null
            : AppUser(
                uid: u.uid,
                email: u.email ?? '',
                displayName: u.displayName ?? '',
                hasPassword:
                    u.providerData.any((p) => p.providerId == 'password'),
              ),
      );
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Operasi autentikasi & profil. Tiap method mengembalikan `null` bila
/// berhasil, atau pesan error berbahasa Indonesia bila gagal.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Atur apakah sesi diingat lintas penutupan browser.
  ///
  /// Hanya berlaku di web: LOCAL = tetap login, SESSION = keluar saat tab
  /// ditutup. Di mobile sesi selalu tersimpan, jadi tidak ada efek.
  Future<void> _applyPersistence(bool rememberMe) async {
    if (!kIsWeb) return;
    await _auth.setPersistence(
      rememberMe ? Persistence.LOCAL : Persistence.SESSION,
    );
  }

  Future<String?> signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    if (!useFirebase) return 'Firebase belum diaktifkan.';
    try {
      await _applyPersistence(rememberMe);
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Gagal masuk: $e';
    }
  }

  Future<String?> register(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    if (!useFirebase) return 'Firebase belum diaktifkan.';
    try {
      await _applyPersistence(rememberMe);
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Gagal mendaftar: $e';
    }
  }

  Future<void> signOut() async {
    if (!useFirebase) return;
    await _auth.signOut();
  }

  /// Tautkan kata sandi ke akun yang sedang login (mis. akun Google yang
  /// belum punya kata sandi). Setelah ini, akun bisa masuk dengan email +
  /// kata sandi dan mengelola akun layaknya akun email biasa.
  Future<String?> linkPassword(String password) async {
    if (!useFirebase) return 'Firebase belum diaktifkan.';
    final user = _auth.currentUser;
    if (user == null || (user.email ?? '').isEmpty) {
      return 'Sesi tidak valid.';
    }
    try {
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.linkWithCredential(cred);
      await user.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      // Sudah punya kata sandi sebelumnya — anggap sukses.
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        return null;
      }
      return _message(e);
    } catch (e) {
      return 'Gagal membuat kata sandi: $e';
    }
  }

  /// Masuk dengan akun Google.
  ///
  /// Web memakai popup; mobile memakai alur native ([signInWithProvider]).
  /// Di Android, login Google memerlukan sidik jari SHA-1 aplikasi terdaftar
  /// di Firebase Console dan provider Google diaktifkan.
  Future<String?> signInWithGoogle({bool rememberMe = true}) async {
    if (!useFirebase) return 'Firebase belum diaktifkan.';
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      if (kIsWeb) {
        await _applyPersistence(rememberMe);
        await _auth.signInWithPopup(provider);
      } else {
        // Alur native (Custom Tab) di mobile — tanpa paket google_sign_in.
        await _auth.signInWithProvider(provider);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Pengguna membatalkan — bukan error yang perlu ditampilkan.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-canceled' ||
          e.code == 'canceled') {
        return null;
      }
      return _message(e);
    } catch (e) {
      return 'Gagal masuk dengan Google: $e';
    }
  }

  /// Perbarui nama tampilan pengguna.
  Future<String?> updateName(String name) async {
    if (!useFirebase) return 'Firebase belum diaktifkan.';
    final user = _auth.currentUser;
    if (user == null) return 'Sesi tidak valid.';
    try {
      await user.updateDisplayName(name.trim());
      await user.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Gagal memperbarui nama: $e';
    }
  }

  /// Verifikasi ulang dengan kata sandi saat ini. Wajib sebelum operasi
  /// sensitif (ganti sandi, hapus akun) bila sesi sudah lama.
  Future<String?> reauthenticate(String currentPassword) async {
    if (!useFirebase) return 'Firebase belum diaktifkan.';
    final user = _auth.currentUser;
    if (user == null || user.email == null) return 'Sesi tidak valid.';
    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Gagal verifikasi: $e';
    }
  }

  /// Ganti kata sandi. Memverifikasi ulang dengan sandi lama lebih dulu.
  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    final reauth = await reauthenticate(currentPassword);
    if (reauth != null) return reauth;
    try {
      await _auth.currentUser!.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Gagal mengganti kata sandi: $e';
    }
  }

  /// Hapus akun pengguna saat ini. Pastikan data Firestore sudah dibersihkan
  /// lebih dulu (saat masih terautentikasi), lalu panggil ini.
  Future<String?> deleteCurrentUser() async {
    if (!useFirebase) return 'Firebase belum diaktifkan.';
    final user = _auth.currentUser;
    if (user == null) return 'Sesi tidak valid.';
    try {
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Gagal menghapus akun: $e';
    }
  }

  String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'Format email tidak valid.',
        'user-disabled' => 'Akun ini dinonaktifkan.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email atau kata sandi salah.',
        'email-already-in-use' => 'Email sudah terdaftar.',
        'weak-password' => 'Kata sandi minimal 6 karakter.',
        'account-exists-with-different-credential' =>
          'Email ini sudah terdaftar dengan metode lain. Masuk dengan email & kata sandi.',
        'popup-blocked' =>
          'Popup diblokir browser. Izinkan popup lalu coba lagi.',
        'requires-recent-login' =>
          'Demi keamanan, masuk ulang dulu sebelum melakukan ini.',
        'network-request-failed' => 'Tidak ada koneksi internet.',
        _ => e.message ?? 'Terjadi kesalahan (${e.code}).',
      };
}
