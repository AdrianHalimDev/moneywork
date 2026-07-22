import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/receipt.dart';

/// Service untuk memindai bon menggunakan Cloudflare Worker + Gemini AI.
///
/// Alur:
/// 1. Menerima foto (dari kamera/galeri) sebagai [XFile].
/// 2. Mengompres dan mengonversi gambar ke Base64.
/// 3. Mengirim ke endpoint Cloudflare Worker yang meneruskan ke Gemini.
/// 4. Mem-parsing respons JSON menjadi [ReceiptScanResult].
class ReceiptScannerService {
  ReceiptScannerService({http.Client? client, required this.ocrEndpoint})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// URL endpoint Cloudflare Worker OCR.
  /// Contoh: 'https://moneywork-ocr.xxx.workers.dev/scan'
  final String ocrEndpoint;

  /// Toleransi pembulatan POS kasir: Rp 100.
  static const double _tolerance = 100.0;


  /// Memindai bon dari gambar. Mengembalikan [ReceiptScanResult] atau throw
  /// [Exception] jika gagal.
  Future<ReceiptScanResult> scanReceipt(XFile image) async {
    // 1. Baca file gambar
    final bytes = await image.readAsBytes();

    // 2. Encode ke Base64
    final base64Image = base64Encode(bytes);

    // 3. Kirim ke Cloudflare Worker
    final response = await _client.post(
      Uri.parse(ocrEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageBase64': base64Image}),
    );

    if (response.statusCode != 200) {
      final errorBody = _tryParseJson(response.body);
      final errorMsg =
          errorBody?['error'] as String? ?? 'HTTP ${response.statusCode}';
      throw Exception(errorMsg);
    }

    // 4. Parse respons JSON
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json.containsKey('error')) {
      throw Exception(json['error'] as String);
    }

    return ReceiptScanResult.fromJson(json);
  }

  /// Validasi silang: apakah jumlah item cocok dengan grand total kertas.
  ///
  /// Verifikasi ini dijalankan otomatis setelah scan, dan dijalankan ulang
  /// setiap kali pengguna mengedit angka di layar Review.
  static VerificationResult verifyReceipt(ReceiptScanResult receipt) {
    // Hitung subtotal berdasarkan penjumlahan item
    final calculatedSubtotal = receipt.items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    // Hitung grand total: subtotal + service + tax - discount
    final calculatedGrandTotal =
        calculatedSubtotal + receipt.serviceCharge + receipt.tax - receipt.discount;

    // Selisih dengan grand total kertas
    final diff = (calculatedGrandTotal - receipt.grandTotal).abs();

    // Toleransi pembulatan POS kasir
    final isVerified = diff <= _tolerance;

    return VerificationResult(
      isVerified: isVerified,
      calculatedSubtotal: calculatedSubtotal,
      calculatedGrandTotal: calculatedGrandTotal,
      errorMessage: isVerified
          ? null
          : 'Total tidak sinkron (Selisih: Rp ${diff.toStringAsFixed(0)})',
    );
  }

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
