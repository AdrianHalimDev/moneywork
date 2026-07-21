/// Saklar utama integrasi Firebase.
///
/// Tetap `false` sampai kamu menyelesaikan setup:
///   1. Buat project di Firebase Console (perlu login Google).
///   2. Jalankan `flutterfire configure` (menimpa firebase_options.dart).
///   3. Ubah nilai ini menjadi `true`, lalu jalankan ulang aplikasi.
///
/// Selama `false`, aplikasi memakai penyimpanan lokal di perangkat —
/// tidak ada login, tidak ada sinkronisasi cloud, dan tidak perlu jaringan.
/// Langkah lengkap ada di `FIREBASE_SETUP.md`.
const bool useFirebase = true;
