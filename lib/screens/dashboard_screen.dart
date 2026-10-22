import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../data/display_preferences.dart';
import '../firebase/auth.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../models/wishlist_item.dart';
import '../services/reminders.dart';
import '../services/report.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sync_indicator.dart';
import 'accounts_screen.dart';
import 'finance_tools_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

/// Beranda harian: saldo, arus kas bulan ini, lalu aktivitas terbaru.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(amountsHiddenProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Flexible(child: Text(l10n.appTitle, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          const SyncIndicator(),
        ]),
        actions: [
          IconButton(
            key: const ValueKey('toggle-dashboard-balances'),
            tooltip: hidden ? l10n.showBalances : l10n.hideBalances,
            onPressed: () =>
                ref.read(amountsHiddenProvider.notifier).state = !hidden,
            icon: Icon(hidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
          ),
          TextButton.icon(
            key: const ValueKey('dashboard-tools'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const FinanceToolsScreen())),
            icon: const Icon(Icons.grid_view_outlined, size: 18),
            label: Text(l10n.focusToolsShort),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.tooltipProfile,
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const FriendlyLoadError(),
        data: (state) => _DashboardBody(state: state),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(amountsHiddenProvider);
    final now = DateTime.now();
    final reminders = Reminders.build(
        transactions: state.transactions,
        wishlist: state.wishlist,
        now: now,
        l10n: l10n);
    final savingTargets =
        state.wishlist.where((w) => !w.purchased && w.hasSavingPlan).toList();
    final user = ref.watch(authStateProvider).valueOrNull;
    final greeting = user == null || user.isLocal
        ? l10n.welcomeBack
        : l10n.greeting(user.label.split(' ').first);
    // Historical entries belong in monthly reports even when their values are
    // already reflected in balances. Transfers are excluded; admin expense counts.
    final monthly = Report.forMonth(state.transactions, now);
    void record() => state.orderedAccounts.isEmpty
        ? showAccountDialog(context, ref)
        : showTransactionDialog(context, ref, state);

    return ResponsiveCenter(
        child: LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 760;
      return ListView(
        key: const ValueKey('dashboard-scroll'),
        padding:
            EdgeInsets.fromLTRB(desktop ? 28 : 16, 20, desktop ? 28 : 16, 32),
        children: [
          const SyncStatusBanner(),
          Text(greeting,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(Fmt.dateFull(now), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          if (desktop)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: 5,
                  child: _AccountBalanceCard(state: state, onRecord: record)),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _MonthlyCashFlow(summary: monthly)),
            ])
          else ...[
            _AccountBalanceCard(state: state, onRecord: record),
            const SizedBox(height: 14),
            _MonthlyCashFlow(summary: monthly),
          ],
          const SizedBox(height: 20),
          if (desktop)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: 7,
                  child: _RecentTransactions(
                      state: state,
                      desktop: constraints.maxWidth >= 1040 &&
                          MediaQuery.textScalerOf(context).scale(14) <= 20)),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _DashboardAccounts(state: state)),
            ])
          else ...[
            _RecentTransactions(state: state),
            const SizedBox(height: 14),
            _DashboardAccounts(state: state),
          ],
          const SizedBox(height: 20),
          _NetWorthOverview(state: state),
          if (!hidden && reminders.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (final reminder in reminders) ...[
              _ReminderBanner(reminder: reminder),
              const SizedBox(height: 8),
            ],
          ],
          if (savingTargets.isNotEmpty) ...[
            const SizedBox(height: 12),
            _WishlistTargets(items: savingTargets),
          ],
        ],
      );
    }));
  }
}

