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
yang sama lagi; baris yang sudah ada akan ditandai sebagai kemungkinan duplikat.
