import 'package:flutter/foundation.dart';

import '../models/transaction.dart';

/// Ringkasan arus kas untuk satu bulan.
@immutable
class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expense,
  });

  /// Bulan yang diringkas (hari diabaikan).
  final DateTime month;
  final double income;
  final double expense;

  /// Selisih = pemasukan - pengeluaran.
  double get net => income - expense;
}

/// Porsi satu kategori pada breakdown pengeluaran.
@immutable
class CategorySlice {
  const CategorySlice({required this.label, required this.amount});
  final String label;
  final double amount;
}

/// Kumpulan perhitungan laporan dari daftar transaksi.
///
/// Transfer antar akun **tidak** dihitung sebagai pemasukan/pengeluaran
/// karena hanya memindahkan uang milik sendiri.
class Report {
  Report._();

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Ringkasan pemasukan & pengeluaran untuk [month].
  static MonthlySummary forMonth(
    List<Transaction> txns,
    DateTime month,
  ) {
    double income = 0;
    double expense = 0;
    for (final t in txns) {
      if (!_sameMonth(t.date, month)) continue;
      if (t.type == TxType.income) income += t.amount;
      if (t.type == TxType.expense) expense += t.amount;
    }
    return MonthlySummary(
      month: DateTime(month.year, month.month),
      income: income,
      expense: expense,
    );
  }

  /// Breakdown pengeluaran per kategori pada [month], urut dari terbesar.
  /// Transaksi tanpa kategori dikelompokkan sebagai 'Lainnya'.
  static List<CategorySlice> expenseByCategory(
    List<Transaction> txns,
    DateTime month,
  ) {
    final map = <String, double>{};
    for (final t in txns) {
      if (t.type != TxType.expense) continue;
      if (!_sameMonth(t.date, month)) continue;
      final key = t.category.trim().isEmpty ? 'Lainnya' : t.category.trim();
      map[key] = (map[key] ?? 0) + t.amount;
    }
    final slices = [
      for (final e in map.entries) CategorySlice(label: e.key, amount: e.value),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return slices;
  }

  /// Seri ringkasan [count] bulan terakhir hingga [anchor] (inklusif),
  /// urut dari paling lama ke paling baru.
  static List<MonthlySummary> lastMonths(
    List<Transaction> txns,
    DateTime anchor, {
    int count = 6,
  }) {
    final result = <MonthlySummary>[];
    for (var i = count - 1; i >= 0; i--) {
      final m = DateTime(anchor.year, anchor.month - i);
      result.add(forMonth(txns, m));
    }
    return result;
  }

  /// Daftar bulan yang punya transaksi, urut terbaru dulu (untuk pemilih bulan).
  static List<DateTime> monthsWithData(List<Transaction> txns) {
    final set = <String, DateTime>{};
    for (final t in txns) {
      final m = DateTime(t.date.year, t.date.month);
      set['${m.year}-${m.month}'] = m;
    }
    final list = set.values.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}
