import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/transaction.dart';
import '../models/wishlist_item.dart';
import '../services/reminders.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

/// Beranda: ringkasan kekayaan bersih, komposisi aset, dan transaksi terbaru.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyWork'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Laporan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil & Pengaturan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
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
    );
    final savingTargets = state.wishlist
        .where((w) => !w.purchased && w.hasSavingPlan)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
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
                Text('Target Tabungan',
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
              'Kekayaan Bersih',
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
                  label: 'Total Aset',
                  value: Fmt.rupiah(state.totalAssets),
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 24),
                _MiniStat(
                  label: 'Total Utang',
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

/// Tiga kartu ringkas: kas, investasi, utang.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final hasReceivable = state.totalReceivable > 0;
    return Row(
      children: [
        Expanded(
          child: _BreakdownCard(
            icon: Icons.account_balance_wallet,
            label: 'Kas',
            value: state.totalCash,
            color: AppTheme.income,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BreakdownCard(
            icon: Icons.show_chart,
            label: 'Investasi',
            value: state.totalInvestment,
            color: AppTheme.investment,
          ),
        ),
        if (hasReceivable) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _BreakdownCard(
              icon: Icons.handshake,
              label: 'Piutang',
              value: state.totalReceivable,
              color: AppTheme.income,
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: _BreakdownCard(
            icon: Icons.credit_card,
            label: 'Utang',
            value: state.totalDebt,
            color: AppTheme.debt,
          ),
        ),
      ],
    );
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
          child: Text('Transaksi Terbaru',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (recent.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('Belum ada transaksi.',
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
      title: Text(tx.note.isEmpty ? tx.type.label : tx.note),
      subtitle: Text('$subtitle · ${Fmt.date(tx.date)}'),
      trailing: Text(
        Fmt.rupiahSigned(tx.signedAmount),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
