import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/transaction.dart';

/// Satu transaksi hasil ekstraksi PDF sebelum pengguna menyetujuinya.
class StatementTransactionDraft {
  const StatementTransactionDraft({
    required this.date,
    required this.type,
    required this.amount,
    required this.note,
    this.category = '',
    this.page,
    this.reference,
  });

  final DateTime date;
  final TxType type;
  final double amount;
  final String note;
  final String category;
  final int? page;
  final String? reference;

  StatementTransactionDraft copyWith({
    DateTime? date,
    TxType? type,
    double? amount,
    String? note,
    String? category,
  }) =>
      StatementTransactionDraft(
        date: date ?? this.date,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        category: category ?? this.category,
        page: page,
        reference: reference,
      );
}

/// Dikembalikan layar review hanya setelah pengguna menyetujui pilihan baris.
class StatementImportApproval {
  const StatementImportApproval({
    required this.accountId,
    required this.rows,
    required this.applyToBalance,
  });

  final String accountId;
  final List<StatementTransactionDraft> rows;

  /// `false` untuk mutasi historis yang sudah tercermin pada saldo saat ini.
  final bool applyToBalance;
}

class StatementImportIssue {
  const StatementImportIssue({required this.row, required this.reason});

  final int row;
  final String reason;
}

class BankStatementDocument {
  const BankStatementDocument({
    required this.rows,
    required this.pageCount,
    required this.issues,
    this.openingBalance,
    this.closingBalance,
  });

  final List<StatementTransactionDraft> rows;
  final int pageCount;
  final List<StatementImportIssue> issues;
  final double? openingBalance;
  final double? closingBalance;

  double? get balanceDifference {
    if (openingBalance == null || closingBalance == null) return null;
    final net = rows.fold<double>(0, (sum, row) =>
        sum + (row.type == TxType.income ? row.amount : -row.amount));
    return openingBalance! + net - closingBalance!;
  }
}

/// Hasil pemeriksaan duplikat. Duplikat tidak otomatis dipilih saat review.
class ReviewedStatementRow {
  const ReviewedStatementRow({
    required this.draft,
    required this.possibleDuplicate,
    this.duplicateInFile = false,
  });

  final StatementTransactionDraft draft;
  final bool possibleDuplicate;
  final bool duplicateInFile;
}

class BankStatementImportException implements Exception {
  const BankStatementImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Mengirim PDF ke Worker OCR yang sudah digunakan untuk bon. PDF hanya
/// dikirim setelah pengguna memberi persetujuan eksplisit di layar review.
class BankStatementImportService {
  BankStatementImportService({required this.endpoint, http.Client? client})
      : _client = client ?? http.Client();

  static const int maxPdfBytes = 10 * 1024 * 1024;
  static const int maxPages = 40;
  static const int maxTransactions = 500;

  final Uri endpoint;
  final http.Client _client;

  void dispose() => _client.close();

