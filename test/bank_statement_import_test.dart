import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/services/bank_statement_import_service.dart';

import 'helpers.dart';

void main() {
  final day = DateTime(2026, 9, 1);
  final account = Account(
    id: 'bank', name: 'Bank', type: AccountType.bank,
    balance: 100000, createdAt: day,
  );

  test('parser checks opening/closing balance and rejects incomplete rows', () {
    final parsed = BankStatementImportService.parseResponse({
      'pageCount': 1,
      'transactionCount': 3,
      'openingBalance': 100000,
      'closingBalance': 95000,
      'transactions': [
        {'date': '2026-09-01', 'direction': 'debit', 'amount': 'Rp 10.000', 'description': 'Belanja'},
        {'date': '2026-09-02', 'direction': 'credit', 'amount': 'Rp 5.000', 'description': 'Refund'},
        {'date': '2026-09-32', 'direction': 'debit', 'amount': 20, 'description': 'Invalid'},
      ],
    });
    expect(parsed.rows.length, 2);
    expect(parsed.issues.length, 1);
    expect(parsed.balanceDifference, 0);
  });

  test('review flags existing and within-file duplicates', () {
    final row = StatementTransactionDraft(
      date: day, type: TxType.expense, amount: 10000, note: 'Belanja Toko',
    );
    final existing = Transaction(
      id: 'old', type: TxType.expense, amount: 10000,
      accountId: 'bank', note: 'belanja toko', date: day,
    );
    final reviewed = BankStatementImportService.reviewDuplicates(
      accountId: 'bank', imported: [row, row], existing: [existing],
    );
    expect(reviewed.first.possibleDuplicate, isTrue);
    expect(reviewed.last.duplicateInFile, isTrue);
  });

  test('historical import and its deletion preserve current balance', () async {
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(InMemoryStorage(AppState(accounts: [account]))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final controller = container.read(appStateProvider.notifier);
    final error = await controller.importStatementTransactions(
      StatementImportApproval(accountId: 'bank', applyToBalance: false, rows: [
        StatementTransactionDraft(
          date: day, type: TxType.expense, amount: 10000, note: 'Belanja',
        ),
      ]),
    );
    expect(error.error, isNull);
    expect(error.importedCount, 1);
    var state = container.read(appStateProvider).requireValue;
    expect(state.accounts.single.balance, 100000);
    expect(state.transactions.single.balanceApplied, isFalse);
    await controller.deleteTransaction(state.transactions.single.id);
    state = container.read(appStateProvider).requireValue;
    expect(state.accounts.single.balance, 100000);
  });

  test('apply-to-balance import applies the selected net exactly once', () async {
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(InMemoryStorage(AppState(accounts: [account]))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final error = await container.read(appStateProvider.notifier)
        .importStatementTransactions(StatementImportApproval(
          accountId: 'bank', applyToBalance: true, rows: [
            StatementTransactionDraft(date: day, type: TxType.expense,
                amount: 10000, note: 'Belanja'),
            StatementTransactionDraft(date: day, type: TxType.income,
                amount: 5000, note: 'Refund'),
          ],
        ));
    expect(error.error, isNull);
    expect(error.importedCount, 2);
    final state = container.read(appStateProvider).requireValue;
    expect(state.accounts.single.balance, 95000);
    expect(state.transactions.every((tx) => tx.balanceApplied), isTrue);
  });

  Future<List<StatementTransactionDraft>> identifiedRows() async {
    final document = await BankStatementImportService.identifyRows(
      BankStatementDocument(pageCount: 1, issues: const [], rows: [
        StatementTransactionDraft(date: day, type: TxType.expense,
            amount: 10000, note: 'Belanja'),
        StatementTransactionDraft(date: day, type: TxType.income,
            amount: 5000, note: 'Refund'),
      ]), Uint8List.fromList('%PDF-1.4\nstatement'.codeUnits),
    );
    return document.rows;
  }

  test('repeating the same PDF never applies its balance twice', () async {
    final rows = await identifiedRows();
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(
          InMemoryStorage(AppState(accounts: [account]))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final controller = container.read(appStateProvider.notifier);
    final approval = StatementImportApproval(
        accountId: 'bank', applyToBalance: true, rows: rows);
    final first = await controller.importStatementTransactions(approval);
    expect(first.importedCount, 2);
    final second = await controller.importStatementTransactions(approval);
    expect(second.error, isNull);
    expect(second.importedCount, 0);
    expect(second.skippedCount, 2);
    final state = container.read(appStateProvider).requireValue;
    expect(state.transactions, hasLength(2));
    expect(state.accounts.single.balance, 95000);
    expect(Transaction.fromJson(state.transactions.first.toJson())
        .statementImportKey, state.transactions.first.statementImportKey);
  });

  test('resuming a partly saved PDF imports only missing rows', () async {
    final rows = await identifiedRows();
    final existing = Transaction(
      id: 'already-saved', type: TxType.expense, amount: 10000,
      accountId: 'bank', note: 'Catatan diubah setelah impor', date: day,
      statementImportKey: rows.first.importKey,
    );
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(InMemoryStorage(AppState(
        accounts: [account.copyWith(balance: 90000)],
        transactions: [existing],
      ))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final result = await container.read(appStateProvider.notifier)
        .importStatementTransactions(StatementImportApproval(
          accountId: 'bank', applyToBalance: true, rows: rows,
        ));
    expect(result.error, isNull);
    expect(result.importedCount, 1);
    expect(result.skippedCount, 1);
    final state = container.read(appStateProvider).requireValue;
    expect(state.transactions, hasLength(2));
    expect(state.accounts.single.balance, 95000);
    expect(state.transactions.firstWhere((tx) => tx.id == existing.id).note,
        'Catatan diubah setelah impor');
  });

  test('same source row repeated within approval is saved once', () async {
    final rows = await identifiedRows();
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(
          InMemoryStorage(AppState(accounts: [account]))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final result = await container.read(appStateProvider.notifier)
        .importStatementTransactions(StatementImportApproval(
          accountId: 'bank', applyToBalance: false,
          rows: [rows.first, rows.first.copyWith(note: 'Different wording')],
        ));
    expect(result.importedCount, 1);
    expect(result.skippedCount, 1);
    expect(container.read(appStateProvider).requireValue.transactions, hasLength(1));
  });

  test('two genuine identical rows in PDF retain separate identities', () async {
    final row = (await identifiedRows()).first;
    final document = await BankStatementImportService.identifyRows(
      BankStatementDocument(pageCount: 1, issues: const [], rows: [row, row]),
      Uint8List.fromList('%PDF-1.4\nstatement'.codeUnits),
    );
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(
          InMemoryStorage(AppState(accounts: [account]))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final result = await container.read(appStateProvider.notifier)
        .importStatementTransactions(StatementImportApproval(
          accountId: 'bank', applyToBalance: true, rows: document.rows,
        ));
    expect(result.importedCount, 2);
    final state = container.read(appStateProvider).requireValue;
    expect(state.transactions.map((tx) => tx.id).toSet(), hasLength(2));
    expect(state.accounts.single.balance, 80000);
  });

  test('invalid row rejects whole approval without adding earlier valid rows', () async {
    final rows = await identifiedRows();
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(
          InMemoryStorage(AppState(accounts: [account]))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final result = await container.read(appStateProvider.notifier)
        .importStatementTransactions(StatementImportApproval(
          accountId: 'bank', applyToBalance: true,
          rows: [rows.first, rows.last.copyWith(amount: 0.001)],
        ));
    expect(result.error, isNotNull);
    expect(container.read(appStateProvider).requireValue.transactions, isEmpty);
    expect(container.read(appStateProvider).requireValue.accounts.single.balance,
        100000);
  });

  test('editing historical transaction preserves import identity', () async {
    final rows = await identifiedRows();
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(
          InMemoryStorage(AppState(accounts: [account]))),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final controller = container.read(appStateProvider.notifier);
    await controller.importStatementTransactions(StatementImportApproval(
      accountId: 'bank', applyToBalance: false, rows: [rows.first],
    ));
    final tx = container.read(appStateProvider).requireValue.transactions.single;
    await controller.updateTransaction(id: tx.id, type: tx.type,
      amount: 9000, accountId: tx.accountId, note: 'Catatan dikoreksi');
    final updated = container.read(appStateProvider).requireValue;
    expect(updated.transactions.single.statementImportKey, rows.first.importKey);
    expect(updated.accounts.single.balance, 100000);
    final result = await controller.importStatementTransactions(
      StatementImportApproval(accountId: 'bank', applyToBalance: true,
        rows: [rows.first]));
    expect(result.importedCount, 0);
    expect(result.skippedCount, 1);
    expect(container.read(appStateProvider).requireValue.accounts.single.balance,
        100000);
  });

  test('legacy transactions do not gain null import metadata when saved', () {
    final legacy = Transaction(id: 'legacy', type: TxType.expense,
      amount: 10000, accountId: 'bank', note: 'Existing record', date: day)
      .toJson();
    expect(legacy.containsKey('statementImportKey'), isFalse);
    expect(Transaction.fromJson(legacy).toJson(), legacy);
  });
}
