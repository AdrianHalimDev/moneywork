import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/app_state.dart';
import '../data/storage.dart';

/// Penyimpanan berbasis Firestore, terisolasi per pengguna.
///
/// Struktur dokumen:
///   users/{uid}/data/state   →  satu dokumen berisi seluruh AppState.
///
/// Menyimpan seluruh state sebagai satu dokumen JSON memudahkan sinkronisasi
/// dan cocok untuk volume data pribadi. Firestore mengaktifkan cache offline
/// secara default, jadi aplikasi tetap responsif saat koneksi terputus dan
/// menyinkronkan ulang begitu online.
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
    try {
      return AppState.fromJson(data);
    } catch (_) {
      // Data tidak terbaca — mulai bersih daripada gagal.
      return const AppState();
    }
  }

  @override
  Future<void> save(AppState state) async {
    await _doc.set(state.toJson());
  }

  @override
  Future<void> clear() async {
    await _doc.delete();
  }
}
