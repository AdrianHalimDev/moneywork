import 'package:intl/intl.dart';

/// Formatter terpusat untuk Rupiah dan tanggal.
class Fmt {
  Fmt._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static final NumberFormat _number = NumberFormat.decimalPattern('id_ID');

  static final DateFormat _date = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dateFull = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');

  /// Rp 1.500.000
  static String rupiah(num value) => _rupiah.format(value);

  /// Rp 1,5 jt — untuk ringkasan/ruang sempit.
  static String rupiahCompact(num value) => _compact.format(value);

  /// Rupiah dengan tanda +/- untuk arus kas.
  static String rupiahSigned(num value) {
    final sign = value > 0 ? '+' : value < 0 ? '-' : '';
    return '$sign${_rupiah.format(value.abs())}';
  }

  /// 1.234,56 — angka biasa (mis. jumlah unit saham).
  static String number(num value) => _number.format(value);

  /// 20 Jun 2026
  static String date(DateTime d) => _date.format(d);

  /// Jumat, 20 Juni 2026
  static String dateFull(DateTime d) => _dateFull.format(d);

  /// Juni 2026
  static String monthYear(DateTime d) => _monthYear.format(d);
}
