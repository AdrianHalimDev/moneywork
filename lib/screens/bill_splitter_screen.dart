import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../services/bill_splitter.dart';
import 'receipt_assign_screen.dart';

/// Kalkulator split bill: bagi tagihan makan bareng + PPN + service + diskon,
/// lalu simpan bagian tiap orang ke Piutang.
class BillSplitterScreen extends ConsumerStatefulWidget {
  const BillSplitterScreen({
    super.key,
    this.initialSharedItems,
    this.initialPeople,
    this.initialPpn,
    this.initialService,
  });

  /// Item bersama dari hasil OCR bon (opsional, mode lama).
  final List<BillItem>? initialSharedItems;

  /// Orang-orang beserta item masing-masing dari layar Assign (opsional).
  final List<PersonAssignment>? initialPeople;

  /// Pajak dari bon (nominal Rupiah, bukan persen). Opsional.
  final double? initialPpn;

  /// Service charge dari bon (nominal Rupiah, bukan persen). Opsional.
  final double? initialService;

  @override
  ConsumerState<BillSplitterScreen> createState() => _BillSplitterScreenState();
}

class _BillSplitterScreenState extends ConsumerState<BillSplitterScreen> {
  // Data mutable; tiap orang punya daftar item sendiri.
  final List<_PersonEntry> _people = [];
  final List<BillItem> _shared = [];

  late final TextEditingController _ppnCtrl;
  late final TextEditingController _serviceCtrl;
  final _discountCtrl = TextEditingController(text: '0');

  // Diskon dibagi rata ke tiap orang (true) atau proporsional ke pesanan.
  bool _splitDiscountEvenly = true;

