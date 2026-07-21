import 'package:flutter/foundation.dart';

/// Satu baris barang di bon.
@immutable
class ReceiptItem {
  const ReceiptItem({
    required this.itemName,
    this.qty = 1,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String itemName;
  final int qty;
  final double unitPrice;
  final double totalPrice;

  ReceiptItem copyWith({
    String? itemName,
    int? qty,
    double? unitPrice,
    double? totalPrice,
  }) =>
      ReceiptItem(
        itemName: itemName ?? this.itemName,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        totalPrice: totalPrice ?? this.totalPrice,
      );

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        itemName: json['name'] as String? ?? 'Unknown',
        qty: (json['qty'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      );
}

/// Keseluruhan hasil scan satu bon.
@immutable
class ReceiptScanResult {
  const ReceiptScanResult({
    required this.items,
    required this.subtotal,
    this.serviceCharge = 0,
    this.tax = 0,
    required this.grandTotal,
  });

  final List<ReceiptItem> items;
  final double subtotal;
  final double serviceCharge;
  final double tax;

  /// Grand Total yang tercetak di kertas bon asli.
  final double grandTotal;

  ReceiptScanResult copyWith({
    List<ReceiptItem>? items,
    double? subtotal,
    double? serviceCharge,
    double? tax,
    double? grandTotal,
  }) =>
      ReceiptScanResult(
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        serviceCharge: serviceCharge ?? this.serviceCharge,
        tax: tax ?? this.tax,
        grandTotal: grandTotal ?? this.grandTotal,
      );

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) =>
      ReceiptScanResult(
        items: (json['items'] as List<dynamic>?)
                ?.map((e) =>
                    ReceiptItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0,
        grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      );
}

/// Hasil validasi silang: apakah jumlah item cocok dengan grand total kertas.
@immutable
class VerificationResult {
  const VerificationResult({
    required this.isVerified,
    required this.calculatedSubtotal,
    required this.calculatedGrandTotal,
    this.errorMessage,
  });

  final bool isVerified;
  final double calculatedSubtotal;
  final double calculatedGrandTotal;
  final String? errorMessage;
}
