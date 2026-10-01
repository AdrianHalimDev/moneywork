import '../core/formatters.dart';
import '../l10n/app_localizations.dart';
import 'bill_splitter.dart';

/// Builds a plain-text bill that can be copied or sent to another app.
class BillShareFormatter {
  BillShareFormatter._();

  static String format({
    required BillResult result,
    required List<BillPerson> people,
    required List<BillItem> sharedItems,
    required AppLocalizations l10n,
  }) {
    final lines = <String>[
      'MoneyWork • ${l10n.tabSplitBill}',
      '',
      '${l10n.detailsLabel}:',
      '${l10n.subtotalLabel}: ${Fmt.rupiah(result.subtotal)}',
    ];

    if (result.serviceAmount > 0) {
      lines.add(
          '${l10n.serviceChargeLabel}: ${Fmt.rupiah(result.serviceAmount)}');
    }
    if (result.taxAmount > 0) {
      lines.add('${l10n.ppnLabel}: ${Fmt.rupiah(result.taxAmount)}');
    }
    if (result.additionalFees > 0) {
      lines.add(
          '${l10n.additionalFeesLabel}: ${Fmt.rupiah(result.additionalFees)}');
    }
    if (result.discount > 0) {
      lines.add('${l10n.discountLabel}: -${Fmt.rupiah(result.discount)}');
    }
    lines.add('${l10n.totalLabel}: ${Fmt.rupiah(result.grandTotal)}');

    if (sharedItems.isNotEmpty) {
      lines.addAll(['', '${l10n.sharedItemsLabel}:']);
      for (final item in sharedItems) {
        lines.add('- ${item.name} (${item.qty} × ${Fmt.rupiah(item.price)}): '
            '${Fmt.rupiah(item.total)}');
      }
    }

    lines.addAll(['', '${l10n.billPerPersonLabel}:']);
    final sharedPerPerson = result.shares.isEmpty
        ? 0.0
        : sharedItems.fold<double>(0, (sum, item) => sum + item.total) /
            result.shares.length;
    for (var i = 0; i < result.shares.length; i++) {
      final share = result.shares[i];
      final name = share.name.isEmpty ? l10n.unnamedLabel : share.name;
      lines.add('');
      lines.add('$name — ${Fmt.rupiah(share.total)}');
      if (i < people.length) {
        for (final item in people[i].items) {
          lines.add('- ${item.name} (${item.qty} × ${Fmt.rupiah(item.price)}): '
              '${Fmt.rupiah(item.total)}');
        }
      }
      if (sharedItems.isNotEmpty) {
        lines.add('- ${l10n.sharedItemsLabel}: ${Fmt.rupiah(sharedPerPerson)}');
      }
      lines.add('${l10n.subtotalLabel}: ${Fmt.rupiah(share.subtotal)}');
      lines.add('${l10n.totalLabel}: ${Fmt.rupiah(share.total)}');
    }

    return lines.join('\n');
  }
}
