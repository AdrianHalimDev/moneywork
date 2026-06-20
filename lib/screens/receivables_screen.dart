import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/receivable.dart';
import '../widgets/common.dart';
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

    return ListView(
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
                  Text('${state.receivables.where((r) => r.remaining > 0).length} orang',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            ),
          ),
        ),
        for (final r in state.receivables) _ReceivableTile(receivable: r),
      ],
    );
  }
}

class _ReceivableTile extends ConsumerWidget {
  const _ReceivableTile({required this.receivable});
  final Receivable receivable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = receivable.dueDate;
    final parts = <String>[
      if (receivable.note.isNotEmpty) receivable.note,
      if (due != null) 'Tempo ${Fmt.date(due)}',
    ];
    final lunas = receivable.remaining <= 0;
    return ListTile(
      leading: IconBadge(icon: receivable.icon, color: AppTheme.income),
      title: Text(receivable.personName),
      subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(lunas ? 'Lunas' : Fmt.rupiah(receivable.remaining),
              style: TextStyle(
                  color: lunas
                      ? Theme.of(context).colorScheme.outline
                      : AppTheme.income,
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
                onPressed: () =>
                    showCollectDialog(context, ref, receivable),
                child: const Text('Terima'),
              ),
            ),
        ],
      ),
      onTap: () => showReceivableDialog(context, ref, existing: receivable),
    );
  }
}

// ============================================================================
// Dialog: terima pembayaran piutang
// ============================================================================

Future<void> showCollectDialog(
  BuildContext context,
  WidgetRef ref,
  Receivable receivable,
) async {
  final state = ref.read(appStateProvider).valueOrNull;
  if (state == null) return;

  if (state.accounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tambahkan rekening dulu di tab Akun.')));
    return;
  }

  final amountCtrl =
      TextEditingController(text: receivable.remaining.toStringAsFixed(0));
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
              Text('Terima dari ${receivable.personName}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Sisa piutang: ${Fmt.rupiah(receivable.remaining)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Jumlah diterima', prefixText: 'Rp '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Masukkan jumlah valid';
                  if (n > receivable.remaining) {
                    return 'Melebihi sisa piutang (${Fmt.rupiah(receivable.remaining)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: accountId,
                decoration: const InputDecoration(labelText: 'Masuk ke'),
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
                    final error = await ref
                        .read(appStateProvider.notifier)
                        .collectReceivable(
                          receivableId: receivable.id,
                          accountId: accountId,
                          amount: amount,
                        );
                    if (error != null) {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    navigator.pop();
                    messenger.showSnackBar(SnackBar(
                        content:
                            Text('Diterima ${Fmt.rupiah(amount)}.')));
                  },
                  child: const Text('Terima Sekarang'),
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
// Dialog: tambah/edit piutang
// ============================================================================

Future<void> showReceivableDialog(
  BuildContext context,
  WidgetRef ref, {
  Receivable? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.personName ?? '');
  final amountCtrl = TextEditingController(
      text: existing != null ? existing.remaining.toStringAsFixed(0) : '');
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  DateTime? dueDate = existing?.dueDate;
  final isEdit = existing != null;
  final formKey = GlobalKey<FormState>();

  // Opsi talangan: uang keluar dari rekening saat membuat piutang (mode tambah).
  final accounts = ref.read(appStateProvider).valueOrNull?.accounts ?? const [];
  var fundFromAccount = false;
  String? fundingAccountId = accounts.isNotEmpty ? accounts.first.id : null;

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
              Text(isEdit ? 'Edit Piutang' : 'Tambah Piutang',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                    labelText: 'Nama orang', hintText: 'mis. Gama'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Jumlah piutang', prefixText: 'Rp '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    hintText: 'mis. Makan di resto X'),
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
              if (!isEdit && accounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  value: fundFromAccount,
                  onChanged: (v) => setState(() => fundFromAccount = v),
                  title: const Text('Saya menalangi sekarang'),
                  subtitle: const Text('Uang keluar dari rekening saya'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (fundFromAccount)
                  DropdownButtonFormField<String>(
                    value: fundingAccountId,
                    decoration: const InputDecoration(labelText: 'Dari rekening'),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(
                            value: a.id,
                            child:
                                Text('${a.name} · ${Fmt.rupiah(a.balance)}')),
                    ],
                    onChanged: (v) =>
                        setState(() => fundingAccountId = v ?? fundingAccountId),
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
                            .deleteReceivable(existing.id);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.expense),
                      label: const Text('Hapus',
                          style: TextStyle(color: AppTheme.expense)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final amount = double.parse(amountCtrl.text.trim());
                      final ctrl = ref.read(appStateProvider.notifier);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      if (isEdit) {
                        ctrl.updateReceivable(existing.copyWith(
                          personName: nameCtrl.text.trim(),
                          remaining: amount,
                          note: noteCtrl.text.trim(),
                          dueDate: dueDate,
                          clearDueDate: dueDate == null,
                        ));
                        navigator.pop();
                      } else {
                        final error = await ctrl.addReceivable(
                          personName: nameCtrl.text.trim(),
                          remaining: amount,
                          note: noteCtrl.text.trim(),
                          dueDate: dueDate,
                          fundingAccountId:
                              fundFromAccount ? fundingAccountId : null,
                        );
                        if (error != null) {
                          messenger
                              .showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }
                        navigator.pop();
                      }
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
