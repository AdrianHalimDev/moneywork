import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.tabMonthlyTx),
        actions: [
          async.maybeWhen(
            data: (state) => state.accounts.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: AppLocalizations.of(context)!.tooltipAddTemplate,
                    onPressed: () => showRecurringDialog(context, ref, state),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.snackFailed} $e')),
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
      return EmptyState(
        icon: Icons.event_repeat_outlined,
        title: AppLocalizations.of(context)!.emptyAccountTitle,
        subtitle: AppLocalizations.of(context)!.emptyAccountSubtitle,
      );
    }
    if (state.recurring.isEmpty) {
      return EmptyState(
        icon: Icons.event_repeat_outlined,
        title: AppLocalizations.of(context)!.emptyMonthlyTitle,
        subtitle: AppLocalizations.of(context)!.emptyMonthlySubtitle,
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
                Text(AppLocalizations.of(context)!.runBarIncome(Fmt.rupiahCompact(totalIncome)),
                    style: const TextStyle(color: AppTheme.income)),
              Text(AppLocalizations.of(context)!.runBarExpense(Fmt.rupiahCompact(totalExpense)),
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
              label: Text(AppLocalizations.of(context)!.runAllBtn(enabledCount.toString())),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRun(
      BuildContext context, WidgetRef ref, int count) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmRunTitle),
        content: Text(l10n.confirmRunContent(count.toString())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.confirmRunOk)),
        ],
      ),
    );
    if (ok != true) return;

    final result = await ref.read(appStateProvider.notifier).runAllRecurring();
    final msg = result.skipped > 0
        ? l10n.runSuccessWithSkip(result.created.toString(), result.skipped.toString())
        : l10n.runSuccessAll(result.created.toString());
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
      text: existing != null ? Fmt.groupInput(existing.amount) : '');
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
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return StatefulBuilder(
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
              Text(isEdit ? l10n.editTemplate : l10n.addTemplate,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: labelCtrl,
                autofocus: !isEdit,
                decoration: InputDecoration(
                    labelText: l10n.itemNameLabel,
                    hintText: l10n.templateNameHint),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<TxType>(
                segments: [
                  ButtonSegment(value: TxType.expense, label: Text(l10n.segmentExpense)),
                  ButtonSegment(value: TxType.income, label: Text(l10n.segmentIncome)),
                  ButtonSegment(value: TxType.transfer, label: Text(l10n.segmentTransfer)),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration:
                    InputDecoration(labelText: l10n.amountLabel, prefixText: 'Rp '),
                validator: (v) {
                  final n = Fmt.tryParseInput(v ?? '');
                  if (n == null || n <= 0) return l10n.invalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: accountId,
                decoration: InputDecoration(
                    labelText: type == TxType.transfer ? l10n.fromAccountLabel : l10n.accountLabel),
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
                  decoration: InputDecoration(labelText: l10n.toAccountLabel),
                  items: [
                    for (final a in state.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => toAccountId = v),
                  validator: (v) {
                    if (type != TxType.transfer) return null;
                    if (v == null) return l10n.errorSelectAccount;
                    if (v == accountId) return l10n.errorSameAccount;
                    return null;
                  },
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(
                      labelText: l10n.categoryLabel,
                      hintText: l10n.templateCategoryHint),
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
                      label: Text(l10n.deleteLabel,
                          style: const TextStyle(color: AppTheme.expense)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final amount = Fmt.tryParseInput(amountCtrl.text)!;
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
                    child: Text(isEdit ? l10n.saveButton : l10n.addButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      );
    },
  );
}
