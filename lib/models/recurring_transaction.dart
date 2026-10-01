import 'package:flutter/foundation.dart';

import 'transaction.dart';

/// Template transaksi bulanan yang berulang (mis. langganan, tagihan, tabungan
/// rutin). Pengguna menyusun daftar ini lalu menjalankannya sekali klik tiap
/// bulan / saat gajian untuk membuat transaksi nyata.
@immutable
class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.label,
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.category = '',
    this.enabled = true,
    this.dueDay,
    required this.createdAt,
  }) : assert(dueDay == null || (dueDay >= 1 && dueDay <= 31));

  final String id;

  /// Nama template, mis. "Netflix", "Listrik", "Nabung darurat".
  final String label;
  final TxType type;
  final double amount;
  final String accountId;
  final String? toAccountId;
  final String category;

  /// Apakah ikut saat "jalankan semua".
  final bool enabled;

  /// Tanggal bulanan untuk proyeksi saja; null berarti belum dijadwalkan.
  /// Tanggal 29–31 jatuh pada hari terakhir jika bulan lebih pendek.
  final int? dueDay;
  final DateTime createdAt;

  RecurringTransaction copyWith({
    String? label,
    TxType? type,
    double? amount,
    String? accountId,
    String? toAccountId,
    bool clearToAccountId = false,
    String? category,
    bool? enabled,
    int? dueDay,
    bool clearDueDay = false,
  }) {
    return RecurringTransaction(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      toAccountId: clearToAccountId ? null : (toAccountId ?? this.toAccountId),
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
      dueDay: clearDueDay ? null : (dueDay ?? this.dueDay),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'amount': amount,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'category': category,
        'enabled': enabled,
        'dueDay': dueDay,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      RecurringTransaction(
        id: json['id'] as String,
        label: json['label'] as String,
        type: TxType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        accountId: json['accountId'] as String,
        toAccountId: json['toAccountId'] as String?,
        category: json['category'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        dueDay: _parseDueDay(json['dueDay']),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

int? _parseDueDay(dynamic value) {
  final day = value is num ? value.toInt() : null;
  return day != null && day >= 1 && day <= 31 ? day : null;
}
