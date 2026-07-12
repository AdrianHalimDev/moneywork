import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_controller.dart';
import '../../data/app_state.dart';
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
    if (state == null || state.accounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Tambahkan rekening dulu di tab Akun.'),
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
            Text('Terima dari ${widget.group.displayName}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                'Sisa total: ${Fmt.rupiah(widget.group.outstanding)}'
                '${widget.group.openCount > 1 ? ' · ${widget.group.openCount} pinjaman' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 6),
            Text(
                'Pembayaran melunasi pinjaman paling lama dulu.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration: const InputDecoration(
                  labelText: 'Jumlah diterima', prefixText: 'Rp '),
              validator: (v) {
                final n = Fmt.tryParseInput(v ?? '');
                if (n == null || n <= 0) return 'Masukkan jumlah valid';
                if (n > widget.group.outstanding) {
                  return 'Melebihi sisa total (${Fmt.rupiah(widget.group.outstanding)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: const InputDecoration(labelText: 'Masuk ke'),
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
                child: const Text('Terima Sekarang'),
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
          SnackBar(content: Text('Diterima ${Fmt.rupiah(amount)}.')));
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
            Text(isEdit ? 'Edit Piutang' : 'Tambah Piutang',
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
                  decoration: const InputDecoration(
                      labelText: 'Nama orang', hintText: 'mis. Gama'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
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
              decoration: const InputDecoration(
                  labelText: 'Jumlah piutang', prefixText: 'Rp '),
              validator: (v) {
                final n = Fmt.tryParseInput(v ?? '');
                if (n == null || n < 0) return 'Angka tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'mis. Makan di resto X'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Jatuh tempo (opsional)',
                  suffixIcon: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _dueDate = null),
                        )
                      : const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(_dueDate != null
                    ? Fmt.dateFull(_dueDate!)
                    : 'Pilih tanggal'),
              ),
            ),
            if (!isEdit && accounts.isNotEmpty) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                value: _fundFromAccount,
                onChanged: (v) => setState(() => _fundFromAccount = v),
                title: const Text('Saya menalangi sekarang'),
                subtitle: const Text('Uang keluar dari rekening saya'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (_fundFromAccount)
                DropdownButtonFormField<String>(
                  value: _fundingAccountId,
                  decoration: const InputDecoration(labelText: 'Dari rekening'),
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
                    label: const Text('Hapus',
                        style: TextStyle(color: AppTheme.expense)),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _submit,
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
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
