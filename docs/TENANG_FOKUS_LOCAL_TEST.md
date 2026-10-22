# Mencoba Tenang Fokus di lokal

Frontend Flutter yang sama digunakan Android dan web. Build lokal tetap memakai konfigurasi Firebase aplikasi; bila masuk dengan akun yang sama, perubahan data dan tema dapat tersinkron ke perangkat lain.

## Alur yang dicoba

1. **Beranda:** saldo rekening menjadi angka utama. Arus kas bulan berjalan mengikuti laporan (transfer dikecualikan, biaya admin dihitung sebagai pengeluaran). Kekayaan bersih ditampilkan sebagai informasi terpisah.
2. **Catat Transaksi:** isi nominal, rekening, dan kategori. Buka **Catatan & tanggal** bila perlu. Pada HP, isi bisa digulir dan tombol Simpan berada di luar area gulir, di atas keyboard.
3. **Transfer:** sumber dan tujuan berbeda; rekening tujuan mengikuti urutan pilihan setelah sumber dikecualikan. Periksa nominal, biaya admin, total keluar, dan saldo setelah transaksi sebelum menyimpan.
4. **Rekening:** ketuk kartu untuk membuka saldo dan riwayat khusus rekening itu. Transfer masuk ditampilkan positif pada rekening penerima. Tombol ubah membuka pengaturan; **Catat di rekening ini** memilih rekening yang sedang dilihat.
5. **Aset:** ketuk aset untuk melihat nilai pasar, modal, jumlah, dan untung/rugi; tombol ubah tetap tersedia. Urutan aset/rekening dan sinkronisasinya tetap didukung.
6. **Alat → Tampilan:** coba **Terang**, **Gelap**, dan **Ikuti sistem**. Pengaturan tema profil yang lama tetap tersedia.
7. **Sembunyikan nominal:** pilihan berlaku bersama selama sesi pada Beranda, rekening, aset, tagihan, laporan, proyeksi, wishlist, dan transaksi rutin. Grafik yang dapat mengungkap nominal ikut disembunyikan. Form input dan review dokumen menampilkan nilai agar dapat diperiksa; ekspor data tidak diubah.
8. **Review struk:** foto asli tetap dapat dibuka, atau ditampilkan berdampingan pada layar lebar. Total dan selisih ditampilkan sebelum tombol transaksi/Split Bill aktif. Kegagalan OCR dapat dicoba ulang dengan foto yang sama.
9. **Review PDF:** filter hasil pemeriksaan dan jumlah terpilih tetap tersedia; tombol impor berada di luar daftar panjang. Konfirmasi impor, pemeriksaan duplikat, dan pilihan dampak terhadap saldo tetap berlaku.

## Penyimpanan

- **Tersinkron** berarti tulisan telah diterima cloud.
- **Tersimpan di perangkat · menunggu sinkronisasi** berarti salinan lokal sudah disimpan dan belum selesai dikirim.
- Kegagalan simpan lokal tidak diberi label tersimpan. Muat versi cloud hanya ditawarkan pada backend cloud dan selalu melalui konfirmasi.
- Detail teknis kegagalan berada di **Rincian**.

## Menjalankan sendiri

```powershell
flutter build web --release
python scripts/serve-local.py
```

Buka `http://localhost:8080/`. Jika tab masih menampilkan tampilan lama, lakukan hard refresh (`Ctrl+Shift+R`). Build lokal tidak memublikasikan website, APK, atau metadata OTA.
