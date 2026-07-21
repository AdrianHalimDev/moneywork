# MoneyWork 💰✨

Aplikasi pencatatan keuangan pribadi modern berbasis **Flutter** untuk Android & Web. Catat transaksi harian, scan struk belanja dengan **AI OCR**, patungan makan bareng lewat **Split Bill Interaktif**, kelola utang-piutang, pantau investasi, dan analisis keuanganmu secara *real-time*.

> 🚀 **Versi Terbaru v2.7.2:**
> - **📸 Pemindai Bon AI (OCR)**: Ambil foto struk dari Kamera/Galeri; AI (Gemini + Cloudflare Worker Proxy) mengekstrak item, PPN, dan service charge secara instan.
> - **👥 Split Bill Interaktif (Item Assignment per Qty)**: Pilih kuantitas menu `[ - ] qty [ + ]` per orang. Bebas pelipatgandaan item; sisa item otomatis dialokasikan ke Item Bersama.
> - **✏️ Edit Transaksi**: Ubah Catatan (Berita) dan Kategori transaksi terarsip tanpa mengubah saldo akun.
> - **🌐 3 Bahasa (ID, EN, 中文)**: Bahasa Indonesia, Inggris, dan Mandarin penuh dengan navigasi yang responsif.
> - **📱 Tampilan Landscape Responsive**: Tombol scan hadir di `NavigationRail` saat HP dimiringkan.
> - **🌐 Deploy Web-Ready**: Siap di-deploy ke Cloudflare Pages, Vercel, Netlify, atau GitHub Pages.

---

## ✨ Fitur Utama

### 📸 1. OCR Pemindai Bon & Struk (AI Powered)
- **Scan dari Kamera & Galeri**: Foto bon belanjaanmu, AI akan mengekstrak nama tempat, daftar item, harga satuan, PPN, dan biaya layanan.
- **Backend Proxy Aman**: Pemrosesan gambar dikirim via Cloudflare Worker Proxy untuk menjaga keamanan API Key.
- **Cross-check Otomatis**: Aplikasi mencocokkan total fisik pada kertas bon dengan hitungan item.
- **Langsung ke Transaksi / Split Bill**: Hasil scan bisa langsung disimpan sebagai pengeluaran atau diteruskan ke kalkulator patungan.

### 👥 2. Split Bill & Assign Item per Qty
- **Pilih Jumlah Orang & Nama**: Masukkan anggota yang ikut bayar.
- **Assign Qty per Orang**: Gunakan counter `[ - ] qty [ + ]` untuk menentukan porsi makanan tiap orang.
- **Bebas Pelipatgandaan Qty**: Tombol `+` dibatasi sesuai sisa item di bon.
- **Item Bersama Sisa**: Item yang belum di-assign otomatis dibagi rata sebagai *Shared Items*. **Grand Total dijamin 100% cocok dengan kertas bon!**

### 💳 3. Manajemen Akun & Transaksi
- **Multi-Akun**: Kelola Tunai, Bank, E-Wallet, dan RDN (Rekening Dana Nasabah).
- **Jenis Transaksi**: Pemasukan, Pengeluaran (dengan kategori & autocomplete), dan Transfer antar akun.
- **Biaya Admin Transfer**: Pencatatan terpisah biaya admin transfer agar laporan pengeluaran tetap presisi.
- **Edit Transaksi**: Edit catatan dan kategori transaksi kapan saja.

### 🤝 4. Utang & Piutang (Gabungan Otomatis)
- **Pengelompokan per Nama**: Piutang otomatis menyatu berdasarkan nama orang.
- **Pelunasan Otomatis (FIFO)**: Pembayaran piutang melunasi pinjaman yang paling lama terlebih dahulu.
- **Satu Klik ke Saldo**: Pelunasan langsung memperbarui saldo akun.

### 📈 5. Investasi & Pemantauan Portofolio
- **Saham, Kripto, & Aset**: Pantau jumlah lot, rata-rata harga beli, nilai pasar, serta Profit/Loss (nominal & persentase).
- **Harga Otomatis**: Sinkronisasi harga saham/kripto otomatis via Cloudflare Worker.
- **Integrasi Saldo RDN**: Beli & jual saham langsung memotong/menambah saldo RDN.

### 📊 6. Laporan, Tanggalan, & Fitur Lainnya
- **Grafik Laporan Bulanan**: Visualisasi ringkasan pemasukan & pengeluaran per kategori.
- **Transaksi Bulanan (Rutin)**: Template otomatis untuk tagihan bulanan / langganan.
- **Wishlist Menabung**: Target tabungan bertahap dengan kalkulator estimasi waktu.
- **Multi-Bahasa**: Bahasa Indonesia (ID), Inggris (EN), dan Mandarin (ZH).

---

## 🛠️ Untuk Developer

Proyek menggunakan **Flutter** (SDK `^3.6.0`).

### Perintah Dasar:
```bash
# Install dependensi
flutter pub get

# Jalankan aplikasi (Mobile / Emulator)
flutter run

# Jalankan aplikasi (Web local)
flutter run -d chrome

# Uji Unit & Analisis Statis
flutter test
flutter analyze

# Build APK Release (Android)
flutter build apk --release

# Build Web Release
flutter build web --release
```

### Deploy Web ke Cloudflare Pages:
```bash
# Build bundle web
flutter build web --release

# Deploy folder build/web ke Cloudflare Pages
npx wrangler pages deploy build/web --project-name=moneywork
```

---

## 🔒 Keamanan & Repositori Publik

Berkas berikut di-ignore oleh `.gitignore` dan **tidak pernah di-commit ke repositori publik**:
- `android/key.properties`, `*.jks`, `*.keystore` *(Signing key release)*
- `android/app/google-services.json`, `lib/firebase_options.dart` *(Firebase project config)*
- `.wrangler/` *(Cloudflare wrangler cache)*

---

Lisensi & Hak Cipta © 2026 **AdrianHalimDev**. All rights reserved.
