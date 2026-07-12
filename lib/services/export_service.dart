import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../core/formatters.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'report.dart';

class ExportService {
  ExportService._();

  /// Menghasilkan file PDF dari daftar transaksi dan membuka sistem Share/Save.
  static Future<void> exportTransactionsToPDF({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required String periodName,
    required MonthlySummary summary,
    required List<CategorySlice> categories,
  }) async {
    final pdf = pw.Document();

    String getAccountName(String id) {
      final match = accounts.where((a) => a.id == id);
      return match.isEmpty ? '-' : match.first.name;
    }

    final headers = [
      'Tanggal',
      'Tipe',
      'Kategori',
      'Jumlah (Rp)',
      'Rekening',
      'Catatan'
    ];

    final data = transactions.map((t) {
      final accStr = t.type == TxType.transfer
          ? '${getAccountName(t.accountId)} -> ${getAccountName(t.toAccountId ?? '')}'
          : getAccountName(t.accountId);

      return [
        Fmt.dateFull(t.date),
        t.type.label,
        t.category.isEmpty ? '-' : t.category,
        Fmt.rupiahSigned(t.signedAmount),
        accStr,
        t.note.isEmpty ? '-' : t.note,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Transaksi MoneyWork - $periodName',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Dicetak pada: ${Fmt.dateFull(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ringkasan Arus Kas', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Pemasukan: ${Fmt.rupiah(summary.income)}', style: const pw.TextStyle(color: PdfColors.green700)),
                    pw.Text('Pengeluaran: ${Fmt.rupiah(summary.expense)}', style: const pw.TextStyle(color: PdfColors.red700)),
                    pw.Divider(color: PdfColors.grey400),
                    pw.Text('Sisa Saldo (Net): ${Fmt.rupiahSigned(summary.net)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]
                ),
              ),
              pw.SizedBox(width: 20),
              if (summary.income > 0 || summary.expense > 0)
                pw.SizedBox(
                  width: 120,
                  height: 120,
                  child: pw.Chart(
                    grid: pw.PieGrid(),
                    datasets: [
                      if (summary.income > 0)
                        pw.PieDataSet(
                          value: summary.income,
                          color: PdfColors.green,
                          legend: 'Masuk',
                        ),
                      if (summary.expense > 0)
                        pw.PieDataSet(
                          value: summary.expense,
                          color: PdfColors.red,
                          legend: 'Keluar',
                        ),
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 24),
          if (categories.isNotEmpty) ...[
            pw.Text('Pengeluaran per Kategori', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categories.map((c) => pw.Text('${c.label}: ${Fmt.rupiah(c.amount)}')).toList(),
            ),
            pw.SizedBox(height: 24),
          ],
          pw.Text('Detail Transaksi', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (data.isEmpty)
            pw.Center(
              child: pw.Text(
                'Tidak ada transaksi di periode ini.',
                style: const pw.TextStyle(fontSize: 12),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 11,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.all(6),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
        ],
      ),
    );

    final bytes = await pdf.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'MoneyWork_Laporan_$periodName.pdf',
    );
  }

  /// Menghasilkan file Excel (XLSX) dari daftar transaksi dan membuka sistem Share.
  static Future<void> exportTransactionsToExcel({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required String periodName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header
    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Tipe'),
      TextCellValue('Kategori'),
      TextCellValue('Jumlah (Rp)'),
      TextCellValue('Rekening'),
      TextCellValue('Catatan'),
    ]);

    String getAccountName(String id) {
      final match = accounts.where((a) => a.id == id);
      return match.isEmpty ? '-' : match.first.name;
    }

    // Data
    for (final t in transactions) {
      final accStr = t.type == TxType.transfer
          ? '${getAccountName(t.accountId)} -> ${getAccountName(t.toAccountId ?? '')}'
          : getAccountName(t.accountId);

      sheet.appendRow([
        TextCellValue(Fmt.dateFull(t.date)),
        TextCellValue(t.type.label),
        TextCellValue(t.category.isEmpty ? '-' : t.category),
        DoubleCellValue(t.signedAmount),
        TextCellValue(accStr),
        TextCellValue(t.note.isEmpty ? '-' : t.note),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/MoneyWork_Laporan_$periodName.xlsx';
      final file = File(path);
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(path)], text: 'Laporan Transaksi MoneyWork $periodName');
    }
  }
}
