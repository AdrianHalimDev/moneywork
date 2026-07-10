import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/app_state.dart';
import '../data/storage.dart';
import 'crypto_service.dart';
import 'key_manager.dart';

/// Penyimpanan berbasis Firestore, terisolasi per pengguna, **terenkripsi
/// end-to-end**.
///
/// Struktur dokumen:
///   - `users/{uid}/data/state`  →  AppState yang sudah **dienkripsi**
///     (ciphertext + nonce + MAC). Developer yang punya akses Console hanya
///     melihat teks acak.
///   - `users/{uid}/data/keys`   →  DEK yang sudah dibungkus (lihat
///     [KeyManager]). Tak berguna tanpa sandi/recovery key.
///
/// Migrasi: dokumen `state` lawas yang masih plaintext (berisi `accounts`)
/// dideteksi & dikembalikan apa adanya sekali untuk migrasi, lalu ditimpa
/// terenkripsi pada simpan berikutnya.
///
/// Firestore mengaktifkan cache offline secara default; data terenkripsi tetap
/// tersinkron dan responsif saat koneksi terputus.
class FirestoreStorage implements StorageBackend {
  FirestoreStorage(this.uid);

  final String uid;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('data')
      .doc('state');

  @override
  Future<AppState> load() async {
    final snap = await _doc.get();
    final data = snap.data();
    if (data == null || data.isEmpty) return const AppState();

    // Bentuk lawas (plaintext): punya field 'accounts' langsung.
    if (data['accounts'] != null) {
      try {
        return AppState.fromJson(data);
      } catch (_) {
        return const AppState();
      }
    }

    // Bentuk terenkripsi: butuh DEK yang sudah dibuka.
    final encRaw = data['encrypted'];
    if (encRaw is! Map) return const AppState();
    final payload = EncryptedPayload.fromJson(Map<String, dynamic>.from(encRaw));

    // DEK belum dibuka (pengguna belum input sandi). Kembalikan kosong agar UI
    // tidak crash; gerbang unlock akan memaksa pengguna membuka kunci dulu,
    // lalu AppController akan memuat ulang (decrypt sungguhan).
    if (!KeyManager.instance.isUnlocked) return const AppState();

    try {
      final dek = await KeyManager.instance.requireDek();
      final json = await CryptoService.instance.decrypt(payload, dek);
      return AppState.fromJson(json);
    } catch (_) {
      // Data tak terbaca — mulai bersih daripada gagal.
      return const AppState();
    }
  }

  @override
  Future<void> save(AppState state) async {
    final json = state.toJson();
    // Belum ada kunci (pengguna belum input sandi): JANGAN tulis plaintext ke
    // server. Lempar agar penulis dibatalkan — AppController mengabaikan
    // kegagalan tulis sesaat, dan akan menulis terenkripsi setelah unlock.
    // Ini menjaga janji: di server tidak pernah ada data terbaca.
    if (!KeyManager.instance.isUnlocked) {
      throw StateError('Kunci data belum dibuka; tulis dibatalkan.');
    }
    final dek = await KeyManager.instance.requireDek();
    final payload = await CryptoService.instance.encrypt(json, dek);
    await _doc.set({'encrypted': payload.toJson()});
  }

  @override
  Future<void> clear() async {
    await _doc.delete();
  }
}
