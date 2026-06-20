import 'package:flutter/material.dart';

/// Prioritas barang wishlist.
enum WishPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
        WishPriority.low => 'Rendah',
        WishPriority.medium => 'Sedang',
        WishPriority.high => 'Tinggi',
      };

  Color get color => switch (this) {
        WishPriority.low => Colors.blueGrey,
        WishPriority.medium => Colors.orange,
        WishPriority.high => Colors.red,
      };
}

/// Barang yang ingin dibeli. Tidak mempengaruhi kekayaan bersih,
/// hanya target/rencana belanja.
///
/// Mendukung rencana menabung: [monthlySaving] (tabung per bulan) atau
/// [durationMonths] (jangka waktu) — keduanya saling melengkapi (lihat getter).
/// [savedAmount] melacak progres tabungan, [reminderDay] hari pengingat tiap
/// bulan, dan [savingAccountId] rekening sumber tabungan.
@immutable
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.url = '',
    this.priority = WishPriority.medium,
    this.targetDate,
    this.purchased = false,
    this.monthlySaving = 0,
    this.durationMonths = 0,
    this.savedAmount = 0,
    this.reminderDay = 0,
    this.savingAccountId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double price;
  final String url;
  final WishPriority priority;
  final DateTime? targetDate;
  final bool purchased;

  /// Rencana tabung per bulan (Rp). 0 = belum diatur.
  final double monthlySaving;

  /// Jangka waktu cicilan (bulan). 0 = belum diatur.
  final int durationMonths;

  /// Akumulasi yang sudah ditabung.
  final double savedAmount;

  /// Tanggal pengingat menabung tiap bulan (1–28). 0 = tidak ada pengingat.
  final int reminderDay;

  /// Rekening sumber dana tabungan (opsional, untuk info pengingat).
  final String? savingAccountId;
  final DateTime createdAt;

  /// Sisa yang masih perlu ditabung.
  double get remainingToSave =>
      (price - savedAmount).clamp(0, price).toDouble();

  /// Progres tabungan 0..1.
  double get savingProgress =>
      price <= 0 ? 0 : (savedAmount / price).clamp(0, 1).toDouble();

  /// Apakah punya rencana menabung aktif.
  bool get hasSavingPlan => monthlySaving > 0 || durationMonths > 0;

  /// Estimasi jumlah bulan tersisa untuk melunasi target dengan [monthlySaving].
  int get monthsRemaining {
    if (monthlySaving <= 0) return 0;
    return (remainingToSave / monthlySaving).ceil();
  }

  WishlistItem copyWith({
    String? name,
    double? price,
    String? url,
    WishPriority? priority,
    DateTime? targetDate,
    bool clearTargetDate = false,
    bool? purchased,
    double? monthlySaving,
    int? durationMonths,
    double? savedAmount,
    int? reminderDay,
    String? savingAccountId,
    bool clearSavingAccount = false,
  }) {
    return WishlistItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      url: url ?? this.url,
      priority: priority ?? this.priority,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      purchased: purchased ?? this.purchased,
      monthlySaving: monthlySaving ?? this.monthlySaving,
      durationMonths: durationMonths ?? this.durationMonths,
      savedAmount: savedAmount ?? this.savedAmount,
      reminderDay: reminderDay ?? this.reminderDay,
      savingAccountId: clearSavingAccount
          ? null
          : (savingAccountId ?? this.savingAccountId),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'url': url,
        'priority': priority.name,
        'targetDate': targetDate?.toIso8601String(),
        'purchased': purchased,
        'monthlySaving': monthlySaving,
        'durationMonths': durationMonths,
        'savedAmount': savedAmount,
        'reminderDay': reminderDay,
        'savingAccountId': savingAccountId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        url: json['url'] as String? ?? '',
        priority: WishPriority.values.byName(
          json['priority'] as String? ?? 'medium',
        ),
        targetDate: json['targetDate'] == null
            ? null
            : DateTime.parse(json['targetDate'] as String),
        purchased: json['purchased'] as bool? ?? false,
        monthlySaving: (json['monthlySaving'] as num?)?.toDouble() ?? 0,
        durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 0,
        savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
        reminderDay: (json['reminderDay'] as num?)?.toInt() ?? 0,
        savingAccountId: json['savingAccountId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
