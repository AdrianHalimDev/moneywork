# OCR bon dan impor PDF mutasi

Worker ini menyediakan dua endpoint:

- `POST /scan` untuk foto bon yang sudah ada.
- `POST /statement-scan` untuk PDF mutasi bank/e-wallet bulanan. Aplikasi
  meminta persetujuan sebelum mengirim PDF, kemudian pengguna memilih dan
  memeriksa transaksi sebelum impor. PDF tidak disimpan dalam Firestore.

Endpoint PDF menerima `{"pdfBase64":"..."}` dan mengembalikan halaman,
saldo awal/akhir (jika tercetak), dan baris debit/kredit. Batas aplikasi adalah
10 MB, 40 halaman, dan 500 transaksi per PDF. PDF hasil scan juga dibaca oleh
model. PDF yang dilindungi sandi perlu dibuka lebih dulu.

## Deploy setelah perubahan kode

Jalankan dari direktori ini:

```sh
node --test worker.test.mjs
npx wrangler login
npx wrangler secret put GEMINI_API_KEY
npx wrangler deploy
```

Jika secret sudah terpasang, langkah `secret put` tidak perlu diulang.
Pastikan URL Worker hasil deploy sama dengan endpoint di
`lib/screens/accounts_screen.dart`. Build web/APK baru juga perlu dirilis agar
tombol impor muncul bagi pengguna. Kode baru tidak mengaktifkan endpoint pada
Worker yang masih menjalankan versi lama sampai `wrangler deploy` dijalankan.

Hasil AI harus tetap diperiksa terhadap PDF asli. Layar review menandai
kemungkinan duplikat dan selisih saldo, serta secara bawaan memasukkan mutasi
sebagai riwayat tanpa mengubah saldo saat ini.

Impor yang sangat panjang disinkronkan dalam beberapa kelompok dokumen. Jika
status simpan gagal di tengah jalan, sebagian baris mungkin sudah masuk cloud.
Setelah masalah sinkronisasi diselesaikan dan versi cloud dimuat, pilih PDF
yang sama lagi; baris yang sudah diimpor dengan versi aplikasi ini dilewati
berdasarkan identitas sumber PDF. Transaksi yang hanya terlihat serupa tetap
ditandai untuk ditinjau, karena dua transaksi dengan nominal/tanggal sama
bisa merupakan transaksi yang berbeda.

## Ketepatan dan impor ulang

- Rekening yang didukung adalah Rupiah (IDR). Worker menolak mata uang lain
  agar nominal asing tidak tercatat sebagai Rupiah.
- Nominal yang formatnya rusak tidak diubah menjadi nol. Barisnya ditandai
  tidak valid. Saldo awal/akhir yang tidak terbaca membuat pemeriksaan
  kelengkapan dari saldo tidak tersedia, dan aplikasi menampilkan peringatan.
- Rekonsiliasi menggunakan ketelitian dua angka desimal. Selisih Rp 0,01 pun
  ditampilkan. Mengubah debit menjadi kredit akan mengubah selisih pemeriksaan.
- Aplikasi memberi identitas pada baris berdasarkan isi PDF, tanggal, arah,
  nominal, referensi bank jika tersedia, dan urutan kemunculan baris serupa.
  Nama file dan uraian AI tidak menentukan identitas. Identitas disimpan
  terenkripsi dan dipertahankan ketika transaksi diedit.
- Perlindungan pasti berlaku untuk file PDF dengan isi byte yang sama dan
  hasil ekstraksi identitas yang konsisten. PDF yang diunduh ulang atau
  diedit bisa memiliki isi berbeda. Perubahan tanggal, nominal, referensi,
  atau kelengkapan baris hasil AI tetap perlu ditinjau terhadap PDF asli.
- Mutasi yang diimpor sebelum penanda sumber ini tersedia hanya dapat
  diperiksa sebagai kemungkinan duplikat, bukan dipastikan otomatis.

Contoh yang dicakup tes otomatis (hasil ekstraksi dan penyimpanan disimulasikan):

| Kasus | Hasil yang diharapkan |
| --- | --- |
| Saldo Rp 100.000, impor debit Rp 10.000 dan kredit Rp 5.000 dengan opsi mengubah saldo | Saldo menjadi Rp 95.000 |
| Impor PDF yang sama lagi | Tidak menambah transaksi atau mengubah saldo lagi |
| Debit sudah tersimpan; impor ulang seluruh PDF | Hanya kredit yang belum tersimpan ditambahkan |
| Dua transaksi debit Rp 10.000 yang benar-benar terpisah di PDF, keduanya dipilih | Keduanya tersimpan dengan identitas berbeda |
| Nominal `1.23.45` atau tanggal `2026-09-31` | Baris ditandai tidak valid |

Tes ini belum menggantikan uji PDF bank asli melalui Gemini dan uji koneksi
putus di Firestore nyata. Tidak ada PDF atau data rekening nyata dalam tes.
