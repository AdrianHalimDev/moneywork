import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../widgets/common.dart';
import '../widgets/responsive_layout.dart';
import '../data/display_preferences.dart';
import '../widgets/display_controls.dart';
import '../widgets/sync_indicator.dart';
import '../widgets/dialogs/transaction_editor.dart';
import '../widgets/display_order_sheet.dart';
import 'finance_tools_screen.dart';

/// Layar Akun: kelola rekening/dompet dan catat transaksi.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStateProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navAccounts),
        actions: [
          const AmountVisibilityButton(),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const FinanceToolsScreen())),
            icon: const Icon(Icons.grid_view_outlined, size: 18),
            label: Text(l10n.focusToolsShort),
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(28),
            child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: SyncIndicator(showLabel: true)))),
      ),
      floatingActionButton: async.maybeWhen(
        data: (state) => _Fab(state: state),
        orElse: () => null,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const FriendlyLoadError(),
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
      onPressed: state.orderedAccounts.isEmpty
          ? () => showAccountDialog(context, ref)
          : () => showTransactionDialog(context, ref, state),
      icon: Icon(state.orderedAccounts.isEmpty ? Icons.add_card : Icons.add),
      label: Text(state.orderedAccounts.isEmpty
          ? AppLocalizations.of(context)!.fabAddAccount
          : AppLocalizations.of(context)!.fabRecordTransaction),
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
    if (state.orderedAccounts.isEmpty) {
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
      child: LayoutBuilder(
          builder: (context, constraints) => ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  const SyncStatusBanner(),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Card(
                          color: AppTheme.heroBackground(context),
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        AppLocalizations.of(context)!
                                            .accountsBalance,
                                        style: const TextStyle(
                                            color: AppTheme.heroForeground)),
                                    const SizedBox(height: 10),
                                    Text(
                                        formatVisibleMoney(
                                            ref, state.totalCash),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                                color: AppTheme.heroForeground,
                                                fontWeight: FontWeight.w600)),
                                  ])))),
                  _AccountsStrip(state: state),
                  SectionHeader(
                      title: AppLocalizations.of(context)!.transactionHistory),
                  if (state.transactions.isNotEmpty) _filterBar(),
                  if (state.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                            AppLocalizations.of(context)!.noTransactionsMessage,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                      ),
                    )
                  else if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                            AppLocalizations.of(context)!.noTransactionsFilter,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                      ),
                    )
                  else if (constraints.maxWidth >= 760 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 18)
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _TransactionsTable(
                                    transactions: filtered, state: state))))
                  else
                    for (final entry in byDate.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline)),
                      ),
                      for (final tx in entry.value)
                        _TxRow(tx: tx, state: state),
                    ],
                ],
              )),
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
        : state.orderedAccounts
            .firstWhere((a) => a.id == _accountFilter,
                orElse: () => state.orderedAccounts.first)
            .name;
    return PopupMenuButton<String?>(
      onSelected: (v) => setState(() => _accountFilter = v),
      itemBuilder: (context) => [
        PopupMenuItem(
            value: null,
            child: Text(AppLocalizations.of(context)!.filterAllAccounts)),
        for (final a in state.orderedAccounts)
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
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    key: const ValueKey('reorder-accounts'),
                    onPressed: () => showAccountOrderSheet(context, state),
                    icon: const Icon(Icons.tune, size: 18),
                    label:
                        Text(AppLocalizations.of(context)!.reorderAccounts)))),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 950
              ? 3
              : constraints.maxWidth >= 650
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - 32 - (columns - 1) * 12) / columns;
          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 12, runSpacing: 12, children: [
                for (final account in state.orderedAccounts)
                  SizedBox(
                      width: width,
                      height: MediaQuery.textScalerOf(context).scale(14) > 18
                          ? 160
                          : 124,
                      child: _AccountCard(account: account)),
              ]));
        }),
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
      key: ValueKey('account-card-${account.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => showAccountDetails(context, account.id),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(account.type.icon,
                    size: 20, color: theme.colorScheme.primary),
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
                    account.accountNumber.isEmpty ||
                            ref.watch(amountsHiddenProvider)
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
                  child: Text(formatVisibleMoney(ref, account.balance),
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

class _TransactionsTable extends ConsumerWidget {
  const _TransactionsTable({required this.transactions, required this.state});
  final List<Transaction> transactions;
  final AppState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
        width: double.infinity,
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 16,
          horizontalMargin: 8,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 88,
          columns: [
            DataColumn(label: Text(l10n.transactionHistory)),
            DataColumn(label: Text(l10n.accountLabel)),
            DataColumn(label: Text(l10n.amountLabel), numeric: true),
            const DataColumn(label: SizedBox.shrink())
          ],
          rows: [
            for (final tx in transactions)
              DataRow(
                  onSelectChanged: (_) =>
                      showTransactionDialog(context, ref, state, existing: tx),
                  cells: [
                    DataCell(SizedBox(
                        width: 190,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  tx.note.isEmpty
                                      ? tx.type.label(l10n)
                                      : tx.note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              Text('${tx.category} · ${Fmt.date(tx.date)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ]))),
                    DataCell(SizedBox(
                        width: 110,
                        child: Text(
                            tx.type == TxType.transfer
                                ? '${_name(tx.accountId)} → ${_name(tx.toAccountId ?? '')}'
                                : _name(tx.accountId),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis))),
                    DataCell(Text(
                        formatVisibleMoney(ref, tx.signedAmount, signed: true),
                        style: TextStyle(
                            color: tx.type == TxType.income
                                ? Theme.of(context).colorScheme.primary
                                : tx.type == TxType.expense
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface))),
                    DataCell(IconButton(
                        tooltip: l10n.deleteLabel,
                        icon: const Icon(Icons.delete_outline, size: 19),
                        onPressed: () async {
                          final ctrl = ref.read(appStateProvider.notifier);
                          if (await _TxRow(tx: tx, state: state)
                              ._confirmDelete(context)) {
                            await ctrl.deleteTransaction(tx.id);
                          }
                        })),
                  ]),
          ],
        ));
  }

  String _name(String id) =>
      state.orderedAccounts
          .where((a) => a.id == id)
          .map((a) => a.name)
          .firstOrNull ??
      '-';
}

class _TxRow extends ConsumerWidget {
  const _TxRow({required this.tx, required this.state});
  final Transaction tx;
  final AppState state;

  String _accountName(String id) {
    final m = state.orderedAccounts.where((a) => a.id == id);
    return m.isEmpty ? '-' : m.first.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = switch (tx.type) {
      TxType.income => (
          Icons.south_west,
          Theme.of(context).colorScheme.primary
        ),
      TxType.expense => (Icons.north_east, Theme.of(context).colorScheme.error),
      TxType.transfer => (
          Icons.swap_horiz,
          Theme.of(context).colorScheme.tertiary
        ),
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
        title: Text(tx.note.isEmpty
            ? tx.type.label(AppLocalizations.of(context)!)
            : tx.note),
        subtitle: Text(subtitle),
        trailing: Text(formatVisibleMoney(ref, tx.signedAmount, signed: true),
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
        content: Text(AppLocalizations.of(context)!.deleteTransactionWarning),
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
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: false,
    clipBehavior: Clip.antiAlias,
    builder: (context) => LayoutBuilder(builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: (constraints.maxHeight - keyboard - 8)
              .clamp(0.0, 660.0)
              .toDouble(),
          child: _AccountEditor(existing: existing),
        ),
      );
    }),
  );
}

