import 'package:flutter/material.dart';

/// Piutang: uang yang dipinjam orang lain kepada kita.
/// Kebalikan dari [Debt] — menambah kekayaan bersih.
///
/// [remaining] adalah sisa yang belum diterima kembali.
@immutable
class Receivable {
  const Receivable({
    required this.id,
    required this.personName,
    required this.remaining,
    this.note = '',
    this.dueDate,
    required this.createdAt,
  });

  final String id;
  final String personName;
  final double remaining;
  final String note;
  final DateTime? dueDate;
  final DateTime createdAt;

  IconData get icon => Icons.person_outline;

  Receivable copyWith({
    String? personName,
    double? remaining,
    String? note,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Receivable(
      id: id,
      personName: personName ?? this.personName,
      remaining: remaining ?? this.remaining,
      note: note ?? this.note,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'remaining': remaining,
        'note': note,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Receivable.fromJson(Map<String, dynamic> json) => Receivable(
        id: json['id'] as String,
        personName: json['personName'] as String,
        remaining: (json['remaining'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
