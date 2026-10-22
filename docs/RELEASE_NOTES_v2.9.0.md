# MoneyWork v2.9.0 — Tenang Fokus

Versi aplikasi **2.9.0**, build **17**. Perubahan sejak v2.8.0.

## Tampilan aplikasi dan website

- Tampilan Tenang dengan warna hijau, permukaan netral, dan ringkasan yang lebih mudah dibaca.
- Beranda baru: sapaan pengguna, saldo rekening, pencatatan transaksi, arus kas bulanan, serta kekayaan bersih sebagai informasi terpisah. Scan struk, impor PDF, dan Split Bill tersedia melalui Alat.
- Nominal dapat disembunyikan bersama pada berbagai halaman untuk privasi layar.
- Navigasi bawah di HP serta sidebar dengan akses alat keuangan pada layar desktop.
- Website memakai ringkasan berdampingan dan tabel transaksi/aset ketika lebar layar mencukupi.
- Halaman Rekening menampilkan ringkasan saldo, kartu menuju detail/riwayat, filter, serta akses ubah/hapus transaksi yang tetap melalui konfirmasi.
- Halaman Aset menampilkan portofolio, komposisi investasi pada layar lebar, nilai pasar, dan untung/rugi.
- Tema terang/gelap serta tata letak daftar sebagai pengganti tabel saat layar sempit atau teks diperbesar.

## Tenang Fokus

- Beranda mengutamakan saldo rekening, pencatatan transaksi, dan arus kas bulan berjalan. Kekayaan bersih tetap ditampilkan terpisah.
- Form transaksi dapat digulir di HP, dengan tombol simpan di luar area gulir dan di atas keyboard. Desktop menggunakan dialog dan ringkasan yang berdampingan.
- Transfer menampilkan sumber, tujuan, biaya admin, total keluar, dan perkiraan saldo setelah dicatat. Tujuan tidak menyertakan rekening sumber.
- Mengedit catatan transfer mempertahankan biaya admin tertaut dan saldo; simpan ganda dicegah.
- Mengetuk rekening membuka detail saldo dan riwayat. Transfer masuk ditampilkan positif pada rekening penerima. Mengetuk aset membuka rincian portofolio; akses ubah/hapus tetap tersedia.
- Menu **Alat** mengelompokkan fitur keuangan pendukung. Pilihan **Terang**, **Gelap**, dan **Ikuti sistem** tetap tersedia di **Alat → Tampilan** dan profil.
- Privasi nominal berlaku bersama selama sesi di halaman utama dan fitur ringkasan lain; grafik yang dapat mengungkap nilai ikut disembunyikan. Angka pada form input, review dokumen, dan ekspor tetap dapat diperiksa.
- Status sinkronisasi membedakan perubahan yang tersimpan di perangkat dan yang telah diterima cloud. Rincian teknis dibuka terpisah. Mode lokal tidak menawarkan pemuatan cloud.
- Review OCR menyertakan foto asli dan ringkasan selisih; review PDF memiliki filter serta tombol impor yang tetap tersedia di luar daftar panjang.

Panduan uji manual tersedia di [TENANG_FOKUS_LOCAL_TEST.md](TENANG_FOKUS_LOCAL_TEST.md).

## Urutan aset yang tersinkron

1. Buka **Aset → Atur urutan**.
2. Geser pegangan atau gunakan tombol naik/turun.
3. Pilih **Simpan urutan**. **Batal** mengabaikan perubahan dalam editor.
4. Tunggu status sinkronisasi menunjukkan data tersimpan di cloud.

Urutan disimpan berdasarkan ID aset sebagai preferensi terenkripsi akun, terpisah dari harga, jumlah, modal, dan saldo. Perangkat lain yang sedang terbuka menerima perubahan urutan melalui listener Firestore. Aset baru yang belum dipilih urutannya ditampilkan di akhir; ID aset yang sudah dihapus diabaikan. Urutan juga ikut dalam penyimpanan lokal dan cadangan JSON.

