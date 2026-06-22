# MoneyWork

Aplikasi pencatatan keuangan pribadi untuk Android. Catat pemasukan dan pengeluaran,
kelola utang-piutang, pantau investasi, bagi tagihan bareng teman, dan lihat ke mana
uangmu pergi lewat laporan. Data tersimpan di cloud dan tetap bisa dibuka saat offline.

---

## Panduan Penggunaan

### Akun

Akun adalah tempat uangmu berada: **Tunai**, **Bank**, **E-Wallet**, atau **RDN**
(rekening dana saham). Setiap akun punya saldo berjalan yang otomatis ikut berubah
setiap kali kamu mencatat transaksi.

- Tambah akun lewat tab **Akun** → tombol tambah, lalu pilih jenis dan saldo awal.
- Saldo tidak pernah dibuat minus: aplikasi menolak pengeluaran/transfer yang melebihi saldo.

### Transaksi: Pemasukan, Pengeluaran, Transfer

Catat lewat tab **Akun**. Tiga jenis:

- **Pemasukan** — uang masuk ke sebuah akun (gaji, bonus, dll).
- **Pengeluaran** — uang keluar, dengan kategori dan catatan.
- **Transfer** — pindah saldo antar akunmu sendiri.

**Biaya admin transfer.** Saat memilih Transfer, aktifkan **"Ada biaya admin"** bila
ada potongan. Contoh: top up GoPay 50.000 dengan admin 1.000 → BCA berkurang 51.000,
GoPay bertambah 50.000. Biaya admin dicatat sebagai pengeluaran terpisah berkategori
"Biaya Admin" sehingga total admin yang kamu bayar bisa dilihat di laporan.

### Piutang (uang yang dipinjam orang ke kamu)

Di tab **Piutang**, catat siapa yang berhutang dan berapa. Piutang **otomatis
dikelompokkan per nama**, jadi kalau Gama meminjam beberapa kali, semuanya menyatu
dalam satu kartu dengan total sisa.

- Saat mengetik nama, aplikasi **menyarankan nama yang sudah ada** agar tidak terpecah
  (mis. "gama" dan "Gama" dianggap sama).
- Ketuk kartu untuk melihat rincian tiap pinjaman.
- Tombol **Terima** menerima pembayaran gabungan: jumlah yang dibayar otomatis melunasi
  **pinjaman paling lama dulu**. Contoh: Gama berhutang 100rb lalu 200rb, bayar 150rb →
  yang 100rb lunas, sisa hutang tinggal 150rb.

### Utang (uang yang kamu pinjam)

Di tab **Utang**, catat utangmu dan bayar dari akun tertentu. Saldo akun berkurang dan
sisa utang ikut menyusut. Membatalkan pembayaran mengembalikan keduanya.

### Split Bill (bagi tagihan)

Kalkulator patungan di tab **Split Bill**:

- Masukkan item dan siapa yang ikut menanggung tiap item (atau item bersama dibagi rata).
- Tambahkan **PPN** dan **biaya layanan** (dihitung sebelum diskon), serta **diskon**
  (dibagi rata atau proporsional, dipotong terakhir).
- Hasilnya bisa langsung **masuk ke piutang per orang** — kalau kamu yang menalangi,
  bagian teman otomatis jadi piutang atas nama mereka.

### Investasi

Pantau aset di tab **Investasi**: saham (dihitung dalam **lot**), kripto, atau lainnya.

- **Perbarui semua harga sekaligus** lewat tombol sinkron di pojok kanan atas (untuk aset
  yang mendukung harga otomatis).
- Tiap aset menampilkan nilai pasar, **untung/rugi dalam Rupiah**, dan persentasenya.
- Transaksi saham (beli/jual) lewat ikon RDN: saldo RDN dan posisi lot menyesuaikan,
  harga beli dihitung rata-rata tertimbang.

### Transaksi Bulanan

Untuk tagihan rutin (langganan, cicilan, dll) di tab **Transaksi Bulanan**:

- Buat **template** lewat tombol tambah di kanan atas.
- **Jalankan Semua** mencatat semua template aktif sekaligus; template dilewati bila
  saldo tidak cukup.

### Wishlist Menabung

Tetapkan target tabungan dan nabung bertahap. Aplikasi menghitung cicilan dan progres,
serta otomatis menandai selesai saat target tercapai.

### Pengingat

Notifikasi lokal mengingatkan hal seperti belum ada transaksi hari ini atau ajakan
menabung setelah gajian.

### Laporan

Lihat ringkasan bulanan dan rincian per kategori dalam bentuk grafik. Transfer antar
akun sendiri tidak dihitung sebagai pemasukan/pengeluaran agar laporan tetap akurat.

### Akun & Sinkronisasi

Masuk dengan Google atau email/kata sandi. Data disimpan di cloud per pengguna dan
**tetap bisa dibuka saat offline** — perubahan tersinkron otomatis begitu kembali online.

### Pembaruan Aplikasi

Aplikasi memeriksa versi terbaru saat dibuka. Bila ada pembaruan, muncul dialog yang
memandu unduh dan pasang langsung dari dalam aplikasi. Pertama kali, Android meminta izin
"install dari sumber tak dikenal" — cukup sekali.

---

## Untuk Developer

Proyek Flutter (Dart `^3.6.0`). Detail teknis singkat:

```bash
flutter pub get
flutter run            # jalankan di perangkat/emulator
flutter test           # uji unit
flutter analyze        # cek statis
flutter build apk --release
```

- **Signing rilis** dibaca dari `android/key.properties` (tidak di-commit). Selalu pakai
  keystore yang sama agar pembaruan bisa "install menimpa" tanpa uninstall.
- **Firebase** diaktifkan di `lib/firebase/firebase_config.dart`. Data:
  `users/{uid}/data/state` (AppState) dan `meta/app_version` (metadata OTA).
- **Pembaruan OTA** bersifat self-hosted dan gratis: metadata versi di Firestore, file
  APK di GitHub Releases. Alur rilis lengkap ada di [`RELEASING.md`](RELEASING.md).

### Keamanan repositori

File berikut **tidak di-commit** (lihat `.gitignore`) dan tidak boleh bocor ke repo publik:
`android/key.properties`, `*.jks`/`*.keystore`, `lib/firebase_options.dart`,
`android/app/google-services.json`.
