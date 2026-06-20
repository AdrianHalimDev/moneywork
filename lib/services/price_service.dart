import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/investment.dart';

/// Hasil pengambilan harga: harga baru (Rupiah) atau pesan error.
class PriceResult {
  const PriceResult.success(this.price)
      : error = null,
        ok = true;
  const PriceResult.failure(this.error)
      : price = 0,
        ok = false;

  final bool ok;
  final double price;
  final String? error;
}

/// Mengambil harga pasar terkini untuk sebuah investasi.
///
/// - **Crypto**: langsung dari CoinGecko (gratis, tanpa kunci, dukung CORS
///   sehingga jalan di web maupun mobile). [Investment.ticker] = id CoinGecko,
///   mis. "bitcoin", "ethereum", "solana".
/// - **Saham**: lewat [stockProxyBase] — sebuah backend perantara yang kita
///   deploy terpisah (Cloud Functions/Workers). Selama URL belum diisi,
///   pembaruan saham mengembalikan pesan ramah, bukan crash.
/// - **Emas & reksadana**: belum ada sumber gratis terbuka, tetap manual.
class PriceService {
  PriceService({http.Client? client, this.stockProxyBase})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Base URL backend proxy saham, mis. "https://xxx.cloudfunctions.net/quote".
  /// Null/kosong = fitur harga saham otomatis belum aktif.
  final String? stockProxyBase;

  static const _coinGecko = 'https://api.coingecko.com/api/v3/simple/price';

  /// Apakah jenis [type] mendukung pembaruan harga otomatis saat ini.
  bool supportsAuto(InvestmentType type) =>
      type == InvestmentType.crypto ||
      (type == InvestmentType.stock &&
          (stockProxyBase != null && stockProxyBase!.isNotEmpty));

  Future<PriceResult> fetch(Investment inv) async {
    if (inv.ticker.trim().isEmpty) {
      return const PriceResult.failure('Isi dulu ticker/simbol asetnya.');
    }
    try {
      return switch (inv.type) {
        InvestmentType.crypto => await _fetchCrypto(inv.ticker.trim()),
        InvestmentType.stock => await _fetchStock(inv.ticker.trim()),
        _ => const PriceResult.failure(
            'Harga otomatis belum tersedia untuk jenis ini.'),
      };
    } catch (e) {
      return PriceResult.failure('Gagal mengambil harga: $e');
    }
  }

  Future<PriceResult> _fetchCrypto(String id) async {
    final uri = Uri.parse(
        '$_coinGecko?ids=${Uri.encodeQueryComponent(id.toLowerCase())}&vs_currencies=idr');
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      return PriceResult.failure('Server CoinGecko error (${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final entry = json[id.toLowerCase()] as Map<String, dynamic>?;
    final price = (entry?['idr'] as num?)?.toDouble();
    if (price == null) {
      return PriceResult.failure(
          'Ticker "$id" tidak ditemukan di CoinGecko.');
    }
    return PriceResult.success(price);
  }

  Future<PriceResult> _fetchStock(String code) async {
    final base = stockProxyBase;
    if (base == null || base.isEmpty) {
      return const PriceResult.failure(
          'Harga saham otomatis belum aktif (backend belum di-deploy).');
    }
    final uri = Uri.parse('$base?symbol=${Uri.encodeQueryComponent(code)}');
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      return PriceResult.failure('Server harga saham error (${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final price = (json['price'] as num?)?.toDouble();
    if (price == null) {
      return PriceResult.failure('Kode saham "$code" tidak ditemukan.');
    }
    return PriceResult.success(price);
  }
}
