import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../l10n/app_localizations.dart';
import 'sync_indicator.dart';

Future<void> showInvestmentOrderSheet(BuildContext context, AppState state) =>
    _showOrderSheet(context, state, accounts: false);

Future<void> showAccountOrderSheet(BuildContext context, AppState state) =>
    _showOrderSheet(context, state, accounts: true);

Future<void> _showOrderSheet(BuildContext context, AppState state,
        {required bool accounts}) =>
    showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 720),
        builder: (_) => _OrderEditor(initial: state, accounts: accounts));

class _OrderEditor extends ConsumerStatefulWidget {
  const _OrderEditor({required this.initial, required this.accounts});
  final AppState initial;
  final bool accounts;
  @override
  ConsumerState<_OrderEditor> createState() => _OrderEditorState();
}

class _OrderEditorState extends ConsumerState<_OrderEditor> {
  List<String> _order(AppState state) =>
      widget.accounts ? state.accountOrder : state.investmentOrder;
  List<String> _orderedIds(AppState state) => widget.accounts
      ? state.orderedAccounts.map((a) => a.id).toList()
      : state.orderedInvestments.map((a) => a.id).toList();
  late final _sourceOrder = List<String>.of(_order(widget.initial));
  late var _ids = _orderedIds(widget.initial);
  bool _saving = false;
  String? _error;

  void _move(int from, int to) => setState(() {
        final id = _ids.removeAt(from);
        _ids.insert(to, id);
      });

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final latest = ref.read(appStateProvider).requireValue;
    if (!const ListEquality<String>().equals(_sourceOrder, _order(latest))) {
      setState(() => _error =
          widget.accounts ? l10n.accountOrderChanged : l10n.assetOrderChanged);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(appStateProvider.notifier);
      if (widget.accounts) {
        await controller.setAccountOrder(_ids);
      } else {
        await controller.setInvestmentOrder(_ids);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.accounts
              ? l10n.accountOrderSaved
              : l10n.assetOrderSaved)));
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider).valueOrNull ?? widget.initial;
    final l10n = AppLocalizations.of(context)!;
    final items = widget.accounts
        ? {
            for (final item in state.accounts)
              item.id: (item.name, item.type.label(l10n))
          }
        : {
            for (final item in state.investments)
              item.id: (item.name, item.type.label(l10n))
          };
    // Aset yang ditambah/dihapus selama mengedit tetap disertakan dengan aman.
    _ids = [
      for (final id in _ids)
        if (items.containsKey(id)) id,
      for (final id in _orderedIds(state))
        if (!_ids.contains(id)) id
    ];
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.accounts ? l10n.reorderAccounts : l10n.reorderAssets,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(widget.accounts ? l10n.accountOrderHint : l10n.assetOrderHint),
          const SizedBox(height: 14),
          Flexible(
              child: SizedBox(
            height: math.min(math.max(_ids.length * 90.0, 90),
                MediaQuery.sizeOf(context).height * .45),
            child: ReorderableListView.builder(
              key: ValueKey(widget.accounts
                  ? 'account-order-list'
                  : 'investment-order-list'),
              buildDefaultDragHandles: false,
              itemCount: _ids.length,
              onReorderItem: (oldIndex, newIndex) {
                if (_saving) return;
                _move(oldIndex, newIndex);
              },
              itemBuilder: (_, i) =>
                  _orderRow(_ids[i], items[_ids[i]]!, i, l10n),
            ),
          )),
          const SizedBox(height: 12),
          Text(
              widget.accounts
                  ? l10n.accountOrderSyncHint
                  : l10n.assetOrderSyncHint,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          const SyncIndicator(showLabel: true),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: Text(l10n.cancelButton)),
            const SizedBox(width: 8),
            Flexible(
                child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(widget.accounts
                        ? l10n.saveAccountOrder
                        : l10n.saveAssetOrder))),
          ]),
        ],
      ),
    ));
  }

  Widget _orderRow(
      String id, (String, String) item, int i, AppLocalizations l10n) {
    final keyPrefix = widget.accounts ? 'account' : 'asset';
    return Material(
      key: ValueKey(id),
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ReorderableDragStartListener(
            index: i,
            enabled: !_saving,
            child: SizedBox(
                width: 44,
                height: 64,
                child: Semantics(
                    label: widget.accounts
                        ? l10n.reorderAccounts
                        : l10n.reorderAssets,
                    child: const Icon(Icons.drag_indicator)))),
        title: Text(item.$1, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${i + 1} · ${item.$2}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              key: ValueKey('$keyPrefix-up-$id'),
              tooltip: widget.accounts ? l10n.moveAccountUp : l10n.moveAssetUp,
              icon: const Icon(Icons.arrow_upward, size: 20),
              onPressed: _saving || i == 0 ? null : () => _move(i, i - 1)),
          IconButton(
              key: ValueKey('$keyPrefix-down-$id'),
              tooltip:
                  widget.accounts ? l10n.moveAccountDown : l10n.moveAssetDown,
              icon: const Icon(Icons.arrow_downward, size: 20),
              onPressed: _saving || i == _ids.length - 1
                  ? null
                  : () => _move(i, i + 1)),
        ]),
      ),
    );
  }
}
