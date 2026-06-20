import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/wishlist_item.dart';
import '../widgets/common.dart';

/// Layar Wishlist: barang yang ingin dibeli, lengkap dengan link,
/// harga, prioritas, dan target tanggal realisasi (opsional).
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWishDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Wishlist'),
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
    if (state.wishlist.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_outline,
        title: 'Wishlist masih kosong',
        subtitle: 'Catat barang yang ingin dibeli beserta harga,\n'
            'link, dan target tanggalnya.',
      );
    }

    // Belum dibeli dulu (urut prioritas tinggi → rendah), lalu yang sudah dibeli.
    final pending = state.wishlist.where((w) => !w.purchased).toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    final done = state.wishlist.where((w) => w.purchased).toList();
    final totalPending =
        pending.fold<double>(0, (s, w) => s + w.price);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: ListTile(
              leading: const IconBadge(
                  icon: Icons.savings_outlined, color: AppTheme.investment),
              title: const Text('Total target belanja'),
              subtitle: Text('${pending.length} barang belum dibeli'),
              trailing: Text(Fmt.rupiah(totalPending),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        for (final w in pending) _WishTile(item: w),
        if (done.isNotEmpty) ...[
          const SectionHeader(title: 'Sudah Dibeli'),
          for (final w in done) _WishTile(item: w),
        ],
      ],
    );
  }
}

