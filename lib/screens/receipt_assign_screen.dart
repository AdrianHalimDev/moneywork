import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';

import '../core/formatters.dart';
import '../services/bill_splitter.dart';
import 'bill_splitter_screen.dart';

/// Data hasil assign: nama orang + daftar item yang dia pesan.
class PersonAssignment {
  PersonAssignment({required this.name, required this.items});
  final String name;
  final List<BillItem> items;
}

/// Layar perantara antara Review Bon dan Bill Splitter.
///
/// Alur:
/// 1. Input jumlah orang yang ikut bayar.
/// 2. Input nama tiap orang.
/// 3. Untuk setiap orang, pilih berapa qty item yang dia pesan.
/// 4. Sisa qty item yang belum di-assign otomatis masuk ke Item Bersama.
/// 5. Tekan "Hitung" → buka BillSplitterScreen dengan data presisi 100%.
class ReceiptAssignScreen extends StatefulWidget {
  const ReceiptAssignScreen({
    super.key,
    required this.items,
    required this.tax,
    required this.serviceCharge,
    this.discount = 0,
    this.additionalFees = 0,
  });

  /// Item dari hasil scan bon (sudah dikonversi ke BillItem, qty = qty di bon, price = unit price).
  final List<BillItem> items;

  /// Pajak nominal dari bon.
  final double tax;

  /// Service charge nominal dari bon.
  final double serviceCharge;

  /// Diskon nominal dari bon.
  final double discount;
  final double additionalFees;

  @override
  State<ReceiptAssignScreen> createState() => _ReceiptAssignScreenState();
}

class _ReceiptAssignScreenState extends State<ReceiptAssignScreen> {
  int _step = 0; // 0 = jumlah orang, 1 = nama, 2 = assign items
  int _personCount = 2;
  final List<TextEditingController> _nameControllers = [];

  // Peta kuantitas per orang per item: _assignedQty[personIndex][itemIndex] = qtySelected
  final List<Map<int, int>> _assignedQty = [];

