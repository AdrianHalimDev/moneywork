import 'package:flutter/material.dart';

/// Jenis transaksi arus kas.
enum TxType {
  income,
  expense,
  transfer;

  String get label => switch (this) {
        TxType.income => 'Pemasukan',
        TxType.expense => 'Pengeluaran',
        TxType.transfer => 'Transfer',
      };
}

/// Transaksi: pemasukan, pengeluaran, atau transfer antar akun.
///
/// - income/expense memakai [accountId].
/// - transfer memakai [accountId] (sumber) dan [toAccountId] (tujuan).
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.category = '',
    this.note = '',
    this.linkedDebtId,
    this.linkedReceivableId,
    required this.date,
  });

  final String id;
  final TxType type;
  final double amount;
  final String accountId;
  final String? toAccountId;
  final String category;
  final String note;

  /// Jika transaksi ini adalah pembayaran utang, menyimpan id utang terkait
  /// agar penghapusan transaksi bisa mengembalikan sisa utang.
  final String? linkedDebtId;

  /// Jika transaksi ini adalah penerimaan piutang, menyimpan id piutang
  /// terkait agar penghapusan transaksi bisa mengembalikan sisa piutang.
  final String? linkedReceivableId;
  final DateTime date;

  /// Dampak ke saldo akun [accountId].
  /// income: +, expense: -, transfer: - (keluar dari sumber).
  double get signedAmount => switch (type) {
        TxType.income => amount,
        TxType.expense => -amount,
        TxType.transfer => -amount,
      };

  Transaction copyWith({
    TxType? type,
    double? amount,
    String? accountId,
    String? toAccountId,
    String? category,
    String? note,
    String? linkedDebtId,
    String? linkedReceivableId,
    DateTime? date,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      category: category ?? this.category,
      note: note ?? this.note,
      linkedDebtId: linkedDebtId ?? this.linkedDebtId,
      linkedReceivableId: linkedReceivableId ?? this.linkedReceivableId,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'category': category,
        'note': note,
        'linkedDebtId': linkedDebtId,
        'linkedReceivableId': linkedReceivableId,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: TxType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        accountId: json['accountId'] as String,
        toAccountId: json['toAccountId'] as String?,
        category: json['category'] as String? ?? '',
        note: json['note'] as String? ?? '',
        linkedDebtId: json['linkedDebtId'] as String?,
        linkedReceivableId: json['linkedReceivableId'] as String?,
        date: DateTime.parse(json['date'] as String),
      );
}
