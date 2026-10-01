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
    expect(error, isNull);
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
    expect(error, isNull);
    final state = container.read(appStateProvider).requireValue;
    expect(state.accounts.single.balance, 95000);
    expect(state.transactions.every((tx) => tx.balanceApplied), isTrue);
  });
}
