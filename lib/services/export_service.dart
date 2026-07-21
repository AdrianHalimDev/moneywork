import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../core/formatters.dart';
import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();

    String getAccountName(String id) {
      final match = accounts.where((a) => a.id == id);
      return match.isEmpty ? '-' : match.first.name;
    }

    final headers = [
      l10n.excelHeaderDate,
      l10n.excelHeaderType,
      l10n.excelHeaderCategory,
      l10n.excelHeaderAmount,
      l10n.excelHeaderAccount,
      l10n.excelHeaderNote
    ];

    final data = transactions.map((t) {
      final accStr = t.type == TxType.transfer
          ? '${getAccountName(t.accountId)} -> ${getAccountName(t.toAccountId ?? '')}'
          : getAccountName(t.accountId);

      return [
        Fmt.dateFull(t.date),
        t.type.label(l10n),
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
              l10n.reportTitle(periodName),
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.reportPrintedAt(Fmt.dateFull(DateTime.now())),
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
                    pw.Text(l10n.reportCashflowSummary, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text(l10n.reportIncome(Fmt.rupiah(summary.income)), style: const pw.TextStyle(color: PdfColors.green700)),
                    pw.Text(l10n.reportExpense(Fmt.rupiah(summary.expense)), style: const pw.TextStyle(color: PdfColors.red700)),
                    pw.Divider(),
                    pw.Text(l10n.reportNet(Fmt.rupiahSigned(summary.net)), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                          legend: l10n.legendIncome,
                        ),
                      if (summary.expense > 0)
                        pw.PieDataSet(
                          value: summary.expense,
                          color: PdfColors.red,
                          legend: l10n.legendExpense,
                        ),
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 24),
          if (categories.isNotEmpty) ...[
            pw.Text(l10n.reportExpenseByCategory, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categories.map((c) => pw.Text('${c.label}: ${Fmt.rupiah(c.amount)}')).toList(),
            ),
            pw.SizedBox(height: 24),
          ],
          pw.Text(l10n.reportTxDetail, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (data.isEmpty)
            pw.Center(
              child: pw.Text(
                l10n.noTransactionPeriod,
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
    required AppLocalizations l10n,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header
    sheet.appendRow([
      TextCellValue(l10n.excelHeaderDate),
      TextCellValue(l10n.excelHeaderType),
      TextCellValue(l10n.excelHeaderCategory),
      TextCellValue(l10n.excelHeaderAmount),
      TextCellValue(l10n.excelHeaderAccount),
      TextCellValue(l10n.excelHeaderNote),
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
        TextCellValue(t.type.label(l10n)),
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
      await Share.shareXFiles([XFile(path)], text: l10n.shareReportText(periodName));
    }
  }

  /// Menghasilkan file Excel (XLSX) berisi semua data aplikasi (Backup Data).
  static Future<void> exportAllToExcel(
      AppState state, AppLocalizations l10n) async {
    final excel = Excel.createExcel();

    String getAccountName(String id) {
      final match = state.accounts.where((a) => a.id == id);
      return match.isEmpty ? '-' : match.first.name;
    }

    // 1. Akun
    final sheetAkun = excel[l10n.excelSheetAccounts];
    sheetAkun.appendRow([
      TextCellValue('ID'), TextCellValue(l10n.labelAccountName), TextCellValue(l10n.excelHeaderType), 
      TextCellValue(l10n.excelHeaderBalance), TextCellValue(l10n.excelHeaderBankNo), TextCellValue(l10n.excelHeaderCreatedAt)
    ]);
    for (final a in state.accounts) {
      sheetAkun.appendRow([
        TextCellValue(a.id), TextCellValue(a.name), TextCellValue(a.type.label(l10n)),
        DoubleCellValue(a.balance), TextCellValue(a.accountNumber), TextCellValue(Fmt.dateFull(a.createdAt))
      ]);
    }

    // 2. Transaksi
    final sheetTx = excel[l10n.excelSheetTransactions];
    sheetTx.appendRow([
      TextCellValue('ID'), TextCellValue(l10n.excelHeaderDate), TextCellValue(l10n.excelHeaderType),
      TextCellValue(l10n.excelHeaderCategory), TextCellValue(l10n.excelHeaderAmount), TextCellValue(l10n.excelHeaderAccount), TextCellValue(l10n.excelHeaderNote)
    ]);
    for (final t in state.transactions) {
      final accStr = t.type == TxType.transfer
          ? '${getAccountName(t.accountId)} -> ${getAccountName(t.toAccountId ?? '')}'
          : getAccountName(t.accountId);
      sheetTx.appendRow([
        TextCellValue(t.id), TextCellValue(Fmt.dateFull(t.date)), TextCellValue(t.type.label(l10n)),
        TextCellValue(t.category), DoubleCellValue(t.signedAmount), TextCellValue(accStr), TextCellValue(t.note)
      ]);
    }

    // 3. Utang
    final sheetUtang = excel[l10n.excelSheetDebts];
    sheetUtang.appendRow([
      TextCellValue('ID'), TextCellValue(l10n.excelHeaderLender), TextCellValue(l10n.excelHeaderType),
      TextCellValue(l10n.excelHeaderDebtRemaining), TextCellValue(l10n.excelHeaderMonthlyPayment), TextCellValue(l10n.excelHeaderDueDate)
    ]);
    for (final d in state.debts) {
      sheetUtang.appendRow([
        TextCellValue(d.id), TextCellValue(d.name), TextCellValue(d.type.name),
        DoubleCellValue(d.remaining), DoubleCellValue(d.monthlyPayment),
        TextCellValue(d.dueDate != null ? Fmt.dateFull(d.dueDate!) : '-')
      ]);
    }

    // 4. Piutang
    final sheetPiutang = excel[l10n.excelSheetReceivables];
    sheetPiutang.appendRow([
      TextCellValue('ID'), TextCellValue(l10n.excelHeaderBorrower), TextCellValue(l10n.excelHeaderRecNote),
      TextCellValue(l10n.excelHeaderRecRemaining), TextCellValue(l10n.excelHeaderDueDate)
    ]);
    for (final r in state.receivables) {
      sheetPiutang.appendRow([
        TextCellValue(r.id), TextCellValue(r.personName), TextCellValue(r.note),
        DoubleCellValue(r.remaining), TextCellValue(r.dueDate != null ? Fmt.dateFull(r.dueDate!) : '-')
      ]);
    }

    // 5. Investasi
    final sheetInvestasi = excel[l10n.excelSheetInvestments];
    sheetInvestasi.appendRow([
      TextCellValue('ID'), TextCellValue(l10n.excelHeaderAssetName), TextCellValue(l10n.excelHeaderType), TextCellValue(l10n.excelHeaderTicker),
      TextCellValue(l10n.excelHeaderQuantity), TextCellValue(l10n.excelHeaderBuyPrice), TextCellValue(l10n.excelHeaderCurrentPrice),
      TextCellValue(l10n.excelHeaderTotalCost), TextCellValue(l10n.excelHeaderTotalMarket), TextCellValue(l10n.excelHeaderReturn)
    ]);
    for (final i in state.investments) {
      sheetInvestasi.appendRow([
        TextCellValue(i.id), TextCellValue(i.name), TextCellValue(i.type.name), TextCellValue(i.ticker),
        DoubleCellValue(i.quantity), DoubleCellValue(i.buyPrice), DoubleCellValue(i.currentPrice),
        DoubleCellValue(i.cost), DoubleCellValue(i.marketValue), DoubleCellValue(i.gainPercent)
      ]);
    }

    // 6. Wishlist
    final sheetWishlist = excel['Wishlist'];
    sheetWishlist.appendRow([
      TextCellValue('ID'), TextCellValue(l10n.excelHeaderItemName), TextCellValue(l10n.excelHeaderTargetPrice), TextCellValue(l10n.excelHeaderSaved),
      TextCellValue(l10n.excelHeaderPriority), TextCellValue(l10n.excelHeaderStatus), TextCellValue(l10n.excelHeaderTargetDate)
    ]);
    for (final w in state.wishlist) {
      sheetWishlist.appendRow([
        TextCellValue(w.id), TextCellValue(w.name), DoubleCellValue(w.price), DoubleCellValue(w.savedAmount),
        TextCellValue(w.priority.name), TextCellValue(w.purchased ? l10n.statusPurchased : l10n.statusNotPurchased),
        TextCellValue(w.targetDate != null ? Fmt.dateFull(w.targetDate!) : '-')
      ]);
    }

    // 7. Rutin
    final sheetRutin = excel[l10n.excelSheetRecurring];
    sheetRutin.appendRow([
      TextCellValue('ID'), TextCellValue(l10n.excelHeaderLabel), TextCellValue(l10n.excelHeaderType), TextCellValue(l10n.excelHeaderCategory),
      TextCellValue(l10n.excelHeaderNominal), TextCellValue(l10n.excelHeaderAccount), TextCellValue(l10n.excelHeaderActiveStatus)
    ]);
    for (final r in state.recurring) {
      sheetRutin.appendRow([
        TextCellValue(r.id), TextCellValue(r.label), TextCellValue(r.type.label(l10n)), TextCellValue(r.category),
        DoubleCellValue(r.amount), TextCellValue(getAccountName(r.accountId)), TextCellValue(r.enabled ? l10n.statusActive : l10n.statusInactive)
      ]);
    }

    // Excel starts with a default "Sheet1", remove it if not used.
    if (excel.tables.containsKey('Sheet1') && excel.tables.length > 1) {
      excel.delete('Sheet1');
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final dir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final path = '${dir.path}/MoneyWork_Backup_AllData_$dateStr.xlsx';
      final file = File(path);
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(path)], text: l10n.shareBackupText(dateStr));
    }
  }
}
