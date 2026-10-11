# MoneyWork v2.8.0

**Versi:** `2.8.0` · **Build Android:** `16` · **Tanggal:** 12 Oktober 2026

Pembaruan ini mencakup perubahan sejak APK terakhir di GitHub Releases,
[v2.7.2](https://github.com/AdrianHalimDev/moneywork/releases/tag/v2.7.2).
Fokusnya adalah impor mutasi PDF, perencanaan arus kas, penggunaan offline,
serta penyempurnaan OCR dan Split Bill.

## Fitur baru

### Impor mutasi rekening dari PDF

- Tambahkan riwayat transaksi dari PDF mutasi bank atau e-wallet bulanan melalui layar **Akun**.
- Tinjau, koreksi, dan pilih baris debit/kredit sebelum menyetujui impor.
- Secara bawaan, impor riwayat tidak mengubah saldo saat ini. Tersedia pilihan untuk menerapkan mutasi ke saldo.
- Baris dari PDF yang sama dan sebelumnya sudah diimpor dikenali melalui penanda sumber. Baris yang tampak serupa ditandai untuk diperiksa.
- Penanda sumber tetap dipertahankan ketika catatan transaksi diedit.
- Pemeriksaan saldo awal dan akhir membantu mendeteksi selisih atau transaksi yang belum terbaca.
- Hasil impor menampilkan jumlah transaksi yang benar-benar ditambahkan dan dilewati.
- Validasi tanggal, nominal, mata uang, jumlah halaman, dan kelengkapan hasil ekstraksi diperketat.

### Proyeksi arus kas 30 hari

- Lihat perkiraan saldo 30 hari ke depan dari Beranda.
- Proyeksi menggunakan saldo akun, transaksi rutin yang dijadwalkan, dan utang yang memiliki tanggal jatuh tempo.
- Lihat grafik, perkiraan per akun, hari dengan dana terendah, dan kewajiban yang akan jatuh tempo.
- Transaksi rutin dapat diberi hari bulanan 1–31; tanggal yang tidak tersedia mengikuti hari terakhir bulan tersebut.
- Proyeksi hanya merupakan perkiraan dan tidak otomatis mencatat transaksi atau mengubah saldo.

### Penggunaan offline dengan salinan terenkripsi

- Setelah data dibuka saat online, aplikasi menyimpan salinan terenkripsi khusus pengguna di perangkat.
- Data yang tersimpan dapat dibuka saat koneksi terputus.
- Perubahan offline disimpan ke antrean lokal terenkripsi dan dipulihkan ketika aplikasi dibuka kembali.
- Sinkronisasi yang gagal karena koneksi dicoba kembali selama aplikasi aktif; pengguna juga dapat mencoba ulang secara manual.

## Penyempurnaan OCR dan Split Bill

- OCR struk mendukung **diskon** dan **biaya tambahan**, termasuk potongan yang terbaca sebagai baris item.
- Diskon dan biaya tambahan dapat dikoreksi saat review, lalu diteruskan ke Split Bill.
- Pemeriksaan total OCR memperhitungkan subtotal, service, pajak, biaya tambahan, dan diskon.
- **PPN dan service charge** dapat diisi sebagai persentase atau nominal Rupiah; nilai pasangannya dihitung otomatis berdasarkan dasar perhitungannya.
- Biaya tambahan ikut diperhitungkan dan dibagi proporsional dalam Split Bill.
- Hasil pembagian dapat disalin atau dibagikan sebagai teks berisi rincian tagihan dan jumlah per orang.

## Perbaikan sinkronisasi dan stabilitas

- Data cloud disimpan sebagai dokumen terenkripsi per entitas agar satu penyimpanan tidak mengganti seluruh riwayat.
- Perubahan bersamaan pada akun atau kewajiban yang sama terdeteksi sebagai konflik dan ditampilkan kepada pengguna.
- Beranda dan Akun menampilkan status memuat, menyimpan, tersimpan, atau gagal, beserta tindakan mencoba ulang.
- Kegagalan membaca data tidak lagi diam-diam dianggap sebagai data kosong pada jalur yang diperbaiki.
- Perapian ekspor laporan PDF/Excel dan pilihan periode; backup seluruh data tidak memerlukan pilihan bulan.
- Pembaruan API Flutter yang deprecated, lokalisasi, API berbagi file, dan konfigurasi build Android.
- Penambahan script serta dokumentasi build otomatis Cloudflare Pages dengan validasi konfigurasi Firebase.

## Catatan penggunaan

- **Buka aplikasi saat online setelah update** untuk menyiapkan salinan data offline. Perangkat baru tetap memerlukan internet untuk login dan memuat data pertama kali.
- Gunakan APK dan web terbaru pada seluruh perangkat agar format data cloud tetap kompatibel.
- Status **tersimpan** berarti perubahan telah diterima server. Saat konflik, periksa perubahan lokal sebelum memilih memuat versi cloud.
- Impor PDF saat ini mendukung **Rupiah (IDR)**, maksimal **10 MB**, **40 halaman**, dan **500 transaksi** per PDF.
- PDF dikirim ke layanan OCR dan Gemini setelah persetujuan pengguna. Hasil AI tetap perlu dibandingkan dengan mutasi asli; PDF yang dilindungi sandi perlu dibuka terlebih dahulu.
- Perlindungan impor ulang bergantung pada isi PDF dan hasil ekstraksi identitas yang konsisten. PDF yang berbeda atau hasil AI yang berubah tetap perlu ditinjau.
- Impor besar dengan pilihan mengubah saldo masih dapat ditolak oleh batas penyimpanan. Untuk mutasi historis, gunakan pilihan bawaan tanpa mengubah saldo dan periksa status sinkronisasi setelah impor.
- OCR struk dan impor PDF memerlukan koneksi internet, Worker OCR terbaru, serta secret runtime `GEMINI_API_KEY` yang aktif. Update APK tidak menggantikan deployment Worker.

## Instalasi pembaruan

Unduh **`MoneyWork-v2.8.0-build16.apk`** dari aset rilis dan pasang sebagai
pembaruan aplikasi yang sudah ada.

## Verifikasi rilis

- `flutter analyze`: tidak ada masalah.
- `flutter test --no-pub`: 102 tes lulus.
- Tes Worker OCR/PDF: 11 tes lulus.
- APK release diverifikasi sebagai `com.moneywork.moneywork`, versi `2.8.0`, build `16`.
- Signature APK valid dan sertifikat signing cocok dengan APK GitHub v2.7.2.
- Build masih menghasilkan warning metadata Android SDK XML; warning tersebut tidak menggagalkan build.
- Pengujian otomatis menggunakan data simulasi dan belum menggantikan uji PDF bank asli, instalasi di HP, atau sinkronisasi Firestore pada jaringan nyata.
