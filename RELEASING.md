# Panduan Rilis & Pembaruan OTA

Pembaruan over-the-air (OTA) MoneyWork bersifat **self-hosted dan gratis**: metadata versi
disimpan di Firestore (paket gratis Spark), file APK di-host di **GitHub Releases**. Tidak
memerlukan Firebase Storage maupun kartu kredit.

## Cara kerja

1. Saat aplikasi dibuka (setelah login), aplikasi membaca dokumen `meta/app_version` di Firestore.
2. `latestVersionCode` dibandingkan dengan build number aplikasi terpasang (bagian `+N` versi).
3. Bila versi server lebih tinggi, dialog pembaruan muncul → unduh APK → buka installer Android.

## Setup sekali

### Firestore rules

Izinkan pengguna login membaca dokumen versi; tulis hanya lewat Console:

```
match /meta/{doc} {
  allow read: if request.auth != null;
  allow write: if false;
}
```

### Dokumen `meta/app_version`

Buat koleksi `meta` → dokumen `app_version` dengan field:

| Field | Tipe | Keterangan |
|---|---|---|
| `latestVersionCode` | number | Dibandingkan dengan build number (`+N`) di `pubspec.yaml` |
| `latestVersionName` | string | Ditampilkan ke pengguna, mis. `1.1.4` |
| `apkUrl` | string | URL unduh langsung APK (GitHub Releases) |
| `releaseNotes` | string | Ringkasan perubahan (opsional) |
| `mandatory` | boolean | `true` = update wajib, dialog tak bisa ditutup |

Nilai baseline saat ini (OTA aktif tapi belum memicu update):

```
latestVersionCode: 5
latestVersionName: "1.1.3"
apkUrl: "https://github.com/AdrianHalimDev/moneywork/releases/download/v1.1.3/app-release.apk"
releaseNotes: "Versi 1.1.3"
mandatory: false
```

## Alur tiap rilis

1. Naikkan versi di `pubspec.yaml` — angka `+N` **wajib** selalu naik, mis. `1.1.4+6`.
2. `flutter build apk --release` → hasil di `build/app/outputs/flutter-apk/app-release.apk`.
3. GitHub → **Releases → Draft a new release** → buat tag (mis. `v1.1.4`) → unggah
   `app-release.apk` → **Publish release**.
4. Klik kanan aset APK → **Copy link address**. Bentuknya:
   `https://github.com/AdrianHalimDev/moneywork/releases/download/v1.1.4/app-release.apk`
5. Perbarui dokumen `meta/app_version`: `latestVersionCode` → `6`, `latestVersionName`
   → `1.1.4`, `apkUrl` → tautan tadi, `releaseNotes` → ringkasan.

Saat pengguna membuka aplikasi berikutnya, dialog pembaruan muncul → unduh → installer berjalan.

## Catatan penting

- **Konsistensi keystore.** Semua APK harus ditandatangani keystore yang sama
  (`android/key.properties`). Tanpa itu, pembaruan tidak bisa "install menimpa" tanpa uninstall.
- **Repo harus publik** (atau repo khusus rilis) agar URL APK bisa diunduh tanpa login.
  Bila privat, tautan butuh token dan unduhan akan gagal.
- **Izin install.** Pertama kali, Android meminta izin "install dari sumber tak dikenal"
  untuk MoneyWork. Normal, cukup sekali.
- **Update wajib.** Set `mandatory: true` untuk pembaruan kritis — dialog tak bisa
  ditutup/dilewati sampai dipasang.
- **Update opsional yang dilewati** tidak ditampilkan lagi sampai ada `latestVersionCode`
  yang lebih baru.
