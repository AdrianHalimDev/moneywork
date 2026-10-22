import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';

/// Display-only privacy for this app session. Never changes financial data.
final amountsHiddenProvider = StateProvider<bool>((_) => false);

String formatVisibleMoney(WidgetRef ref, double value,
    {bool signed = false, bool compact = false}) {
  if (ref.watch(amountsHiddenProvider)) return 'Rp ••••••';
  if (compact) return Fmt.rupiahCompact(value);
  return signed ? Fmt.rupiahSigned(value) : Fmt.rupiah(value);
}
