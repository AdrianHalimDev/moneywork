import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/display_preferences.dart';
import '../l10n/app_localizations.dart';

class AmountVisibilityButton extends ConsumerWidget {
  const AmountVisibilityButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(amountsHiddenProvider);
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const ValueKey('toggle-amount-visibility'),
      tooltip: hidden ? l10n.showBalances : l10n.hideBalances,
      onPressed: () => ref.read(amountsHiddenProvider.notifier).state = !hidden,
      icon: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
    );
  }
}
