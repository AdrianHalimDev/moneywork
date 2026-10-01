import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_controller.dart';
import '../../models/debt.dart';

Future<void> showPayDebtDialog(
  BuildContext context,
  WidgetRef ref,
  Debt debt,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _PayDebtSheet(debt: debt),
  );
}

class _PayDebtSheet extends ConsumerStatefulWidget {
  const _PayDebtSheet({required this.debt});
  final Debt debt;

  @override
  ConsumerState<_PayDebtSheet> createState() => _PayDebtSheetState();
}

class _PayDebtSheetState extends ConsumerState<_PayDebtSheet> {
  late final TextEditingController _amountCtrl;
  String? _accountId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    final defaultAmount = d.monthlyPayment > 0 && d.monthlyPayment <= d.remaining
        ? d.monthlyPayment
        : d.remaining;
    _amountCtrl = TextEditingController(text: defaultAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    if (state == null || state.accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.addAccountFirst),
      );
    }
    
    _accountId ??= state.accounts.first.id;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.payDebtTitle(widget.debt.name),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.debtRemainingLabel(Fmt.rupiah(widget.debt.remaining)),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final source =
                  state.accounts.firstWhere((a) => a.id == _accountId);
              return TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.payAmountLabel,
                  prefixText: 'Rp ',
                  helperText: l10n.balanceHelper(source.name, Fmt.rupiah(source.balance)),
                ),
                validator: (v) {
                  final n = Fmt.tryParseInput(v ?? '');
                  if (n == null || n <= 0) return l10n.invalidNumber;
                  if (n > widget.debt.remaining) {
                    return l10n.exceedsDebtRemaining(Fmt.rupiah(widget.debt.remaining));
                  }
                  if (n > source.balance) {
                    return l10n.exceedsBalance(Fmt.rupiah(source.balance));
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: InputDecoration(labelText: l10n.payFromLabel),
              items: [
                for (final a in state.accounts)
                  DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} · ${Fmt.rupiah(a.balance)}')),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(l10n.payNowBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = Fmt.tryParseInput(_amountCtrl.text)!;
    final error = await ref.read(appStateProvider.notifier).payDebt(
          debtId: widget.debt.id,
          accountId: _accountId!,
          amount: amount,
        );
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.paymentRecorded(Fmt.rupiah(amount)))));
    }
  }
}

// ============================================================================
// Dialog: tambah/edit utang
// ============================================================================

Future<void> showDebtDialog(
  BuildContext context,
  WidgetRef ref, {
  Debt? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _DebtDialogSheet(existing: existing),
  );
}

class _DebtDialogSheet extends ConsumerStatefulWidget {
  const _DebtDialogSheet({this.existing});
  final Debt? existing;

  @override
  ConsumerState<_DebtDialogSheet> createState() => _DebtDialogSheetState();
}

class _DebtDialogSheetState extends ConsumerState<_DebtDialogSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _remainingCtrl;
  late final TextEditingController _monthlyCtrl;
  late DebtType _type;
  DateTime? _dueDate;
  final _formKey = GlobalKey<FormState>();

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _remainingCtrl = TextEditingController(
        text: d != null ? Fmt.groupInput(d.remaining) : '');
    _monthlyCtrl = TextEditingController(
        text: d != null && d.monthlyPayment > 0
            ? Fmt.groupInput(d.monthlyPayment)
            : '');
    _type = d?.type ?? DebtType.loan;
    _dueDate = d?.dueDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _remainingCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? l10n.editDebtTitle : l10n.addDebtTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              autofocus: !isEdit,
              decoration: InputDecoration(
                  labelText: l10n.nameLabel, hintText: l10n.debtNameHint),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DebtType>(
              value: _type,
              decoration: InputDecoration(labelText: l10n.typeLabel),
              items: [
                for (final t in DebtType.values)
                  DropdownMenuItem(
                      value: t,
                      child: Row(children: [
                        Icon(t.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(t.label(AppLocalizations.of(context)!)),
                      ])),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remainingCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration: InputDecoration(
                  labelText: l10n.debtRemainingInputLabel, prefixText: 'Rp '),
              validator: (v) {
                final n = Fmt.tryParseInput(v ?? '');
                if (n == null || n < 0) return l10n.invalidNumber;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _monthlyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration: InputDecoration(
                  labelText: l10n.monthlyPaymentOptional,
                  prefixText: 'Rp '),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dueDateOptional,
                  suffixIcon: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _dueDate = null),
                        )
                      : const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(_dueDate != null
                    ? Fmt.dateFull(_dueDate!)
                    : l10n.selectDateBtn),
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
                          .deleteDebt(widget.existing!.id);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.expense),
                    label: Text(l10n.deleteLabel,
                        style: const TextStyle(color: AppTheme.expense)),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _submit,
                  child: Text(isEdit ? l10n.saveButton : l10n.addButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final remaining = Fmt.tryParseInput(_remainingCtrl.text)!;
    final monthly = Fmt.tryParseInput(_monthlyCtrl.text) ?? 0;
    final ctrl = ref.read(appStateProvider.notifier);
    
    if (isEdit) {
      ctrl.updateDebt(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        type: _type,
        remaining: remaining,
        monthlyPayment: monthly,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      ));
    } else {
      ctrl.addDebt(
        name: _nameCtrl.text.trim(),
        type: _type,
        remaining: remaining,
        monthlyPayment: monthly,
        dueDate: _dueDate,
      );
    }
    Navigator.pop(context);
  }
}