class _AccountBalanceCard extends ConsumerWidget {
  const _AccountBalanceCard({required this.state, required this.onRecord});
  final AppState state;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const foreground = AppTheme.heroForeground;
    return Card(
      key: const ValueKey('dashboard-cash-card'),
      color: AppTheme.heroBackground(context),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.focusAccountBalance,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: foreground.withValues(alpha: .85))),
          const SizedBox(height: 10),
          Text(formatVisibleMoney(ref, state.totalCash),
              key: const ValueKey('dashboard-cash-total'),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(l10n.focusAccountBalanceHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: foreground.withValues(alpha: .85))),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('dashboard-record'),
              style: FilledButton.styleFrom(
                  backgroundColor: foreground,
                  foregroundColor: AppTheme.heroBackground(context)),
              onPressed: onRecord,
              icon: const Icon(Icons.add),
              label: Text(l10n.fabRecordTransaction),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MonthlyCashFlow extends ConsumerWidget {
  const _MonthlyCashFlow({required this.summary});
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('dashboard-month-summary'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(l10n.focusThisMonth,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(Fmt.monthYear(summary.month),
                      style: theme.textTheme.bodySmall),
                ])),
            IconButton(
              tooltip: l10n.tooltipReport,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const ReportScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          _CashFlowLine(
              icon: Icons.south_west,
              label: l10n.summaryIncome,
              value: formatVisibleMoney(ref, summary.income),
              valueKey: const ValueKey('dashboard-month-income'),
              color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          _CashFlowLine(
              icon: Icons.north_east,
              label: l10n.summaryExpense,
              value: formatVisibleMoney(ref, summary.expense),
              valueKey: const ValueKey('dashboard-month-expense'),
              color: theme.colorScheme.error),
          const Divider(height: 28),
          _CashFlowLine(
              label: l10n.focusMonthNet,
              value: formatVisibleMoney(ref, summary.net, signed: true),
              valueKey: const ValueKey('dashboard-month-net')),
        ]),
      ),
    );
  }
}

class _CashFlowLine extends StatelessWidget {
  const _CashFlowLine(
      {required this.label,
      required this.value,
      this.valueKey,
      this.icon,
      this.color});
  final String label;
  final String value;
  final Key? valueKey;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 290 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final labelWidget = Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
        ],
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      ]);
      final valueWidget = Text(value,
          key: valueKey,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600));
      return stacked
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              labelWidget,
              const SizedBox(height: 4),
              valueWidget,
            ])
          : Row(children: [
              Expanded(child: labelWidget),
              const SizedBox(width: 12),
              valueWidget,
            ]);
    });
  }
}

class _NetWorthOverview extends ConsumerWidget {
  const _NetWorthOverview({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('dashboard-net-worth-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.netWorthTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(formatVisibleMoney(ref, state.netWorth),
              key: const ValueKey('dashboard-net-worth-total'),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(l10n.focusNetWorthHint, style: theme.textTheme.bodySmall),
          const Divider(height: 28),
          LayoutBuilder(builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
            final columns = largeText
                ? (constraints.maxWidth >= 700 ? 2 : 1)
                : (constraints.maxWidth >= 700 ? 4 : 2);
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(spacing: 16, runSpacing: 18, children: [
              for (final entry in [
                (l10n.totalAssetsTitle, state.totalAssets),
                (l10n.investmentTitle, state.totalInvestment),
                (l10n.receivableTitle, state.totalReceivable),
                (l10n.totalDebtTitle, state.totalDebt),
              ])
                SizedBox(
                    width: width,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.$1, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(formatVisibleMoney(ref, entry.$2),
                              style: theme.textTheme.titleSmall),
                        ])),
            ]);
          }),
        ]),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.state, this.desktop = false});
  final AppState state;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...state.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(5).toList();
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: _SectionHeading(title: l10n.recentTransactionsTitle),
        ),
        if (recent.isEmpty)
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.noTransactionsMessage,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
        else if (desktop)
          _RecentTable(state: state, transactions: recent)
        else
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _TxTile(tx: recent[i], state: state),
          ],
      ]),
    ));
  }
}

void _openAccounts(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.go('/akun');
    return;
  }
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const AccountsScreen()));
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final heading = Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600));
    final action = TextButton(
        onPressed: () => _openAccounts(context),
        child: Text(AppLocalizations.of(context)!.viewAll));
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 20) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          heading,
          const SizedBox(height: 4),
          action,
        ]);
      }
      return Row(children: [Expanded(child: heading), action]);
    });
  }
}

