# MoneyWork v1.1.9

**versionCode:** 11 · **versionName:** 1.1.9

Rilis ini memperbaiki pembaruan otomatis (OTA) dan menambah cara manual untuk memeriksa update, plus beberapa perbaikan keamanan & ketahanan.

## ✨ Baru
- **Tombol "Cek pembaruan" di Profil → Aplikasi.** Periksa & pasang versi terbaru kapan saja. Berguna bila tak sengaja menekan "Lewati" saat dialog update muncul — tombol ini tetap menawarkan update terbaru.

## 🐛 Perbaikan
- **Dialog pembaruan otomatis kini muncul dengan benar.** Sebelumnya dialog gagal tampil di versi rilis karena ditampilkan di atas Navigator; sekarang dibuka lewat navigator root sehingga andal.
- **Pesan error harga tidak lagi membocorkan URL internal.** Saat offline atau gagal mengambil harga, aplikasi menampilkan pesan ramah tanpa menyebut alamat endpoint.

## 🔒 Keamanan
- **Proxy harga saham diperketat.** Backend kini memvalidasi format kode saham dan menolak input yang tidak wajar, mengurangi peluang penyalahgunaan.

## 📲 Cara memasang
1. Unduh `moneywork-v1.1.9.apk` di bawah.
2. Buka file-nya, izinkan "pasang aplikasi tak dikenal" bila diminta.
3. Pasang menimpa versi lama — data kamu tetap aman.

> Pengguna versi sebelumnya akan otomatis ditawari pembaruan ini saat membuka aplikasi.
