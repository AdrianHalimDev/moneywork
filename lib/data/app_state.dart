import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/debt.dart';
import '../models/investment.dart';
import '../models/receivable.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../models/wishlist_item.dart';

/// Snapshot seluruh data aplikasi pada satu waktu.
///
/// Immutable: setiap perubahan menghasilkan [AppState] baru lewat [copyWith].
@immutable
class AppState {
  const AppState({
    this.accounts = const [],
    this.transactions = const [],
    this.investments = const [],
    this.debts = const [],
    this.receivables = const [],
    this.wishlist = const [],
    this.recurring = const [],
    this.themeMode = 'system',
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Investment> investments;
  final List<Debt> debts;
  final List<Receivable> receivables;
  final List<WishlistItem> wishlist;
  final List<RecurringTransaction> recurring;

  /// Preferensi tema: 'system', 'light', atau 'dark'. Tersinkron per akun.
  final String themeMode;

  /// Jam & menit pengingat harian "catat transaksi" (default 20:00).
  final int reminderHour;
  final int reminderMinute;

  // --- Ringkasan kekayaan bersih ---

  /// Total saldo seluruh akun (kas + bank + e-wallet).
  double get totalCash =>
      accounts.fold(0, (sum, a) => sum + a.balance);

  /// Total nilai pasar seluruh investasi.
  double get totalInvestment =>
      investments.fold(0, (sum, i) => sum + i.marketValue);

  /// Total sisa utang.
  double get totalDebt => debts.fold(0, (sum, d) => sum + d.remaining);

  /// Total piutang (uang yang dipinjam orang lain ke kita).
  double get totalReceivable =>
      receivables.fold(0, (sum, r) => sum + r.remaining);

  /// Kekayaan bersih = (kas + investasi + piutang) - utang.
  double get netWorth =>
      totalCash + totalInvestment + totalReceivable - totalDebt;

  /// Total aset (tanpa dikurangi utang).
  double get totalAssets => totalCash + totalInvestment + totalReceivable;

  AppState copyWith({
    List<Account>? accounts,
    List<Transaction>? transactions,
    List<Investment>? investments,
    List<Debt>? debts,
    List<Receivable>? receivables,
    List<WishlistItem>? wishlist,
    List<RecurringTransaction>? recurring,
    String? themeMode,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppState(
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      investments: investments ?? this.investments,
      debts: debts ?? this.debts,
      receivables: receivables ?? this.receivables,
      wishlist: wishlist ?? this.wishlist,
      recurring: recurring ?? this.recurring,
      themeMode: themeMode ?? this.themeMode,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'investments': investments.map((e) => e.toJson()).toList(),
        'debts': debts.map((e) => e.toJson()).toList(),
        'receivables': receivables.map((e) => e.toJson()).toList(),
        'wishlist': wishlist.map((e) => e.toJson()).toList(),
        'recurring': recurring.map((e) => e.toJson()).toList(),
        'themeMode': themeMode,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      accounts: _parseList(json['accounts'], Account.fromJson),
      transactions: _parseList(json['transactions'], Transaction.fromJson),
      investments: _parseList(json['investments'], Investment.fromJson),
      debts: _parseList(json['debts'], Debt.fromJson),
      receivables: _parseList(json['receivables'], Receivable.fromJson),
      wishlist: _parseList(json['wishlist'], WishlistItem.fromJson),
      recurring:
          _parseList(json['recurring'], RecurringTransaction.fromJson),
      themeMode: json['themeMode'] as String? ?? 'system',
      reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 20,
      reminderMinute: (json['reminderMinute'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Helper top-level untuk mem-parsing list JSON menjadi list model.
///
/// Sengaja diletakkan di luar factory constructor: fungsi generic yang
/// di-nest dalam constructor memicu bug pada compiler dev web (DDC).
List<T> _parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  final list = raw as List<dynamic>? ?? const [];
  return list
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}
