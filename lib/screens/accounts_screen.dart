import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../widgets/common.dart';
import 'monthly_expenses_screen.dart';

/// Layar Akun: kelola rekening/dompet dan catat transaksi.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun & Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_repeat_outlined),
            tooltip: 'Transaksi Bulanan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const MonthlyExpensesScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: async.maybeWhen(
        data: (state) => _Fab(state: state),
        orElse: () => null,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (state) => _Body(state: state),
      ),
    );
  }
}

class _Fab extends ConsumerWidget {
  const _Fab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: state.accounts.isEmpty
          ? () => showAccountDialog(context, ref)
          : () => showTransactionDialog(context, ref, state),
      icon: Icon(state.accounts.isEmpty ? Icons.add_card : Icons.add),
      label: Text(state.accounts.isEmpty ? 'Tambah Akun' : 'Catat Transaksi'),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.state});
  final AppState state;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  TxType? _typeFilter; // null = semua
  String? _accountFilter; // null = semua
  String _query = '';

  AppState get state => widget.state;

  bool _matches(Transaction t) {
    if (_typeFilter != null && t.type != _typeFilter) return false;
    if (_accountFilter != null &&
        t.accountId != _accountFilter &&
        t.toAccountId != _accountFilter) {
      return false;
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      final hay = '${t.note} ${t.category}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  bool get _hasActiveFilter =>
      _typeFilter != null || _accountFilter != null || _query.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (state.accounts.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Belum ada akun',
        subtitle: 'Tambahkan rekening, dompet tunai, atau e-wallet\n'
            'untuk mulai mencatat keuangan.',
      );
    }

    final filtered = state.transactions.where(_matches).toList();
    final byDate = groupBy<Transaction, String>(
      filtered,
      (t) => Fmt.date(t.date),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _AccountsStrip(state: state),
        const SectionHeader(title: 'Riwayat Transaksi'),
        if (state.transactions.isNotEmpty) _filterBar(),
        if (state.transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Belum ada transaksi.',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Tidak ada transaksi yang cocok dengan filter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
          )
        else
          for (final entry in byDate.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(entry.key,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
            ),
            for (final tx in entry.value) _TxRow(tx: tx, state: state),
          ],
      ],
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari catatan / kategori',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixIcon: _hasActiveFilter
                  ? IconButton(
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                      tooltip: 'Hapus filter',
                      onPressed: () => setState(() {
                        _typeFilter = null;
                        _accountFilter = null;
                        _query = '';
                      }),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filter jenis transaksi.
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _typeFilter == null,
                  onSelected: (_) => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                for (final t in TxType.values) ...[
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _typeFilter == t,
                    onSelected: (_) => setState(() => _typeFilter = t),
                  ),
                  const SizedBox(width: 8),
                ],
                // Filter akun.
                _accountFilterChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountFilterChip() {
    final selectedName = _accountFilter == null
        ? null
        : state.accounts
            .firstWhere((a) => a.id == _accountFilter,
                orElse: () => state.accounts.first)
            .name;
    return PopupMenuButton<String?>(
      onSelected: (v) => setState(() => _accountFilter = v),
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Semua akun')),
        for (final a in state.accounts)
          PopupMenuItem(value: a.id, child: Text(a.name)),
      ],
      child: Chip(
        avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16),
        label: Text(selectedName ?? 'Akun'),
        deleteIcon: const Icon(Icons.arrow_drop_down, size: 18),
        onDeleted: null,
      ),
    );
  }
}