  Future<BankStatementDocument> scanPdf(Uint8List bytes) async {
    validatePdf(bytes);
    final response = await _client.post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pdfBase64': base64Encode(bytes)}),
    ).timeout(const Duration(minutes: 3));
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const BankStatementImportException(
          'Layanan tidak mengembalikan hasil yang dapat dibaca. Coba lagi.');
    }
    if (response.statusCode != 200) {
      // Hanya kode error yang disiapkan sendiri oleh Worker boleh ditampilkan.
      final code = data['code'] as String?;
      throw BankStatementImportException(_messageForCode(code));
    }
    return parseResponse(data);
  }

  static void validatePdf(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxPdfBytes) {
      throw const BankStatementImportException(
          'PDF harus berukuran paling besar 10 MB. Pisahkan mutasi per bulan.');
    }
    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2d) {
      throw const BankStatementImportException(
          'File bukan PDF yang valid. Unduh ulang PDF mutasi dari bank.');
    }
  }

  static BankStatementDocument parseResponse(Map<String, dynamic> data) {
    final pages = data['pageCount'];
    if (pages is! int || pages < 1 || pages > maxPages) {
      throw const BankStatementImportException(
          'PDF tidak terbaca atau melebihi 40 halaman. Pisahkan PDF menjadi bagian lebih kecil.');
    }
    final rawRows = data['transactions'];
    final count = data['transactionCount'];
    if (rawRows is! List || count is! int || count != rawRows.length ||
        rawRows.length > maxTransactions) {
      throw const BankStatementImportException(
          'Daftar transaksi tidak lengkap. Coba PDF yang lebih kecil; tidak ada data yang disimpan.');
    }
    final rows = <StatementTransactionDraft>[];
    final issues = <StatementImportIssue>[];
    for (var i = 0; i < rawRows.length; i++) {
      try {
        final item = Map<String, dynamic>.from(rawRows[i] as Map);
        final date = parseIsoDate(item['date']);
        final rawType = (item['direction'] as String?)?.toLowerCase();
        final type = switch (rawType) {
          'debit' => TxType.expense,
          'credit' => TxType.income,
          _ => null,
        };
        final amount = parseMoney(item['amount']);
        final description = (item['description'] as String?)?.trim() ?? '';
        final page = item['page'];
        if (date == null || type == null || amount == null || amount <= 0 ||
            description.isEmpty || (page != null && (page is! num || page < 1 || page > pages))) {
          throw const FormatException('Kolom tanggal, jenis, nominal, atau uraian tidak valid');
        }
        rows.add(StatementTransactionDraft(
          date: date,
          type: type,
          amount: amount,
          note: description,
          page: page is num ? page.toInt() : null,
          reference: item['reference'] is String
              ? (item['reference'] as String).trim()
              : null,
        ));
      } catch (_) {
        issues.add(StatementImportIssue(
            row: i + 1,
            reason: 'Tanggal, jenis, nominal, atau uraian tidak terbaca.'));
      }
    }
    if (rows.isEmpty) {
      throw const BankStatementImportException(
          'Tidak ada transaksi yang bisa dibaca. Pastikan PDF berisi mutasi rekening dan tidak dilindungi sandi.');
    }
    final opening = parseMoney(data['openingBalance']);
    final closing = parseMoney(data['closingBalance']);
    return BankStatementDocument(
      rows: rows,
      pageCount: pages,
      issues: issues,
      openingBalance: opening,
      closingBalance: closing,
    );
  }

  static List<ReviewedStatementRow> reviewDuplicates({
    required String accountId,
    required List<StatementTransactionDraft> imported,
    required List<Transaction> existing,
  }) {
    final existingKeys = <String>{
      for (final tx in existing)
        if (tx.accountId == accountId && tx.type != TxType.transfer)
          _duplicateKey(tx.date, tx.type, tx.amount, tx.note),
    };
    final seenInFile = <String>{};
    return [
      for (final row in imported)
        _reviewRow(row, existingKeys, seenInFile),
    ];
  }

  static ReviewedStatementRow _reviewRow(
    StatementTransactionDraft row,
    Set<String> existingKeys,
    Set<String> seenInFile,
  ) {
    final key = _duplicateKey(row.date, row.type, row.amount, row.note);
    final inFile = !seenInFile.add(key);
    return ReviewedStatementRow(
      draft: row,
      possibleDuplicate: inFile || existingKeys.contains(key),
      duplicateInFile: inFile,
    );
  }

  static String _duplicateKey(
      DateTime date, TxType type, double amount, String description) {
    final day = '${date.year}-${date.month}-${date.day}';
    final cents = (amount * 100).round();
    final normalized = description.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return '$day|${type.name}|$cents|$normalized';
  }

  static DateTime? parseIsoDate(Object? value) {
    if (value is! String) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (m == null) return null;
    final year = int.parse(m[1]!);
    final month = int.parse(m[2]!);
    final day = int.parse(m[3]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }

  /// Rupiah pada respons model bisa berupa angka atau teks lokal seperti
  /// `1.234.567,89`. Nilai negatif hanya dipakai untuk saldo awal/akhir.
  static double? parseMoney(Object? value) {
    if (value == null) return null;
    if (value is num) return value.isFinite ? value.toDouble() : null;
    if (value is! String) return null;
    var raw = value.trim().replaceAll(RegExp(r'[^0-9.,()-]'), '');
    if (raw.isEmpty) return null;
    final negative = raw.contains('-') || (raw.startsWith('(') && raw.endsWith(')'));
    raw = raw.replaceAll(RegExp(r'[()-]'), '');
    if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(raw)) {
      raw = raw.replaceAll(RegExp(r'[.,]'), '');
    } else if (raw.contains(',') && raw.contains('.')) {
      final commaDecimal = raw.lastIndexOf(',') > raw.lastIndexOf('.');
      raw = raw.replaceAll(commaDecimal ? '.' : ',', '')
          .replaceAll(commaDecimal ? ',' : '.', '.');
    } else if (raw.contains(',')) {
      raw = raw.replaceAll(',', '.');
    }
    final parsed = double.tryParse(raw);
    return parsed == null || !parsed.isFinite ? null : (negative ? -parsed : parsed);
  }

  static String _messageForCode(String? code) => switch (code) {
        'PDF_TOO_LARGE' => 'PDF terlalu besar. Maksimal 10 MB.',
        'INVALID_PDF' => 'File bukan PDF yang valid. Unduh ulang dari bank.',
        'PDF_UNREADABLE' =>
          'PDF tidak dapat dibaca. Jika dilindungi sandi, buka kuncinya dan simpan salinan PDF baru.',
        'PAGE_LIMIT' => 'PDF melebihi 40 halaman. Pisahkan per bulan.',
        'OUTPUT_TRUNCATED' =>
          'Daftar transaksi terlalu panjang untuk sekali scan. Pisahkan PDF menjadi bagian lebih kecil.',
        _ => 'Gagal membaca PDF mutasi. Coba lagi beberapa saat.',
      };
}
