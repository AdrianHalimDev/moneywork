import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.tabWishlist)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWishDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.tabWishlist),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.snackFailed} $e')),
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
      return EmptyState(
        icon: Icons.favorite_outline,
        title: AppLocalizations.of(context)!.emptyWishlistTitle,
        subtitle: AppLocalizations.of(context)!.emptyWishlistSubtitle,
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
              title: Text(AppLocalizations.of(context)!.totalTargetBelanja),
              subtitle: Text(AppLocalizations.of(context)!.barangBelumDibeli(pending.length.toString())),
              trailing: Text(Fmt.rupiah(totalPending),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        for (final w in pending) _WishTile(item: w),
        if (done.isNotEmpty) ...[
          SectionHeader(title: AppLocalizations.of(context)!.sudahDibeli),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.gagalMembukaLink)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final target = item.targetDate;
    final subtitleParts = <String>[
      item.priority.label(AppLocalizations.of(context)!),
      if (target != null) '${l10n.targetDateLabel} ${Fmt.date(target)}',
      if (item.monthlySaving > 0)
        '${Fmt.rupiahCompact(item.monthlySaving)}${l10n.savingPerMonthSuffix}',
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
              '${l10n.savingProgressLabel(Fmt.rupiah(item.savedAmount), Fmt.rupiah(item.price))}'
              '${item.monthsRemaining > 0 ? l10n.savingMonthsRemaining(item.monthsRemaining.toString()) : ''}',
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
              tooltip: l10n.tooltipCatatNabung,
              onPressed: () => _showContribute(context, ref),
            )
          else
            Text(Fmt.rupiah(item.price),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          if (item.url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: l10n.tooltipBukaLink,
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
            ? Fmt.groupInput(item.monthlySaving)
            : '');
    final formKey = GlobalKey<FormState>();
    final accounts =
        ref.read(appStateProvider).valueOrNull?.accounts ?? const [];
    // Default ke rekening tabungan wishlist bila masih ada, jika tidak rekening
    // pertama. Boleh juga null = catat progres tanpa memotong saldo.
    String? accountId = accounts.any((a) => a.id == item.savingAccountId)
        ? item.savingAccountId
        : (accounts.isNotEmpty ? accounts.first.id : null);

    await showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.dialogNabungTitle(item.name)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.savingProgressLabel(Fmt.rupiah(item.savedAmount), Fmt.rupiah(item.price))),
                const SizedBox(height: 4),
                Text(l10n.dialogNabungSisa(Fmt.rupiah(item.remainingToSave)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  decoration: InputDecoration(
                      labelText: l10n.dialogNabungJumlah, prefixText: 'Rp '),
                  validator: (v) {
                    final n = Fmt.tryParseInput(v ?? '');
                    if (n == null || n <= 0) return l10n.invalidNumber;
                    return null;
                  },
                ),
                if (accounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: accountId,
                    decoration:
                        InputDecoration(labelText: l10n.dialogNabungAmbilDari),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(l10n.dialogNabungTanpaPotong)),
                      for (final a in accounts)
                        DropdownMenuItem(
                            value: a.id,
                            child: Text(
                                '${a.name} · ${Fmt.rupiah(a.balance)}')),
                    ],
                    onChanged: (v) => setState(() => accountId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancelButton)),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final error = await ref
                    .read(appStateProvider.notifier)
                    .contributeToWish(
                      item.id,
                      Fmt.tryParseInput(ctrl.text)!,
                      accountId: accountId,
                    );
                if (error != null) {
                  messenger.showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                navigator.pop();
              },
              child: Text(l10n.recordButton),
            ),
          ],
        ),
      );
      },
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
      text: existing != null ? Fmt.groupInput(existing.price) : '');
  final urlCtrl = TextEditingController(text: existing?.url ?? '');
  final monthlyCtrl = TextEditingController(
      text: existing != null && existing.monthlySaving > 0
          ? Fmt.groupInput(existing.monthlySaving)
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
    final price = Fmt.tryParseInput(priceCtrl.text) ?? 0;
    final monthly = Fmt.tryParseInput(monthlyCtrl.text) ?? 0;
    if (price > 0 && monthly > 0) {
      durationCtrl.text = (price / monthly).ceil().toString();
    }
  }

  // Kalkulator dua-arah: hitung tabungan bulanan dari jangka waktu.
  void recalcMonthly() {
    final price = Fmt.tryParseInput(priceCtrl.text) ?? 0;
    final months = int.tryParse(durationCtrl.text.trim()) ?? 0;
    if (price > 0 && months > 0) {
      monthlyCtrl.text = Fmt.groupInput((price / months).ceil());
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return StatefulBuilder(
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
              Text(isEdit ? l10n.editWishlist : l10n.addWishlist,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: InputDecoration(
                    labelText: l10n.itemNameLabel,
                    hintText: l10n.itemNameHint),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: InputDecoration(
                    labelText: l10n.estPriceLabel, prefixText: 'Rp '),
                validator: (v) {
                  final n = Fmt.tryParseInput(v ?? '');
                  if (n == null || n < 0) return l10n.invalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                    labelText: l10n.linkOptionalLabel,
                    hintText: 'https://...'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WishPriority>(
                initialValue: priority,
                decoration: InputDecoration(labelText: l10n.priorityLabel),
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
                          Text(p.label(AppLocalizations.of(context)!)),
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
                    labelText: l10n.targetDateOptionalLabel,
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
                      : l10n.selectDate),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.savingPlanOptional,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: monthlyCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsInputFormatter()],
                      decoration: InputDecoration(
                          labelText: l10n.savePerMonthLabel, prefixText: 'Rp '),
                      // Isi tabungan -> hitung durasi otomatis.
                      onChanged: (_) => setState(recalcDuration),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: l10n.durationLabel, suffixText: l10n.monthSuffix),
                      // Isi durasi -> hitung tabungan otomatis.
                      onChanged: (_) => setState(recalcMonthly),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Builder(builder: (context) {
                final monthly = Fmt.tryParseInput(monthlyCtrl.text) ?? 0;
                final months = int.tryParse(durationCtrl.text.trim()) ?? 0;
                if (monthly <= 0 || months <= 0) {
                  return Text(
                      l10n.calcHelperText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline));
                }
                return Text(
                  l10n.nabungSelamaHelper(Fmt.rupiah(monthly), months.toString()),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.income),
                );
              }),
              if (accounts.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: savingAccountId,
                  decoration:
                      InputDecoration(labelText: l10n.saveFromAccountLabel),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.noneOption)),
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => savingAccountId = v),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: reminderDay,
                decoration: InputDecoration(
                    labelText: l10n.reminderDayLabel),
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.noReminder)),
                  for (var d = 1; d <= 28; d++)
                    DropdownMenuItem(value: d, child: Text(l10n.dateSuffix(d.toString()))),
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
                      label: Text(l10n.deleteLabel,
                          style: const TextStyle(color: AppTheme.expense)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final price = Fmt.tryParseInput(priceCtrl.text)!;
                      final monthly =
                          Fmt.tryParseInput(monthlyCtrl.text) ?? 0;
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
                    child: Text(isEdit ? l10n.saveButton : l10n.addButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      );
    },
  );
}