class _AccountEditor extends ConsumerStatefulWidget {
  const _AccountEditor({this.existing});
  final Account? existing;

  @override
  ConsumerState<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<_AccountEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _number;
  late AccountType _type;
  bool _busy = false;
  String? _error;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _balance =
        TextEditingController(text: Fmt.groupInput(existing?.balance ?? 0));
    _number = TextEditingController(text: existing?.accountNumber ?? '');
    _type = existing?.type ?? AccountType.bank;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _number.dispose();
    super.dispose();
  }

  Account? _liveAccount() => ref
      .read(appStateProvider)
      .valueOrNull
      ?.accounts
      .where((account) => account.id == widget.existing?.id)
      .firstOrNull;

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final balance = Fmt.tryParseInput(_balance.text) ?? 0;
    Account? updated;
    final original = widget.existing;
    if (original != null) {
      final live = _liveAccount();
      if (live == null) {
        setState(() => _error = l10n.focusAccountMissing);
        return;
      }
      final balanceEdited = balance != original.balance;
      // A name-only edit must not restore a balance from before a new transaction.
      if (balanceEdited && live.balance != original.balance) {
        setState(() => _error = l10n.focusAccountBalanceChanged);
        return;
      }
      final nextType = _type == original.type ? live.type : _type;
      updated = live.copyWith(
        name:
            _name.text.trim() == original.name ? live.name : _name.text.trim(),
        type: nextType,
        balance: balanceEdited ? balance : live.balance,
        accountNumber: nextType == AccountType.cash
            ? ''
            : _number.text.trim() == original.accountNumber
                ? live.accountNumber
                : _number.text.trim(),
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final controller = ref.read(appStateProvider.notifier);
      if (updated != null) {
        await controller.updateAccount(updated);
      } else {
        await controller.addAccount(
            name: _name.text.trim(),
            type: _type,
            initialBalance: balance,
            accountNumber:
                _type == AccountType.cash ? '' : _number.text.trim());
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.focusAccountSaveFailed;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final live = _liveAccount();
    if (live == null) {
      setState(() => _error = l10n.focusAccountMissing);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Confirm while the editor is mounted; the dialog uses its own navigator.
      final confirmed = await _confirmDeleteAccount(context, live);
      if (!mounted) return;
      if (!confirmed) {
        setState(() => _busy = false);
        return;
      }
      await ref.read(appStateProvider.notifier).deleteAccount(live.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.focusAccountSaveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_busy,
      child: Material(
        color: colors.surface,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(children: [
                Expanded(
                    child: Text(
                        _isEdit ? l10n.editAccountTitle : l10n.fabAddAccount,
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close)),
              ])),
          const Divider(height: 1),
          Expanded(
              child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              key: const ValueKey('account-editor-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('account-editor-name'),
                      controller: _name,
                      enabled: !_busy,
                      autofocus: !_isEdit,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                          labelText: l10n.labelAccountName,
                          hintText: l10n.hintAccountName),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? l10n.validationRequired
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AccountType>(
                      key: const ValueKey('account-editor-type'),
                      initialValue: _type,
                      isExpanded: true,
                      decoration:
                          InputDecoration(labelText: l10n.labelAccountType),
                      items: [
                        for (final type in AccountType.values)
                          DropdownMenuItem(
                              value: type,
                              child: Row(children: [
                                Icon(type.icon, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                    child: Text(type.label(l10n),
                                        overflow: TextOverflow.ellipsis)),
                              ]))
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _type = value ?? _type),
                    ),
                    if (_type != AccountType.cash) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('account-editor-number'),
                        controller: _number,
                        enabled: !_busy,
                        decoration: InputDecoration(
                            labelText: _type == AccountType.ewallet
                                ? l10n.labelEwalletNumber
                                : l10n.labelBankNumber,
                            hintText: l10n.hintOptional),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('account-editor-balance'),
                      controller: _balance,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsInputFormatter()],
                      decoration: InputDecoration(
                          labelText: _isEdit
                              ? l10n.labelBalance
                              : l10n.labelInitialBalance,
                          prefixText: 'Rp '),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final balance = Fmt.tryParseInput(value);
                        return balance == null || !balance.isFinite
                            ? l10n.validationInvalidNumber
                            : null;
                      },
                    ),
                  ]),
            ),
          )),
          DecoratedBox(
              decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  border:
                      Border(top: BorderSide(color: colors.outlineVariant))),
              child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Text(_error!,
                                key: const ValueKey('account-editor-error'),
                                style: TextStyle(color: colors.error)),
                            const SizedBox(height: 8),
                          ],
                          Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                if (_isEdit)
                                  TextButton.icon(
                                      key: const ValueKey(
                                          'account-editor-delete'),
                                      onPressed: _busy ? null : _delete,
                                      icon: Icon(Icons.delete_outline,
                                          color: colors.error),
                                      label: Text(l10n.deleteLabel,
                                          style:
                                              TextStyle(color: colors.error))),
                                FilledButton(
                                    key: const ValueKey('account-editor-save'),
                                    onPressed: _busy ? null : _save,
                                    child: _busy
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : Text(_isEdit
                                            ? l10n.saveButton
                                            : l10n.addButton)),
                              ]),
                        ]),
                  ))),
        ]),
      ),
    );
  }
}

