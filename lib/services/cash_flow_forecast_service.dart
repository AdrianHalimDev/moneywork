import 'dart:math' as math;

import '../data/app_state.dart';
import '../models/debt.dart';
import '../models/transaction.dart';

/// A read-only estimate. Posted transactions are already reflected in Account.balance.
enum ForecastEventKind { income, expense, transfer, debtDue }

class ForecastEvent {
  const ForecastEvent({
    required this.date,
    required this.label,
    required this.amount,
    required this.kind,
    this.accountId,
    this.toAccountId,
  });

  final DateTime date;
  final String label;
  final double amount;
  final ForecastEventKind kind;
  final String? accountId;
  final String? toAccountId;

  double get totalCashImpact => switch (kind) {
        ForecastEventKind.income => amount,
        ForecastEventKind.expense || ForecastEventKind.debtDue => -amount,
        ForecastEventKind.transfer => 0,
      };
}

class ForecastDay {
  ForecastDay({
    required this.date,
    required Map<String, double> accountBalances,
    required this.debtDueToDate,
  }) : accountBalances = Map.unmodifiable(accountBalances);

  final DateTime date;
  final Map<String, double> accountBalances;
  final double debtDueToDate;

  double get totalAccountBalance =>
      accountBalances.values.fold(0, (sum, value) => sum + value);

  /// Debt has no funding account yet, so it is deducted only from total cash.
  double get availableAfterDebt => totalAccountBalance - debtDueToDate;
}

class CashFlowForecast {
  CashFlowForecast({
    required this.asOf,
    required Map<String, double> openingBalances,
    required List<ForecastDay> days,
    required List<ForecastEvent> events,
    required List<Transaction> postedTransactions,
    required this.unplannedRecurringCount,
    required this.unscheduledDebtCount,
    required this.overdueDebtCount,
    required this.matchedPostedCount,
  })  : openingBalances = Map.unmodifiable(openingBalances),
        days = List.unmodifiable(days),
        events = List.unmodifiable(events),
        postedTransactions = List.unmodifiable(postedTransactions);

  final DateTime asOf;
  final Map<String, double> openingBalances;
  final List<ForecastDay> days;
  final List<ForecastEvent> events;
  final List<Transaction> postedTransactions;
  final int unplannedRecurringCount;
  final int unscheduledDebtCount;
  final int overdueDebtCount;
  final int matchedPostedCount;

  double get openingCash =>
      openingBalances.values.fold(0, (sum, value) => sum + value);
  double get closingAccountCash =>
      days.isEmpty ? openingCash : days.last.totalAccountBalance;
  double get closingAvailableCash =>
      days.isEmpty ? openingCash : days.last.availableAfterDebt;

  ForecastDay? get lowestDay {
    if (days.isEmpty) return null;
    var lowest = days.first;
    for (final day in days.skip(1)) {
      if (day.availableAfterDebt < lowest.availableAfterDebt) lowest = day;
    }
    return lowest;
  }
}

class CashFlowForecastService {
  const CashFlowForecastService._();

