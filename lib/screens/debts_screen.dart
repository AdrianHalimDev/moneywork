import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/debt.dart';
import '../widgets/common.dart';

/// Layar Utang: pinjaman, kartu kredit, cicilan beserta jatuh tempo.
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Utang & Cicilan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDebtDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Utang'),
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
    if (state.debts.isEmpty) {
      return const EmptyState(
        icon: Icons.credit_card_outlined,
        title: 'Tidak ada utang',
        subtitle: 'Bagus! Kalau ada pinjaman, kartu kredit, atau cicilan,\n'
            'catat di sini untuk hitung kekayaan bersih.',
      );
    }

    final totalMonthly =
        state.debts.fold<double>(0, (s, d) => s + d.monthlyPayment);

    return ListView(
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
                        Text('Total Utang',
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
                        Text('Cicilan/bln',
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
        for (final debt in state.debts) _DebtTile(debt: debt),
      ],
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
      debt.type.label,
      if (debt.monthlyPayment > 0) '${Fmt.rupiah(debt.monthlyPayment)}/bln',
      if (due != null) 'Tempo ${Fmt.date(due)}',
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
          Text(lunas ? 'Lunas' : Fmt.rupiah(debt.remaining),
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
                child: const Text('Bayar'),
              ),
            ),
        ],
      ),
      onTap: () => showDebtDialog(context, ref, existing: debt),
    );
  }
}

// ============================================================================
// Dialog: bayar utang dari rekening
// ============================================================================

Future<void> showPayDebtDialog(
  BuildContext context,
  WidgetRef ref,
  Debt debt,
) async {
  final state = ref.read(appStateProvider).valueOrNull;
  if (state == null) return;

  if (state.accounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tambahkan rekening dulu di tab Akun.')));
    return;
  }

  // Default: bayar sebesar cicilan bulanan bila ada, jika tidak full sisa.
  final defaultAmount =
      debt.monthlyPayment > 0 && debt.monthlyPayment <= debt.remaining
          ? debt.monthlyPayment
          : debt.remaining;
  final amountCtrl =
      TextEditingController(text: defaultAmount.toStringAsFixed(0));
  var accountId = state.accounts.first.id;
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
              Text('Bayar ${debt.name}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Sisa utang: ${Fmt.rupiah(debt.remaining)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final source = state.accounts
                    .firstWhere((a) => a.id == accountId);
                return TextFormField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah bayar',
                    prefixText: 'Rp ',
                    helperText:
                        'Saldo ${source.name}: ${Fmt.rupiah(source.balance)}',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return 'Masukkan jumlah valid';
                    if (n > debt.remaining) {
                      return 'Melebihi sisa utang (${Fmt.rupiah(debt.remaining)})';
                    }
                    if (n > source.balance) {
                      return 'Melebihi saldo (${Fmt.rupiah(source.balance)})';
                    }
                    return null;
                  },
                );
              }),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: accountId,
                decoration: const InputDecoration(labelText: 'Bayar dari'),
                items: [
                  for (final a in state.accounts)
                    DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.name} · ${Fmt.rupiah(a.balance)}')),
                ],
                onChanged: (v) => setState(() => accountId = v ?? accountId),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = double.parse(amountCtrl.text.trim());
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final error =
                        await ref.read(appStateProvider.notifier).payDebt(
                              debtId: debt.id,
                              accountId: accountId,
                              amount: amount,
                            );
                    if (error != null) {
                      messenger
                          .showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    navigator.pop();
                    messenger.showSnackBar(SnackBar(
                        content: Text(
                            'Pembayaran ${Fmt.rupiah(amount)} tercatat.')));
                  },
                  child: const Text('Bayar Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ============================================================================
// Dialog: tambah/edit utang
// ============================================================================

Future<void> showDebtDialog(
  BuildContext context,
  WidgetRef ref, {
  Debt? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final remainingCtrl = TextEditingController(
      text: existing != null ? existing.remaining.toStringAsFixed(0) : '');
  final monthlyCtrl = TextEditingController(
      text: existing != null && existing.monthlyPayment > 0
          ? existing.monthlyPayment.toStringAsFixed(0)
          : '');
  var type = existing?.type ?? DebtType.loan;
  DateTime? dueDate = existing?.dueDate;
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
              Text(isEdit ? 'Edit Utang' : 'Tambah Utang',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                    labelText: 'Nama', hintText: 'mis. KPR BTN, Kartu Kredit'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DebtType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Jenis'),
                items: [
                  for (final t in DebtType.values)
                    DropdownMenuItem(
                        value: t,
                        child: Row(children: [
                          Icon(t.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ])),
                ],
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: remainingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Sisa utang', prefixText: 'Rp '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: monthlyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cicilan per bulan (opsional)',
                    prefixText: 'Rp '),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime(2015),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Jatuh tempo (opsional)',
                    suffixIcon: dueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => dueDate = null),
                          )
                        : const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(dueDate != null
                      ? Fmt.dateFull(dueDate!)
                      : 'Pilih tanggal'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (isEdit)
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(appStateProvider.notifier)
                            .deleteDebt(existing.id);
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
                      final remaining =
                          double.parse(remainingCtrl.text.trim());
                      final monthly =
                          double.tryParse(monthlyCtrl.text.trim()) ?? 0;
                      final ctrl = ref.read(appStateProvider.notifier);
                      if (isEdit) {
                        ctrl.updateDebt(existing.copyWith(
                          name: nameCtrl.text.trim(),
                          type: type,
                          remaining: remaining,
                          monthlyPayment: monthly,
                          dueDate: dueDate,
                          clearDueDate: dueDate == null,
                        ));
                      } else {
                        ctrl.addDebt(
                          name: nameCtrl.text.trim(),
                          type: type,
                          remaining: remaining,
                          monthlyPayment: monthly,
                          dueDate: dueDate,
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
