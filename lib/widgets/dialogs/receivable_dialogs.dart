import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_controller.dart';
import '../../models/receivable.dart';

// ============================================================================
// Dialog: terima pembayaran gabungan dari satu orang (alokasi FIFO)
// ============================================================================

Future<void> showCollectFromPersonDialog(
  BuildContext context,
  WidgetRef ref,
  ReceivableGroup group,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CollectFromPersonSheet(group: group),
  );
}

class _CollectFromPersonSheet extends ConsumerStatefulWidget {
  const _CollectFromPersonSheet({required this.group});
  final ReceivableGroup group;

  @override
  ConsumerState<_CollectFromPersonSheet> createState() =>
      _CollectFromPersonSheetState();
}

class _CollectFromPersonSheetState extends ConsumerState<_CollectFromPersonSheet> {
  late final TextEditingController _amountCtrl;
  String? _accountId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: Fmt.groupInput(widget.group.outstanding));
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
            Text(l10n.collectFromTitle(widget.group.displayName),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                '${l10n.totalOutstanding(Fmt.rupiah(widget.group.outstanding))}'
                '${widget.group.openCount > 1 ? ' · ${l10n.loanCount(widget.group.openCount)}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 6),
            Text(
                l10n.fifoPaymentNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration: InputDecoration(
                  labelText: l10n.amountReceivedLabel, prefixText: 'Rp '),
              validator: (v) {
                final n = Fmt.tryParseInput(v ?? '');
                if (n == null || n <= 0) return l10n.invalidNumber;
                if (n > widget.group.outstanding) {
                  return l10n.exceedsTotalOutstanding(Fmt.rupiah(widget.group.outstanding));
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: InputDecoration(labelText: l10n.receiveIntoLabel),
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
                child: Text(l10n.receiveNowBtn),
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
    final error = await ref.read(appStateProvider.notifier).collectFromPerson(
          nameKey: widget.group.key,
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
          SnackBar(content: Text(AppLocalizations.of(context)!.receivedAmount(Fmt.rupiah(amount)))));
    }
  }
}

// ============================================================================
// Dialog: tambah/edit piutang
// ============================================================================

Future<void> showReceivableDialog(
  BuildContext context,
  WidgetRef ref, {
  Receivable? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ReceivableDialogSheet(existing: existing),
  );
}

class _ReceivableDialogSheet extends ConsumerStatefulWidget {
  const _ReceivableDialogSheet({this.existing});
  final Receivable? existing;

  @override
  ConsumerState<_ReceivableDialogSheet> createState() =>
      _ReceivableDialogSheetState();
}

class _ReceivableDialogSheetState extends ConsumerState<_ReceivableDialogSheet> {
  late final TextEditingController _nameCtrl;
  final _nameFocus = FocusNode();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  DateTime? _dueDate;
  final _formKey = GlobalKey<FormState>();

  bool _fundFromAccount = false;
  String? _fundingAccountId;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.personName ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? Fmt.groupInput(e.remaining) : '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _dueDate = e?.dueDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(appStateProvider).valueOrNull;
    final accounts = state?.accounts ?? const [];
    final knownNames = <String>{
      for (final r in (state?.receivables ?? const []))
        if (r.personName.trim().isNotEmpty) r.personName.trim(),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
    if (accounts.isNotEmpty) {
      _fundingAccountId ??= accounts.first.id;
    }

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
            Text(isEdit ? l10n.editReceivableTitle : l10n.addReceivableTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            RawAutocomplete<String>(
              textEditingController: _nameCtrl,
              focusNode: _nameFocus,
              optionsBuilder: (value) {
                final q = value.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<String>.empty();
                return knownNames.where((n) {
                  final low = n.toLowerCase();
                  return low.contains(q) && low != q;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: !isEdit,
                  decoration: InputDecoration(
                      labelText: l10n.personNameLabel, hintText: l10n.personNameHint),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final list = options.toList();
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, i) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_outline, size: 18),
                          title: Text(list[i]),
                          onTap: () => onSelected(list[i]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration: InputDecoration(
                  labelText: l10n.receivableAmountLabel, prefixText: 'Rp '),
              validator: (v) {
                final n = Fmt.tryParseInput(v ?? '');
                if (n == null || n < 0) return l10n.invalidNumber;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                  labelText: l10n.noteOptional,
                  hintText: l10n.noteReceivableHint),
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
            if (!isEdit && accounts.isNotEmpty) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                value: _fundFromAccount,
                onChanged: (v) => setState(() => _fundFromAccount = v),
                title: Text(l10n.fundNowTitle),
                subtitle: Text(l10n.fundNowSubtitle),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (_fundFromAccount)
                DropdownButtonFormField<String>(
                  value: _fundingAccountId,
                  decoration: InputDecoration(labelText: l10n.fromAccountLabel),
                  items: [
                    for (final a in accounts)
                      DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} · ${Fmt.rupiah(a.balance)}')),
                  ],
                  onChanged: (v) => setState(() => _fundingAccountId = v),
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
                          .deleteReceivable(widget.existing!.id);
                    },
                    icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = Fmt.tryParseInput(_amountCtrl.text)!;
    final ctrl = ref.read(appStateProvider.notifier);
    
    if (isEdit) {
      ctrl.updateReceivable(widget.existing!.copyWith(
        personName: _nameCtrl.text.trim(),
        remaining: amount,
        note: _noteCtrl.text.trim(),
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      ));
      if (mounted) Navigator.pop(context);
    } else {
      final error = await ctrl.addReceivable(
        personName: _nameCtrl.text.trim(),
        remaining: amount,
        note: _noteCtrl.text.trim(),
        dueDate: _dueDate,
        fundingAccountId: _fundFromAccount ? _fundingAccountId : null,
      );
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }
      if (mounted) Navigator.pop(context);
    }
  }
}
