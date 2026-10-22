import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../data/display_preferences.dart';
import '../models/account.dart';
import '../models/investment.dart';
import '../widgets/common.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/display_order_sheet.dart';
import '../widgets/sync_indicator.dart';
import '../widgets/display_controls.dart';

/// Layar Investasi: portofolio saham/reksadana/crypto/emas dengan untung-rugi.
class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.of(context)!.assetsTitle),
          const SizedBox(width: 8),
          const SyncIndicator(),
        ]),
        actions: [
          const AmountVisibilityButton(),
          async.maybeWhen(
            data: (state) {
              final priceSvc = ref.read(priceServiceProvider);
              final autoCount = state.investments
                  .where((i) =>
                      i.ticker.trim().isNotEmpty &&
                      priceSvc.supportsAuto(i.type))
                  .length;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (autoCount > 0)
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip:
                          '${AppLocalizations.of(context)!.tooltipUpdatePrices} ($autoCount)',
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
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.snackFailed} $e')),
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
    final totalCost = state.investments.fold<double>(0, (s, i) => s + i.cost);
    final totalGain = totalValue - totalCost;
    final gainPct = totalCost == 0 ? 0.0 : (totalGain / totalCost) * 100;
    final l10n = AppLocalizations.of(context)!;

    return ResponsiveCenter(
      child: LayoutBuilder(
          builder: (context, constraints) => ListView(
                padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth >= 720 ? 28 : 16,
                    20,
                    constraints.maxWidth >= 720 ? 28 : 16,
                    100),
                children: [
                  Text(l10n.personalFinance.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(l10n.myAssetsTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  if (constraints.maxWidth >= 900)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 3,
                              child: _PortfolioCard(
                                  value: totalValue,
                                  gain: totalGain,
                                  gainPct: gainPct)),
                          const SizedBox(width: 14),
                          Expanded(
                              flex: 2,
                              child: _InvestmentAllocation(state: state)),
                        ])
                  else
                    _PortfolioCard(
                      value: totalValue,
                      gain: totalGain,
                      gainPct: gainPct,
                    ),
                  const SizedBox(height: 20),
                  Card(
                      child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 16,
                              children: [
                                Text(l10n.manualAssetOrder,
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                TextButton.icon(
                                    key: const ValueKey('reorder-assets'),
                                    onPressed: () => showInvestmentOrderSheet(
                                        context, state),
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: Text(l10n.reorderAssets)),
                              ]),
                          const SizedBox(height: 12),
                          if (constraints.maxWidth >= 760 &&
                              MediaQuery.textScalerOf(context).scale(14) <= 18)
                            _InvestmentTable(state: state)
                          else
                            for (final inv in state.orderedInvestments)
                              _InvestmentTile(inv: inv),
                          const SizedBox(height: 12),
                          Text(l10n.assetOrderSyncHint,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                        ]),
                  )),
                ],
              )),
    );
  }
}

class _PortfolioCard extends ConsumerWidget {
  const _PortfolioCard({
    required this.value,
    required this.gain,
    required this.gainPct,
  });
  final double value;
  final double gain;
  final double gainPct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hidden = ref.watch(amountsHiddenProvider);
    final positive = gain >= 0;
    const color = AppTheme.heroForeground;
    return Card(
      color: AppTheme.heroBackground(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.totalPortfolioValue,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: color.withValues(alpha: .85))),
            const SizedBox(height: 6),
            Text(formatVisibleMoney(ref, value),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                    hidden
                        ? Icons.insights_outlined
                        : positive
                            ? Icons.trending_up
                            : Icons.trending_down,
                    color: color,
                    size: 18),
                const SizedBox(width: 4),
                Flexible(
                    child: Text(
                  _visibleGain(ref, gain, gainPct),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentAllocation extends ConsumerWidget {
  const _InvestmentAllocation({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(amountsHiddenProvider);
    final groups = <InvestmentType, double>{};
    for (final asset in state.investments) {
      groups.update(asset.type, (value) => value + asset.marketValue,
          ifAbsent: () => asset.marketValue);
    }
    final total = state.totalInvestment;
    final entries = groups.entries.toList();
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.assetDistribution,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 20),
        if (total > 0 && !hidden)
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                  height: 12,
                  child: Row(children: [
                    for (var i = 0; i < entries.length; i++)
                      if (entries[i].value > 0)
                        Expanded(
                            flex: (entries[i].value / total * 10000)
                                .round()
                                .clamp(1, 10000),
                            child: Container(
                                margin: const EdgeInsets.only(right: 2),
                                color: primary.withValues(alpha: 1 - i * .14))),
                  ]))),
        const SizedBox(height: 16),
        Wrap(spacing: 14, runSpacing: 12, children: [
          for (var i = 0; i < entries.length; i++)
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 8,
                        height: 8,
                        color: primary.withValues(alpha: 1 - i * .14)),
                    const SizedBox(width: 5),
                    Text(entries[i].key.label(l10n),
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      hidden
                          ? formatVisibleMoney(ref, entries[i].value)
                          : '${formatVisibleMoney(ref, entries[i].value, compact: true)} · '
                              '${(total <= 0 ? 0 : entries[i].value / total * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall),
                ]),
        ]),
      ]),
    ));
  }
}

