import 'package:flutter/material.dart';

import 'package:moneywork/l10n/app_localizations.dart';

/// Jenis akun penyimpanan uang.
enum AccountType {
  cash,
  bank,
  ewallet,
  rdn;

  String label(AppLocalizations l10n) => switch (this) {
        AccountType.cash => l10n.accountTypeCash,
        AccountType.bank => l10n.accountTypeBank,
        AccountType.ewallet => l10n.accountTypeEwallet,
        AccountType.rdn => l10n.accountTypeRdn,
      };

  IconData get icon => switch (this) {
        AccountType.cash => Icons.payments_outlined,
        AccountType.bank => Icons.account_balance_outlined,
        AccountType.ewallet => Icons.account_balance_wallet_outlined,
        AccountType.rdn => Icons.candlestick_chart_outlined,
      };
}

/// Akun: kas, rekening bank, atau e-wallet. Menyimpan saldo berjalan.
@immutable
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.accountNumber = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final double balance;

  /// Nomor rekening / nomor HP e-wallet. Kosong untuk akun tunai.
  final String accountNumber;
  final DateTime createdAt;

  Account copyWith({
    String? name,
    AccountType? type,
    double? balance,
    String? accountNumber,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
        'accountNumber': accountNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.values.byName(json['type'] as String),
        balance: (json['balance'] as num).toDouble(),
        accountNumber: json['accountNumber'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
