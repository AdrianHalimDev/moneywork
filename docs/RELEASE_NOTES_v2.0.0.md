# Release Notes v2.0.0

Pembaruan utama pada versi 2.0.0 ini berfokus pada stabilitas layar autentikasi (Login/Register), perbaikan kompatibilitas *native keyboard* di Android, dan perapian struktur proyek.

## Ringkasan Pembaruan (Changelog)

### 1. Perbaikan Bug "Teks Hantu" pada Keyboard Android (Khususnya Samsung)
Sebelumnya terdapat isu (bug) di mana teks yang sudah dihapus hingga kosong di kolom input akan muncul kembali ketika pengguna mengetik karakter baru. Ini disebabkan oleh konflik antara manajemen memori keyboard prediktif bawaan Android dan state internal Flutter.
- **Perbaikan Kode:** Mengubah file `lib/screens/login_screen.dart` dan `lib/widgets/common.dart`.
- **Detail:** Menambahkan atribut `autocorrect: false`, `enableSuggestions: false`, dan `enableIMEPersonalizedLearning: false` ke seluruh `TextFormField` (Kolom Email, Nama, dan Kata Sandi). Pengaturan ini memaksa keyboard untuk tidak melakukan koreksi pintar pada form login, sehingga input teks bekerja 100% secara sinkron.

### 2. Perbaikan Crash Layar Merah (No Overlay Widget Found)
Aplikasi sebelumnya mengalami crash fatal saat baru dijalankan apabila pengaturan *Tooltip* pada ikon visibilitas kata sandi (ikon mata) mencoba merender di layar.
- **Perbaikan Kode:** Mengubah struktur gerbang autentikasi di `lib/main.dart`.
- **Detail:** Pada versi sebelumnya, `LoginScreen` dan layar keamanan lainnya langsung di-*return* di dalam `MaterialApp.builder` tanpa dibungkus oleh `Navigator` atau `Overlay`. Kami telah membungkus pemanggilan layar tersebut ke dalam `Navigator(onGenerateRoute: ...)` agar UI seperti *Tooltip* atau *SnackBar* bisa merender overlay-nya tanpa memicu error mematikan.

### 3. Pemulihan Fitur Login dengan Google
- **Perbaikan Kode:** Memodifikasi `lib/screens/login_screen.dart`.
- **Detail:** Mengembalikan tombol `OutlinedButton.icon` untuk opsi **"Masuk dengan Google"**. Tombol ini kini kembali terhubung dengan metode `_googleSignIn` yang akan memanggil `signInWithGoogle()` lewat Riverpod `authServiceProvider`.

### 4. Fitur Pemisah Ribuan (Titik Angka)
- **Detail:** Telah ditambahkan fitur *auto-formatting* untuk input angka sehingga setiap nominal uang yang dimasukkan otomatis menggunakan pemisah ribuan (titik) sesuai dengan standar Rupiah (misal: 1.000.000). Ini mempermudah pengguna membaca dan memasukkan nominal uang dengan tepat tanpa takut kelebihan nol.

### 5. Kerapian Struktur Proyek (Documentation Cleanup)
- Memindahkan berbagai file catatan dan panduan (seperti `COMPARISON.md`, `FIREBASE_SETUP.md`, `RELEASING.md`, dan versi rilis sebelumnya) dari direktori utama (`root`) ke dalam folder khusus `/docs` agar repositori lebih bersih dan rapi.
- Menghapus file sampah dan duplikat dari *root*.

### 6. Peningkatan Versi (Version Bump)
- Mengubah versi aplikasi di `pubspec.yaml` menjadi **`version: 2.0.0+12`** untuk memungkinkan pembaruan OTA (Over-The-Air) pada instalasi pengguna yang sudah ada.