class _InvestmentTile extends ConsumerWidget {
  const _InvestmentTile({required this.inv});
  final Investment inv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(amountsHiddenProvider);
    final positive = inv.gain >= 0;
    final color = hidden
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : positive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;
    // Saham ditampilkan dalam lot, jenis lain dalam unit.
    final qtyLabel = hidden
        ? '••••••'
        : inv.type.tradedInLots
            ? '${Fmt.number(inv.lots)} ${l10n.qtyLot}'
            : '${Fmt.number(inv.quantity)} ${l10n.qtyUnit}';
    return InkWell(
      key: ValueKey('investment-${inv.id}'),
      onTap: () => showInvestmentDetails(context, inv.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(inv.type.icon,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(inv.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
          const SizedBox(height: 6),
          Text('${inv.type.label(l10n)} · $qtyLabel',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            Text(formatVisibleMoney(ref, inv.marketValue),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(_visibleGain(ref, inv.gain, inv.gainPercent),
                style: TextStyle(color: color, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Text(
              '${l10n.updatedAtLabel} ${Fmt.date(inv.updatedAt)} · '
              '@ ${formatVisibleMoney(ref, inv.currentPrice)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ]),
      ),
    );
  }
}

class _InvestmentTable extends ConsumerWidget {
  const _InvestmentTable({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(amountsHiddenProvider);
    final assets = state.orderedInvestments;
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        key: const ValueKey('investment-table'),
        showCheckboxColumn: false,
        horizontalMargin: 8,
        columnSpacing: 18,
        dataRowMinHeight: 78,
        dataRowMaxHeight: 88,
        columns: [
          DataColumn(label: Text(l10n.orderLabel)),
          DataColumn(label: Text(l10n.assetName)),
          DataColumn(label: Text(l10n.marketValue), numeric: true),
          DataColumn(label: Text(l10n.profitLoss), numeric: true)
        ],
        rows: [
          for (var i = 0; i < assets.length; i++)
            DataRow(
                key: ValueKey('investment-${assets[i].id}'),
                onSelectChanged: (_) =>
                    showInvestmentDetails(context, assets[i].id),
                cells: [
                  DataCell(Text('${i + 1}'.padLeft(2, '0'))),
                  DataCell(SizedBox(
                      width: 150,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(assets[i].name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(assets[i].type.label(l10n),
                                style: Theme.of(context).textTheme.bodySmall),
                          ]))),
                  DataCell(
                      Text(formatVisibleMoney(ref, assets[i].marketValue))),
                  DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            formatVisibleMoney(ref, assets[i].gain,
                                signed: true),
                            style: TextStyle(
                                color: hidden
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                    : assets[i].gain >= 0
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error)),
                        Text(
                            hidden
                                ? '••••••'
                                : '${assets[i].gainPercent.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall),
                      ])),
                ]),
        ],
      ),
    );
  }
}

String _visibleGain(WidgetRef ref, double gain, double percentage) {
  final amount = formatVisibleMoney(ref, gain, signed: true);
  if (ref.watch(amountsHiddenProvider)) return amount;
  return '$amount (${percentage > 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%)';
}

/// Resolve the asset by ID on every update so details follow edits and prices.
Future<void> showInvestmentDetails(BuildContext context, String investmentId) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _InvestmentDetailScreen(investmentId: investmentId),
    ),
  );
}

class _InvestmentDetailScreen extends ConsumerWidget {
  const _InvestmentDetailScreen({required this.investmentId});
  final String investmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(appStateProvider);
    final investment = async.valueOrNull?.investments
        .firstWhereOrNull((item) => item.id == investmentId);
    return Scaffold(
      key: ValueKey('investment-detail-$investmentId'),
      appBar: AppBar(
        title: Text(l10n.focusAssetDetailsTitle),
        actions: [
          const AmountVisibilityButton(),
          if (investment != null)
            IconButton(
              key: const ValueKey('edit-asset-detail'),
              tooltip: l10n.editInvestment,
              onPressed: () =>
                  showInvestmentDialog(context, ref, existing: investment),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.snackFailed} $error')),
        data: (_) => investment == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      Text(l10n.focusAssetMissing, textAlign: TextAlign.center),
                ),
              )
            : _InvestmentDetailBody(investment: investment),
      ),
    );
  }
}