  @override
  void initState() {
    super.initState();

    // Hitung subtotal untuk konversi nominal → persentase
    double subtotal = 0;

    // Mode baru: initialPeople (dari layar Assign)
    if (widget.initialPeople != null) {
      for (final p in widget.initialPeople!) {
        final entry = _PersonEntry(
            nameCtrl: TextEditingController(text: p.name));
        entry.items = List.of(p.items);
        _people.add(entry);
        subtotal += p.items.fold<double>(0, (s, i) => s + i.total);
      }
    }
    // Shared items (bisa ada bersama initialPeople maupun berdiri sendiri)
    if (widget.initialSharedItems != null) {
      _shared.addAll(widget.initialSharedItems!);
      subtotal += widget.initialSharedItems!
          .fold<double>(0, (s, i) => s + i.total);
    }

    // PPN
    if (widget.initialPpn != null && subtotal > 0) {
      final ppnPct = widget.initialPpn! / subtotal * 100;
      _ppnCtrl = TextEditingController(text: ppnPct.toStringAsFixed(1));
    } else {
      _ppnCtrl = TextEditingController(text: '11');
    }

    // Service
    if (widget.initialService != null && subtotal > 0) {
      final scPct = widget.initialService! / subtotal * 100;
      _serviceCtrl = TextEditingController(text: scPct.toStringAsFixed(1));
    } else {
      _serviceCtrl = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _ppnCtrl.dispose();
    _serviceCtrl.dispose();
    _discountCtrl.dispose();
    for (final p in _people) {
      p.nameCtrl.dispose();
    }
    super.dispose();
  }

  double get _ppnRate => (double.tryParse(_ppnCtrl.text.trim()) ?? 0) / 100;
  double get _serviceRate =>
      (double.tryParse(_serviceCtrl.text.trim()) ?? 0) / 100;
  double get _discount => Fmt.tryParseInput(_discountCtrl.text) ?? 0;

  BillResult _compute() {
    return BillSplitter.calculate(
      people: [
        for (final p in _people)
          BillPerson(name: p.nameCtrl.text.trim(), items: p.items),
      ],
      sharedItems: _shared,
      discount: _discount,
      serviceRate: _serviceRate,
      ppnRate: _ppnRate,
      splitDiscountEvenly: _splitDiscountEvenly,
    );
  }

  void _addPerson() {
    setState(() => _people.add(_PersonEntry(
        nameCtrl: TextEditingController(text: AppLocalizations.of(context)!.personLabel((_people.length + 1).toString())))));
  }

  Future<void> _addItem({_PersonEntry? person}) async {
    final item = await _showItemDialog();
    if (item == null) return;
    setState(() {
      if (person != null) {
        person.items = [...person.items, item];
      } else {
        _shared.add(item);
      }
    });
  }

  Future<BillItem?> _showItemDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    return showDialog<BillItem>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
        title: Text(l10n.addBillItem),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: l10n.menuNameLabel, hintText: l10n.menuNameHint),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration:
                    InputDecoration(labelText: l10n.priceLabel, prefixText: 'Rp '),
                validator: (v) {
                  final n = Fmt.tryParseInput(v ?? '');
                  if (n == null || n <= 0) return l10n.invalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.qtyLabel),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton)),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                BillItem(
                  name: nameCtrl.text.trim(),
                  price: Fmt.tryParseInput(priceCtrl.text)!,
                  qty: int.tryParse(qtyCtrl.text.trim()) ?? 1,
                ),
              );
            },
            child: Text(l10n.addButton),
          ),
        ],
      );
      },
    );
  }

  Future<void> _saveToReceivables(BillResult result) async {
    // Nama yang ditandai sebagai diri sendiri (owner) tidak dipiutangkan.
    final ownerNames = _people
        .where((p) => p.isOwner)
        .map((p) => p.nameCtrl.text.trim())
        .toSet();

    // Tagihan orang lain: punya nama, > 0, dan bukan owner.
    final valid = result.shares
        .where((s) =>
            s.name.isNotEmpty && s.total > 0 && !ownerNames.contains(s.name))
        .toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.noOtherBillsToSave)));
      return;
    }

    // Total bagian kita sendiri (akan jadi pengeluaran bila ada sumber dana).
    final ownerShare = result.shares
        .where((s) => ownerNames.contains(s.name))
        .fold<double>(0, (sum, s) => sum + s.total);
    final friendsTotal = valid.fold<double>(0, (sum, s) => sum + s.total);

    final accounts =
        ref.read(appStateProvider).valueOrNull?.accounts ?? const [];
    // Default: potong dari rekening pertama bila ada.
    String? fundingId = accounts.isNotEmpty ? accounts.first.id : null;

    final selected = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          final deduct = fundingId != null
              ? friendsTotal + ownerShare
              : friendsTotal;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.saveSplitBillTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.friendBillsLabel,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                for (final s in valid)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.name),
                        Text(Fmt.rupiah(s.total),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (ownerShare > 0) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.myShareLabel),
                      Text(Fmt.rupiah(ownerShare)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (accounts.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    value: fundingId,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fundFromAccountLabel),
                    items: [
                      DropdownMenuItem(
                          value: null,
                          child: Text(AppLocalizations.of(context)!.doNotDeductBalance)),
                      for (final a in accounts)
                        DropdownMenuItem(
                            value: a.id,
                            child:
                                Text('${a.name} · ${Fmt.rupiah(a.balance)}')),
                    ],
                    onChanged: (v) => setSheet(() => fundingId = v),
                  ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fundingId != null
                          ? AppLocalizations.of(context)!.totalOutFromAccount
                          : AppLocalizations.of(context)!.totalReceivableRecorded),
                      Text(Fmt.rupiah(deduct),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.expense)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(AppLocalizations.of(context)!.saveButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (selected != true || !mounted) return;

    final ctrl = ref.read(appStateProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (fundingId != null) {
      // Talangi dari rekening: teman jadi piutang+talangan, bagian sendiri
      // jadi pengeluaran. Atomik.
      final error = await ctrl.splitBillPayment(
        fundingAccountId: fundingId!,
        shares: [for (final s in valid) (name: s.name, amount: s.total)],
        ownerShare: ownerShare,
      );
      if (error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(
          AppLocalizations.of(context)!.receivableSavedDeducted(valid.length.toString(), Fmt.rupiah(friendsTotal + ownerShare)))));
    } else {
      // Tanpa sumber dana: catat piutang teman saja (saldo tidak berubah).
      for (final s in valid) {
        await ctrl.addReceivable(
          personName: s.name,
          remaining: s.total,
          note: '${AppLocalizations.of(context)!.splitBillNotePrefix} ${Fmt.date(DateTime.now())}',
        );
      }
      messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.receivableSavedOnly(valid.length.toString()))));
    }
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final result = _compute();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.tabSplitBill)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPerson,
        icon: const Icon(Icons.person_add_alt),
        label: Text(AppLocalizations.of(context)!.personLabelOnly),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (_people.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 40, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                        AppLocalizations.of(context)!.splitBillEmptyState,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          for (final p in _people) _personCard(p),
          _sharedCard(),
          const SizedBox(height: 8),
          _ratesCard(),
          const SizedBox(height: 8),
          _resultCard(result),
        ],
      ),
    );
  }

  Widget _personCard(_PersonEntry p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: p.nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nama', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
                  tooltip: AppLocalizations.of(context)!.deletePersonTooltip,
                  onPressed: () => setState(() => _people.remove(p)),
                ),
              ],
            ),
            // Tandai diri sendiri: bagiannya tidak masuk piutang.
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(AppLocalizations.of(context)!.meNotBilledLabel),
                selected: p.isOwner,
                onSelected: (v) => setState(() {
                  // Hanya satu owner.
                  for (final other in _people) {
                    other.isOwner = false;
                  }
                  p.isOwner = v;
                }),
                visualDensity: VisualDensity.compact,
              ),
            ),
            for (final item in p.items)
              _itemRow(item, () => setState(() => p.items = [...p.items]..remove(item))),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addItem(person: p),
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context)!.itemLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sharedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.sharedItemsLabel,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            for (final item in _shared)
              _itemRow(item, () => setState(() => _shared.remove(item))),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addItem(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context)!.addSharedItemLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(BillItem item, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
                item.qty > 1 ? '${item.name} ×${item.qty}' : item.name),
          ),
          Text(Fmt.rupiah(item.total)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _ratesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.taxAndDiscountLabel,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ppnCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.ppnLabel, suffixText: '%', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _serviceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.serviceChargeLabel, suffixText: '%', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.discountLabel, prefixText: 'Rp ', isDense: true),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)!.splitDiscountEvenlyLabel),
              subtitle: Text(_splitDiscountEvenly
                  ? AppLocalizations.of(context)!.discountEvenlyDesc
                  : AppLocalizations.of(context)!.discountProportionalDesc),
              value: _splitDiscountEvenly,
              onChanged: (v) => setState(() => _splitDiscountEvenly = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(BillResult result) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.detailsLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _summaryRow(AppLocalizations.of(context)!.subtotalLabel, result.subtotal),
            if (result.serviceAmount > 0)
              _summaryRow(AppLocalizations.of(context)!.serviceChargeLabel, result.serviceAmount),
            if (result.taxAmount > 0) _summaryRow(AppLocalizations.of(context)!.ppnLabel, result.taxAmount),
            if (result.discount > 0)
              _summaryRow(AppLocalizations.of(context)!.discountLabel, -result.discount),
            const Divider(),
            _summaryRow(AppLocalizations.of(context)!.totalLabel, result.grandTotal, bold: true),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.billPerPersonLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final s in result.shares)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.name.isEmpty ? AppLocalizations.of(context)!.unnamedLabel : s.name),
                    Text(Fmt.rupiah(s.total),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: result.grandTotal > 0
                    ? () => _saveToReceivables(result)
                    : null,
                icon: const Icon(Icons.save_alt),
                label: Text(AppLocalizations.of(context)!.saveToReceivablesBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(Fmt.rupiah(value), style: style),
        ],
      ),
    );
  }
}

/// State mutable per orang di layar (controller nama + daftar item).
/// [isOwner] menandai diri sendiri — bagiannya tidak dicatat sebagai piutang.
class _PersonEntry {
  _PersonEntry({required this.nameCtrl});
  final TextEditingController nameCtrl;
  List<BillItem> items = [];
  bool isOwner = false;
}
