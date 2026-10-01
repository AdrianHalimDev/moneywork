import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/firebase/record_codec.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/debt.dart';
import 'package:moneywork/models/receivable.dart';
import 'package:moneywork/models/transaction.dart';

void main() {
  final day = DateTime(2026, 9, 1);
  final account = Account(id: 'a', name: 'Bank', type: AccountType.bank,
      balance: 100000, createdAt: day);

  test('account base stays stable across separately encoded transactions', () {
    final first = Transaction(id: 't1', type: TxType.expense,
        amount: 10000, accountId: 'a', date: day);
    final second = Transaction(id: 't2', type: TxType.expense,
        amount: 20000, accountId: 'a', date: day);
    final deviceOne = RecordCodec.encode(AppState(
      accounts: [account.copyWith(balance: 90000)], transactions: [first],
    ));
    final deviceTwo = RecordCodec.encode(AppState(
      accounts: [account.copyWith(balance: 80000)], transactions: [second],
    ));
    expect(deviceOne['accounts/a'], deviceTwo['accounts/a']);
    final merged = RecordCodec.decode({
      'accounts/a': deviceOne['accounts/a']!,
      'transactions/t1': deviceOne['transactions/t1']!,
      'transactions/t2': deviceTwo['transactions/t2']!,
    });
    expect(merged.accounts.single.balance, 70000);
    expect(merged.transactions.length, 2);
  });

  test('historical import is visible but excluded from account balance', () {
    final imported = Transaction(id: 'old', type: TxType.expense,
        amount: 10000, accountId: 'a', balanceApplied: false, date: day);
    final records = RecordCodec.encode(AppState(
      accounts: [account], transactions: [imported],
    ));
    final restored = RecordCodec.decode(records);
    expect(restored.accounts.single.balance, 100000);
    expect(restored.transactions.single.balanceApplied, isFalse);
  });

  test('linked payments update debt and receivable records for conflict detection', () {
    final debt = Debt(id: 'd', name: 'Pinjaman', type: DebtType.loan,
        remaining: 50000, createdAt: day);
    final receivable = Receivable(id: 'r', personName: 'Ari',
        remaining: 30000, createdAt: day);
    final original = RecordCodec.encode(AppState(
      accounts: [account], debts: [debt], receivables: [receivable],
    ));
    final debtPayment = Transaction(id: 'pay', type: TxType.expense,
        amount: 10000, accountId: 'a', linkedDebtId: 'd', date: day);
    final collection = Transaction(id: 'collect', type: TxType.income,
        amount: 5000, accountId: 'a', linkedReceivableId: 'r', date: day);
    final changed = RecordCodec.encode(AppState(
      accounts: [account.copyWith(balance: 95000)],
      debts: [debt.copyWith(remaining: 40000)],
      receivables: [receivable.copyWith(remaining: 25000)],
      transactions: [debtPayment, collection],
    ));

    expect(RecordCodec.changedKeys(original, changed),
        {'debts/d', 'receivables/r', 'transactions/pay', 'transactions/collect'});
    expect(RecordCodec.affectedAccountKeys(original, changed,
        {'transactions/pay', 'transactions/collect'}), {'accounts/a'});
    final restored = RecordCodec.decode(changed);
    expect(restored.accounts.single.balance, 95000);
    expect(restored.debts.single.remaining, 40000);
    expect(restored.receivables.single.remaining, 25000);
  });
}
