import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/receivable.dart';
import '../widgets/common.dart';
import '../widgets/dialogs/receivable_dialogs.dart';
import '../widgets/responsive_layout.dart';
import 'bill_splitter_screen.dart';

/// Layar Piutang: uang yang dipinjam orang lain ke kita.
class ReceivablesScreen extends ConsumerWidget {
  const ReceivablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piutang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Split Bill',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BillSplitterScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showReceivableDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Piutang'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
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
    if (state.receivables.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'Belum ada piutang',
        subtitle: 'Catat uang yang dipinjam teman/orang lain ke kamu.\n'
            'Bisa juga dari kalkulator split bill.',
      );
    }

    final groups = ReceivableGroup.groupByName(state.receivables);
    final openGroups = groups.where((g) => !g.isSettled).length;

    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: AppTheme.income.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Piutang',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(Fmt.rupiah(state.totalReceivable),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: AppTheme.income,
                                      fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Text('$openGroups orang',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
            ),
          ),
          for (final g in groups.where((g) => !g.isSettled))
            _GroupTile(group: g),
          if (groups.any((g) => g.isSettled)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Lunas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            for (final g in groups.where((g) => g.isSettled))
              _GroupTile(group: g),
          ],
        ],
      ),
    );
  }
}

/// Kartu satu orang: total sisa + jumlah pinjaman, dapat di-expand untuk
/// melihat rincian tiap pinjaman dan menerima pembayaran gabungan.
class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.group});
  final ReceivableGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lunas = group.isSettled;
    final due = group.nearestDue;
    final subtitleParts = <String>[
      if (group.openCount > 1) '${group.openCount} pinjaman',
      if (due != null) 'Tempo ${Fmt.date(due)}',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        // Pakai key agar status expand tahan terhadap rebuild list.
        key: PageStorageKey('rcv-${group.key}'),
        leading: IconBadge(icon: Icons.person_outline, color: AppTheme.income),
        title: Text(group.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(lunas ? 'Lunas' : Fmt.rupiah(group.outstanding),
                style: TextStyle(
                    color: lunas
                        ? Theme.of(context).colorScheme.outline
                        : AppTheme.income,
                    fontWeight: FontWeight.w600)),
            Text(lunas ? 'selesai' : 'sisa',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final r in group.items) _LoanRow(receivable: r),
          const SizedBox(height: 8),
          if (!lunas)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    showCollectFromPersonDialog(context, ref, group),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text('Terima dari ${group.displayName}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Satu baris pinjaman di dalam grup orang.
class _LoanRow extends ConsumerWidget {
  const _LoanRow({required this.receivable});
  final Receivable receivable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lunas = receivable.remaining <= 0;
    final due = receivable.dueDate;
    final parts = <String>[
      Fmt.date(receivable.createdAt),
      if (receivable.note.isNotEmpty) receivable.note,
      if (due != null) 'tempo ${Fmt.date(due)}',
    ];
    return InkWell(
      onTap: () => showReceivableDialog(context, ref, existing: receivable),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(parts.join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(lunas ? 'Lunas' : Fmt.rupiah(receivable.remaining),
                style: TextStyle(
                    color: lunas
                        ? Theme.of(context).colorScheme.outline
                        : AppTheme.income,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
