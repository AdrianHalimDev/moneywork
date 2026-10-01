import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/debt.dart';
import '../widgets/common.dart';
import '../widgets/dialogs/debt_dialogs.dart';
import '../widgets/responsive_layout.dart';

/// Layar Utang: pinjaman, kartu kredit, cicilan beserta jatuh tempo.
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key, this.hideAppBar = false});
  final bool hideAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: hideAppBar ? null : AppBar(title: Text(AppLocalizations.of(context)!.tabDebts)),
      floatingActionButton: hideAppBar ? null : FloatingActionButton.extended(
        onPressed: () => showDebtDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.fabDebt),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.errorLoadFailed}: $e')),
        data: (state) => _Body(state: state),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.debts.isEmpty) {
      return EmptyState(
        icon: Icons.credit_card_outlined,
        title: AppLocalizations.of(context)!.emptyDebtTitle,
        subtitle: AppLocalizations.of(context)!.emptyDebtSubtitle,
      );
    }

    final totalMonthly =
        state.debts.fold<double>(0, (s, d) => s + d.monthlyPayment);

    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: AppTheme.debt.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.totalDebtLabel,
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(Fmt.rupiah(state.totalDebt),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: AppTheme.debt,
                                      fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (totalMonthly > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppLocalizations.of(context)!.monthlyInstallment,
                              style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(Fmt.rupiah(totalMonthly),
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          for (final debt in state.debts.where((d) => d.remaining > 0))
            _DebtTile(debt: debt),
          if (state.debts.any((d) => d.remaining <= 0)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                AppLocalizations.of(context)!.paidOff,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            for (final debt in state.debts.where((d) => d.remaining <= 0))
              _DebtTile(debt: debt),
          ],
        ],
      ),
    );
  }
}

class _DebtTile extends ConsumerWidget {
  const _DebtTile({required this.debt});
  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = debt.dueDate;
    final parts = <String>[
      debt.type.label(AppLocalizations.of(context)!),
      if (debt.monthlyPayment > 0) '${Fmt.rupiah(debt.monthlyPayment)}${AppLocalizations.of(context)!.perMonthSuffix}',
      if (due != null) '${AppLocalizations.of(context)!.duePrefix} ${Fmt.date(due)}',
    ];
    final lunas = debt.remaining <= 0;
    return ListTile(
      leading: IconBadge(icon: debt.type.icon, color: AppTheme.debt),
      title: Text(debt.name),
      subtitle: Text(parts.join(' · ')),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(lunas ? AppLocalizations.of(context)!.paidOff : Fmt.rupiah(debt.remaining),
              style: TextStyle(
                  color: lunas ? AppTheme.income : AppTheme.debt,
                  fontWeight: FontWeight.w600)),
          if (!lunas)
            SizedBox(
              height: 28,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => showPayDebtDialog(context, ref, debt),
                child: Text(AppLocalizations.of(context)!.payButton),
              ),
            ),
        ],
      ),
      onTap: () => showDebtDialog(context, ref, existing: debt),
    );
  }
}
