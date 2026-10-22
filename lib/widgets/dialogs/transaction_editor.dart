import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/app_controller.dart';
import '../../data/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';

/// A keyboard-safe editor shared by the mobile application and the website.
/// Account selections always refer to IDs, independently of display ordering.
Future<void> showFocusTransactionEditor(
  BuildContext context,
  WidgetRef ref,
  AppState state, {
  double? prefilledAmount,
  Transaction? existing,
  String? initialAccountId,
}) async {
  if (state.accounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.transactionNoAccounts),
    ));
    return;
  }
  final desktop = MediaQuery.sizeOf(context).width >= 840;
  Widget editor() => _TransactionEditor(
        state: state,
        prefilledAmount: prefilledAmount,
        existing: existing,
        initialAccountId: initialAccountId,
        desktop: desktop,
      );
  if (desktop) {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        final media = MediaQuery.of(context);
        return Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SizedBox(
            width: 920,
            height:
                math.min(760, media.size.height - media.viewInsets.bottom - 48),
            child: editor(),
          ),
        );
      },
    );
  } else {
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
            height: math.max(0, constraints.maxHeight - keyboard - 8),
            child: editor(),
          ),
        );
      }),
    );
  }
}

class _TransactionEditor extends ConsumerStatefulWidget {
  const _TransactionEditor({
    required this.state,
    required this.desktop,
    this.prefilledAmount,
    this.existing,
    this.initialAccountId,
  });

  final AppState state;
  final bool desktop;
  final double? prefilledAmount;
  final Transaction? existing;
  final String? initialAccountId;