Future<bool> _confirmDeleteAccount(
    BuildContext context, Account account) async {
  final ok = await showDialog<bool>(
    context: context,
    // Pop pakai context dialog (dialogCtx). Bila pakai context bottom sheet,
    // pop salah sasaran: dialog tak tertutup & future menggantung (stuck).
    builder: (dialogCtx) => AlertDialog(
      title:
          Text('${AppLocalizations.of(context)!.deleteLabel} ${account.name}?'),
      content: Text(AppLocalizations.of(context)!.deleteAccountWarning),
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
  String? initialAccountId,
}) =>
    showFocusTransactionEditor(context, ref, state,
        prefilledAmount: prefilledAmount,
        existing: existing,
        initialAccountId: initialAccountId);

Future<void> showAccountDetails(BuildContext context, String accountId) =>
    Navigator.of(context, rootNavigator: true).push<void>(MaterialPageRoute(
        builder: (_) => AccountDetailsScreen(accountId: accountId)));

class AccountDetailsScreen extends ConsumerWidget {
  const AccountDetailsScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(appStateProvider);
    final state = async.valueOrNull;
    final account = state?.accounts.where((a) => a.id == accountId).firstOrNull;
    return Scaffold(
      key: ValueKey('account-detail-$accountId'),
      appBar: AppBar(
        title: Text(account?.name ?? l10n.focusAccountDetails),
        actions: [
          const AmountVisibilityButton(),
          if (account != null)
            IconButton(
              key: const ValueKey('edit-account-details'),
              tooltip: l10n.editAccount,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showAccountDialog(context, ref, existing: account),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const FriendlyLoadError(),
        data: (current) {
          final live =
              current.accounts.where((a) => a.id == accountId).firstOrNull;
          if (live == null) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.focusAccountMissing)));
          }
          final transactions = current.transactions
              .where((tx) =>
                  tx.accountId == accountId || tx.toAccountId == accountId)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return ResponsiveCenter(
              child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              const SyncStatusBanner(),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.focusAccountBalance,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text(formatVisibleMoney(ref, live.balance),
                              key: const ValueKey('account-detail-balance'),
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 12),
                          Text(live.type.label(l10n)),
                          if (live.accountNumber.isNotEmpty &&
                              !ref.watch(amountsHiddenProvider))
                            Text(live.accountNumber,
                                style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                              onPressed: () => showTransactionDialog(
                                  context, ref, current,
                                  initialAccountId: live.id),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.focusRecordHere)),
                        ],
                      ))),
              const SizedBox(height: 20),
              Text(l10n.transactionHistory,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (transactions.isEmpty)
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(l10n.noTransactionsMessage)),
              for (final tx in transactions)
                _AccountHistoryRow(
                    tx: tx, state: current, accountId: accountId),
            ],
          ));
        },
      ),
    );
  }
}

