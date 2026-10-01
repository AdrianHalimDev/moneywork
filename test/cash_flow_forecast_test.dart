import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/debt.dart';
import 'package:moneywork/models/recurring_transaction.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/services/cash_flow_forecast_service.dart';

void main() {
  final created = DateTime(2024, 1);

  Account account(String id, double balance) => Account(
        id: id,
        name: id,
        type: AccountType.bank,
        balance: balance,
        createdAt: created,
      );

  RecurringTransaction recurring(
    String id, {
    TxType type = TxType.expense,
    String accountId = 'bank',
    String? toAccountId,
    int? dueDay,
    double amount = 100,
    bool enabled = true,
    String? label,
  }) =>
      RecurringTransaction(
        id: id,
        label: label ?? id,
        type: type,
        amount: amount,
        accountId: accountId,
        toAccountId: toAccountId,
        dueDay: dueDay,
        enabled: enabled,
        createdAt: created,
      );

  test('legacy recurring data remains unscheduled until user sets a day', () {
    final oldJson = recurring('Listrik').toJson()..remove('dueDay');
    final restored = RecurringTransaction.fromJson(oldJson);
    expect(restored.dueDay, isNull);
    expect(restored.copyWith(dueDay: 31).dueDay, 31);
    expect(restored.copyWith(dueDay: 31).copyWith(clearDueDay: true).dueDay,
        isNull);
    expect(RecurringTransaction.fromJson({...oldJson, 'dueDay': 99}).dueDay,
        isNull);

    final forecast = CashFlowForecastService.build(
      AppState(accounts: [account('bank', 1000)], recurring: [restored]),
      asOf: DateTime(2024, 1, 1),
    );
    expect(forecast.events, isEmpty);
    expect(forecast.unplannedRecurringCount, 1);
    expect(forecast.closingAvailableCash, 1000);
  });

  test('day 31 falls on leap-February month end; transfer preserves total', () {
    final state = AppState(
      accounts: [account('bank', 1000), account('wallet', 200)],
      recurring: [
        recurring('Transfer',
            type: TxType.transfer,
            toAccountId: 'wallet',
            dueDay: 31,
            amount: 150),
      ],
    );
    final forecast = CashFlowForecastService.build(
      state,
      asOf: DateTime(2024, 1, 31),
      days: 30,
    );
    expect(forecast.events.map((e) => e.date),
        [DateTime(2024, 1, 31), DateTime(2024, 2, 29)]);
    expect(forecast.events.every((e) => e.totalCashImpact == 0), isTrue);
    expect(forecast.days.last.accountBalances, {
      'bank': 700,
      'wallet': 500,
    });
    expect(forecast.closingAvailableCash, 1200);
    expect(state.accounts.first.balance, 1000); // Forecast is read-only.
  });

  test('posted matching transaction consumes one monthly occurrence only', () {
    final state = AppState(
      accounts: [account('bank', 900)],
      recurring: [
        recurring('a', label: 'Internet', dueDay: 5),
        recurring('b', label: 'Internet', dueDay: 5),
        recurring('inactive', dueDay: 6, enabled: false),
      ],
      transactions: [
        Transaction(
          id: 'posted',
          type: TxType.expense,
          amount: 100,
          accountId: 'bank',
          note: 'Internet',
          date: DateTime(2024, 10, 2),
        ),
      ],
    );
    final forecast = CashFlowForecastService.build(
      state,
      asOf: DateTime(2024, 10, 1),
      days: 10,
    );
    expect(forecast.matchedPostedCount, 1);
    expect(forecast.events, hasLength(1));
    expect(forecast.closingAvailableCash, 800);
    expect(forecast.postedTransactions, hasLength(1));
    expect(state.accounts.single.balance, 900);
  });

  test('debt due uses remaining monthly amount after posted payment', () {
    final state = AppState(
      accounts: [account('bank', 1000)],
      debts: [
        Debt(
          id: 'loan',
          name: 'Cicilan',
          type: DebtType.installment,
          remaining: 900,
          monthlyPayment: 400,
          dueDate: DateTime(2024, 10, 10),
          createdAt: created,
        ),
      ],
      transactions: [
        Transaction(
          id: 'paid',
          type: TxType.expense,
          amount: 100,
          accountId: 'bank',
          linkedDebtId: 'loan',
          date: DateTime(2024, 10, 2),
        ),
      ],
    );
    final forecast = CashFlowForecastService.build(
      state,
      asOf: DateTime(2024, 10, 3),
      days: 10,
    );
    expect(forecast.events.single.kind, ForecastEventKind.debtDue);
    expect(forecast.events.single.amount, 300);
    expect(forecast.days.last.accountBalances['bank'], 1000);
    expect(forecast.closingAvailableCash, 700);
  });

  test('recurring payment with same debt name/date does not double count', () {
    final state = AppState(
      accounts: [account('bank', 1000)],
      recurring: [
        recurring('loan-template', label: 'Cicilan', dueDay: 10, amount: 400)
      ],
      debts: [
        Debt(
          id: 'loan',
          name: 'Cicilan',
          type: DebtType.installment,
          remaining: 900,
          monthlyPayment: 400,
          dueDate: DateTime(2024, 10, 10),
          createdAt: created,
        ),
      ],
    );
    final forecast = CashFlowForecastService.build(
      state,
      asOf: DateTime(2024, 10, 1),
      days: 15,
    );
    expect(forecast.events, hasLength(1));
    expect(forecast.closingAvailableCash, 600);
  });

  test('past or undated debt is disclosed but not silently charged today', () {
    final state = AppState(
      accounts: [account('bank', 1000)],
      debts: [
        Debt(
          id: 'past',
          name: 'Past',
          type: DebtType.loan,
          remaining: 500,
          dueDate: DateTime(2024, 9, 1),
          createdAt: created,
        ),
        Debt(
          id: 'unknown',
          name: 'Unknown',
          type: DebtType.loan,
          remaining: 200,
          createdAt: created,
        ),
      ],
    );
    final forecast = CashFlowForecastService.build(
      state,
      asOf: DateTime(2024, 10, 1),
    );
    expect(forecast.events, isEmpty);
    expect(forecast.overdueDebtCount, 1);
    expect(forecast.unscheduledDebtCount, 1);
    expect(forecast.closingAvailableCash, 1000);
  });
}
