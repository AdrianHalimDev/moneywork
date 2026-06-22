import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../widgets/common.dart';

/// Layar Monthly Expenses: kelola template transaksi rutin bulanan dan
/// jalankan semuanya sekali klik (mis. saat gajian).
class MonthlyExpensesScreen extends ConsumerWidget {
  const MonthlyExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Bulanan'),
        actions: [
          async.maybeWhen(
            data: (state) => state.accounts.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Tambah template',
                    onPressed: () => showRecurringDialog(context, ref, state),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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

  String _accountName(String id) {
    final m = state.accounts.where((a) => a.id == id);
    return m.isEmpty ? '-' : m.first.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.accounts.isEmpty) {
      return const EmptyState(
        icon: Icons.event_repeat_outlined,
        title: 'Tambahkan rekening dulu',
        subtitle: 'Transaksi bulanan butuh rekening sebagai sumber/tujuan.',
      );
    }
    if (state.recurring.isEmpty) {
      return const EmptyState(
        icon: Icons.event_repeat_outlined,
        title: 'Belum ada transaksi bulanan',
        subtitle: 'Susun biaya rutin (langganan, tagihan, tabungan), lalu\n'
            'jalankan semua sekaligus tiap bulan.',
      );
    }

    final enabled = state.recurring.where((r) => r.enabled).toList();
    final totalExpense = enabled
        .where((r) => r.type == TxType.expense)
        .fold<double>(0, (s, r) => s + r.amount);
    final totalIncome = enabled
        .where((r) => r.type == TxType.income)
        .fold<double>(0, (s, r) => s + r.amount);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 180),
            children: [
              for (final r in state.recurring)
                _RecurringTile(
                  recurring: r,
                  accountName: _accountName(r.accountId),
                  toAccountName:
                      r.toAccountId == null ? null : _accountName(r.toAccountId!),
                ),
            ],
          ),
        ),
        _RunBar(
          enabledCount: enabled.length,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        ),
      ],
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  const _RecurringTile({
    required this.recurring,
    required this.accountName,
    this.toAccountName,
  });
  final RecurringTransaction recurring;
  final String accountName;
  final String? toAccountName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = switch (recurring.type) {
      TxType.income => (Icons.south_west, AppTheme.income),
      TxType.expense => (Icons.north_east, AppTheme.expense),
      TxType.transfer => (Icons.swap_horiz, AppTheme.investment),
    };
    final sub = recurring.type == TxType.transfer
        ? '$accountName → ${toAccountName ?? '-'}'
        : [
            if (recurring.category.isNotEmpty) recurring.category,
            accountName,
          ].join(' · ');

    return ListTile(
      leading: IconBadge(icon: icon, color: color),
      title: Text(recurring.label),
      subtitle: Text(sub),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Fmt.rupiah(recurring.amount),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  decoration:
                      recurring.enabled ? null : TextDecoration.lineThrough)),
          Switch(
            value: recurring.enabled,
            onChanged: (_) => ref
                .read(appStateProvider.notifier)
                .toggleRecurringEnabled(recurring.id),
          ),
        ],
      ),
      onTap: () {
        final state = ref.read(appStateProvider).valueOrNull;
        if (state != null) {
          showRecurringDialog(context, ref, state, existing: recurring);
        }
      },
    );
  }
}

/// Bilah bawah berisi ringkasan & tombol jalankan semua.
class _RunBar extends ConsumerWidget {
  const _RunBar({
    required this.enabledCount,
    required this.totalIncome,
    required this.totalExpense,
  });
  final int enabledCount;
  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (totalIncome > 0)
                Text('Masuk ${Fmt.rupiahCompact(totalIncome)}',
                    style: const TextStyle(color: AppTheme.income)),
              Text('Keluar ${Fmt.rupiahCompact(totalExpense)}',
                  style: const TextStyle(color: AppTheme.expense)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabledCount == 0
                  ? null
                  : () => _confirmRun(context, ref, enabledCount),
              icon: const Icon(Icons.playlist_add_check),
              label: Text('Jalankan Semua ($enabledCount)'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRun(
      BuildContext context, WidgetRef ref, int count) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jalankan transaksi bulanan?'),
        content: Text(
            '$count transaksi aktif akan dibuat dengan tanggal hari ini. '
            'Saldo rekening akan diperbarui.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Jalankan')),
        ],
      ),
    );
    if (ok != true) return;

    final result = await ref.read(appStateProvider.notifier).runAllRecurring();
    final msg = result.skipped > 0
        ? '${result.created} transaksi dibuat, ${result.skipped} dilewati (saldo kurang).'
        : '${result.created} transaksi bulanan berhasil dijalankan.';
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ============================================================================
// Dialog: tambah/edit template
// ============================================================================

Future<void> showRecurringDialog(
  BuildContext context,
  WidgetRef ref,
  AppState state, {
  RecurringTransaction? existing,
}) async {
  final labelCtrl = TextEditingController(text: existing?.label ?? '');
  final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '');
  final categoryCtrl = TextEditingController(text: existing?.category ?? '');
  var type = existing?.type ?? TxType.expense;
  var accountId = existing?.accountId ?? state.accounts.first.id;
  String? toAccountId = existing?.toAccountId ??
      (state.accounts.length > 1 ? state.accounts[1].id : null);
  final isEdit = existing != null;
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Template' : 'Tambah Template',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: labelCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                    labelText: 'Nama',
                    hintText: 'mis. Netflix, Listrik, Nabung'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<TxType>(
                segments: const [
                  ButtonSegment(value: TxType.expense, label: Text('Keluar')),
                  ButtonSegment(value: TxType.income, label: Text('Masuk')),
                  ButtonSegment(value: TxType.transfer, label: Text('Transfer')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Masukkan jumlah valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: accountId,
                decoration: InputDecoration(
                    labelText: type == TxType.transfer ? 'Dari akun' : 'Akun'),
                items: [
                  for (final a in state.accounts)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => accountId = v ?? accountId),
              ),
              if (type == TxType.transfer) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toAccountId,
                  decoration: const InputDecoration(labelText: 'Ke akun'),
                  items: [
                    for (final a in state.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => toAccountId = v),
                  validator: (v) {
                    if (type != TxType.transfer) return null;
                    if (v == null) return 'Pilih akun tujuan';
                    if (v == accountId) return 'Pilih akun berbeda';
                    return null;
                  },
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'mis. Langganan, Tagihan'),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (isEdit)
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(appStateProvider.notifier)
                            .deleteRecurring(existing.id);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.expense),
                      label: const Text('Hapus',
                          style: TextStyle(color: AppTheme.expense)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final amount = double.parse(amountCtrl.text.trim());
                      final ctrl = ref.read(appStateProvider.notifier);
                      final isTransfer = type == TxType.transfer;
                      if (isEdit) {
                        ctrl.updateRecurring(existing.copyWith(
                          label: labelCtrl.text.trim(),
                          type: type,
                          amount: amount,
                          accountId: accountId,
                          toAccountId: isTransfer ? toAccountId : null,
                          category: isTransfer ? '' : categoryCtrl.text.trim(),
                        ));
                      } else {
                        ctrl.addRecurring(
                          label: labelCtrl.text.trim(),
                          type: type,
                          amount: amount,
                          accountId: accountId,
                          toAccountId: isTransfer ? toAccountId : null,
                          category: isTransfer ? '' : categoryCtrl.text.trim(),
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: Text(isEdit ? 'Simpan' : 'Tambah'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
