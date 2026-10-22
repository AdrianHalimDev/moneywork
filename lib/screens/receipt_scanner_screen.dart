import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../data/app_controller.dart';
import '../models/receipt.dart';
import '../services/bill_splitter.dart';
import '../services/receipt_scanner_service.dart';
import '../widgets/responsive_layout.dart';
import 'accounts_screen.dart';
import 'receipt_assign_screen.dart';

/// Layar review hasil scan bon.
///
/// Menampilkan daftar item, service charge, pajak, dan grand total yang
/// diekstrak oleh AI. Pengguna bisa mengedit setiap angka dan memilih
/// untuk menyimpan sebagai transaksi atau split bill.
class ReceiptReviewScreen extends ConsumerStatefulWidget {
  const ReceiptReviewScreen(
      {super.key, required this.initialData, this.sourceImageBytes});

  final ReceiptScanResult initialData;
  final Uint8List? sourceImageBytes;

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late List<ReceiptItem> _items;
  late List<Key> _itemKeys;
  late TextEditingController _serviceCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _additionalFeesCtrl;
  late TextEditingController _grandTotalCtrl;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialData.items);
    _itemKeys = List.generate(_items.length, (_) => UniqueKey());
    _serviceCtrl = TextEditingController(
        text: widget.initialData.serviceCharge.toStringAsFixed(0));
    _taxCtrl =
        TextEditingController(text: widget.initialData.tax.toStringAsFixed(0));
    _discountCtrl = TextEditingController(
        text: widget.initialData.discount.toStringAsFixed(0));
    _additionalFeesCtrl = TextEditingController(
        text: widget.initialData.additionalFees.toStringAsFixed(0));
    _grandTotalCtrl = TextEditingController(
        text: widget.initialData.grandTotal.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _taxCtrl.dispose();
    _discountCtrl.dispose();
    _additionalFeesCtrl.dispose();
    _grandTotalCtrl.dispose();
    super.dispose();
  }

  ReceiptScanResult _currentReceipt() => ReceiptScanResult(
        items: _items,
        subtotal: _items.fold<double>(0, (s, i) => s + i.totalPrice),
        serviceCharge: double.tryParse(_serviceCtrl.text) ?? 0,
        tax: double.tryParse(_taxCtrl.text) ?? 0,
        discount: double.tryParse(_discountCtrl.text) ?? 0,
        additionalFees: double.tryParse(_additionalFeesCtrl.text) ?? 0,
        grandTotal: double.tryParse(_grandTotalCtrl.text) ?? 0,
      );

  VerificationResult _verify() =>
      ReceiptScannerService.verifyReceipt(_currentReceipt());

  void _onChanged() => setState(() {});

  // === Route A: Simpan sebagai Transaksi ===
  void _saveAsTransaction() {
    final state = ref.read(appStateProvider).valueOrNull;
    if (state == null || state.orderedAccounts.isEmpty) return;
    final receipt = _currentReceipt();
    final verification = ReceiptScannerService.verifyReceipt(receipt);

    // Buka dialog catat transaksi yang sudah ada, pre-fill amount
    showTransactionDialog(
      context,
      ref,
      state,
      prefilledAmount: verification.calculatedGrandTotal,
    );
  }

  // === Route B: Split Bill ===
  void _splitBill() {
    final receipt = _currentReceipt();
    // Konversi ReceiptItem → BillItem
    final extractedItems = receipt.items
        .map((i) => BillItem(
            name: i.itemName,
            price: i.qty > 0 ? i.totalPrice / i.qty : i.unitPrice,
            qty: i.qty))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptAssignScreen(
          items: extractedItems,
          tax: receipt.tax,
          serviceCharge: receipt.serviceCharge,
          discount: receipt.discount,
          additionalFees: receipt.additionalFees,
        ),
      ),
    );
  }

  void _showSource() {
    final bytes = widget.sourceImageBytes;
    if (bytes == null) return;
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => Scaffold(
              appBar: AppBar(title: Text(l10n.focusReviewSource)),
              body: _ReceiptSourceImage(bytes: bytes),
            )));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final v = _verify();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptReview), actions: [
        if (widget.sourceImageBytes != null)
          IconButton(
            key: const ValueKey('receipt-view-original'),
            onPressed: _showSource,
            tooltip: l10n.focusReviewSource,
            icon: const Icon(Icons.image_outlined),
          ),
      ]),
      body: ResponsiveCenter(
        child: LayoutBuilder(builder: (context, constraints) {
          final review = _buildReviewList(context, v);
          if (constraints.maxWidth < 1000 || widget.sourceImageBytes == null) {
            return review;
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(flex: 3, child: review),
            const SizedBox(width: 12),
            Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
                  child: Card(
                    key: const ValueKey('receipt-original-panel'),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.focusReviewSource,
                            style: theme.textTheme.titleSmall),
                      ),
                      Expanded(
                          child: _ReceiptSourceImage(
                              bytes: widget.sourceImageBytes!)),
                    ]),
                  ),
                )),
          ]);
        }),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (context, constraints) {
                final transaction = FilledButton.icon(
                  onPressed: v.isVerified ? _saveAsTransaction : null,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.receiptSaveAsTransaction),
                );
                final split = FilledButton.tonalIcon(
                  onPressed: v.isVerified ? _splitBill : null,
                  icon: const Icon(Icons.call_split),
                  label: Text(l10n.receiptSplitBill),
                );
                if (constraints.maxWidth < 520 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18) {
                  return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        transaction,
                        const SizedBox(height: 8),
                        split
                      ]);
                }
                return Row(children: [
                  Expanded(child: transaction),
                  const SizedBox(width: 12),
                  Expanded(child: split),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewList(BuildContext context, VerificationResult v) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final difference =
        (v.calculatedGrandTotal - _currentReceipt().grandTotal).abs();
    return ListView(
      key: const ValueKey('receipt-review-list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Banner verifikasi
        _VerificationBanner(verification: v),
        const SizedBox(height: 12),
        Text(l10n.focusReviewBeforeSave, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          color: v.isVerified
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.focusReviewDifference),
              const SizedBox(height: 4),
              Text(Fmt.rupiah(difference),
                  key: const ValueKey('receipt-review-difference'),
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: v.isVerified
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Daftar item
        for (var i = 0; i < _items.length; i++) ...[
          _ItemEditTile(
            key: _itemKeys[i],
            index: i,
            item: _items[i],
            onChanged: (updated) {
              _items[i] = updated;
              _onChanged();
            },
            onDelete: () {
              _items.removeAt(i);
              _itemKeys.removeAt(i);
              _onChanged();
            },
          ),
          if (i < _items.length - 1) const Divider(height: 1),
        ],

        const SizedBox(height: 16),

        // Service Charge
        _NumberField(
          label: l10n.receiptServiceCharge,
          controller: _serviceCtrl,
          onChanged: _onChanged,
        ),
        const SizedBox(height: 12),

        // Tax / Pajak
        _NumberField(
          label: l10n.receiptTax,
          controller: _taxCtrl,
          onChanged: _onChanged,
        ),
        const SizedBox(height: 12),

        // Discount / Diskon
        _NumberField(
          label: l10n.receiptDiscount,
          controller: _discountCtrl,
          onChanged: _onChanged,
        ),
        const SizedBox(height: 12),

        _NumberField(
          label: l10n.additionalFeesLabel,
          controller: _additionalFeesCtrl,
          onChanged: _onChanged,
        ),
        const SizedBox(height: 12),

        // Grand Total Kertas (editable)
        _NumberField(
          label: l10n.receiptGrandTotalPaper,
          controller: _grandTotalCtrl,
          onChanged: _onChanged,
        ),
        const SizedBox(height: 16),

        // Grand Total Terhitung (read-only)
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(l10n.receiptGrandTotalCalc,
                    style: theme.textTheme.titleSmall),
                Text(
                  Fmt.rupiah(v.calculatedGrandTotal),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: v.isVerified
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptSourceImage extends StatelessWidget {
  const _ReceiptSourceImage({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => InteractiveViewer(
        minScale: .5,
        maxScale: 5,
        child: Center(
          child: Image.memory(bytes,
              fit: BoxFit.contain,
              semanticLabel: AppLocalizations.of(context)!.focusReviewSource,
              errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  )),
        ),
      );
}

// ============================================================================
// Verification Banner
// ============================================================================

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.verification});
  final VerificationResult verification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (verification.isVerified) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.receiptVerified,
                  style:
                      TextStyle(color: theme.colorScheme.onPrimaryContainer)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              verification.errorMessage ?? l10n.receiptMismatch,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Item Edit Tile
// ============================================================================

class _ItemEditTile extends StatefulWidget {
  const _ItemEditTile({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final ReceiptItem item;
  final ValueChanged<ReceiptItem> onChanged;
  final VoidCallback onDelete;

  @override
  State<_ItemEditTile> createState() => _ItemEditTileState();
}

class _ItemEditTileState extends State<_ItemEditTile> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.itemName);
    _qtyCtrl = TextEditingController(text: widget.item.qty.toString());
    _priceCtrl =
        TextEditingController(text: widget.item.unitPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    widget.onChanged(ReceiptItem(
      itemName: _nameCtrl.text,
      qty: qty,
      unitPrice: price,
      totalPrice: qty * price,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = TextField(
      controller: _nameCtrl,
      decoration:
          InputDecoration(labelText: l10n.receiptItemName, isDense: true),
      onChanged: (_) => _emit(),
    );
    final quantity = TextField(
      controller: _qtyCtrl,
      decoration: InputDecoration(labelText: l10n.receiptQty, isDense: true),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _emit(),
    );
    final price = TextField(
      controller: _priceCtrl,
      decoration: InputDecoration(
          labelText: l10n.receiptUnitPrice, isDense: true, prefixText: 'Rp '),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _emit(),
    );
    final remove = IconButton(
      tooltip: l10n.deleteLabel,
      onPressed: widget.onDelete,
      icon: const Icon(Icons.close, size: 18),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 520 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(children: [
            Row(children: [Expanded(child: name), remove]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: quantity),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: price),
            ]),
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 4, child: name),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: quantity),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: price),
          remove,
        ]);
      }),
    );
  }
}

// ============================================================================
// Number Field
// ============================================================================

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => onChanged(),
    );
  }
}