  // Orang yang sedang di-assign (index ke berapa di step 2).
  int _currentPerson = 0;

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initNames() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    _nameControllers.clear();
    _assignedQty.clear();
    for (var i = 0; i < _personCount; i++) {
      _nameControllers.add(TextEditingController());
      _assignedQty.add(<int, int>{});
    }
  }

  void _goToNameStep() {
    _initNames();
    setState(() => _step = 1);
  }

  void _goToAssignStep() {
    // Validasi nama tidak kosong
    for (var i = 0; i < _nameControllers.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        _nameControllers[i].text = 'Person ${i + 1}';
      }
    }
    _currentPerson = 0;
    setState(() => _step = 2);
  }

  void _nextPerson() {
    if (_currentPerson < _personCount - 1) {
      setState(() => _currentPerson++);
    }
  }

  void _prevPerson() {
    if (_currentPerson > 0) {
      setState(() => _currentPerson--);
    }
  }

  /// Total qty yang sudah di-assign ke SEMUA orang untuk item ke-i
  int _totalAssignedQty(int itemIdx) {
    var sum = 0;
    for (var p = 0; p < _personCount; p++) {
      sum += _assignedQty[p][itemIdx] ?? 0;
    }
    return sum;
  }

  /// Sisa qty item ke-i yang belum di-assign ke siapapun
  int _unassignedQty(int itemIdx) {
    final receiptQty = widget.items[itemIdx].qty;
    return (receiptQty - _totalAssignedQty(itemIdx)).clamp(0, receiptQty);
  }

  void _finish() {
    // 1. Buat initialPeople dari hasil assign
    final people = <PersonAssignment>[];
    for (var p = 0; p < _personCount; p++) {
      final personItems = <BillItem>[];
      for (var i = 0; i < widget.items.length; i++) {
        final qty = _assignedQty[p][i] ?? 0;
        if (qty > 0) {
          personItems.add(BillItem(
            name: widget.items[i].name,
            price: widget.items[i].price, // Unit price!
            qty: qty,
          ));
        }
      }
      people.add(PersonAssignment(
        name: _nameControllers[p].text.trim(),
        items: personItems,
      ));
    }

    // 2. Buat initialSharedItems dari sisa item yang belum di-assign
    final unassignedSharedItems = <BillItem>[];
    for (var i = 0; i < widget.items.length; i++) {
      final unassigned = _unassignedQty(i);
      if (unassigned > 0) {
        unassignedSharedItems.add(BillItem(
          name: widget.items[i].name,
          price: widget.items[i].price, // Unit price!
          qty: unassigned,
        ));
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BillSplitterScreen(
          initialPeople: people,
          initialSharedItems:
              unassignedSharedItems.isNotEmpty ? unassignedSharedItems : null,
          initialPpn: widget.tax,
          initialService: widget.serviceCharge,
          initialDiscount: widget.discount,
          initialAdditionalFees: widget.additionalFees,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assignItemsTitle),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_step == 2 && _currentPerson > 0) {
                    _prevPerson();
                  } else {
                    setState(() => _step = (_step - 1).clamp(0, 2));
                  }
                },
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_step) {
          0 => _buildCountStep(l10n, theme),
          1 => _buildNameStep(l10n, theme),
          _ => _buildAssignStep(l10n, theme),
        },
      ),
    );
  }

  // === Step 0: Berapa orang? ===
  Widget _buildCountStep(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      key: const ValueKey('count'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(l10n.howManyPeople,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _personCount > 2
                    ? () => setState(() => _personCount--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 24),
              Text('$_personCount',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              IconButton.filled(
                onPressed: () => setState(() => _personCount++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: _goToNameStep,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.nextStep),
          ),
        ],
      ),
    );
  }

  // === Step 1: Nama tiap orang ===
  Widget _buildNameStep(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      key: const ValueKey('names'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.enterNames, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _personCount,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => TextField(
                controller: _nameControllers[i],
                decoration: InputDecoration(
                  labelText: l10n.personNumber(i + 1),
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _goToAssignStep,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.nextStep),
          ),
        ],
      ),
    );
  }

  // === Step 2: Assign items per orang ===
  Widget _buildAssignStep(AppLocalizations l10n, ThemeData theme) {
    final name = _nameControllers[_currentPerson].text.trim();

    return Column(
      key: ValueKey('assign_$_currentPerson'),
      children: [
        // Progress indicator (orang ke-berapa)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              for (var i = 0; i < _personCount; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _currentPerson
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < _personCount - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.selectItemsFor(name),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_currentPerson + 1} / $_personCount',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final currentQty = _assignedQty[_currentPerson][i] ?? 0;
              final remainingQty = _unassignedQty(i);

              // Cek siapa saja yang sudah mengambil item ini beserta kuantitasnya
              final assignedBreakdown = <String>[];
              for (var p = 0; p < _personCount; p++) {
                if (p != _currentPerson) {
                  final q = _assignedQty[p][i] ?? 0;
                  if (q > 0) {
                    assignedBreakdown
                        .add('${_nameControllers[p].text.trim()} (${q}x)');
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Info Item
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Struk: ${item.qty}x @ ${Fmt.rupiah(item.price)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (assignedBreakdown.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Dipilih: ${assignedBreakdown.join(", ")}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (remainingQty > 0 && item.qty > 1) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Sisa belum dibagi: ${remainingQty}x',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Counter Selector Qty [ - ]  qty  [ + ]
                    Container(
                      decoration: BoxDecoration(
                        color: currentQty > 0
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: currentQty > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: currentQty > 0
                                ? () {
                                    setState(() {
                                      final newQty = currentQty - 1;
                                      if (newQty <= 0) {
                                        _assignedQty[_currentPerson].remove(i);
                                      } else {
                                        _assignedQty[_currentPerson][i] =
                                            newQty;
                                      }
                                    });
                                  }
                                : null,
                            visualDensity: VisualDensity.compact,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '$currentQty',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: currentQty > 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: remainingQty > 0
                                ? () {
                                    setState(() {
                                      _assignedQty[_currentPerson][i] =
                                          currentQty + 1;
                                    });
                                  }
                                : null,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Ringkasan Subtotal Orang Saat Ini & Navigasi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal $name:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      Fmt.rupiah(_calculateCurrentPersonSubtotal()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_currentPerson > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _prevPerson,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(
                              _nameControllers[_currentPerson - 1].text.trim()),
                        ),
                      ),
                    if (_currentPerson > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _currentPerson < _personCount - 1
                          ? FilledButton.icon(
                              onPressed: _nextPerson,
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(_nameControllers[_currentPerson + 1]
                                  .text
                                  .trim()),
                            )
                          : FilledButton.icon(
                              onPressed: _finish,
                              icon: const Icon(Icons.calculate),
                              label: Text(l10n.calculateSplit),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _calculateCurrentPersonSubtotal() {
    double sum = 0;
    final map = _assignedQty[_currentPerson];
    for (final entry in map.entries) {
      final itemIdx = entry.key;
      final qty = entry.value;
      if (itemIdx < widget.items.length) {
        sum += widget.items[itemIdx].price * qty;
      }
    }
    return sum;
  }
}
