import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/export_service.dart';
import '../widgets/common.dart';
import '../widgets/responsive_layout.dart';
import 'monthly_expenses_screen.dart';

/// Layar Akun: kelola rekening/dompet dan catat transaksi.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.titleAccounts),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_repeat_outlined),
            tooltip: AppLocalizations.of(context)!.tooltipMonthlyExpenses,
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
        error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.errorLoadFailed}: $e')),
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
      label: Text(state.accounts.isEmpty ? AppLocalizations.of(context)!.fabAddAccount : AppLocalizations.of(context)!.fabRecordTransaction),
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
        title: AppLocalizations.of(context)!.emptyAccountTitle,
        subtitle: AppLocalizations.of(context)!.emptyAccountSubtitle,
      );
    }

    final filtered = state.transactions.where(_matches).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final byDate = groupBy<Transaction, String>(
      filtered,
      (t) => Fmt.date(t.date),
    );

    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
      children: [
        _AccountsStrip(state: state),
        SectionHeader(title: AppLocalizations.of(context)!.transactionHistory),
        if (state.transactions.isNotEmpty) _filterBar(),
        if (state.transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(AppLocalizations.of(context)!.noTransactionsMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(AppLocalizations.of(context)!.noTransactionsFilter,
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
      ),
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
              hintText: AppLocalizations.of(context)!.searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixIcon: _hasActiveFilter
                  ? IconButton(
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                      tooltip: AppLocalizations.of(context)!.tooltipClearFilter,
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
                  label: Text(AppLocalizations.of(context)!.filterAll),
                  selected: _typeFilter == null,
                  onSelected: (_) => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                for (final t in TxType.values) ...[
                  ChoiceChip(
                    label: Text(t.label(AppLocalizations.of(context)!)),
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
        PopupMenuItem(value: null, child: Text(AppLocalizations.of(context)!.filterAllAccounts)),
        for (final a in state.accounts)
          PopupMenuItem(value: a.id, child: Text(a.name)),
      ],
      child: Chip(
        avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16),
        label: Text(selectedName ?? AppLocalizations.of(context)!.accountLabel),
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
          title: AppLocalizations.of(context)!.myAccounts,
          trailing: TextButton.icon(
            onPressed: () => showAccountDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context)!.accountLabel),
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
                        ? account.type.label(AppLocalizations.of(context)!)
                        : '${account.type.label(AppLocalizations.of(context)!)} · ${account.accountNumber}',
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
        onTap: () => showTransactionDialog(context, ref, state, existing: tx),
        leading: IconBadge(icon: icon, color: color),
        title: Text(tx.note.isEmpty ? tx.type.label(AppLocalizations.of(context)!) : tx.note),
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
        title: Text('${AppLocalizations.of(context)!.deleteLabel}?'),
        content: Text(
            AppLocalizations.of(context)!.deleteTransactionWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(AppLocalizations.of(context)!.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(AppLocalizations.of(context)!.deleteLabel)),
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
      text: existing != null ? Fmt.groupInput(existing.balance) : '');
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
              Text(isEdit ? AppLocalizations.of(context)!.editAccountTitle : AppLocalizations.of(context)!.fabAddAccount,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: !isEdit,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelAccountName, hintText: AppLocalizations.of(context)!.hintAccountName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.validationRequired : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountType>(
                value: type,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.labelAccountType),
                items: [
                  for (final t in AccountType.values)
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
              if (type != AccountType.cash) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: type == AccountType.ewallet
                        ? AppLocalizations.of(context)!.labelEwalletNumber
                        : AppLocalizations.of(context)!.labelBankNumber,
                    hintText: AppLocalizations.of(context)!.hintOptional,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: InputDecoration(
                  labelText: isEdit ? AppLocalizations.of(context)!.labelBalance : AppLocalizations.of(context)!.labelInitialBalance,
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return Fmt.tryParseInput(v) == null
                      ? AppLocalizations.of(context)!.validationInvalidNumber
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
                      label: Text(AppLocalizations.of(context)!.deleteLabel,
                          style: TextStyle(color: AppTheme.expense)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final balance =
                          Fmt.tryParseInput(balanceCtrl.text) ?? 0;
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
                    child: Text(isEdit ? AppLocalizations.of(context)!.saveButton : AppLocalizations.of(context)!.addButton),
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
      title: Text('${AppLocalizations.of(context)!.deleteLabel} ${account.name}?'),
      content: Text(
          AppLocalizations.of(context)!.deleteAccountWarning),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(AppLocalizations.of(context)!.cancelButton)),
        FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(AppLocalizations.of(context)!.deleteLabel)),
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
  AppState state, {
  double? prefilledAmount,
  Transaction? existing,
}) async {
  final isEdit = existing != null;
  final amountCtrl = TextEditingController(
    text: existing != null
        ? Fmt.groupInput(existing.amount)
        : (prefilledAmount != null ? prefilledAmount.toStringAsFixed(0) : ''),
  );
  final categoryCtrl = TextEditingController(text: existing?.category ?? '');
  final categoryFocus = FocusNode();
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  final adminFeeCtrl = TextEditingController();

  final knownCategories = <String>{
    for (final t in state.transactions)
      if (t.category.trim().isNotEmpty) t.category.trim(),
  }.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  var type = existing?.type ?? TxType.expense;
  var useAdminFee = false;
  var accountId = existing?.accountId ?? state.accounts.first.id;
  String? toAccountId = existing?.toAccountId ??
      (state.accounts.length > 1 ? state.accounts[1].id : null);
  var date = existing?.date ?? DateTime.now();
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
              Text(
                isEdit
                    ? AppLocalizations.of(context)!.editTransactionTitle
                    : AppLocalizations.of(context)!.recordTransactionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<TxType>(
                segments: [
                  ButtonSegment(
                      value: TxType.expense,
                      label: Text(AppLocalizations.of(context)!.segmentExpense)),
                  ButtonSegment(
                      value: TxType.income,
                      label: Text(AppLocalizations.of(context)!.segmentIncome)),
                  ButtonSegment(
                      value: TxType.transfer,
                      label: Text(AppLocalizations.of(context)!.segmentTransfer)),
                ],
                selected: {type},
                onSelectionChanged: isEdit ? null : (s) => setState(() => type = s.first),
              ),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final source = state.accounts.firstWhere(
                  (a) => a.id == accountId,
                  orElse: () => state.accounts.first,
                );
                return TextFormField(
                  controller: amountCtrl,
                  enabled: !isEdit,
                  autofocus: !isEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelAmount,
                    prefixText: 'Rp ',
                    helperText: type == TxType.income
                        ? null
                        : AppLocalizations.of(context)!.helperBalance(source.name, Fmt.rupiah(source.balance)),
                  ),
                  validator: (v) {
                    final n = Fmt.tryParseInput(v ?? '');
                    if (n == null || n <= 0) return AppLocalizations.of(context)!.validationInvalidAmount;
                    if (!isEdit && type != TxType.income && n > source.balance) {
                      return AppLocalizations.of(context)!.validationExceedBalance(Fmt.rupiah(source.balance));
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
                        type == TxType.transfer ? AppLocalizations.of(context)!.labelFromAccount : AppLocalizations.of(context)!.accountLabel),
                items: [
                  for (final a in state.accounts)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: isEdit ? null : (v) => setState(() => accountId = v ?? accountId),
              ),
              if (type == TxType.transfer) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toAccountId,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.labelToAccount),
                  items: [
                    for (final a in state.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: isEdit ? null : (v) => setState(() => toAccountId = v),
                  validator: (v) {
                    if (type != TxType.transfer) return null;
                    if (v == null) return AppLocalizations.of(context)!.validationSelectDest;
                    if (v == accountId) return AppLocalizations.of(context)!.validationDiffAccount;
                    return null;
                  },
                ),
                SwitchListTile(
                  value: useAdminFee,
                  onChanged: isEdit ? null : (v) => setState(() => useAdminFee = v),
                  title: Text(AppLocalizations.of(context)!.adminFeeOptional),
                  subtitle: Text(
                      AppLocalizations.of(context)!.adminFeeSubtitle),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (useAdminFee)
                  Builder(builder: (context) {
                    final amt = Fmt.tryParseInput(amountCtrl.text) ?? 0;
                    final fee = Fmt.tryParseInput(adminFeeCtrl.text) ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: adminFeeCtrl,
                          enabled: !isEdit,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsInputFormatter()],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.labelAdminFee,
                            prefixText: 'Rp ',
                            helperText:
                                AppLocalizations.of(context)!.helperAdminFee,
                          ),
                          validator: (v) {
                            if (!useAdminFee) return null;
                            final n = Fmt.tryParseInput(v ?? '');
                            if (n == null || n <= 0) {
                              return AppLocalizations.of(context)!.validationAdminFee;
                            }
                            return null;
                          },
                        ),
                        if (amt > 0 && fee > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                                AppLocalizations.of(context)!.totalOut(Fmt.rupiah(amt + fee)),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.expense)),
                          ),
                      ],
                    );
                  }),
              ] else ...[
                const SizedBox(height: 12),
                RawAutocomplete<String>(
                  textEditingController: categoryCtrl,
                  focusNode: categoryFocus,
                  optionsBuilder: (value) {
                    final q = value.text.trim().toLowerCase();
                    if (q.isEmpty) return const Iterable<String>.empty();
                    return knownCategories.where((c) {
                      final low = c.toLowerCase();
                      return low.contains(q) && low != q;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.labelCategory,
                          hintText: AppLocalizations.of(context)!.hintCategory),
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
                              leading: const Icon(Icons.category_outlined, size: 18),
                              title: Text(list[i]),
                              onTap: () => onSelected(list[i]),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                autofocus: isEdit,
                decoration:
                    InputDecoration(labelText: AppLocalizations.of(context)!.labelNote),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: isEdit
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2015),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) setState(() => date = picked);
                      },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.labelDate),
                  child: Text(Fmt.dateFull(date)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = Fmt.tryParseInput(amountCtrl.text)!;
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final String? error;
                    if (isEdit) {
                      error = await ref
                          .read(appStateProvider.notifier)
                          .updateTransaction(
                            id: existing.id,
                            type: type,
                            amount: amount,
                            accountId: accountId,
                            toAccountId:
                                type == TxType.transfer ? toAccountId : null,
                            category: categoryCtrl.text.trim(),
                            note: noteCtrl.text.trim(),
                            adminFee: type == TxType.transfer && useAdminFee
                                ? (Fmt.tryParseInput(adminFeeCtrl.text) ?? 0)
                                : 0,
                            date: date,
                          );
                    } else {
                      error = await ref
                          .read(appStateProvider.notifier)
                          .addTransaction(
                            type: type,
                            amount: amount,
                            accountId: accountId,
                            toAccountId:
                                type == TxType.transfer ? toAccountId : null,
                            category: categoryCtrl.text.trim(),
                            note: noteCtrl.text.trim(),
                            adminFee: type == TxType.transfer && useAdminFee
                                ? (Fmt.tryParseInput(adminFeeCtrl.text) ?? 0)
                                : 0,
                            date: date,
                          );
                    }
                    if (error != null) {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    navigator.pop();
                  },
                  child: Text(AppLocalizations.of(context)!.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