  /// Projects [days] calendar days, including [asOf], without mutating state.
  /// Only templates with dueDay are scheduled. A posted transaction matching
  /// the same template in the same month consumes that occurrence, avoiding a
  /// second charge. Debt due dates are one-off obligations; no account is
  /// chosen because the debt model does not store a funding account.
  static CashFlowForecast build(
    AppState state, {
    DateTime? asOf,
    int days = 30,
  }) {
    if (days < 1) throw ArgumentError.value(days, 'days', 'Must be positive');
    final now = asOf ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(start.year, start.month, start.day + days - 1);
    final opening = {for (final a in state.accounts) a.id: a.balance};
    final events = <ForecastEvent>[];
    final usedPostedIds = <String>{};
    var unplannedRecurringCount = 0;

    var month = DateTime(start.year, start.month);
    while (!month.isAfter(end)) {
      for (final template in state.recurring) {
        if (!template.enabled || template.amount <= 0) continue;
        final dueDay = template.dueDay;
        if (dueDay == null) {
          // Count templates once, even when horizon spans two calendar months.
          if (month.year == start.year && month.month == start.month) {
            unplannedRecurringCount++;
          }
          continue;
        }
        if (!opening.containsKey(template.accountId) ||
            (template.type == TxType.transfer &&
                (template.toAccountId == null ||
                    !opening.containsKey(template.toAccountId) ||
                    template.toAccountId == template.accountId))) {
          continue;
        }

        final lastDay = DateTime(month.year, month.month + 1, 0).day;
        final occurrence =
            DateTime(month.year, month.month, math.min(dueDay, lastDay));
        if (occurrence.isBefore(start) || occurrence.isAfter(end)) continue;

        Transaction? matchingPosted;
        for (final tx in state.transactions) {
          if (usedPostedIds.contains(tx.id) ||
              tx.date.year != month.year ||
              tx.date.month != month.month ||
              tx.type != template.type ||
              tx.accountId != template.accountId ||
              tx.toAccountId != template.toAccountId ||
              (tx.amount - template.amount).abs() > 0.005 ||
              tx.note.trim().toLowerCase() !=
                  template.label.trim().toLowerCase()) {
            continue;
          }
          matchingPosted = tx;
          break;
        }
        if (matchingPosted != null) {
          usedPostedIds.add(matchingPosted.id);
          continue;
        }

        final kind = switch (template.type) {
          TxType.income => ForecastEventKind.income,
          TxType.expense => ForecastEventKind.expense,
          TxType.transfer => ForecastEventKind.transfer,
        };
        events.add(ForecastEvent(
          date: occurrence,
          label: template.label,
          amount: template.amount,
          kind: kind,
          accountId: template.accountId,
          toAccountId: template.toAccountId,
        ));
      }
      month = DateTime(month.year, month.month + 1);
    }

    var unscheduledDebtCount = 0;
    var overdueDebtCount = 0;
    for (final debt in state.debts) {
      if (debt.remaining <= 0) continue;
      final dueDate = debt.dueDate;
      if (dueDate == null) {
        unscheduledDebtCount++;
        continue;
      }
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (due.isBefore(start)) {
        overdueDebtCount++;
        continue;
      }
      if (due.isAfter(end)) continue;

      // A scheduled expense with the same debt name on the due date already
      // reduces the account balance in this estimate. Count only any gap.
      final plannedForThisDebt = events
          .where((event) =>
              event.kind == ForecastEventKind.expense &&
              _sameDate(event.date, due) &&
              event.label.trim().toLowerCase() ==
                  debt.name.trim().toLowerCase())
          .fold<double>(0, (sum, event) => sum + event.amount);
      final amount = math.max(0.0,
          _outstandingDueAmount(debt, state.transactions) - plannedForThisDebt);
      if (amount <= 0) continue;
      events.add(ForecastEvent(
        date: due,
        label: debt.name,
        amount: amount,
        kind: ForecastEventKind.debtDue,
      ));
    }

    events.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.label.compareTo(b.label);
    });

    final balances = Map<String, double>.of(opening);
    final snapshots = <ForecastDay>[];
    var cumulativeDebt = 0.0;
    var eventIndex = 0;
    for (var offset = 0; offset < days; offset++) {
      final date = DateTime(start.year, start.month, start.day + offset);
      while (eventIndex < events.length &&
          _sameDate(events[eventIndex].date, date)) {
        final event = events[eventIndex++];
        switch (event.kind) {
          case ForecastEventKind.income:
            balances[event.accountId!] =
                balances[event.accountId]! + event.amount;
          case ForecastEventKind.expense:
            balances[event.accountId!] =
                balances[event.accountId]! - event.amount;
          case ForecastEventKind.transfer:
            balances[event.accountId!] =
                balances[event.accountId]! - event.amount;
            balances[event.toAccountId!] =
                balances[event.toAccountId]! + event.amount;
          case ForecastEventKind.debtDue:
            cumulativeDebt += event.amount;
        }
      }
      snapshots.add(ForecastDay(
        date: date,
        accountBalances: balances,
        debtDueToDate: cumulativeDebt,
      ));
    }

    final posted = state.transactions.where((tx) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      return !date.isBefore(start.subtract(const Duration(days: 29))) &&
          !date.isAfter(end);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return CashFlowForecast(
      asOf: start,
      openingBalances: opening,
      days: snapshots,
      events: events,
      postedTransactions: posted,
      unplannedRecurringCount: unplannedRecurringCount,
      unscheduledDebtCount: unscheduledDebtCount,
      overdueDebtCount: overdueDebtCount,
      matchedPostedCount: usedPostedIds.length,
    );
  }

  static double _outstandingDueAmount(
      Debt debt, List<Transaction> transactions) {
    if (debt.monthlyPayment <= 0) return debt.remaining;
    final due = debt.dueDate!;
    final alreadyPaidThisMonth = transactions
        .where((tx) =>
            tx.linkedDebtId == debt.id &&
            tx.type == TxType.expense &&
            tx.date.year == due.year &&
            tx.date.month == due.month)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    return math.max(0.0,
        math.min(debt.remaining, debt.monthlyPayment - alreadyPaidThisMonth));
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
