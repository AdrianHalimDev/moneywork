import 'dart:convert';

import '../data/app_state.dart';

/// Bentuk dokumen Firestore v2 sebelum enkripsi. Setiap entitas memakai satu
/// dokumen, sehingga penambahan transaksi dari dua perangkat mempunyai ID
/// berbeda dan tidak mengganti seluruh AppState.
///
/// Saldo akun disimpan sebagai nilai awal dan dihitung dari transaksi ketika
/// membaca. Sisa utang/piutang disimpan langsung agar dua pembayaran serentak
/// pada kewajiban yang sama dapat dideteksi sebagai konflik revisi.
class RecordCodec {
  static const collections = <String>[
    'accounts',
    'transactions',
    'investments',
    'debts',
    'receivables',
    'wishlist',
    'recurring',
  ];

  static Map<String, Map<String, dynamic>> encode(AppState state) {
    final json = state.toJson();
    final records = <String, Map<String, dynamic>>{};
    final transactions = state.transactions;

    for (final collection in collections) {
      for (final raw in json[collection] as List<dynamic>) {
        final item = Map<String, dynamic>.from(raw as Map);
        final id = item['id'] as String;
        if (collection == 'accounts') {
          final adjustment = transactions.fold<double>(0, (sum, tx) {
            if (!tx.balanceApplied) return sum;
            var delta = tx.accountId == id ? tx.signedAmount : 0.0;
            if (tx.toAccountId == id && tx.type.name == 'transfer') {
              delta += tx.amount;
            }
            return sum + delta;
          });
          item['balance'] = (item['balance'] as num).toDouble() - adjustment;
        }
        records['$collection/$id'] = item;
      }
    }
    records['settings/main'] = {
      'themeMode': json['themeMode'],
      'locale': json['locale'],
      'reminderHour': json['reminderHour'],
      'reminderMinute': json['reminderMinute'],
    };
    return records;
  }

  static AppState decode(Map<String, Map<String, dynamic>> records) {
    final json = <String, dynamic>{
      for (final collection in collections) collection: <Map<String, dynamic>>[],
      ...?records['settings/main'],
    };
    for (final entry in records.entries) {
      final parts = entry.key.split('/');
      if (parts.length != 2 || !collections.contains(parts[0])) continue;
      (json[parts[0]] as List<Map<String, dynamic>>)
          .add(Map<String, dynamic>.from(entry.value));
    }
    final transactions = json['transactions'] as List<Map<String, dynamic>>;
    for (final account in json['accounts'] as List<Map<String, dynamic>>) {
      final id = account['id'];
      var balance = (account['balance'] as num).toDouble();
      for (final tx in transactions) {
        if (tx['balanceApplied'] == false) continue;
        final amount = (tx['amount'] as num).toDouble();
        if (tx['accountId'] == id) {
          balance += tx['type'] == 'income' ? amount : -amount;
        }
        if (tx['type'] == 'transfer' && tx['toAccountId'] == id) {
          balance += amount;
        }
      }
      account['balance'] = balance;
    }
    return AppState.fromJson(json);
  }

  /// Dokumen akun yang harus ikut diperiksa revisinya ketika transaksi berubah.
  /// Ini mencegah dua perangkat menghabiskan saldo awal yang sama bersamaan.
  static Set<String> affectedAccountKeys(
    Map<String, Map<String, dynamic>> before,
    Map<String, Map<String, dynamic>> after,
    Iterable<String> transactionKeys,
  ) {
    final affected = <String>{};
    for (final key in transactionKeys) {
      if (!key.startsWith('transactions/')) continue;
      for (final record in [before[key], after[key]]) {
        if (record == null) continue;
        final accountId = record['accountId'];
        if (accountId is String) affected.add('accounts/$accountId');
        if (record['type'] == 'transfer' && record['toAccountId'] is String) {
          affected.add('accounts/${record['toAccountId']}');
        }
      }
    }
    return affected;
  }

  /// Membandingkan bentuk JSON, bukan identitas object Dart.
  static Set<String> changedKeys(
    Map<String, Map<String, dynamic>> before,
    Map<String, Map<String, dynamic>> after,
  ) => {
        for (final key in {...before.keys, ...after.keys})
          if (jsonEncode(before[key]) != jsonEncode(after[key])) key,
      };
}