class _DashboardAccounts extends ConsumerWidget {
  const _DashboardAccounts({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeading(title: l10n.myAccounts),
        if (state.orderedAccounts.isEmpty)
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l10n.emptyAccountTitle,
                  style: Theme.of(context).textTheme.bodySmall)),
        for (final account in state.orderedAccounts.take(4))
          ListTile(
            key: ValueKey('dashboard-account-${account.id}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(account.type.icon,
                size: 22, color: Theme.of(context).colorScheme.primary),
            title: Text(account.name),
            subtitle: Text(formatVisibleMoney(ref, account.balance)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => showAccountDetails(context, account.id),
          ),
      ]),
    ));
  }
}

class _RecentTable extends ConsumerWidget {
  const _RecentTable({required this.state, required this.transactions});
  final AppState state;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
        width: double.infinity,
        child: DataTable(
          columnSpacing: 12,
          horizontalMargin: 4,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 88,
          columns: [
            DataColumn(label: Text(l10n.transactionHistory)),
            DataColumn(label: Text(l10n.accountLabel)),
            DataColumn(label: Text(l10n.amountLabel), numeric: true),
          ],
          rows: [
            for (final tx in transactions)
              DataRow(cells: [
                DataCell(SizedBox(
                    width: 130,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.note.isEmpty ? tx.type.label(l10n) : tx.note,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(Fmt.date(tx.date),
                              style: Theme.of(context).textTheme.bodySmall),
                        ]))),
                DataCell(SizedBox(
                    width: 65,
                    child: Text(_accountName(state, tx.accountId),
                        maxLines: 2, overflow: TextOverflow.ellipsis))),
                DataCell(Text(
                    formatVisibleMoney(ref, tx.signedAmount, signed: true),
                    style:
                        TextStyle(color: _transactionColor(context, tx.type)))),
              ]),
          ],
        ));
  }
}

String _accountName(AppState state, String id) =>
    state.orderedAccounts
        .where((a) => a.id == id)
        .map((a) => a.name)
        .firstOrNull ??
    '-';

Color _transactionColor(BuildContext context, TxType type) => switch (type) {
      TxType.income => Theme.of(context).colorScheme.primary,
      TxType.expense => Theme.of(context).colorScheme.error,
      TxType.transfer => Theme.of(context).colorScheme.tertiary,
    };

class _TxTile extends ConsumerWidget {
  const _TxTile({required this.tx, required this.state});
  final Transaction tx;
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _transactionColor(context, tx.type);
    final icon = switch (tx.type) {
      TxType.income => Icons.south_west,
      TxType.expense => Icons.north_east,
      TxType.transfer => Icons.swap_horiz,
    };
    final subtitle = tx.type == TxType.transfer
        ? '${_accountName(state, tx.accountId)} → ${_accountName(state, tx.toAccountId ?? '')}'
        : [
            if (tx.category.isNotEmpty) tx.category,
            _accountName(state, tx.accountId)
          ].join(' · ');
    // Put the amount below its description so narrow screens and large text fit.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: .12),
            foregroundColor: color,
            child: Icon(icon, size: 18)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.note.isEmpty
              ? tx.type.label(AppLocalizations.of(context)!)
              : tx.note),
          const SizedBox(height: 4),
          Text('$subtitle · ${Fmt.date(tx.date)}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(formatVisibleMoney(ref, tx.signedAmount, signed: true),
              key: ValueKey('dashboard-tx-${tx.id}-amount'),
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}

/// Pengingat tetap tersedia, setelah informasi keuangan harian.
class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (reminder.level) {
      ReminderLevel.warning => (
          AppTheme.debt,
          Icons.notifications_active_outlined
        ),
      ReminderLevel.success => (AppTheme.income, Icons.savings_outlined),
      ReminderLevel.info => (AppTheme.investment, Icons.info_outline),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reminder.title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(reminder.message, style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]),
    );
  }
}

class _WishlistTargets extends ConsumerWidget {
  const _WishlistTargets({required this.items});
  final List<WishlistItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hidden = ref.watch(amountsHiddenProvider);
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(AppLocalizations.of(context)!.savingTargetTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 14),
        for (final item in items) ...[
          Text(item.name),
          const SizedBox(height: 4),
          Text(
              '${formatVisibleMoney(ref, item.savedAmount, compact: true)} / ${formatVisibleMoney(ref, item.price, compact: true)}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          if (!hidden)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: item.savingProgress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: AppTheme.income),
            ),
          const SizedBox(height: 16),
        ],
      ]),
    ));
  }
}
