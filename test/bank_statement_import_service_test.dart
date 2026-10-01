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