  @override
  ConsumerState<_TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends ConsumerState<_TransactionEditor> {
  final _formKey = GlobalKey<FormState>();
  final _categoryFocus = FocusNode();
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _note;
  late final TextEditingController _fee;
  late final List<String> _knownCategories;
  late TxType _type;
  late String _sourceId;
  String? _destinationId;
  late DateTime _date;
  bool _useFee = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;
  List<Account> get _accounts => widget.state.orderedAccounts;
  Account get _source => _accounts.firstWhere(
        (account) => account.id == _sourceId,
        orElse: () => _accounts.first,
      );
  double get _amountValue => Fmt.tryParseInput(_amount.text) ?? 0;
  double get _feeValue => _type == TxType.transfer && _useFee
      ? Fmt.tryParseInput(_fee.text) ?? 0
      : 0;
  double get _total => _amountValue + _feeValue;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amount = TextEditingController(
        text: Fmt.groupInput(existing?.amount ?? widget.prefilledAmount ?? 0));
    _category = TextEditingController(text: existing?.category ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    // Admin fees are separate linked rows; keeping them is essential on edits.
    final existingFee = existing == null
        ? 0.0
        : widget.state.transactions
            .where((transaction) => transaction.linkedTransferId == existing.id)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    _fee = TextEditingController(text: Fmt.groupInput(existingFee));
    _useFee = existingFee > 0;
    _type = existing?.type ?? TxType.expense;
    _sourceId = existing?.accountId ??
        (_accounts.any((account) => account.id == widget.initialAccountId)
            ? widget.initialAccountId!
            : _accounts.first.id);
    _destinationId = existing?.toAccountId;
    _ensureDestination();
    _date = existing?.date ?? DateTime.now();
    _knownCategories = {
      for (final transaction in widget.state.transactions)
        if (transaction.category.trim().isNotEmpty) transaction.category.trim(),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _ensureDestination() {
    if (_isEdit) return;
    final candidates = _accounts.where((account) => account.id != _sourceId);
    if (!candidates.any((account) => account.id == _destinationId)) {
      _destinationId = candidates.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    _fee.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;
    try {
      final controller = ref.read(appStateProvider.notifier);
      final error = _isEdit
          ? await controller.updateTransaction(
              id: widget.existing!.id,
              type: _type,
              amount: _amountValue,
              accountId: _sourceId,
              toAccountId: _type == TxType.transfer ? _destinationId : null,
              category: _category.text.trim(),
              note: _note.text.trim(),
              adminFee: _feeValue,
              date: _date,
            )
          : await controller.addTransaction(
              type: _type,
              amount: _amountValue,
              accountId: _sourceId,
              toAccountId: _type == TxType.transfer ? _destinationId : null,
              category: _category.text.trim(),
              note: _note.text.trim(),
              adminFee: _feeValue,
              date: _date,
            );
      if (!mounted) return;
      if (error == null) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _error = error;
          _saving = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l10n.transactionSaveFailed;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_saving,
      child: Material(
        color: colors.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _isEdit
                        ? l10n.editTransactionTitle
                        : l10n.recordTransactionTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                CloseButton(
                    onPressed: _saving ? null : () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _form(context)),
                  if (widget.desktop) ...[
                    VerticalDivider(width: 1, color: colors.outlineVariant),
                    SizedBox(
                      width: 290,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _summary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const ValueKey('transaction-form-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in [
                  TxType.expense,
                  TxType.income,
                  TxType.transfer
                ])
                  ChoiceChip(
                    label: Text(type.label(l10n)),
                    selected: _type == type,
                    showCheckmark: false,
                    onSelected: _isEdit || _saving
                        ? null
                        : (_) => setState(() {
                              _type = type;
                              _ensureDestination();
                              _error = null;
                            }),
                  ),
              ],
            ),
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l10n.transactionEditHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
              ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('transaction-amount'),
              controller: _amount,
              enabled: !_isEdit && !_saving,
              autofocus: !_isEdit,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [ThousandsInputFormatter()],
              style: Theme.of(context).textTheme.headlineSmall,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.labelAmount,
                prefixText: 'Rp ',
                helperText: _type == TxType.income
                    ? null
                    : l10n.helperBalance(
                        _source.name, Fmt.rupiah(_source.balance)),
                helperMaxLines: 2,
                errorMaxLines: 2,
              ),
              validator: (value) {
                final amount = Fmt.tryParseInput(value ?? '');
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return l10n.validationInvalidAmount;
                }
                if (!_isEdit &&
                    _type != TxType.income &&
                    _total > _source.balance) {
                  return l10n
                      .validationExceedBalance(Fmt.rupiah(_source.balance));
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('transaction-source-$_sourceId'),
              initialValue: _sourceId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _type == TxType.transfer
                    ? l10n.labelFromAccount
                    : l10n.accountLabel,
              ),
              items: [
                for (final account in _accounts)
                  DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name, overflow: TextOverflow.ellipsis),
                  ),
                if (!_accounts.any((account) => account.id == _sourceId))
                  DropdownMenuItem(value: _sourceId, child: Text(_sourceId)),
              ],
              onChanged: _isEdit || _saving
                  ? null
                  : (value) => setState(() {
                        _sourceId = value ?? _sourceId;
                        _ensureDestination();
                        _error = null;
                      }),
            ),
            if (_type == TxType.transfer) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(
                    'transaction-destination-$_sourceId-$_destinationId'),
                initialValue: _destinationId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.labelToAccount,
                  errorMaxLines: 2,
                ),
                items: [
                  for (final account in _accounts)
                    if (account.id != _sourceId)
                      DropdownMenuItem(
                        value: account.id,
                        child:
                            Text(account.name, overflow: TextOverflow.ellipsis),
                      ),
                ],
                onChanged: _isEdit || _saving
                    ? null
                    : (value) => setState(() => _destinationId = value),
                validator: (value) => value == null
                    ? l10n.validationSelectDest
                    : value == _sourceId
                        ? l10n.validationDiffAccount
                        : null,
              ),
              if (_accounts.length < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.transactionNeedDestination,
                      style: TextStyle(color: colors.error)),
                ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                key: const ValueKey('transaction-admin-switch'),
                value: _useFee,
                onChanged: _isEdit || _saving
                    ? null
                    : (value) => setState(() => _useFee = value),
                title: Text(l10n.adminFeeOptional),
                subtitle: Text(l10n.adminFeeSubtitle),
                contentPadding: EdgeInsets.zero,
              ),
              if (_useFee) ...[
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('transaction-admin-fee'),
                  controller: _fee,
                  enabled: !_isEdit && !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.labelAdminFee,
                    prefixText: 'Rp ',
                    helperText: l10n.helperAdminFee,
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    if (!_useFee) return null;
                    final fee = Fmt.tryParseInput(value ?? '');
                    return fee == null || !fee.isFinite || fee <= 0
                        ? l10n.validationAdminFee
                        : null;
                  },
                ),
              ],
              if (!widget.desktop) ...[
                const SizedBox(height: 16),
                _summary(context),
              ],
            ] else ...[
              const SizedBox(height: 16),
              _categoryField(context),
            ],
            const SizedBox(height: 16),
            ExpansionTile(
              key: const ValueKey('transaction-more-details'),
              initiallyExpanded: _isEdit || _note.text.isNotEmpty,
              maintainState: true,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
              title: Text(l10n.transactionMoreDetails),
              subtitle: Text(Fmt.date(_date)),
              children: [
                TextFormField(
                  key: const ValueKey('transaction-note'),
                  controller: _note,
                  enabled: !_saving,
                  autofocus: _isEdit,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l10n.labelNote),
                ),
                const SizedBox(height: 16),
                InkWell(
                  key: const ValueKey('transaction-date'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isEdit || _saving
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2015),
                            lastDate:
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null && mounted) {
                            setState(() => _date = picked);
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.labelDate,
                      enabled: !_isEdit && !_saving,
                      suffixIcon: Icon(_isEdit
                          ? Icons.lock_outline
                          : Icons.calendar_today_outlined),
                    ),
                    child: Text(Fmt.dateFull(_date)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, constraints) {
      return RawAutocomplete<String>(
        textEditingController: _category,
        focusNode: _categoryFocus,
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty || _saving) return const Iterable<String>.empty();
          return _knownCategories.where((category) =>
              category.toLowerCase().contains(query) &&
              category.toLowerCase() != query);
        },
        fieldViewBuilder: (context, controller, focus, onSubmitted) =>
            TextFormField(
          key: const ValueKey('transaction-category'),
          controller: controller,
          focusNode: focus,
          enabled: !_saving,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.labelCategory,
            hintText: l10n.hintCategory,
          ),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: constraints.maxWidth,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      ListTile(
                        title: Text(option),
                        leading: const Icon(Icons.category_outlined, size: 20),
                        onTap: () => onSelected(option),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _summary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    String accountName(String? id) =>
        _accounts.where((account) => account.id == id).firstOrNull?.name ?? '—';
    Widget line(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(color: colors.onSurfaceVariant))),
            const SizedBox(width: 12),
            Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontWeight:
                            strong ? FontWeight.w700 : FontWeight.w500))),
          ]),
        );
    return DecoratedBox(
      key: const ValueKey('transaction-summary'),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.transactionSummary,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          line(_type.label(l10n), Fmt.rupiah(_amountValue)),
          line(
              _type == TxType.transfer
                  ? l10n.labelFromAccount
                  : l10n.accountLabel,
              accountName(_sourceId)),
          if (_type == TxType.transfer) ...[
            line(l10n.labelToAccount, accountName(_destinationId)),
            line(l10n.labelAdminFee, Fmt.rupiah(_feeValue)),
            const Divider(),
            line(l10n.totalOutFromAccount, Fmt.rupiah(_total), strong: true),
          ],
          if (widget.desktop) ...[
            const SizedBox(height: 8),
            line(l10n.labelDate, Fmt.date(_date)),
          ],
        ]),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) ...[
              Text(_error!,
                  key: const ValueKey('transaction-save-error'),
                  style: TextStyle(color: colors.error)),
              const SizedBox(height: 8),
            ],
            if (_type == TxType.transfer) ...[
              Text(l10n.totalOut(Fmt.rupiah(_total)),
                  key: const ValueKey('transaction-total-out'),
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
            ],
            FilledButton(
              key: const ValueKey('transaction-save'),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colors.primary))
                  : Text(l10n.saveButton),
            ),
          ]),
        ),
      ),
    );
  }
}
