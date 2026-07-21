# Backend Proxy Harga Saham IDX

Aplikasi web tidak bisa mengambil harga saham langsung dari Yahoo Finance
karena pembatasan CORS browser. Backend kecil ini bertindak sebagai
perantara: ia yang memanggil Yahoo, lalu meneruskan harga ke aplikasi.

Keduanya menghasilkan respons JSON yang **sama persis**, jadi `price_service.dart`
tidak perlu diubah apa pun—cukup isi URL-nya.

```json
{ "symbol": "BBCA", "price": 9500, "currency": "IDR" }
```

## Pilih salah satu

| Opsi | Biaya | Perlu kartu? | Kapan dipakai |
|------|-------|--------------|---------------|
| **Firebase Functions** (`firebase-functions/`) | Gratis dalam kuota | Ya (paket Blaze) | Kalau sekalian pakai Firebase untuk login & sync (Fase 5) |
| **Cloudflare Workers** (`cloudflare-worker/`) | Gratis (100rb req/hari) | Tidak | Kalau mau cepat & tanpa kartu |

Langkah deploy ada di komentar masing-masing file.

## Menyambungkan ke aplikasi

Setelah dapat URL hasil deploy, buka `lib/data/app_controller.dart` dan isi
`stockProxyBase`:

```dart
final priceServiceProvider = Provider<PriceService>(
  (ref) => PriceService(
    stockProxyBase: 'https://URL-HASIL-DEPLOY-KAMU/quote',
  ),
);
```

Setelah itu tombol refresh pada saham (mis. BBCA) langsung aktif, sama seperti
crypto. Tanpa URL ini, harga saham tetap diisi manual dan crypto tetap berjalan
otomatis lewat CoinGecko.
