import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/transaction.dart';
import '../models/wishlist_item.dart';
import '../services/reminders.dart';
import '../widgets/responsive_layout.dart';
import 'profile_screen.dart';
import 'cash_flow_forecast_screen.dart';
import 'report_screen.dart';
import 'wishlist_screen.dart';

/// Beranda: ringkasan kekayaan bersih, komposisi aset, dan transaksi terbaru.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.of(context)!.appTitle),
          const SizedBox(width: 6),
          const _SyncIcon(),
        ]),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: AppLocalizations.of(context)!.tooltipForecast,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CashFlowForecastScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: AppLocalizations.of(context)!.tooltipWishlist,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: AppLocalizations.of(context)!.tooltipReport,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: AppLocalizations.of(context)!.tooltipProfile,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.errorLoadData}: $e')),
        data: (state) => _DashboardBody(state: state),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final reminders = Reminders.build(
      transactions: state.transactions,
      wishlist: state.wishlist,
      now: DateTime.now(),
      l10n: AppLocalizations.of(context)!,
    );
    final savingTargets = state.wishlist
        .where((w) => !w.purchased && w.hasSavingPlan)
        .toList();

    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SyncBanner(),
          for (final r in reminders) ...[
            _ReminderBanner(reminder: r),
            const SizedBox(height: 8),
          ],
          _NetWorthCard(state: state),
          const SizedBox(height: 16),
          _BreakdownRow(state: state),
          if (savingTargets.isNotEmpty) ...[
            const SizedBox(height: 8),
            _WishlistTargets(items: savingTargets),
          ],
          const SizedBox(height: 8),
          _RecentTransactions(state: state),
        ],
      ),
    );
  }
}

class _SyncBanner extends ConsumerWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    if (status.phase == SyncPhase.synced) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, label) = switch (status.phase) {
      SyncPhase.loading =>
        (Icons.cloud_sync_outlined, scheme.outline, l10n.syncStatusLoading),
      SyncPhase.synced =>
        (Icons.cloud_done_outlined, scheme.primary, l10n.syncStatusSynced),
      SyncPhase.pending =>
        (Icons.cloud_upload_outlined, scheme.tertiary,
          status.message == 'cache' ? l10n.syncCache : l10n.syncStatusPending),
      SyncPhase.error =>
        (Icons.cloud_off_outlined, scheme.error, l10n.syncStatusError),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
      color: status.phase == SyncPhase.error ? scheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              if (status.phase == SyncPhase.error && status.message != null)
                Text(status.message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          )),
          if (status.phase == SyncPhase.error) ...[
            TextButton(
              onPressed: () => ref.read(appStateProvider.notifier).retrySync(),
              child: Text(l10n.syncRetry),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.syncLoadCloud,
              onSelected: (_) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.syncDiscardTitle),
                    content: Text(l10n.syncDiscardBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(l10n.syncCancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(l10n.syncContinue),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await ref.read(appStateProvider.notifier)
                      .discardPendingAndReload();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'reload', child: Text(l10n.syncLoadCloud)),
              ],
            ),
          ],
        ]),
      ),
      ),
    );
  }
}

class _SyncIcon extends ConsumerWidget {
  const _SyncIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(syncStatusProvider).phase;
    final l10n = AppLocalizations.of(context)!;
    final (icon, label) = switch (phase) {
      SyncPhase.loading => (Icons.cloud_sync_outlined, l10n.syncStatusLoading),
      SyncPhase.synced => (Icons.cloud_done_outlined, l10n.syncStatusSynced),
      SyncPhase.pending => (Icons.cloud_upload_outlined, l10n.syncStatusPending),
      SyncPhase.error => (Icons.cloud_off_outlined, l10n.syncStatusError),
    };
    return Tooltip(
      message: label,
      child: Icon(icon, size: 18, color: phase == SyncPhase.error
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary),
    );
  }
}

