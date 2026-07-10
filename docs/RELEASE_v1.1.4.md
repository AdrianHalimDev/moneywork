# Rilis v1.1.4 (build 6)

Tanggal: 2026-06-23

## Perubahan

- **Investasi:** Tombol refresh harga di tiap kartu saham dihapus. Pembaruan harga
  kini cukup lewat tombol **"Perbarui semua harga"** di pojok kanan atas — lebih ringkas
  dan tidak ada aksi ganda.

## Versi

| | Lama | Baru |
|---|---|---|
| `versionName` | 1.1.3 | **1.1.4** |
| `versionCode` (`+N`) | 5 | **6** |

## Langkah rilis OTA

1. APK sudah ter-build di `build/app/outputs/flutter-apk/app-release.apk`.
2. GitHub → **Releases → Draft a new release** → tag `v1.1.4` → unggah `app-release.apk`
   → **Publish release**.
3. Klik kanan aset APK → **Copy link address**.
4. Perbarui dokumen Firestore `meta/app_version` dengan nilai di bawah.

## Nilai dokumen `meta/app_version` (siap tempel)

```json
{
  "latestVersionCode": 6,
  "latestVersionName": "1.1.4",
  "apkUrl": "https://github.com/AdrianHalimDev/moneywork/releases/download/v1.1.4/app-release.apk",
  "releaseNotes": "Tombol refresh per kartu saham dihapus. Pakai 'Perbarui semua harga' di pojok kanan atas.",
  "mandatory": false
}
```

> Ganti `apkUrl` bila tautan asset GitHub berbeda dari pola di atas.

## Verifikasi update berhasil

Buka aplikasi di HP yang masih versi `+5` → dialog pembaruan muncul → unduh → installer
Android jalan. Tanda update sukses: **tombol refresh kecil di tiap kartu saham hilang**.
