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

  /// Kunci normalisasi nama untuk pengelompokan: trim + lowercase.
  /// "Gama", "gama", "Gama " dianggap orang yang sama.
  static String nameKey(String name) => name.trim().toLowerCase();
}

/// Sekelompok piutang dari satu orang (dikelompokkan otomatis by nama).
///
/// Tiap pinjaman tetap disimpan sebagai [Receivable] terpisah agar riwayat
/// utuh; grup hanya menggabungkan tampilan & memudahkan pembayaran gabungan.
@immutable
class ReceivableGroup {
  const ReceivableGroup({required this.displayName, required this.items});

  final String displayName;

  /// Pinjaman orang ini, terurut dari yang paling lama (untuk alokasi FIFO).
  final List<Receivable> items;

  String get key => Receivable.nameKey(displayName);

  /// Total sisa yang belum dibayar.
  double get outstanding =>
      items.fold(0, (s, r) => s + (r.remaining > 0 ? r.remaining : 0));

  /// Jumlah pinjaman yang masih berjalan.
  int get openCount => items.where((r) => r.remaining > 0).length;

  bool get isSettled => outstanding <= 0;

  /// Tempo terdekat di antara pinjaman yang masih berjalan.
  DateTime? get nearestDue {
    DateTime? d;
    for (final r in items) {
      if (r.remaining <= 0 || r.dueDate == null) continue;
      if (d == null || r.dueDate!.isBefore(d)) d = r.dueDate;
    }
    return d;
  }

  /// Kelompokkan daftar piutang berdasarkan nama (case-insensitive).
  /// Grup dengan sisa tagihan tampil lebih dulu, lalu tempo terdekat, lalu nama.
  static List<ReceivableGroup> groupByName(List<Receivable> receivables) {
    final buckets = <String, List<Receivable>>{};
    final display = <String, String>{};
    final displayAt = <String, DateTime>{};
    for (final r in receivables) {
      final key = Receivable.nameKey(r.personName);
      buckets.putIfAbsent(key, () => []).add(r);
      // Nama tampilan mengikuti ejaan dari entri yang dibuat paling akhir.
      final prev = displayAt[key];
      if (prev == null || r.createdAt.isAfter(prev)) {
        display[key] = r.personName.trim();
        displayAt[key] = r.createdAt;
      }
    }

    final groups = [
      for (final entry in buckets.entries)
        ReceivableGroup(
          displayName: display[entry.key]!,
          items: entry.value
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        ),
    ];

    groups.sort((a, b) {
      if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
      final ad = a.nearestDue, bd = b.nearestDue;
      if (ad != null && bd != null && ad != bd) return ad.compareTo(bd);
      if (ad == null && bd != null) return 1;
      if (ad != null && bd == null) return -1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return groups;
  }
}
