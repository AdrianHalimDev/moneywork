import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/account.dart';
import '../models/investment.dart';
import '../widgets/common.dart';
import '../widgets/responsive_layout.dart';

/// Layar Investasi: portofolio saham/reksadana/crypto/emas dengan untung-rugi.
class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tabInvestments),
        actions: [
          async.maybeWhen(
            data: (state) {
              final priceSvc = ref.read(priceServiceProvider);
              final autoCount = state.investments
                  .where((i) =>
                      i.ticker.trim().isNotEmpty && priceSvc.supportsAuto(i.type))
                  .length;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (autoCount > 0)
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: '${AppLocalizations.of(context)!.tooltipUpdatePrices} ($autoCount)',
                      onPressed: () => _refreshAll(context, ref),
                    ),
                  IconButton(
                    icon: const Icon(Icons.candlestick_chart_outlined),
                    tooltip: AppLocalizations.of(context)!.tooltipStockTrade,
                    onPressed: () => showStockTradeDialog(context, ref, state),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showInvestmentDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.fabInvestment),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.snackFailed} $e')),
        data: (state) => _Body(state: state),
      ),
    );
  }
}

/// Ambil harga semua aset yang mendukung harga otomatis sekaligus.
Future<void> _refreshAll(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(
      content: Text(l10n.snackUpdatingPrices),
      duration: const Duration(seconds: 1)));
  final r = await ref.read(appStateProvider.notifier).refreshAllPrices(l10n);
  final msg = r.total == 0
      ? l10n.snackNoAutoPrices
      : r.failed == 0
          ? '${r.updated} ${l10n.snackPricesUpdated}'
          : '${r.updated} ${l10n.snackPricesUpdateFailed1} ${r.failed} ${l10n.snackPricesUpdateFailed2} ${r.total}.';
  messenger.showSnackBar(SnackBar(content: Text(msg)));
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.investments.isEmpty) {
      return EmptyState(
        icon: Icons.show_chart,
        title: AppLocalizations.of(context)!.emptyInvestmentTitle,
        subtitle: AppLocalizations.of(context)!.emptyInvestmentSubtitle,
      );
    }

    final totalValue = state.totalInvestment;
    final totalCost =
        state.investments.fold<double>(0, (s, i) => s + i.cost);
    final totalGain = totalValue - totalCost;
    final gainPct = totalCost == 0 ? 0.0 : (totalGain / totalCost) * 100;

    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _PortfolioCard(
              value: totalValue,
              gain: totalGain,
              gainPct: gainPct,
            ),
          ),
          for (final inv in state.investments) _InvestmentTile(inv: inv),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.value,
    required this.gain,
    required this.gainPct,
  });
  final double value;
  final double gain;
  final double gainPct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = gain >= 0;
    final color = positive ? AppTheme.income : AppTheme.expense;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.totalPortfolioValue,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 6),
            Text(Fmt.rupiah(value),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(positive ? Icons.trending_up : Icons.trending_down,
                    color: color, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${Fmt.rupiahSigned(gain)} (${gainPct.toStringAsFixed(1)}%)',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentTile extends ConsumerWidget {
  const _InvestmentTile({required this.inv});
  final Investment inv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final positive = inv.gain >= 0;
    final color = positive ? AppTheme.income : AppTheme.expense;
    // Saham ditampilkan dalam lot, jenis lain dalam unit.
    final qtyLabel = inv.type.tradedInLots
        ? '${Fmt.number(inv.lots)} ${l10n.qtyLot}'
        : '${Fmt.number(inv.quantity)} ${l10n.qtyUnit}';
    return ListTile(
      leading: IconBadge(icon: inv.type.icon, color: AppTheme.investment),
      title: Text(inv.name),
      subtitle: Text(
          '${inv.type.label(AppLocalizations.of(context)!)} · $qtyLabel @ ${Fmt.rupiah(inv.currentPrice)}'
          '\n${l10n.updatedAtLabel} ${Fmt.date(inv.updatedAt)}'),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Fmt.rupiah(inv.marketValue),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(Fmt.rupiahSigned(inv.gain),
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          Text('${positive ? '+' : ''}${inv.gainPercent.toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
      onTap: () => showInvestmentDialog(context, ref, existing: inv),
    );
  }
}

// ============================================================================
// Dialog: tambah/edit investasi
// ============================================================================

Future<void> showInvestmentDialog(
  BuildContext context,
  WidgetRef ref, {
  Investment? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  // Saham diinput dalam lot; jenis lain dalam unit/lembar.
  final qtyCtrl = TextEditingController(
      text: existing == null
          ? ''
          : _trim(existing.type.tradedInLots
              ? existing.lots
              : existing.quantity));
  final buyCtrl = TextEditingController(
      text: existing != null ? _trim(existing.buyPrice) : '');
  final nowCtrl = TextEditingController(
      text: existing != null ? _trim(existing.currentPrice) : '');
  final tickerCtrl = TextEditingController(text: existing?.ticker ?? '');
  var type = existing?.type ?? InvestmentType.stock;
  var fetching = false;
  final isEdit = existing != null;
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        return Padding(
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
              Text(isEdit ? l10n.editInvestment : l10n.addInvestment,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: InputDecoration(
                    labelText: l10n.nameLabel, hintText: l10n.nameHint),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InvestmentType>(
                initialValue: type,
                decoration: InputDecoration(labelText: l10n.typeLabel),
                items: [
                  for (final t in InvestmentType.values)
                    DropdownMenuItem(
                        value: t,
                        child: Row(children: [
                          Icon(t.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(t.label(AppLocalizations.of(context)!)),
                        ])),
                ],
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              // Ticker untuk harga otomatis (crypto & saham).
              if (type == InvestmentType.crypto ||
                  type == InvestmentType.stock) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: tickerCtrl,
                  textCapitalization: type == InvestmentType.stock
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: type == InvestmentType.crypto
                        ? l10n.tickerCryptoLabel
                        : l10n.tickerStockLabel,
                    hintText: type == InvestmentType.crypto
                        ? l10n.tickerCryptoHint
                        : l10n.tickerStockHint,
                    helperText: type == InvestmentType.crypto
                        ? l10n.tickerCryptoHelper
                        : l10n.tickerStockHelper,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: type.tradedInLots ? l10n.qtyLotLabel : l10n.qtyUnitLabel,
                  hintText: type.tradedInLots ? l10n.qtyLotHint : l10n.qtyUnitHint,
                  helperText:
                      type.tradedInLots ? l10n.qtyLotHelper(sharesPerLot.toString()) : null,
                ),
                validator: _numValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: buyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: type.tradedInLots
                        ? l10n.buyLotLabel
                        : l10n.buyUnitLabel,
                    prefixText: 'Rp '),
                validator: _numValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nowCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: type.tradedInLots
                      ? l10n.nowLotLabel
                      : l10n.nowUnitLabel,
                  prefixText: 'Rp ',
                  suffixIcon: (type == InvestmentType.crypto ||
                          type == InvestmentType.stock)
                      ? (fetching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: l10n.tooltipFetchPrice,
                              onPressed: () async {
                                final ticker = tickerCtrl.text.trim();
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                if (ticker.isEmpty) {
                                  messenger.showSnackBar(SnackBar(
                                      content: Text(l10n.snackTickerEmpty)));
                                  return;
                                }
                                setState(() => fetching = true);
                                final service =
                                    ref.read(priceServiceProvider);
                                final result = await service.fetch(
                                  Investment(
                                    id: 'tmp',
                                    name: nameCtrl.text.trim(),
                                    type: type,
                                    quantity: 0,
                                    buyPrice: 0,
                                    currentPrice: 0,
                                    ticker: ticker,
                                    updatedAt: DateTime.now(),
                                  ),
                                  AppLocalizations.of(context)!,
                                );
                                setState(() => fetching = false);
                                if (result.ok) {
                                  nowCtrl.text = _trim(result.price);
                                  messenger.showSnackBar(SnackBar(
                                      content: Text(
                                          '${l10n.snackPriceUpdated} ${Fmt.rupiah(result.price)}')));
                                } else {
                                  messenger.showSnackBar(SnackBar(
                                      content:
                                          Text(result.error ?? l10n.snackFailed)));
                                }
                              },
                            ))
                      : null,
                ),
                validator: _numValidator,
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
                            .deleteInvestment(existing.id);
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
                      final qtyInput = double.parse(qtyCtrl.text.trim());
                      // Saham diinput dalam lot; simpan sebagai lembar.
                      final qty = type.tradedInLots
                          ? qtyInput * sharesPerLot
                          : qtyInput;
                      final buy = double.parse(buyCtrl.text.trim());
                      final now = double.parse(nowCtrl.text.trim());
                      final ctrl = ref.read(appStateProvider.notifier);
                      if (isEdit) {
                        ctrl.updateInvestment(existing.copyWith(
                          name: nameCtrl.text.trim(),
                          type: type,
                          quantity: qty,
                          buyPrice: buy,
                          currentPrice: now,
                          ticker: tickerCtrl.text.trim(),
                          updatedAt: DateTime.now(),
                        ));
                      } else {
                        ctrl.addInvestment(
                          name: nameCtrl.text.trim(),
                          type: type,
                          quantity: qty,
                          buyPrice: buy,
                          currentPrice: now,
                          ticker: tickerCtrl.text.trim(),
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
      );
      },
    ),
  );
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

String? _numValidator(String? v) {
  final n = double.tryParse((v ?? '').trim());
  if (n == null || n < 0) return 'Angka tidak valid';
  return null;
}

// ============================================================================
// Dialog: transaksi saham (beli/jual) via RDN
// ============================================================================

Future<void> showStockTradeDialog(
  BuildContext context,
  WidgetRef ref,
  AppState state,
) async {
  final l10n = AppLocalizations.of(context)!;
  final rdnAccounts =
      state.accounts.where((a) => a.type == AccountType.rdn).toList();
  if (rdnAccounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.snackNoRdn)));
    return;
  }
  final stocks = state.investments
      .where((i) => i.type == InvestmentType.stock)
      .toList();

  var isBuy = true;
  var rdnId = rdnAccounts.first.id;
  // Untuk beli: null = saham baru. Untuk jual: wajib pilih saham.
  String? stockId = stocks.isNotEmpty ? stocks.first.id : null;
  final nameCtrl = TextEditingController();
  final tickerCtrl = TextEditingController();
  final lotCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        // Saham baru hanya opsi saat beli.
        final newStockSelected = isBuy && stockId == null;
        final selectedStock = stockId == null
            ? null
            : stocks.where((s) => s.id == stockId).firstOrNull;
        final lots = double.tryParse(lotCtrl.text.trim()) ?? 0;
        final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
        final total = lots * sharesPerLot * price;

        return Padding(
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
                Text(l10n.tradeStockTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l10n.buyLabel)),
                    ButtonSegment(value: false, label: Text(l10n.sellLabel)),
                  ],
                  selected: {isBuy},
                  onSelectionChanged: (s) => setState(() {
                    isBuy = s.first;
                    // Saat pindah ke jual, pastikan ada saham terpilih.
                    if (!isBuy && stockId == null && stocks.isNotEmpty) {
                      stockId = stocks.first.id;
                    }
                  }),
                ),
                const SizedBox(height: 16),
                // Pilih saham (untuk jual: wajib; untuk beli: bisa baru).
                if (!isBuy && stocks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.noStockToSell),
                  )
                else
                  DropdownButtonFormField<String?>(
                    initialValue: stockId,
                    decoration: InputDecoration(labelText: l10n.stockDropdownLabel),
                    items: [
                      if (isBuy)
                        DropdownMenuItem(
                            value: null, child: Text(l10n.newStockOption)),
                      for (final s in stocks)
                        DropdownMenuItem(
                            value: s.id,
                            child: Text(
                                '${s.name} (${Fmt.number(s.lots)} lot)')),
                    ],
                    onChanged: (v) => setState(() => stockId = v),
                  ),
                if (newStockSelected) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.stockNameLabel, hintText: l10n.stockNameHint),
                    validator: (v) => newStockSelected &&
                            (v == null || v.trim().isEmpty)
                        ? 'Wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tickerCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                        labelText: l10n.stockCodeLabel, hintText: l10n.stockNameHint),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rdnId,
                  decoration: InputDecoration(labelText: l10n.rdnAccountLabel),
                  items: [
                    for (final a in rdnAccounts)
                      DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} · ${Fmt.rupiah(a.balance)}')),
                  ],
                  onChanged: (v) => setState(() => rdnId = v ?? rdnId),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: lotCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.qtyLotLabel,
                          helperText: selectedStock != null && !isBuy
                              ? l10n.lotQtyHelperSell(Fmt.number(selectedStock.lots))
                              : l10n.qtyLotHelper(sharesPerLot.toString()),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return l10n.invalidNumber;
                          if (!isBuy &&
                              selectedStock != null &&
                              n > selectedStock.lots) {
                            return l10n.maxLotError(Fmt.number(selectedStock.lots));
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: l10n.pricePerShareLabel, prefixText: 'Rp '),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return l10n.invalidNumber;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isBuy ? AppTheme.expense : AppTheme.income)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isBuy ? l10n.totalPayLabel : l10n.totalReceiveLabel),
                      Text(Fmt.rupiah(total),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isBuy
                                  ? AppTheme.expense
                                  : AppTheme.income)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (!isBuy && stockId == null) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final ctrl = ref.read(appStateProvider.notifier);
                      final lotsVal = double.parse(lotCtrl.text.trim());
                      final priceVal = double.parse(priceCtrl.text.trim());
                      final error = isBuy
                          ? await ctrl.buyStock(
                              investmentId: stockId,
                              name: nameCtrl.text.trim(),
                              ticker: tickerCtrl.text.trim(),
                              rdnAccountId: rdnId,
                              lots: lotsVal,
                              pricePerShare: priceVal,
                            )
                          : await ctrl.sellStock(
                              investmentId: stockId!,
                              rdnAccountId: rdnId,
                              lots: lotsVal,
                              pricePerShare: priceVal,
                            );
                      if (error != null) {
                        messenger
                            .showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      navigator.pop();
                      messenger.showSnackBar(SnackBar(
                          content: Text(isBuy
                              ? l10n.snackBuySuccess
                              : l10n.snackSellSuccess)));
                    },
                    child: Text(isBuy ? l10n.buyLabel : l10n.sellLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