/// Daftar kartu akun horizontal.
class _AccountsStrip extends ConsumerWidget {
  const _AccountsStrip({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Akun Saya',
          trailing: TextButton.icon(
            onPressed: () => showAccountDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Akun'),
          ),
        ),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.accounts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final a = state.accounts[i];
              return _AccountCard(account: a);
            },
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showAccountDialog(context, ref, existing: account),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(account.type.icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    account.accountNumber.isEmpty
                        ? account.type.label
                        : '${account.type.label} · ${account.accountNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Fmt.rupiah(account.balance),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends ConsumerWidget {
  const _TxRow({required this.tx, required this.state});
  final Transaction tx;
  final AppState state;

  String _accountName(String id) {
    final m = state.accounts.where((a) => a.id == id);
    return m.isEmpty ? '-' : m.first.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = switch (tx.type) {
      TxType.income => (Icons.south_west, AppTheme.income),
      TxType.expense => (Icons.north_east, AppTheme.expense),
      TxType.transfer => (Icons.swap_horiz, AppTheme.investment),
    };
    final subtitle = tx.type == TxType.transfer
        ? '${_accountName(tx.accountId)} → ${_accountName(tx.toAccountId ?? '')}'
        : [
            if (tx.category.isNotEmpty) tx.category,
            _accountName(tx.accountId),
          ].join(' · ');

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppTheme.expense.withValues(alpha: 0.12),
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppTheme.expense),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          ref.read(appStateProvider.notifier).deleteTransaction(tx.id),
      child: ListTile(
        leading: IconBadge(icon: icon, color: color),
        title: Text(tx.note.isEmpty ? tx.type.label : tx.note),
        subtitle: Text(subtitle),
        trailing: Text(Fmt.rupiahSigned(tx.signedAmount),
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        // Geser ke kiri untuk hapus, atau tahan (long-press) bila gestur geser
        // sulit — keduanya melalui konfirmasi yang sama.
        onLongPress: () async {
          final ctrl = ref.read(appStateProvider.notifier);
          if (await _confirmDelete(context)) {
            await ctrl.deleteTransaction(tx.id);
          }
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      // Pakai context milik dialog (dialogCtx) untuk pop — bukan context baris,
      // yang resolve ke navigator halaman dan malah menutup layar (layar hitam).
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text(
            'Saldo akun akan disesuaikan kembali. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    return ok ?? false;
  }
}

// ============================================================================
// Dialog: tambah/edit akun
// ============================================================================

Future<void> showAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  Account? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final balanceCtrl = TextEditingController(
      text: existing != null ? existing.balance.toStringAsFixed(0) : '');
  final numberCtrl =
      TextEditingController(text: existing?.accountNumber ?? '');
  var type = existing?.type ?? AccountType.bank;
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
              Text(isEdit ? 'Edit Akun' : 'Tambah Akun',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                    labelText: 'Nama akun', hintText: 'mis. BCA, GoPay, Dompet'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Jenis'),
                items: [
                  for (final t in AccountType.values)
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
              if (type != AccountType.cash) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: type == AccountType.ewallet
                        ? 'Nomor HP / akun e-wallet'
                        : 'Nomor rekening',
                    hintText: 'opsional',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Saldo' : 'Saldo awal',
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v.trim()) == null
                      ? 'Angka tidak valid'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (isEdit)
                    TextButton.icon(
                      onPressed: () async {
                        // Konfirmasi dulu (sheet masih terbuka → context valid),
                        // baru hapus, lalu tutup sheet. Memanggil dialog setelah
                        // pop sebelumnya membuat dialog tak pernah muncul.
                        final navigator = Navigator.of(context);
                        final ctrl = ref.read(appStateProvider.notifier);
                        final confirmed =
                            await _confirmDeleteAccount(context, existing);
                        if (!confirmed) return;
                        await ctrl.deleteAccount(existing.id);
                        navigator.pop();
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
                      final balance =
                          double.tryParse(balanceCtrl.text.trim()) ?? 0;
                      // Nomor rekening tidak berlaku untuk akun tunai.
                      final number = type == AccountType.cash
                          ? ''
                          : numberCtrl.text.trim();
                      final ctrl = ref.read(appStateProvider.notifier);
                      if (isEdit) {
                        ctrl.updateAccount(existing.copyWith(
                            name: nameCtrl.text.trim(),
                            type: type,
                            balance: balance,
                            accountNumber: number));
                      } else {
                        ctrl.addAccount(
                            name: nameCtrl.text.trim(),
                            type: type,
                            initialBalance: balance,
                            accountNumber: number);
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

Future<bool> _confirmDeleteAccount(
    BuildContext context, Account account) async {
  final ok = await showDialog<bool>(
    context: context,
    // Pop pakai context dialog (dialogCtx). Bila pakai context bottom sheet,
    // pop salah sasaran: dialog tak tertutup & future menggantung (stuck).
    builder: (dialogCtx) => AlertDialog(
      title: Text('Hapus ${account.name}?'),
      content: const Text(
          'Semua transaksi terkait akun ini juga akan dihapus.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal')),
        FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Hapus')),
      ],
    ),
  );
  return ok ?? false;
}

// ============================================================================
// Dialog: catat transaksi
// ============================================================================

Future<void> showTransactionDialog(
  BuildContext context,
  WidgetRef ref,
  AppState state,
) async {
  final amountCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var type = TxType.expense;
  var accountId = state.accounts.first.id;
  String? toAccountId =
      state.accounts.length > 1 ? state.accounts[1].id : null;
  var date = DateTime.now();
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
              Text('Catat Transaksi',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<TxType>(
                segments: const [
                  ButtonSegment(
                      value: TxType.expense, label: Text('Keluar')),
                  ButtonSegment(value: TxType.income, label: Text('Masuk')),
                  ButtonSegment(
                      value: TxType.transfer, label: Text('Transfer')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
              ),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final source = state.accounts.firstWhere(
                  (a) => a.id == accountId,
                  orElse: () => state.accounts.first,
                );
                return TextFormField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    prefixText: 'Rp ',
                    helperText: type == TxType.income
                        ? null
                        : 'Saldo ${source.name}: ${Fmt.rupiah(source.balance)}',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return 'Masukkan jumlah valid';
                    if (type != TxType.income && n > source.balance) {
                      return 'Melebihi saldo (${Fmt.rupiah(source.balance)})';
                    }
                    return null;
                  },
                );
              }),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: accountId,
                decoration: InputDecoration(
                    labelText:
                        type == TxType.transfer ? 'Dari akun' : 'Akun'),
                items: [
                  for (final a in state.accounts)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => accountId = v ?? accountId),
              ),
              if (type == TxType.transfer) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toAccountId,
                  decoration: const InputDecoration(labelText: 'Ke akun'),
                  items: [
                    for (final a in state.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => toAccountId = v),
                  validator: (v) {
                    if (type != TxType.transfer) return null;
                    if (v == null) return 'Pilih akun tujuan';
                    if (v == accountId) return 'Pilih akun berbeda';
                    return null;
                  },
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'mis. Makan, Gaji, Transport'),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Catatan (opsional)'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tanggal'),
                  child: Text(Fmt.dateFull(date)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = double.parse(amountCtrl.text.trim());
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final error = await ref
                        .read(appStateProvider.notifier)
                        .addTransaction(
                          type: type,
                          amount: amount,
                          accountId: accountId,
                          toAccountId:
                              type == TxType.transfer ? toAccountId : null,
                          category: categoryCtrl.text.trim(),
                          note: noteCtrl.text.trim(),
                          date: date,
                        );
                    if (error != null) {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    navigator.pop();
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
