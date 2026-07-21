# Setup Firebase — Login & Sinkronisasi Cloud

Semua kode sudah siap. Tahap ini menghubungkan aplikasi ke project Firebase
**milikmu**, karena butuh login akun Google yang tidak bisa diwakilkan.

Selama belum diselesaikan, aplikasi tetap berjalan normal dengan penyimpanan
lokal (`useFirebase = false`).

---

## Ringkasan alur

```
Buat project  →  Aktifkan Auth + Firestore  →  flutterfire configure
   →  Pasang security rules  →  ubah useFirebase = true  →  selesai
```

Perkiraan waktu: 10–15 menit.

---

## 1. Buat project di Firebase Console

1. Buka <https://console.firebase.google.com> dan login akun Google.
2. **Add project** → beri nama (mis. `moneywork`) → ikuti sampai selesai.
   Google Analytics boleh dimatikan, tidak diperlukan.

## 2. Aktifkan Authentication

1. Menu kiri → **Build → Authentication → Get started**.
2. Tab **Sign-in method** → aktifkan **Email/Password** → Save.
3. (Opsional) Di tab yang sama → **Add new provider → Google** → aktifkan,
   pilih email support, lalu Save. Ini mengaktifkan tombol "Masuk dengan
   Google" di layar login (saat ini berfungsi di web).
   - Catatan: untuk login Google di **Android** nanti, perlu menambahkan
     sidik jari **SHA-1** aplikasi di Project Settings. Tidak diperlukan
     untuk web.

## 3. Aktifkan Firestore Database

1. Menu kiri → **Build → Firestore Database → Create database**.
2. Pilih lokasi terdekat (mis. `asia-southeast2` / Jakarta).
3. Mulai dengan **production mode** (rules-nya kita isi di langkah 5).

## 4. Hubungkan aplikasi: `flutterfire configure`

Jalankan di terminal, dari folder project. CLI Flutter dan Firebase sudah
terpasang di mesinmu; tinggal pasang FlutterFire CLI sekali:

```bash
# 1) Pasang FlutterFire CLI (sekali saja)
"D:\Users\LIM\Downloads\Kuliah\Sems_5\flutter\bin\dart" pub global activate flutterfire_cli

# 2) Tambahkan folder ini ke PATH (sekali saja), lalu buka ulang terminal:
#    %USERPROFILE%\AppData\Local\Pub\Cache\bin

# 3) Login ke Firebase
firebase login

# 4) Konfigurasikan project (dari folder moneywork)
flutterfire configure
```

Saat `flutterfire configure` berjalan:
- Pilih project Firebase yang tadi dibuat.
- Pilih platform: **android** dan **web** (spasi untuk centang, Enter).
- CLI akan **menimpa** `lib/firebase_options.dart` dengan konfigurasi aslimu.
  Ini yang diharapkan — placeholder lama memang untuk diganti.

## 5. Pasang Security Rules (penting!)

Tanpa ini, data antar pengguna tidak terlindungi. Di Console →
**Firestore Database → Rules**, ganti isinya dengan:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Setiap pengguna hanya boleh mengakses datanya sendiri.
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

Klik **Publish**. Rules ini mengunci `users/{uid}/...` agar hanya bisa
diakses pemilik UID yang sedang login — sejalan dengan `FirestoreStorage`.

## 6. Aktifkan di aplikasi

Buka `lib/firebase/firebase_config.dart`, ubah satu baris:

```dart
const bool useFirebase = true;
```

Jalankan ulang:

```bash
"D:\Users\LIM\Downloads\Kuliah\Sems_5\flutter\bin\flutter" run -d chrome
```

Sekarang aplikasi membuka layar login. Daftar dengan email & kata sandi,
lalu datamu tersimpan di cloud dan tersinkron di setiap perangkat yang
login dengan akun sama.

---

## Catatan

- **Data lokal lama tidak otomatis pindah** ke cloud. Kalau sudah terlanjur
  banyak input saat mode lokal, beri tahu saya — bisa dibuatkan tombol
  migrasi sekali-jalan.
- **Backend harga saham** (folder `backend/`) terpisah dari ini. Kalau pakai
  Firebase Functions, project yang sama bisa dipakai sekalian.
- Mau kembali ke mode lokal? Cukup ubah `useFirebase = false` lagi.
