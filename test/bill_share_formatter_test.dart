import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/core/formatters.dart';
import 'package:moneywork/l10n/app_localizations_id.dart';
import 'package:moneywork/services/bill_share_formatter.dart';
import 'package:moneywork/services/bill_splitter.dart';

void main() {
  test('shared bill includes items, charges, and each payable amount', () {
    final people = [
      const BillPerson(
          name: 'Alya', items: [BillItem(name: 'Nasi', price: 10000)]),
      const BillPerson(
          name: 'Bima', items: [BillItem(name: 'Ayam', price: 20000)]),
    ];
    final sharedItems = [
      const BillItem(name: 'Es teh', price: 3000, qty: 2),
    ];
    final result = BillSplitter.calculate(
      people: people,
      sharedItems: sharedItems,
      serviceAmount: 3600,
      taxAmount: 3960,
      additionalFees: 500,
      discount: 1000,
    );

    final text = BillShareFormatter.format(
      result: result,
      people: people,
      sharedItems: sharedItems,
      l10n: AppLocalizationsId(),
    );

    expect(text, contains('Nasi (1 × ${Fmt.rupiah(10000)})'));
    expect(text, contains('Ayam (1 × ${Fmt.rupiah(20000)})'));
    expect(text, contains('Es teh (2 × ${Fmt.rupiah(3000)})'));
    expect(text, contains('Service: ${Fmt.rupiah(3600)}'));
    expect(text, contains('PPN: ${Fmt.rupiah(3960)}'));
    expect(text, contains('Biaya tambahan: ${Fmt.rupiah(500)}'));
    expect(text, contains('Diskon: -${Fmt.rupiah(1000)}'));
    expect(text, contains('Alya — ${Fmt.rupiah(result.shares[0].total)}'));
    expect(text, contains('Bima — ${Fmt.rupiah(result.shares[1].total)}'));
    expect(text, contains('Item Bersama (dibagi rata): ${Fmt.rupiah(3000)}'));
    expect(text, contains('Total: ${Fmt.rupiah(result.grandTotal)}'));
  });
}
