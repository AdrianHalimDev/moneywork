import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../models/wishlist_item.dart';

/// Tingkat kepentingan pengingat (mempengaruhi warna banner).
enum ReminderLevel { info, warning, success }

/// Satu pengingat dalam-app untuk ditampilkan di Beranda.
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.message,
    this.level = ReminderLevel.info,
  });

  final String id;
  final String title;
  final String message;
  final ReminderLevel level;
}

/// Membangun daftar pengingat dalam-app dari kondisi data saat [now].
///
/// Catatan: ini pengingat yang muncul ketika aplikasi dibuka, bukan push
/// notification OS (yang butuh FCM + service worker dan belum disiapkan).
class Reminders {
  Reminders._();

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Apakah ada transaksi yang tercatat pada hari [now].
  static bool hasTransactionToday(List<Transaction> txns, DateTime now) {
    return txns.any((t) => _sameDay(t.date, now));
  }

  /// Apakah ada pemasukan bertanda gaji pada bulan [now].
  /// Deteksi via kategori/catatan yang mengandung kata "gaji".
  static bool receivedSalaryThisMonth(List<Transaction> txns, DateTime now) {
    return txns.any((t) {
      if (t.type != TxType.income) return false;
      if (!_sameMonth(t.date, now)) return false;
      final hay = '${t.category} ${t.note}'.toLowerCase();
      return hay.contains('gaji') || hay.contains('salary');
    });
  }

  /// Susun semua pengingat yang relevan.
  static List<Reminder> build({
    required List<Transaction> transactions,
    required List<WishlistItem> wishlist,
    required DateTime now,
  }) {
    final list = <Reminder>[];

    // 1) Belum ada transaksi hari ini.
    if (!hasTransactionToday(transactions, now)) {
      list.add(const Reminder(
        id: 'no-tx-today',
        title: 'Belum ada transaksi hari ini',
        message: 'Catat pemasukan atau pengeluaranmu biar tetap terpantau.',
        level: ReminderLevel.warning,
      ));
    }

    // 2) Sudah gajian bulan ini → ingatkan menabung untuk wishlist aktif.
    final savingTargets = wishlist
        .where((w) => !w.purchased && w.hasSavingPlan && w.remainingToSave > 0)
        .toList();
    if (receivedSalaryThisMonth(transactions, now) && savingTargets.isNotEmpty) {
      final names = savingTargets.map((w) => w.name).take(3).join(', ');
      list.add(Reminder(
        id: 'salary-save',
        title: 'Sudah gajian? Sisihkan untuk tabungan',
        message: 'Jangan lupa nabung untuk: $names.',
        level: ReminderLevel.success,
      ));
    }

    // 3) Pengingat tanggal menabung untuk tiap wishlist (hari ini = reminderDay).
    for (final w in savingTargets) {
      if (w.reminderDay > 0 && w.reminderDay == now.day) {
        list.add(Reminder(
          id: 'save-${w.id}',
          title: 'Waktunya menabung: ${w.name}',
          message: w.monthlySaving > 0
              ? 'Sisihkan ${_rupiahShort(w.monthlySaving)} bulan ini.'
              : 'Sisihkan dana untuk target ini.',
          level: ReminderLevel.info,
        ));
      }
    }

    return list;
  }

  static String _rupiahShort(double v) =>
      'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
}
