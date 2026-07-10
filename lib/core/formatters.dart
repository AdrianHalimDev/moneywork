import 'package:flutter/services.dart';
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

  static final NumberFormat _grouping = NumberFormat.decimalPattern('id_ID');

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

  /// 1.250.000 tanpa simbol — angka murni dgn pemisah ribuan.
  static String group(num value) => _grouping.format(value);

  /// Menghapus pemisah ribuan & mengganti koma desimal dengan titik.
  /// "1.250.000" → "1250000"; "1.250,50" → "1250.50".
  static String unformatInput(String input) {
    return input.replaceAll('.', '').replaceAll(',', '.');
  }

  /// Mengurai input hasil [unformatInput] menjadi double (null bila invalid).
  static double? tryParseInput(String input) {
    final s = unformatInput(input);
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Memformat nilai untuk prafilling field input (titik pemisah ribuan).
  /// 0 → '' (kosong, bukan "0") supaya field tidak menampilkan nol.
  static String groupInput(num value) {
    if (value == 0) return '';
    return _grouping.format(value);
  }
}

/// Memberi pemisah ribuan ("titik") secara langsung saat pengguna mengetik
/// nominal Rupiah, mis. "1000000" → "1.000.000".
///
/// Hanya menerima digit (nominal Rupiah selalu bilangan bulat). Posisi kursor
/// dijaga relatif terhadap jumlah digit, bukan jumlah karakter, agar tidak
/// melompat saat pemisah disisipkan/dihapus.
class ThousandsInputFormatter extends TextInputFormatter {
  static final NumberFormat _grouping = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = _grouping.format(int.parse(digits));

    // Hitung berapa digit yang berada sebelum kursor pada teks baru, lalu
    // tempatkan kursor setelah digit ke-N pada teks yang sudah diformat.
    final digitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.baseOffset.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBeforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(formatted[offset])) seen++;
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Mencegah bug "teks lama dikembalikan" pada field teks akibat composing
/// region IME yang basi (Flutter issue #78827 / #31512).
///
/// Gejala: ketik "initest123" → hapus per-karakter hingga kosong → ketik "ab"
/// → muncul "initest123ab" padahal seharusnya "ab". Terjadi di semua keyboard
/// & semua field (email, nama, sandi) karena akar masalahnya di lapisan
/// engine↔IME, bukan keyboard/autofill tertentu.
///
/// Mekanisme: saat input connection terbuka, IME menjaga composing region.
/// Jika region itu basi (teks sudah dihapus) lalu user mengetik lagi, IME
/// meng-commit gabungan composing lama + ketikan baru. Formatter ini selalu
/// mengosongkan composing region pada setiap perubahan nilai, sehingga tidak
/// ada region basi yang bisa dipulihkan IME. Tidak mengubah teks/kursor —
/// aman, tanpa false-positive.
class NoComposingFormatter extends TextInputFormatter {
  const NoComposingFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing == TextRange.empty) return newValue;
    return TextEditingValue(
      text: newValue.text,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

/// Mencegah bug "teks lama dikembalikan" saat hapus per-karakter lalu ketik
/// ulang. Terverifikasi via log diagnostik: IME mengirim teks terpanjang yang
/// pernah ada (peak) + ketikan baru dalam satu commit saat field sudah
/// dikosongkan, mis. ketik "testab" → hapus → "" → ketik "a" → IME kirim
/// "testaba" padahal seharusnya "a".
///
/// Mekanisme: lacak [_peak] (teks terpanjang, HANYA naik, tidak ikut turun
/// saat hapus). Saat commit masuk memenuhi SEMUA syarat:
///  - [_peak] tidak kosong & [oldValue] lebih pendek dari [_peak] (peak pernah
///    dihapus)
///  - [newValue] diawali persis [_peak] (teks lama dikembalikan)
///  - lompatan panjang [newValue] - [oldValue] ≥ 2 (bukan ketik 1 karakter
///    normal — lihat log: ketik normal selalu +1 per commit)
///  - sufiks (di luar [_peak]) pendek (≤ 4) — cakupan ketikan baru, bukan paste
/// maka koreksi: nilai benar = oldValue + sufiks. Lompatan ≥2 menjamin ketik
/// normal karakter-tunggal tidak pernah salah-tembak.
class AntiRestoreFormatter extends TextInputFormatter {
  AntiRestoreFormatter();

  /// Teks terpanjang yang pernah ada. Hanya naik, tidak pernah turun saat
  /// user menghapus — inilah jejak teks yang bisa dikembalikan IME.
  String _peak = '';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final old = oldValue.text;
    final now = newValue.text;

    if (_peak.isNotEmpty &&
        old.length < _peak.length &&
        now.length > old.length &&
        now.length - old.length >= 2 &&
        now.startsWith(_peak)) {
      final suffix = now.substring(_peak.length);
      if (suffix.isNotEmpty && suffix.length <= 4) {
        final corrected = old + suffix;
        if (corrected.length > _peak.length) _peak = corrected;
        return TextEditingValue(
          text: corrected,
          selection: TextSelection.collapsed(offset: corrected.length),
          composing: TextRange.empty,
        );
      }
    }

    // High-water mark: hanya naik saat teks lebih panjang.
    if (now.length > _peak.length) _peak = now;
    return newValue;
  }
}
