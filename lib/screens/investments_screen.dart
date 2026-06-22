import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/account.dart';
import '../models/investment.dart';
import '../widgets/common.dart';

/// Layar Investasi: portofolio saham/reksadana/crypto/emas dengan untung-rugi.
class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investasi'),
        actions: [
          async.maybeWhen(
            data: (state) => IconButton(
              icon: const Icon(Icons.candlestick_chart_outlined),
              tooltip: 'Transaksi Saham (RDN)',
              onPressed: () => showStockTradeDialog(context, ref, state),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showInvestmentDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Investasi'),
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
    if (state.investments.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'Belum ada investasi',
        subtitle: 'Tambahkan saham, reksadana, crypto, atau emas\n'
            'untuk melacak nilai portofoliomu.',
      );
    }

    final totalValue = state.totalInvestment;
    final totalCost =
        state.investments.fold<double>(0, (s, i) => s + i.cost);
    final totalGain = totalValue - totalCost;
    final gainPct = totalCost == 0 ? 0.0 : (totalGain / totalCost) * 100;

    return ListView(
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
            Text('Total Nilai Portofolio',
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
    final positive = inv.gain >= 0;
    final color = positive ? AppTheme.income : AppTheme.expense;
    final canRefresh = inv.ticker.trim().isNotEmpty &&
        ref.read(priceServiceProvider).supportsAuto(inv.type);
    // Saham ditampilkan dalam lot, jenis lain dalam unit.
    final qtyLabel = inv.type.tradedInLots
        ? '${Fmt.number(inv.lots)} lot'
        : '${Fmt.number(inv.quantity)} unit';
    return ListTile(
      leading: IconBadge(icon: inv.type.icon, color: AppTheme.investment),
      title: Text(inv.name),
      subtitle: Text(
          '${inv.type.label} · $qtyLabel @ ${Fmt.rupiah(inv.currentPrice)}'
          '\nDiperbarui ${Fmt.date(inv.updatedAt)}'),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canRefresh)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Perbarui harga',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final error = await ref
                    .read(appStateProvider.notifier)
                    .refreshPrice(inv.id);
                messenger.showSnackBar(SnackBar(
                    content: Text(error ?? 'Harga ${inv.name} diperbarui.')));
              },
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.rupiah(inv.marketValue),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                  '${positive ? '+' : ''}${inv.gainPercent.toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
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
              Text(isEdit ? 'Edit Investasi' : 'Tambah Investasi',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                    labelText: 'Nama', hintText: 'mis. BBCA, Bitcoin, Emas'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InvestmentType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Jenis'),
                items: [
                  for (final t in InvestmentType.values)
                    DropdownMenuItem(
                        value: t,
                        child: Row(children: [
                          Icon(t.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(t.label),
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
                        ? 'ID CoinGecko'
                        : 'Kode saham',
                    hintText: type == InvestmentType.crypto
                        ? 'mis. bitcoin, ethereum, solana'
                        : 'mis. BBCA, TLKM',
                    helperText: type == InvestmentType.crypto
                        ? 'Untuk ambil harga otomatis (opsional)'
                        : 'Harga saham otomatis aktif setelah backend di-deploy',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: type.tradedInLots ? 'Jumlah lot' : 'Jumlah unit',
                  hintText: type.tradedInLots ? 'mis. 5, 10' : 'mis. 100, 0.5',
                  helperText:
                      type.tradedInLots ? '1 lot = $sharesPerLot lembar' : null,
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
                        ? 'Harga beli / lembar'
                        : 'Harga beli / unit',
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
                      ? 'Harga sekarang / lembar'
                      : 'Harga sekarang / unit',
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
                              tooltip: 'Ambil harga sekarang',
                              onPressed: () async {
                                final ticker = tickerCtrl.text.trim();
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                if (ticker.isEmpty) {
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text(
                                          'Isi dulu ticker/simbol asetnya.')));
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
                                );
                                setState(() => fetching = false);
                                if (result.ok) {
                                  nowCtrl.text = _trim(result.price);
                                  messenger.showSnackBar(SnackBar(
                                      content: Text(
                                          'Harga diperbarui: ${Fmt.rupiah(result.price)}')));
                                } else {
                                  messenger.showSnackBar(SnackBar(
                                      content:
                                          Text(result.error ?? 'Gagal.')));
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
                      label: const Text('Hapus',
                          style: TextStyle(color: AppTheme.expense)),
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
  final rdnAccounts =
      state.accounts.where((a) => a.type == AccountType.rdn).toList();
  if (rdnAccounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Buat akun jenis "RDN (Saham)" dulu di tab Akun untuk transaksi saham.')));
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
                Text('Transaksi Saham',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Beli')),
                    ButtonSegment(value: false, label: Text('Jual')),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Belum ada saham untuk dijual.'),
                  )
                else
                  DropdownButtonFormField<String?>(
                    value: stockId,
                    decoration: const InputDecoration(labelText: 'Saham'),
                    items: [
                      if (isBuy)
                        const DropdownMenuItem(
                            value: null, child: Text('+ Saham baru')),
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
                    decoration: const InputDecoration(
                        labelText: 'Nama saham', hintText: 'mis. BBCA'),
                    validator: (v) => newStockSelected &&
                            (v == null || v.trim().isEmpty)
                        ? 'Wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tickerCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        labelText: 'Kode (opsional)', hintText: 'mis. BBCA'),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: rdnId,
                  decoration: const InputDecoration(labelText: 'Rekening RDN'),
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
                          labelText: 'Jumlah lot',
                          helperText: selectedStock != null && !isBuy
                              ? 'Punya ${Fmt.number(selectedStock.lots)} lot'
                              : '1 lot = $sharesPerLot lembar',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Tidak valid';
                          if (!isBuy &&
                              selectedStock != null &&
                              n > selectedStock.lots) {
                            return 'Maks ${Fmt.number(selectedStock.lots)}';
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
                        decoration: const InputDecoration(
                            labelText: 'Harga/lembar', prefixText: 'Rp '),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Tidak valid';
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
                      Text(isBuy ? 'Total bayar' : 'Total diterima'),
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
                              ? 'Pembelian saham tercatat.'
                              : 'Penjualan saham tercatat.')));
                    },
                    child: Text(isBuy ? 'Beli' : 'Jual'),
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
