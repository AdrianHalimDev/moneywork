import 'package:flutter/material.dart';

/// Kelas aset investasi.
enum InvestmentType {
  stock,
  mutualFund,
  crypto,
  gold,
  other;

  String get label => switch (this) {
        InvestmentType.stock => 'Saham',
        InvestmentType.mutualFund => 'Reksadana',
        InvestmentType.crypto => 'Crypto',
        InvestmentType.gold => 'Emas',
        InvestmentType.other => 'Lainnya',
      };

  /// Saham IDX diperdagangkan per lot (1 lot = 100 lembar).
  bool get tradedInLots => this == InvestmentType.stock;

  IconData get icon => switch (this) {
        InvestmentType.stock => Icons.show_chart,
        InvestmentType.mutualFund => Icons.pie_chart_outline,
        InvestmentType.crypto => Icons.currency_bitcoin,
        InvestmentType.gold => Icons.diamond_outlined,
        InvestmentType.other => Icons.savings_outlined,
      };
}

/// Investasi: saham, reksadana, crypto, emas.
///
/// Menyimpan jumlah unit, harga rata-rata beli, dan harga sekarang
/// untuk menghitung nilai & keuntungan/kerugian.
/// Jumlah lembar saham dalam satu lot di Bursa Efek Indonesia.
const int sharesPerLot = 100;

@immutable
class Investment {
  const Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    this.ticker = '',
    required this.updatedAt,
  });

  final String id;
  final String name;
  final InvestmentType type;
  final double quantity;
  final double buyPrice;
  final double currentPrice;

  /// Simbol untuk pembaruan harga otomatis.
  /// Crypto: id CoinGecko (mis. "bitcoin"). Saham: kode (mis. "BBCA").
  /// Kosong = harga diisi manual.
  final String ticker;
  final DateTime updatedAt;

  /// Modal awal = unit × harga beli.
  double get cost => quantity * buyPrice;

  /// Nilai sekarang = unit × harga sekarang.
  double get marketValue => quantity * currentPrice;

  /// Keuntungan/kerugian dalam Rupiah.
  double get gain => marketValue - cost;

  /// Keuntungan/kerugian dalam persen.
  double get gainPercent => cost == 0 ? 0 : (gain / cost) * 100;

  /// Jumlah lot untuk saham (1 lot = [sharesPerLot] lembar).
  /// [quantity] selalu disimpan dalam lembar agar perhitungan nilai konsisten.
  double get lots => quantity / sharesPerLot;

  Investment copyWith({
    String? name,
    InvestmentType? type,
    double? quantity,
    double? buyPrice,
    double? currentPrice,
    String? ticker,
    DateTime? updatedAt,
  }) {
    return Investment(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      ticker: ticker ?? this.ticker,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'quantity': quantity,
        'buyPrice': buyPrice,
        'currentPrice': currentPrice,
        'ticker': ticker,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: json['id'] as String,
        name: json['name'] as String,
        type: InvestmentType.values.byName(json['type'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        buyPrice: (json['buyPrice'] as num).toDouble(),
        currentPrice: (json['currentPrice'] as num).toDouble(),
        ticker: json['ticker'] as String? ?? '',
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
