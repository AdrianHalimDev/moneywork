# MoneyWork 💰✨

Aplikasi pencatatan dan pengelolaan keuangan pribadi modern berbasis **Flutter** untuk Android & Web. **MoneyWork** membantu kamu mencatat transaksi harian, memindai struk belanja dengan **AI OCR**, membagi tagihan patungan secara presisi lewat **Split Bill Interaktif**, mengelola utang-piutang, memantau portofolio investasi secara *real-time*, hingga merencanakan tabungan impian.

---

## 📸 Fitur Unggulan Terbaru (v2.7.2)

- **🤖 Pemindai Bon & Struk Berbasis AI (OCR)**: Foto struk belanja dari kamera atau galeri. AI secara otomatis mengidentifikasi nama merchant, daftar item, harga satuan, PPN, dan service charge. Diproses via Cloudflare Worker Proxy untuk keamanan API key.
- **👥 Split Bill Interaktif (Item Assignment per Qty)**: Tentukan porsi makanan per individu menggunakan selector kuantitas `[ - ] qty [ + ]`. Bebas pelipatgandaan item; sisa makanan yang belum dipilih otomatis dialokasikan sebagai *Item Bersama* (Shared Items) yang dibagi rata. Total hitungan 100% cocok dengan bon fisik.
- **✏️ Edit Transaksi Terarsip**: Ubah Catatan (Berita) dan Kategori pada transaksi yang sudah dicatat tanpa mengganggu mutasi saldo akun.
- **🌐 Dukungan 3 Bahasa (ID, EN, 中文)**: Lokalisasi penuh dalam Bahasa Indonesia, Bahasa Inggris, dan Bahasa Mandarin.
- **📱 Layout Responsif & Landscape Mode**: Navigasi bawah otomatis menyesuaikan menjadi `NavigationRail` lengkap dengan tombol Scan saat layar dimiringkan.
- **☁️ Web Deployment Ready**: Dapat di-build dan di-deploy langsung ke Cloudflare Pages, Vercel, Netlify, atau GitHub Pages.

---

## 📚 Panduan Fitur Lengkap Aplikasi

### 💳 1. Manajemen Akun & Saldo Keuangan
- **Empat Jenis Akun**: Kelola aset di akun **Tunai**, **Bank**, **E-Wallet** (GoPay, OVO, ShopeePay, dll), dan **RDN** (Rekening Dana Nasabah untuk saham).
- **Saldo Berjalan & Saldo Awal**: Setiap transaksi otomatis memutasi saldo akun terkait secara *real-time*.
- **Proteksi Saldo Negatif**: Aplikasi menolak transaksi pengeluaran atau transfer yang melebihi sisa saldo berjalan.
- **Manajemen Akun**: Tambah, edit nama/nomor rekening, ubah warna/ikon, dan hapus akun.

### 📝 2. Transaksi: Pemasukan, Pengeluaran, & Transfer
- **Pemasukan**: Catat uang masuk (gaji, bonus, dividen) ke akun pilihan.
- **Pengeluaran**: Catat uang keluar lengkap dengan kategori (*autocomplete suggestion*) dan catatan/berita.
- **Transfer Antar Akun**: Pindahkan dana antar akun pribadi.
- **Biaya Admin Transfer**: Opsi pencatatan biaya admin saat transfer (misal: top up e-wallet Rp 50.000 + admin Rp 1.000 → BCA berkurang Rp 51.000, GoPay bertambah Rp 50.000). Biaya admin dicatat sebagai pengeluaran terpisah berkategori "Biaya Admin" untuk pelaporan presisi.
- **Edit Transaksi**: Ketuk baris transaksi untuk mengubah Catatan dan Kategori. Kolom nominal, akun, dan tanggal dikunci untuk menjaga integritas pembukuan.
- **Auto-Formatting Ribuan**: Nominal angka otomatis memiliki titik pemisah ribuan saat diketik.

### 📸 3. Pemindai Bon & Struk Otomatis (AI OCR)
- **Sumber Gambar**: Ambil foto dari Kamera langsung atau pilih dari Galeri HP.
- **Ekstraksi Presisi**: Membaca nama toko, item, qty, harga satuan, PPN/pajak, dan service charge dari gambar bon.
- **Verifikasi Matematika**: Fitur *Cross-Check* otomatis mencocokkan total fisik di kertas bon dengan hasil hitungan item.
- **Diskon & Biaya Tambahan**: Hasil OCR membaca potongan harga dan biaya lain (misalnya kemasan atau admin); keduanya dapat dikoreksi di layar review dan diteruskan ke Split Bill.
- **Aksi Instan**: Hasil scan bisa langsung disimpankan sebagai **Transaksi Pengeluaran Baru** atau dilempar ke **Split Bill**.

### 👥 4. Split Bill Interaktif (Patungan Makan Bareng)
- **Wizard 3-Langkah**:
  1. Input jumlah orang yang ikut bayar.
  2. Input nama masing-masing orang (misal: Saya, Abhi, Gama).
  3. Pilih porsi/qty item yang dipesan tiap orang.
