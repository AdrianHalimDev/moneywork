import 'package:flutter/foundation.dart';

/// Satu item pesanan dalam bill.
@immutable
class BillItem {
  const BillItem({required this.name, required this.price, this.qty = 1});

  final String name;
  final double price;
  final int qty;

  double get total => price * qty;

  BillItem copyWith({String? name, double? price, int? qty}) => BillItem(
        name: name ?? this.name,
        price: price ?? this.price,
        qty: qty ?? this.qty,
      );
}

/// Seorang peserta beserta item yang dia pesan sendiri.
@immutable
class BillPerson {
  const BillPerson({required this.name, this.items = const []});

  final String name;
  final List<BillItem> items;

  double get ownSubtotal => items.fold(0, (s, i) => s + i.total);

  BillPerson copyWith({String? name, List<BillItem>? items}) => BillPerson(
        name: name ?? this.name,
        items: items ?? this.items,
      );
}

/// Tagihan yang ditanggung satu orang setelah pembagian.
@immutable
class BillShare {
  const BillShare({
    required this.name,
    required this.subtotal,
    required this.total,
  });

  final String name;

  /// Subtotal item orang ini (termasuk porsi item bersama).
  final double subtotal;

  /// Jumlah akhir yang harus dia bayar (setelah diskon, service, PPN).
  final double total;
}

/// Hasil perhitungan split bill.
@immutable
class BillResult {
  const BillResult({
    required this.shares,
    required this.subtotal,
    required this.discount,
    required this.serviceAmount,
    required this.taxAmount,
    required this.grandTotal,
  });

  final List<BillShare> shares;
  final double subtotal;
  final double discount;
  final double serviceAmount;
  final double taxAmount;
  final double grandTotal;
}

/// Kalkulator split bill.
///
/// Alur perhitungan (diskon dipotong paling akhir, setelah pajak):
///   1. subtotal per orang = item sendiri + porsi item bersama (dibagi rata)
///   2. service charge = subtotal × serviceRate
///   3. PPN = (subtotal + service charge) × ppnRate
///   4. total dengan pajak = subtotal + service charge + PPN
///   5. grand total = total dengan pajak − diskon
///
/// Service & PPN selalu dibagi proporsional terhadap subtotal tiap orang.
/// Diskon dipotong terakhir (di luar hitungan PPN & service) dan distribusinya
/// mengikuti [splitDiscountEvenly]:
///   - `true` : rata — tiap orang dapat potongan diskon yang sama besar.
///   - `false`: proporsional — yang pesan lebih mahal dapat potongan lebih besar.
/// Apa pun pilihannya, grand total tetap sama; hanya distribusi per orang yang
/// berbeda. Pembulatan ke rupiah utuh; selisih sisa pembulatan ditimpakan ke
/// pembayar terbesar agar jumlah per orang persis = grand total.
class BillSplitter {
  /// [serviceRate] dan [ppnRate] dalam fraksi (0.11 untuk 11%).
  static BillResult calculate({
    required List<BillPerson> people,
    List<BillItem> sharedItems = const [],
    double discount = 0,
    double serviceRate = 0,
    double ppnRate = 0.11,
    bool splitDiscountEvenly = true,
  }) {
    final n = people.length;
    final sharedTotal = sharedItems.fold<double>(0, (s, i) => s + i.total);
    final sharedPerPerson = n == 0 ? 0.0 : sharedTotal / n;

    // Subtotal tiap orang termasuk porsi item bersama.
    final subtotals = [
      for (final p in people) p.ownSubtotal + sharedPerPerson,
    ];
    final subtotal = subtotals.fold<double>(0, (s, v) => s + v);

    // Service & PPN dihitung dari subtotal penuh (sebelum diskon).
    final serviceAmount = subtotal * serviceRate;
    final taxAmount = (subtotal + serviceAmount) * ppnRate;
    final totalWithTax = subtotal + serviceAmount + taxAmount;

    // Diskon dipotong paling akhir, di luar pajak. Dibatasi agar tak melebihi
    // total dengan pajak (grand total tidak bisa minus).
    final effDiscount = discount.clamp(0, totalWithTax).toDouble();
    final grandTotal = totalWithTax - effDiscount;

    // Pengali pajak per orang: subtotal × (1+service) × (1+ppn).
    final taxMultiplier = (1 + serviceRate) * (1 + ppnRate);
    final discountPerPerson = n == 0 ? 0.0 : effDiscount / n;

    // Tiap orang: (subtotal + pajak) lalu dikurangi porsi diskon.
    final rawShares = <double>[];
    for (var i = 0; i < n; i++) {
      final withTax = subtotals[i] * taxMultiplier;
      final disc = splitDiscountEvenly
          ? discountPerPerson
          : (subtotal == 0 ? 0.0 : effDiscount * (subtotals[i] / subtotal));
      rawShares.add((withTax - disc).clamp(0, double.infinity).toDouble());
    }
    final rounded = rawShares.map((v) => v.roundToDouble()).toList();

    // Koreksi selisih pembulatan pada pembayar terbesar.
    final roundedSum = rounded.fold<double>(0, (s, v) => s + v);
    final diff = grandTotal.roundToDouble() - roundedSum;
    if (diff != 0 && rounded.isNotEmpty) {
      var maxIdx = 0;
      for (var i = 1; i < rounded.length; i++) {
        if (rounded[i] > rounded[maxIdx]) maxIdx = i;
      }
      rounded[maxIdx] += diff;
    }

    final shares = [
      for (var i = 0; i < n; i++)
        BillShare(
          name: people[i].name,
          subtotal: subtotals[i],
          total: rounded[i],
        ),
    ];

    return BillResult(
      shares: shares,
      subtotal: subtotal,
      discount: effDiscount,
      serviceAmount: serviceAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
    );
  }
}