class _InvestmentDetailBody extends ConsumerWidget {
  const _InvestmentDetailBody({required this.investment});
  final Investment investment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hidden = ref.watch(amountsHiddenProvider);
    final updatedAt = investment.updatedAt.toLocal();
    final updatedTime = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(updatedAt),
        alwaysUse24HourFormat: true);
    final quantity = hidden
        ? '••••••'
        : investment.type.tradedInLots
            ? '${Fmt.number(investment.lots)} ${l10n.qtyLot} '
                '(${Fmt.number(investment.quantity)} ${l10n.qtyUnit})'
            : '${Fmt.number(investment.quantity)} ${l10n.qtyUnit}';
    final values = <(String, String)>[
      (l10n.portfolioCost, formatVisibleMoney(ref, investment.cost)),
      (
        l10n.profitLoss,
        _visibleGain(ref, investment.gain, investment.gainPercent)
      ),
      (
        investment.type.tradedInLots ? l10n.qtyLotLabel : l10n.qtyUnitLabel,
        quantity
      ),
      (
        investment.type.tradedInLots ? l10n.buyLotLabel : l10n.buyUnitLabel,
        formatVisibleMoney(ref, investment.buyPrice)
      ),
      (
        investment.type.tradedInLots ? l10n.nowLotLabel : l10n.nowUnitLabel,
        formatVisibleMoney(ref, investment.currentPrice)
      ),
      (l10n.updatedAtLabel, '${Fmt.date(updatedAt)} · $updatedTime'),
    ];
    return ResponsiveCenter(
      maxWidth: 860,
      child: ListView(
        key: const ValueKey('asset-detail-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(investment.type.icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(investment.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(investment.ticker.trim().isEmpty
                      ? investment.type.label(l10n)
                      : '${investment.type.label(l10n)} · ${investment.ticker}'),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Card(
            color: AppTheme.heroBackground(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.marketValue,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: AppTheme.heroForeground)),
                    const SizedBox(height: 8),
                    Text(formatVisibleMoney(ref, investment.marketValue),
                        key: const ValueKey('asset-detail-market-value'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppTheme.heroForeground,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 &&
                    MediaQuery.textScalerOf(context).scale(14) <= 18
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final value in values)
                SizedBox(
                  width: width,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value.$1,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text(value.$2,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
                ),
            ]);
          }),
          const SizedBox(height: 16),
          Text(l10n.focusAssetValueHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
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
          : _trim(
              existing.type.tradedInLots ? existing.lots : existing.quantity));
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
        return SingleChildScrollView(
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
                  isExpanded: true,
                  initialValue: type,
                  decoration: InputDecoration(labelText: l10n.typeLabel),
                  items: [
                    for (final t in InvestmentType.values)
                      DropdownMenuItem(
                          value: t,
                          child: Row(children: [
                            Icon(t.icon, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    t.label(AppLocalizations.of(context)!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
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
                    labelText: type.tradedInLots
                        ? l10n.qtyLotLabel
                        : l10n.qtyUnitLabel,
                    hintText:
                        type.tradedInLots ? l10n.qtyLotHint : l10n.qtyUnitHint,
                    helperText: type.tradedInLots
                        ? l10n.qtyLotHelper(sharesPerLot.toString())
                        : null,
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
                                        content: Text(
                                            result.error ?? l10n.snackFailed)));
                                  }
                                },
                              ))
                        : null,
                  ),
                  validator: _numValidator,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (isEdit)
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref
                              .read(appStateProvider.notifier)
                              .deleteInvestment(existing.id);
                        },
                        icon: Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error),
                        label: Text(l10n.deleteLabel,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
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
      state.orderedAccounts.where((a) => a.type == AccountType.rdn).toList();
  if (rdnAccounts.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.snackNoRdn)));
    return;
  }
  final stocks =
      state.investments.where((i) => i.type == InvestmentType.stock).toList();

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

        return SingleChildScrollView(
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
                    isExpanded: true,
                    initialValue: stockId,
                    decoration:
                        InputDecoration(labelText: l10n.stockDropdownLabel),
                    items: [
                      if (isBuy)
                        DropdownMenuItem(
                            value: null,
                            child: Text(l10n.newStockOption,
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                      for (final s in stocks)
                        DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${Fmt.number(s.lots)} lot)',
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => stockId = v),
                  ),
                if (newStockSelected) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.stockNameLabel,
                        hintText: l10n.stockNameHint),
                    validator: (v) =>
                        newStockSelected && (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tickerCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                        labelText: l10n.stockCodeLabel,
                        hintText: l10n.stockNameHint),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: rdnId,
                  decoration: InputDecoration(labelText: l10n.rdnAccountLabel),
                  items: [
                    for (final a in rdnAccounts)
                      DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} · ${Fmt.rupiah(a.balance)}',
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                              ? l10n.lotQtyHelperSell(
                                  Fmt.number(selectedStock.lots))
                              : l10n.qtyLotHelper(sharesPerLot.toString()),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return l10n.invalidNumber;
                          if (!isBuy &&
                              selectedStock != null &&
                              n > selectedStock.lots) {
                            return l10n
                                .maxLotError(Fmt.number(selectedStock.lots));
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
                            labelText: l10n.pricePerShareLabel,
                            prefixText: 'Rp '),
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
                    color: (isBuy
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(isBuy ? l10n.totalPayLabel : l10n.totalReceiveLabel),
                      Text(Fmt.rupiah(total),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isBuy
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary)),
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
                        messenger.showSnackBar(SnackBar(content: Text(error)));
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