class _WishTile extends ConsumerWidget {
  const _WishTile({required this.item});
  final WishlistItem item;

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(item.url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final target = item.targetDate;
    final subtitleParts = <String>[
      item.priority.label,
      if (target != null) 'Target ${Fmt.date(target)}',
      if (item.monthlySaving > 0)
        '${Fmt.rupiahCompact(item.monthlySaving)}/bln',
    ];
    final showSaving = !item.purchased && item.hasSavingPlan;

    return ListTile(
      isThreeLine: showSaving,
      leading: Checkbox(
        value: item.purchased,
        onChanged: (_) =>
            ref.read(appStateProvider.notifier).toggleWishPurchased(item.id),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.purchased ? TextDecoration.lineThrough : null,
          color: item.purchased ? theme.colorScheme.outline : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                    color: item.priority.color, shape: BoxShape.circle),
              ),
              Flexible(child: Text(subtitleParts.join(' · '))),
            ],
          ),
          if (showSaving) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.savingProgress,
                minHeight: 5,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: AppTheme.income,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Terkumpul ${Fmt.rupiah(item.savedAmount)} / ${Fmt.rupiah(item.price)}'
              '${item.monthsRemaining > 0 ? ' · ~${item.monthsRemaining} bln lagi' : ''}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSaving)
            IconButton(
              icon: const Icon(Icons.savings_outlined, size: 20),
              tooltip: 'Catat nabung',
              onPressed: () => _showContribute(context, ref),
            )
          else
            Text(Fmt.rupiah(item.price),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          if (item.url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Buka link',
              onPressed: () => _openUrl(context),
            ),
        ],
      ),
      onTap: () => showWishDialog(context, ref, existing: item),
    );
  }

  Future<void> _showContribute(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(
        text: item.monthlySaving > 0
            ? item.monthlySaving.toStringAsFixed(0)
            : '');
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nabung untuk ${item.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terkumpul ${Fmt.rupiah(item.savedAmount)} dari '
                  '${Fmt.rupiah(item.price)}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Jumlah ditabung', prefixText: 'Rp '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Masukkan jumlah valid';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ref
                  .read(appStateProvider.notifier)
                  .contributeToWish(item.id, double.parse(ctrl.text.trim()));
              Navigator.pop(context);
            },
            child: const Text('Catat'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Dialog: tambah/edit wishlist
// ============================================================================

Future<void> showWishDialog(
  BuildContext context,
  WidgetRef ref, {
  WishlistItem? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '');
  final urlCtrl = TextEditingController(text: existing?.url ?? '');
  final monthlyCtrl = TextEditingController(
      text: existing != null && existing.monthlySaving > 0
          ? existing.monthlySaving.toStringAsFixed(0)
          : '');
  final durationCtrl = TextEditingController(
      text: existing != null && existing.durationMonths > 0
          ? existing.durationMonths.toString()
          : '');
  var priority = existing?.priority ?? WishPriority.medium;
  DateTime? targetDate = existing?.targetDate;
  var reminderDay = existing?.reminderDay ?? 0;
  String? savingAccountId = existing?.savingAccountId;
  final isEdit = existing != null;
  final formKey = GlobalKey<FormState>();

  final accounts = ref.read(appStateProvider).valueOrNull?.accounts ?? const [];

  // Kalkulator dua-arah: hitung jangka waktu dari tabungan bulanan.
  void recalcDuration() {
    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final monthly = double.tryParse(monthlyCtrl.text.trim()) ?? 0;
    if (price > 0 && monthly > 0) {
      durationCtrl.text = (price / monthly).ceil().toString();
    }
  }

  // Kalkulator dua-arah: hitung tabungan bulanan dari jangka waktu.
  void recalcMonthly() {
    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final months = int.tryParse(durationCtrl.text.trim()) ?? 0;
    if (price > 0 && months > 0) {
      monthlyCtrl.text = (price / months).ceil().toString();
    }
  }

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
              Text(isEdit ? 'Edit Wishlist' : 'Tambah Wishlist',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                    labelText: 'Nama barang',
                    hintText: 'mis. iPhone, Sepeda, Laptop'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Perkiraan harga', prefixText: 'Rp '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    labelText: 'Link pembelian (opsional)',
                    hintText: 'https://...'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WishPriority>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Prioritas'),
                items: [
                  for (final p in WishPriority.values)
                    DropdownMenuItem(
                        value: p,
                        child: Row(children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                                color: p.color, shape: BoxShape.circle),
                          ),
                          Text(p.label),
                        ])),
                ],
                onChanged: (v) => setState(() => priority = v ?? priority),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => targetDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Target tanggal (opsional)',
                    suffixIcon: targetDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => targetDate = null),
                          )
                        : const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(targetDate != null
                      ? Fmt.dateFull(targetDate!)
                      : 'Pilih tanggal'),
                ),
              ),
              const SizedBox(height: 16),
              Text('Rencana Menabung (opsional)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: monthlyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Tabung/bln', prefixText: 'Rp '),
                      // Isi tabungan -> hitung durasi otomatis.
                      onChanged: (_) => setState(recalcDuration),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Jangka', suffixText: 'bln'),
                      // Isi durasi -> hitung tabungan otomatis.
                      onChanged: (_) => setState(recalcMonthly),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Builder(builder: (context) {
                final monthly = double.tryParse(monthlyCtrl.text.trim()) ?? 0;
                final months = int.tryParse(durationCtrl.text.trim()) ?? 0;
                if (monthly <= 0 || months <= 0) {
                  return Text(
                      'Isi salah satu, yang lain dihitung otomatis.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline));
                }
                return Text(
                  'Nabung ${Fmt.rupiah(monthly)}/bln selama $months bulan.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.income),
                );
              }),
              if (accounts.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: savingAccountId,
                  decoration:
                      const InputDecoration(labelText: 'Tabung dari rekening'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => savingAccountId = v),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: reminderDay,
                decoration: const InputDecoration(
                    labelText: 'Pengingat menabung tiap tanggal'),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('Tidak ada')),
                  for (var d = 1; d <= 28; d++)
                    DropdownMenuItem(value: d, child: Text('Tanggal $d')),
                ],
                onChanged: (v) => setState(() => reminderDay = v ?? 0),
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
                            .deleteWish(existing.id);
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
                      final price = double.parse(priceCtrl.text.trim());
                      final monthly =
                          double.tryParse(monthlyCtrl.text.trim()) ?? 0;
                      final months =
                          int.tryParse(durationCtrl.text.trim()) ?? 0;
                      final ctrl = ref.read(appStateProvider.notifier);
                      if (isEdit) {
                        ctrl.updateWish(existing.copyWith(
                          name: nameCtrl.text.trim(),
                          price: price,
                          url: urlCtrl.text.trim(),
                          priority: priority,
                          targetDate: targetDate,
                          clearTargetDate: targetDate == null,
                          monthlySaving: monthly,
                          durationMonths: months,
                          reminderDay: reminderDay,
                          savingAccountId: savingAccountId,
                          clearSavingAccount: savingAccountId == null,
                        ));
                      } else {
                        ctrl.addWish(
                          name: nameCtrl.text.trim(),
                          price: price,
                          url: urlCtrl.text.trim(),
                          priority: priority,
                          targetDate: targetDate,
                          monthlySaving: monthly,
                          durationMonths: months,
                          reminderDay: reminderDay,
                          savingAccountId: savingAccountId,
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