class _AccountHistoryRow extends ConsumerWidget {
  const _AccountHistoryRow(
      {required this.tx, required this.state, required this.accountId});
  final Transaction tx;
  final AppState state;
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final receivedTransfer =
        tx.type == TxType.transfer && tx.toAccountId == accountId;
    final amount = receivedTransfer ? tx.amount : tx.signedAmount;
    final color = amount >= 0
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    final source =
        state.accounts.where((a) => a.id == tx.accountId).firstOrNull?.name ??
            '-';
    final destination =
        state.accounts.where((a) => a.id == tx.toAccountId).firstOrNull?.name ??
            '-';
    return Card(
        child: ListTile(
      onTap: () => showTransactionDialog(context, ref, state, existing: tx),
      leading: Icon(
          tx.type == TxType.transfer
              ? Icons.swap_horiz
              : amount >= 0
                  ? Icons.south_west
                  : Icons.north_east,
          color: color),
      title: Text(tx.note.isEmpty ? tx.type.label(l10n) : tx.note),
      subtitle: Text([
        if (tx.type == TxType.transfer) '$source → $destination',
        if (tx.category.isNotEmpty) tx.category,
        Fmt.date(tx.date),
      ].join(' · ')),
      trailing: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .38),
          child: Text(formatVisibleMoney(ref, amount, signed: true),
              style: TextStyle(color: color, fontWeight: FontWeight.w600))),
    ));
  }
}