/// Banner pengingat dalam-app (muncul saat aplikasi dibuka).
class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (reminder.level) {
      ReminderLevel.warning => (
          AppTheme.debt.withValues(alpha: 0.12),
          AppTheme.debt,
          Icons.notifications_active_outlined
        ),
      ReminderLevel.success => (
          AppTheme.income.withValues(alpha: 0.12),
          AppTheme.income,
          Icons.savings_outlined
        ),
      ReminderLevel.info => (
          AppTheme.investment.withValues(alpha: 0.12),
          AppTheme.investment,
          Icons.info_outline
        ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(reminder.message,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan target wishlist yang sedang ditabung.
class _WishlistTargets extends StatelessWidget {
  const _WishlistTargets({required this.items});
  final List<WishlistItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.savingTargetTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            for (final w in items) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(w.name)),
                  Text(
                      '${Fmt.rupiahCompact(w.savedAmount)} / ${Fmt.rupiahCompact(w.price)}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: w.savingProgress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: AppTheme.income,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kartu utama kekayaan bersih.
class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.netWorthTitle,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 6),
            Text(
              Fmt.rupiah(state.netWorth),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(
                  label: AppLocalizations.of(context)!.totalAssetsTitle,
                  value: Fmt.rupiah(state.totalAssets),
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 24),
                _MiniStat(
                  label: AppLocalizations.of(context)!.totalDebtTitle,
                  value: Fmt.rupiah(state.totalDebt),
                  color: scheme.onPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: color.withValues(alpha: 0.85))),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Kartu ringkas kas, investasi, piutang, utang — disusun grid 2 kolom.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _BreakdownCard(
        icon: Icons.account_balance_wallet,
        label: AppLocalizations.of(context)!.cashTitle,
        value: state.totalCash,
        color: AppTheme.income,
      ),
      _BreakdownCard(
        icon: Icons.show_chart,
        label: AppLocalizations.of(context)!.investmentTitle,
        value: state.totalInvestment,
        color: AppTheme.investment,
      ),
      if (state.totalReceivable > 0)
        _BreakdownCard(
          icon: Icons.handshake,
          label: AppLocalizations.of(context)!.receivableTitle,
          value: state.totalReceivable,
          color: AppTheme.income,
        ),
      _BreakdownCard(
        icon: Icons.credit_card,
        label: AppLocalizations.of(context)!.debtTitle,
        value: state.totalDebt,
        color: AppTheme.debt,
      ),
    ];

    // Susun 2 kolom per baris. IntrinsicHeight memberi baris tinggi terbatas
    // (setinggi kartu tertinggi) sehingga stretch bisa menyamakan tinggi kedua
    // kartu — tanpa ini, stretch di dalam ListView memicu error "infinite
    // height" dan seluruh blok tak tampil. Slot kosong dipakai bila jumlah
    // kartu ganjil agar lebarnya tetap separuh.
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
            ),
          ],
        ),
      ));
    }

    return Column(children: rows);
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Fmt.rupiah(value),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daftar 5 transaksi terbaru.
class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = state.transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(AppLocalizations.of(context)!.recentTransactionsTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (recent.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(AppLocalizations.of(context)!.noTransactionsMessage,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _TxTile(tx: recent[i], state: state),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx, required this.state});
  final Transaction tx;
  final AppState state;

  String _accountName(String id) {
    final match = state.accounts.where((a) => a.id == id);
    return match.isEmpty ? '-' : match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tx.type) {
      TxType.income => (Icons.south_west, AppTheme.income),
      TxType.expense => (Icons.north_east, AppTheme.expense),
      TxType.transfer => (Icons.swap_horiz, AppTheme.investment),
    };

    final subtitle = tx.type == TxType.transfer
        ? '${_accountName(tx.accountId)} → ${_accountName(tx.toAccountId ?? '')}'
        : [
            if (tx.category.isNotEmpty) tx.category,
            _accountName(tx.accountId),
          ].join(' · ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
        child: Icon(icon, size: 18),
      ),
      title: Text(tx.note.isEmpty ? tx.type.label(AppLocalizations.of(context)!) : tx.note),
      subtitle: Text('$subtitle · ${Fmt.date(tx.date)}'),
      trailing: Text(
        Fmt.rupiahSigned(tx.signedAmount),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
