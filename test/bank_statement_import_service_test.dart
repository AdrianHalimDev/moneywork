import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/services/bank_statement_import_service.dart';

void main() {
  final pdf = Uint8List.fromList('%PDF-1.4\n'.codeUnits);

  test('PDF header and 10 MB size limit are checked before upload', () {
    expect(() => BankStatementImportService.validatePdf(
        Uint8List.fromList('not a PDF'.codeUnits)),
        throwsA(isA<BankStatementImportException>()));
    expect(() => BankStatementImportService.validatePdf(
        Uint8List(BankStatementImportService.maxPdfBytes + 1)),
        throwsA(isA<BankStatementImportException>()));
    expect(() => BankStatementImportService.validatePdf(pdf), returnsNormally);
  });

  test('statement money parser handles Indonesian and mixed separators', () {
    expect(BankStatementImportService.parseMoney('Rp 1.234.567,89'), 1234567.89);
    expect(BankStatementImportService.parseMoney('1,234,567.89'), 1234567.89);
    expect(BankStatementImportService.parseMoney('(1.500)'), -1500);
    expect(BankStatementImportService.parseMoney('abc'), isNull);
    expect(BankStatementImportService.parseMoney('-Rp 1.500,50'), -1500.50);
    expect(BankStatementImportService.parseMoney('1.23.45'), isNull);
    expect(BankStatementImportService.parseMoney('1,23,456'), isNull);
    expect(BankStatementImportService.parseMoney('1.234,5.6'), isNull);
    expect(BankStatementImportService.parseMoney('123-45'), isNull);
    expect(BankStatementImportService.parseMoney('abc123'), isNull);
    expect(BankStatementImportService.parseMoney(0.001), isNull);
    expect(BankStatementImportService.parseMoney(double.infinity), isNull);
    expect(BankStatementImportService.parseMoney(0.30), 0.30);
  });

  test('same PDF preserves identities across description edits and rescans', () async {
    final day = DateTime(2026, 9, 1);
    BankStatementDocument document(List<StatementTransactionDraft> rows) =>
        BankStatementDocument(rows: rows, pageCount: 1, issues: const []);
    final row = StatementTransactionDraft(
      date: day, type: TxType.expense, amount: 10000, note: 'BELANJA TOKO',
    );
    final first = await BankStatementImportService.identifyRows(
        document([row, row]), pdf);
    final rescan = await BankStatementImportService.identifyRows(
        document([row.copyWith(note: 'Belanja  Toko.'), row]), pdf);
    expect(first.rows[0].importKey, rescan.rows[0].importKey);
    expect(first.rows[1].importKey, rescan.rows[1].importKey);
    expect(first.rows[0].importKey, isNot(first.rows[1].importKey));
    expect(first.rows[0].copyWith(amount: 9000).importKey,
        first.rows[0].importKey);
    final otherPdf = await BankStatementImportService.identifyRows(
        document([row]), Uint8List.fromList('%PDF-1.4\nother'.codeUnits));
    expect(otherPdf.rows[0].importKey, isNot(first.rows[0].importKey));
  });

  test('already imported identity is independent of edited note and amount', () async {
    final document = await BankStatementImportService.identifyRows(
      BankStatementDocument(rows: [StatementTransactionDraft(
        date: DateTime(2026, 9, 1), type: TxType.expense,
        amount: 10000, note: 'Belanja',
      )], pageCount: 1, issues: const []), pdf,
    );
    final row = document.rows.single;
    final existing = [Transaction(
      id: 'old', type: TxType.expense, amount: 9000, accountId: 'bank',
      note: 'Catatan dikoreksi', date: row.date,
      statementImportKey: row.importKey,
    )];
    final reviewed = BankStatementImportService.reviewDuplicates(
        accountId: 'bank', imported: [row], existing: existing);
    expect(reviewed.single.alreadyImported, isTrue);
    expect(BankStatementImportService.reviewDuplicates(
        accountId: 'wallet', imported: [row], existing: existing)
        .single.alreadyImported, isFalse);
  });

  test('bank references keep identities when AI changes row order', () async {
    final rows = [
      StatementTransactionDraft(date: DateTime(2026, 9, 1),
        type: TxType.expense, amount: 10000, note: 'Toko A', reference: 'REF-A'),
      StatementTransactionDraft(date: DateTime(2026, 9, 1),
        type: TxType.expense, amount: 10000, note: 'Toko B', reference: 'REF-B'),
    ];
    final first = await BankStatementImportService.identifyRows(
      BankStatementDocument(rows: rows, pageCount: 1, issues: const []), pdf);
    final reversed = await BankStatementImportService.identifyRows(
      BankStatementDocument(rows: rows.reversed.toList(), pageCount: 1,
        issues: const []), pdf);
    expect(first.rows[0].importKey, reversed.rows[1].importKey);
    expect(first.rows[1].importKey, reversed.rows[0].importKey);
  });

  test('invalid calendar dates are not silently rolled into next month', () {
    expect(BankStatementImportService.parseIsoDate('2026-02-29'), isNull);
    expect(BankStatementImportService.parseIsoDate('2026-09-31'), isNull);
    expect(BankStatementImportService.parseIsoDate('2026-09-01junk'), isNull);
    expect(BankStatementImportService.parseIsoDate('2024-02-29'),
        DateTime(2024, 2, 29));
  });

  test('balance reconciliation keeps cents and exposes reversed directions', () {
    final rows = [
      StatementTransactionDraft(date: DateTime(2026, 9, 1),
          type: TxType.expense, amount: 0.10, note: 'A'),
      StatementTransactionDraft(date: DateTime(2026, 9, 1),
          type: TxType.expense, amount: 0.20, note: 'B'),
    ];
    expect(BankStatementImportService.reconcileBalance(
      rows: rows, openingBalance: 1, closingBalance: 0.70), 0);
    expect(BankStatementImportService.reconcileBalance(
      rows: rows, openingBalance: 1, closingBalance: 0.69), 0.01);
    expect(BankStatementImportService.reconcileBalance(
      rows: [rows[0].copyWith(type: TxType.income), rows[1]],
      openingBalance: 1, closingBalance: 0.70), 0.20);
  });

  test('malformed page and ambiguous amount become review issues', () {
    final document = BankStatementImportService.parseResponse({
      'currency': 'IDR', 'pageCount': 1, 'transactionCount': 3,
      'openingBalance': '12.34.56', 'closingBalance': '0',
      'transactions': [
        {'date': '2026-09-01', 'direction': ' CREDIT ',
          'amount': 100, 'description': 'Valid', 'page': 1},
        {'date': '2026-09-02', 'direction': 'debit',
          'amount': '1.23.45', 'description': 'Invalid amount'},
        {'date': '2026-09-02', 'direction': 'debit',
          'amount': 100, 'description': 'Invalid page', 'page': 1.5},
      ],
    });
    expect(document.rows, hasLength(1));
    expect(document.rows.single.type, TxType.income);
    expect(document.issues, hasLength(2));
    expect(document.openingBalance, isNull);
    expect(document.balanceDifference, isNull);
  });

  test('non-IDR statements cannot be imported as Rupiah', () {
    expect(() => BankStatementImportService.parseResponse({
      'currency': 'USD', 'pageCount': 1, 'transactionCount': 1,
      'transactions': [{'date': '2026-09-01', 'direction': 'debit',
        'amount': 100, 'description': 'Dollar transaction'}],
    }), throwsA(isA<BankStatementImportException>()));
  });

  test('malformed row is surfaced while valid rows remain reviewable', () {
    final document = BankStatementImportService.parseResponse({
      'pageCount': 1,
      'transactionCount': 3,
      'openingBalance': 100000,
      'closingBalance': 95000,
      'transactions': [
        {'date': '2026-09-01', 'direction': 'debit',
          'amount': 'Rp 10.000', 'description': 'Belanja'},
        {'date': '2026-09-02', 'direction': 'credit',
          'amount': 'Rp 5.000', 'description': 'Refund'},
        {'date': '2026-09-32', 'direction': 'debit',
          'amount': 200, 'description': 'Tanggal tidak valid'},
      ],
    });
    expect(document.rows, hasLength(2));
    expect(document.issues.single.row, 3);
    expect(document.balanceDifference, 0);
  });

  test('incomplete model output is rejected without importing a subset', () {
    expect(() => BankStatementImportService.parseResponse({
      'pageCount': 1,
      'transactionCount': 3,
      'transactions': [
        {'date': '2026-09-01', 'direction': 'debit',
          'amount': 10000, 'description': 'Belanja'},
      ],
    }), throwsA(isA<BankStatementImportException>()));
  });

  test('duplicate key uses account, date, direction, amount and description', () {
    final row = StatementTransactionDraft(
      date: DateTime(2026, 9, 1), type: TxType.expense,
      amount: 10000, note: 'Belanja-Toko',
    );
    final existing = [
      Transaction(id: 'same', type: TxType.expense, amount: 10000,
          accountId: 'bank', note: 'BELANJA TOKO', date: row.date),
      Transaction(id: 'other-account', type: TxType.expense, amount: 20000,
          accountId: 'wallet', note: row.note, date: row.date),
    ];
    final reviewed = BankStatementImportService.reviewDuplicates(
      accountId: 'bank', imported: [row, row.copyWith(amount: 20000), row],
      existing: existing,
    );
    expect(reviewed[0].possibleDuplicate, isTrue);
    expect(reviewed[1].possibleDuplicate, isFalse);
    expect(reviewed[2].duplicateInFile, isTrue);
  });

  test('existing transfers are reviewed as debit at source and credit at destination', () {
    final day = DateTime(2026, 9, 1);
    final transfer = Transaction(id: 'transfer', type: TxType.transfer,
        amount: 10000, accountId: 'bank', toAccountId: 'wallet',
        date: day, note: 'Transfer pribadi');
    final debit = StatementTransactionDraft(date: day, type: TxType.expense,
        amount: 10000, note: transfer.note);
    final credit = debit.copyWith(type: TxType.income);
    expect(BankStatementImportService.reviewDuplicates(accountId: 'bank',
      imported: [debit], existing: [transfer]).single.possibleDuplicate, isTrue);
    expect(BankStatementImportService.reviewDuplicates(accountId: 'wallet',
      imported: [credit], existing: [transfer]).single.possibleDuplicate, isTrue);
    expect(BankStatementImportService.reviewDuplicates(accountId: 'wallet',
      imported: [debit], existing: [transfer]).single.possibleDuplicate, isFalse);
  });

  test('service does not expose upstream error text or save PDF locally', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/statement-scan');
      expect(jsonDecode(request.body)['pdfBase64'], base64Encode(pdf));
      return http.Response(jsonEncode({
        'code': 'SERVICE_UNAVAILABLE',
        'raw': 'private account number and secret',
      }), 502);
    });
    final service = BankStatementImportService(
        endpoint: Uri.parse('https://example.test/statement-scan'),
        client: client);
    await expectLater(service.scanPdf(pdf), throwsA(
      isA<BankStatementImportException>().having(
          (error) => error.message, 'message',
          isNot(contains('private account number'))),
    ));
  });
}
