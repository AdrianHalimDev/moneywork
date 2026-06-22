# MoneyWork

Aplikasi pencatatan keuangan pribadi (Flutter) — transaksi, akun, utang & piutang,
investasi, split bill, transaksi bulanan, wishlist, dan laporan. Sinkronisasi cloud
lewat Firebase (Auth + Firestore) dengan cache offline, plus pembaruan OTA mandiri.

## Fitur utama

- **Akun & transaksi**: kas, bank, e-wallet, RDN. Pemasukan, pengeluaran, dan transfer
  antar akun. Transfer mendukung **biaya admin terpisah** (mis. top up GoPay 50rb +
  admin 1rb → sumber keluar 51rb, tujuan terima 50rb) yang tetap tertracking di laporan.
- **Utang & piutang**: piutang **dikelompokkan otomatis per nama** dengan pembayaran
  gabungan **FIFO** (melunasi pinjaman paling lama dulu).
- **Split bill**: kalkulator patungan dengan PPN, service, dan diskon (rata/proporsional);
  hasil otomatis masuk ke piutang per orang.
- **Investasi**: posisi saham (lot)/kripto/lainnya, refresh **semua harga sekaligus**,
  untung/rugi ditampilkan dalam Rupiah dan persentase.
- **Transaksi bulanan**: template berulang, jalankan semua sekaligus.
- **Wishlist menabung**, **pengingat** (notifikasi lokal), dan **laporan** (grafik).
- **Pembaruan OTA**: aplikasi memeriksa versi terbaru dan memandu unduh + pasang APK.

## Menjalankan

```bash
flutter pub get
flutter run
```

Butuh Flutter SDK (Dart `^3.6.0`). Lihat `pubspec.yaml` untuk dependensi.

## Build APK rilis

Signing release dibaca dari `android/key.properties` (tidak di-commit). Buat file ini
berdasarkan keystore-mu:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=C:/path/ke/keystore.jks
```

Lalu:

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> **Penting:** selalu gunakan keystore yang sama untuk setiap rilis. Pembaruan OTA hanya
> bisa "install menimpa" tanpa uninstall bila APK ditandatangani kunci yang konsisten.

## Firebase

Integrasi diaktifkan lewat `lib/firebase/firebase_config.dart` (`useFirebase = true`).
Konfigurasi project (`lib/firebase_options.dart`, `android/app/google-services.json`)
tidak di-commit; hasilkan dengan `flutterfire configure`. Struktur data:

```
users/{uid}/data/state   → seluruh AppState (satu dokumen JSON)
meta/app_version         → metadata rilis untuk OTA (lihat di bawah)
```

## Pembaruan OTA (self-hosted, gratis)

OTA tidak memerlukan Firebase Storage. Metadata versi disimpan di Firestore (paket
gratis Spark) dan file APK di-host di **GitHub Releases**.

### Firestore rules (sekali)

Izinkan pengguna login membaca dokumen versi; tulis hanya lewat Console:

```
match /meta/{doc} {
  allow read: if request.auth != null;
  allow write: if false;
}
```

### Dokumen `meta/app_version`

| Field | Tipe | Keterangan |
|---|---|---|
| `latestVersionCode` | number | Dibandingkan dengan build number (`+N`) di `pubspec.yaml` |
| `latestVersionName` | string | Ditampilkan ke pengguna, mis. `1.1.4` |
| `apkUrl` | string | URL unduh langsung APK (GitHub Releases) |
| `releaseNotes` | string | Ringkasan perubahan (opsional) |
| `mandatory` | boolean | `true` = update wajib, dialog tak bisa ditutup |

### Alur tiap rilis

1. Naikkan versi di `pubspec.yaml` (angka `+N` **wajib** naik), mis. `1.1.4+6`.
2. `flutter build apk --release`.
3. GitHub → **Releases → Draft a new release** → buat tag (mis. `v1.1.4`) → unggah
   `app-release.apk` → **Publish**.
4. Salin tautan aset APK (klik kanan → *Copy link address*):
   `https://github.com/<user>/<repo>/releases/download/v1.1.4/app-release.apk`
5. Perbarui dokumen `meta/app_version` di Firestore: `latestVersionCode` → `6`,
   `latestVersionName` → `1.1.4`, `apkUrl` → tautan tadi.

Saat pengguna membuka aplikasi berikutnya, dialog pembaruan muncul → unduh → installer
Android berjalan.

> Repo (atau repo khusus rilis) harus **public** agar URL APK bisa diunduh tanpa login.

## Keamanan repositori

File berikut **tidak di-commit** (lihat `.gitignore`) dan tidak boleh bocor ke repo public:

- `android/key.properties` — berisi password keystore dalam teks biasa.
- `*.jks` / `*.keystore` — file keystore signing.
- `lib/firebase_options.dart`, `android/app/google-services.json` — konfigurasi Firebase.

## Pengujian

```bash
flutter test
flutter analyze
```