- **Selector Qty `[ - ] qty [ + ]`**: Memilih kuantitas item spesifik per orang. Tombol `+` dibatasi hingga sisa item yang belum diambil di bon (mencegah pelipatgandaan item).
- **Auto Shared Items**: Kuantitas item yang belum habis dibagi otomatis dijadikan *Item Bersama* dan dibagi rata.
- **Perhitungan Pajak & Diskon**: PPN dan Service Charge dihitung sebelum diskon. Diskon dapat dibagi rata atau proporsional.
- **Input Persen atau Nominal**: PPN dan Service Charge bisa diisi dalam persen atau Rupiah; nilai pasangannya dihitung otomatis. Biaya tambahan ikut dibagi proporsional.
- **Langsung ke Piutang**: Hasil perhitungan per orang bisa langsung disimpan sebagai Piutang atas nama mereka jika kamu yang menalangi tagihan.

### 🤝 5. Pengelolaan Piutang (Uang Kamu yang Dipinjam Orang)
- **Pengelompokan Otomatis per Nama**: Pinjaman dari orang yang sama otomatis digabung dalam 1 kartu dengan saran nama otomatis.
- **Pelunasan FIFO (First In First Out)**: Pembayaran piutang secara otomatis melunasi pinjaman paling lama terlebih dahulu.
- **Integrasi Saldo Akun**: Pelunasan piutang menambah saldo akun yang dipilih untuk menerima uang.
- **Riwayat Transaksi Piutang**: Melacak detail rincian tiap tanggal pinjaman dan sisa tagihan.

### 💸 6. Pengelolaan Utang (Uang yang Kamu Pinjam)
- **Pencatatan Utang**: Catat utang ke kreditur lengkap dengan nominal dan tanggal jatuh tempo.
- **Pembayaran Utang**: Mengurangi saldo akun pilihan dan mengupdate sisa utang.
- **Pembatalan Pembayaran**: Fitur *rollback* untuk mengembalikan saldo akun dan sisa utang jika terjadi kesalahan.

### 📈 7. Portofolio Investasi & Harga Otomatis
- **Ragam Jenis Aset**: Pantau Saham (dihitung dalam **Lot**), Kripto, Reksadana, Emas, atau Aset Fisik.
- **Sinkronisasi Harga Real-Time**: Perbarui harga pasar otomatis via Cloudflare Worker untuk saham & kripto yang mendukung.
- **Analisis Profit / Loss**: Menampilkan Nilai Pasar (*Market Value*), Gain/Loss nominal (Rp), dan persentase *return* (% PnL).
- **Transaksi Saham via RDN**: Jual/Beli saham memotong/menambah saldo RDN dan menghitung harga beli rata-rata tertimbang (*Average Purchase Price*).

### 🔄 8. Transaksi Bulanan & Tagihan Rutin
- **Template Tagihan Rutin**: Catat langganan bulanan (Netflix, Spotify, Kos, Listrik, Internet) atau cicilan.
- **Eksekusi "Jalankan Semua"**: Catat semua transaksi rutin sekaligus dalam satu klik. Template dilewati otomatis jika saldo akun tidak mencukupi.

### 🎯 9. Wishlist Menabung (Saving Target)
- **Target Tabungan**: Setel foto barang impian, target nominal, dan estimasi waktu pencapaian.
- **Setor Bertahap**: Nabung berkala dengan indikator *Progress Bar* persentase tabungan.
- **Auto-Complete**: Otomatis menandai target selesai saat dana terkumpul 100%.

### 📊 10. Laporan Keuangan & Ekspor Data
- **Grafik Pie Chart**: Visualisasi pengeluaran per kategori secara intuitif.
- **Murni Tanpa Bias**: Transfer antar akun pribadi tidak dihitung sebagai pengeluaran/pemasukan agar grafik tetap akurat.
- **Ekspor Excel (.xlsx)**: Unduh seluruh riwayat transaksi ke dalam file format Excel.

### 🔒 11. Keamanan, Biometrik, & Enkripsi Cloud
- **Layar Kunci (Lock Screen)**: Dilengkapi Keamanan PIN 6-Digit dan Sidik Jari / Biometrik (Fingerprint & Face ID).
- **Kunci Sesi Otomatis**: Aplikasi terkunci otomatis saat ditinggalkan di latar belakang.
- **Cloud Sync Terenkripsi**: Sinkronisasi data ke Firebase Firestore menggunakan enkripsi *End-to-End*.
- **Mode Offline**: Aplikasi tetap berfungsi penuh saat tidak ada koneksi internet (data tersimpan di lokal dan tersinkron otomatis saat online).

---

## 🛠️ Panduan Developer & Deployment

Proyek dibangun menggunakan **Flutter** (SDK `^3.6.0`).

### Perintah Utama:
```bash
# 1. Install dependensi
flutter pub get

# 2. Jalankan di perangkat/emulator (Mobile)
flutter run

# 3. Jalankan di browser (Web)
flutter run -d chrome

# 4. Uji Unit & Analisis Statis
flutter test
flutter analyze

# 5. Build APK Release (Android)
flutter build apk --release

# 6. Build Web Release
flutter build web --release
```

### Deploy Web ke Cloudflare Pages:
```bash
# Build berkas web
flutter build web --release

# Deploy folder build/web ke Cloudflare Pages
npx wrangler pages deploy build/web --project-name=moneywork
```

---

## 🛡️ Kebijakan Keamanan Repositori

File-file sensitif berikut **di-ignore oleh `.gitignore`** dan **tidak pernah di-commit ke repositori publik**:
- `android/key.properties`, `*.jks`, `*.keystore` *(Keystore signing rilis)*
- `android/app/google-services.json`, `lib/firebase_options.dart` *(Konfigurasi project Firebase)*
- `.wrangler/` *(Folder cache build Cloudflare)*

---

Lisensi & Hak Cipta © 2026 **AdrianHalimDev**. All rights reserved.
