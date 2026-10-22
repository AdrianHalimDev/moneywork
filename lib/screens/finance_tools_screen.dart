import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_controller.dart';
import '../data/display_preferences.dart';
import '../l10n/app_localizations.dart';
import '../widgets/finance_actions.dart';
import '../widgets/responsive_layout.dart';
import 'bill_splitter_screen.dart';
import 'cash_flow_forecast_screen.dart';
import 'monthly_expenses_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'wishlist_screen.dart';

class FinanceToolsScreen extends ConsumerWidget {
  const FinanceToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(appStateProvider).valueOrNull;
    void open(Widget page) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    final tools = <(IconData, String, VoidCallback?)>[
      (
        Icons.document_scanner_outlined,
        l10n.scanReceiptAction,
        () => showReceiptScanOptions(context)
      ),
      (
        Icons.picture_as_pdf_outlined,
        l10n.importStatementAction,
        state == null ? null : () => importBankStatement(context, ref, state)
      ),
      (
        Icons.group_outlined,
        l10n.tooltipSplitBill,
        () => open(const BillSplitterScreen())
      ),
      (
        Icons.bar_chart_outlined,
        l10n.tooltipReport,
        () => open(const ReportScreen())
      ),
      (
        Icons.calendar_month_outlined,
        l10n.forecastTitle,
        () => open(const CashFlowForecastScreen())
      ),
      (
        Icons.favorite_outline,
        l10n.tooltipWishlist,
        () => open(const WishlistScreen())
      ),
      (
        Icons.event_repeat_outlined,
        l10n.tooltipMonthlyExpenses,
        () => open(const MonthlyExpensesScreen())
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.financeTools)),
      body: ResponsiveCenter(
          child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800
                ? 3
                : constraints.maxWidth >= 540
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final tool in tools)
                SizedBox(
                    width: width,
                    child: Card(
                        child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      leading: Icon(tool.$1,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(tool.$2),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: tool.$3,
                    ))),
            ]);
          }),
          const SizedBox(height: 24),
          Text(l10n.focusAppearance,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                          'focus-theme-${state?.themeMode ?? 'system'}'),
                      initialValue: state?.themeMode ?? 'system',
                      decoration:
                          InputDecoration(labelText: l10n.focusAppearance),
                      items: [
                        DropdownMenuItem(
                            value: 'system', child: Text(l10n.themeSystem)),
                        DropdownMenuItem(
                            value: 'light', child: Text(l10n.themeLight)),
                        DropdownMenuItem(
                            value: 'dark', child: Text(l10n.themeDark)),
                      ],
                      onChanged: state == null
                          ? null
                          : (value) async {
                              if (value == null) return;
                              try {
                                await ref
                                    .read(appStateProvider.notifier)
                                    .setThemeMode(value);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(l10n.focusSyncFailed)));
                                }
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.hideBalances),
                      value: ref.watch(amountsHiddenProvider),
                      onChanged: (value) => ref
                          .read(amountsHiddenProvider.notifier)
                          .state = value,
                    ),
                  ]))),
          const SizedBox(height: 12),
          Card(
              child: ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.profileTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const ProfileScreen()),
          )),
        ],
      )),
    );
  }
}