Saat offline, perubahan mengikuti antrean penyimpanan terenkripsi yang sudah ada dan dikirim kembali ketika sinkronisasi berhasil. Perubahan masuk dari perangkat lain ditunda selama masih ada simpanan lokal yang berjalan/belum selesai. Dua perubahan pada urutan yang sama menggunakan pemeriksaan revisi: konflik ditampilkan, bukan ditimpa diam-diam. Gunakan opsi memuat versi cloud setelah meninjau perubahan lokal jika memilih urutan perangkat lain.

Jika urutan berubah saat editor terbuka, simpan ditahan dan pengguna diminta membuka ulang editor untuk meninjau urutan terbaru.

## Urutan rekening dan dropdown transaksi

1. Buka **Akun → Atur urutan rekening**.
2. Geser rekening atau gunakan tombol naik/turun, lalu **Simpan urutan**.
3. Daftar rekening dan dropdown rekening di transaksi mengikuti urutan tersebut, termasuk sumber dan tujuan transfer.

Rekening pertama menjadi pilihan awal transaksi baru. Transaksi yang sudah ada tetap memakai ID rekening semula. Urutan juga digunakan pada pilihan rekening di fitur lain, seperti transaksi rutin, Split Bill, impor mutasi, utang/piutang, dan pembelian aset. Rekening baru muncul di akhir.

Preferensi rekening disimpan terpisah dari preferensi aset dan tersinkron antar perangkat dengan akun yang sama. Keduanya mendukung cache terenkripsi, antrean offline, dan pemeriksaan konflik revisi. Mengurutkan rekening tidak mengubah saldo atau riwayat transaksi.

## Catatan pemasangan

- Perbarui **APK dan website** ke versi yang mendukung urutan aset dan rekening. Versi lama belum mengenali preferensi ini dan dapat menghapusnya saat menyimpan data.
- Gunakan akun yang sama dan buka kunci data pada setiap perangkat. Mode lokal menyimpan urutan hanya di perangkat tersebut.
- Pembaruan frontend tidak memerlukan perubahan Worker OCR atau API key.
- Build website berada di `build/web`; APK disiapkan sebagai aset GitHub Release, bukan berkas sumber Git.
- Ini tidak mengubah perhitungan keuangan maupun menjalankan transaksi otomatis.

## Verifikasi

Pengujian mencakup codec record, pemulihan cache terenkripsi, dua replika perangkat, konflik saat offline, perubahan preferensi lain selama sinkronisasi, editor urutan, navigasi, lebar HP/desktop, serta tema dan ukuran teks besar. Simulasi replika tidak menggantikan uji pada dua perangkat dengan akun Firebase sungguhan.

- `flutter analyze --no-pub`: tidak ada masalah.
- Seluruh **167 tes Flutter lulus**, termasuk form saat keyboard terbuka, edit transfer beserta biaya admin, detail rekening/aset, tema terang/gelap/sistem, privasi antarlayar, serta sinkronisasi urutan dan konflik offline.
- `flutter build web --release --no-pub --no-wasm-dry-run`: hasil JavaScript di `build/web`, versi `2.9.0`, build `17`.
- `flutter build apk --release --no-pub`: berhasil; APK `MoneyWork-v2.9.0-build17.apk` tersedia di `build/releases`.
- Metadata APK menunjukkan `versionCode=17`, `versionName=2.9.0`; signature valid dan sertifikat sama dengan APK v2.8.0 sebelumnya.
- Warning metadata Android SDK XML dan pemeriksaan kompatibilitas Wasm pada dependensi lama masih muncul. Keduanya tidak menggagalkan build Android maupun build web JavaScript ini.

Teks pembaruan dalam aplikasi tersedia di `docs/UPDATE_TEXT_v2.9.0.txt`. Contoh field OTA ada di `docs/OTA_v2.9.0.example.json`; gunakan setelah APK benar-benar diunggah ke GitHub Release v2.9.0. Build ini belum otomatis memublikasikan website, APK, atau metadata Firestore.
