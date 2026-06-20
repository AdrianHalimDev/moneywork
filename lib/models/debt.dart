import 'package:flutter/material.dart';

/// Jenis utang/kewajiban.
enum DebtType {
  loan,
  creditCard,
  installment,
  other;

  String get label => switch (this) {
        DebtType.loan => 'Pinjaman',
        DebtType.creditCard => 'Kartu Kredit',
        DebtType.installment => 'Cicilan',
        DebtType.other => 'Lainnya',
      };

  IconData get icon => switch (this) {
        DebtType.loan => Icons.request_quote_outlined,
        DebtType.creditCard => Icons.credit_card,
        DebtType.installment => Icons.calendar_month_outlined,
        DebtType.other => Icons.money_off,
      };
}

/// Utang/cicilan. Mengurangi kekayaan bersih.
///
/// [remaining] adalah sisa utang yang masih harus dibayar.
@immutable
class Debt {
  const Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.remaining,
    this.monthlyPayment = 0,
    this.dueDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DebtType type;
  final double remaining;
  final double monthlyPayment;
  final DateTime? dueDate;
  final DateTime createdAt;

  Debt copyWith({
    String? name,
    DebtType? type,
    double? remaining,
    double? monthlyPayment,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Debt(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      remaining: remaining ?? this.remaining,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'remaining': remaining,
        'monthlyPayment': monthlyPayment,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'] as String,
        name: json['name'] as String,
        type: DebtType.values.byName(json['type'] as String),
        remaining: (json['remaining'] as num).toDouble(),
        monthlyPayment: (json['monthlyPayment'] as num?)?.toDouble() ?? 0,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
