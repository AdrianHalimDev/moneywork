import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/storage.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/widgets/dialogs/transaction_editor.dart';

import 'helpers.dart';

AppState _fixture() => AppState(
      accounts: [
        Account(
            id: 'bank',
            name: 'BCA',
            type: AccountType.bank,
            balance: 50000,
            createdAt: DateTime(2026, 10, 22)),
        Account(
            id: 'cash',
            name: 'Tunai',
            type: AccountType.cash,
            balance: 20000,
            createdAt: DateTime(2026, 10, 22)),
        Account(
            id: 'wallet',
            name: 'GoPay',
            type: AccountType.ewallet,
            balance: 30000,
            createdAt: DateTime(2026, 10, 22)),
      ],
      accountOrder: const ['wallet', 'bank', 'cash'],
    );

class _PausedStorage extends InMemoryStorage {
  _PausedStorage(super.initial);
  final gate = Completer<void>();
  var saves = 0;

  @override
  Future<void> save(AppState state) async {
    saves++;
    await gate.future;
    await super.save(state);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  Future<ProviderContainer> open(
    WidgetTester tester, {
    double width = 390,
    double height = 800,
    bool dark = false,
    StorageBackend? storage,
    Transaction? existing,
    String? initialAccountId,
    double? prefilledAmount,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(storage ?? InMemoryStorage(_fixture())),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('id'),
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(builder: (context, ref, _) {
          final state = ref.watch(appStateProvider).valueOrNull;
          return Scaffold(
              body: Center(
                  child: FilledButton(
            key: const ValueKey('open-editor'),
            onPressed: state == null
                ? null
                : () => showFocusTransactionEditor(
                      context,
                      ref,
                      state,
                      existing: existing,
                      initialAccountId: initialAccountId,
                      prefilledAmount: prefilledAmount,
                    ),
            child: const Text('Buka'),
          )));
        }),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-editor')));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> reveal(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
  }

  List<DropdownButtonFormField<String>> fields(WidgetTester tester) => tester
      .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>))
      .toList();

  List<String?> options(WidgetTester tester, int index) => tester
      .widget<DropdownButton<String>>(find.descendant(
        of: find.byType(DropdownButtonFormField<String>).at(index),
        matching: find
            .byWidgetPredicate((widget) => widget is DropdownButton<String>),
      ))
      .items!
      .map((item) => item.value)
      .toList();

  Future<void> selectSource(WidgetTester tester, String name) async {
    await tester
        .ensureVisible(find.byType(DropdownButtonFormField<String>).first);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0]) {
    for (final dark in [false, true]) {
      testWidgets('save remains above keyboard at width $width, dark=$dark',
          (tester) async {
        final container =
            await open(tester, width: width, height: 680, dark: dark);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const ValueKey('transaction-amount')), '1000');
        await reveal(tester, const ValueKey('transaction-category'));
        await tester.enterText(
            find.byKey(const ValueKey('transaction-category')), 'Makan');
        final save = find.byKey(const ValueKey('transaction-save'));
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(400));
        expect(tester.getTopLeft(save).dy, greaterThan(0));
        expect(tester.takeException(), isNull);
        await tester.tap(save);
        await tester.pumpAndSettle();
        final state = container.read(appStateProvider).requireValue;
        expect(state.transactions.single.accountId, 'wallet');
        expect(state.transactions.single.amount, 1000);
        expect(state.transactions.single.category, 'Makan');
        expect(
            state.accounts
                .firstWhere((account) => account.id == 'wallet')
                .balance,
            29000);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
      'transfer review includes fee and keeps a valid distinct destination',
      (tester) async {
    final container = await open(tester,
        width: 1100,
        height: 850,
        initialAccountId: 'bank',
        prefilledAmount: 10000);
    expect(fields(tester).single.initialValue, 'bank');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Transfer'));
    await tester.pumpAndSettle();
    expect(fields(tester).last.initialValue, 'wallet');
    expect(options(tester, 1), ['wallet', 'cash']);
    await selectSource(tester, 'GoPay');
    expect(fields(tester).last.initialValue, 'bank');
    expect(options(tester, 1), ['bank', 'cash']);
    expect(
        tester
            .widget<TextFormField>(
                find.byKey(const ValueKey('transaction-amount')))
            .controller!
            .text,
        '10.000');
    await reveal(tester, const ValueKey('transaction-admin-switch'));
    await tester.tap(find.byKey(const ValueKey('transaction-admin-switch')));
    await tester.pumpAndSettle();
    await reveal(tester, const ValueKey('transaction-admin-fee'));
    await tester.enterText(
        find.byKey(const ValueKey('transaction-admin-fee')), '1000');
    await tester.pumpAndSettle();
    expect(find.textContaining('11.000'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pumpAndSettle();
    final state = container.read(appStateProvider).requireValue;
    final transfer =
        state.transactions.singleWhere((t) => t.type == TxType.transfer);
    final fee = state.transactions
        .singleWhere((t) => t.linkedTransferId == transfer.id);
    expect(transfer.accountId, 'wallet');
    expect(transfer.toAccountId, 'bank');
    expect(transfer.amount, 10000);
    expect(fee.amount, 1000);
    expect(
        state.accounts.firstWhere((account) => account.id == 'wallet').balance,
        19000);
    expect(state.accounts.firstWhere((account) => account.id == 'bank').balance,
        60000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('transfer with one account cannot submit', (tester) async {
    final fixture = _fixture();
    final container = await open(tester,
        storage: InMemoryStorage(
            fixture.copyWith(accounts: [fixture.accounts.first])),
        prefilledAmount: 1000);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Transfer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pumpAndSettle();
    expect(container.read(appStateProvider).requireValue.transactions, isEmpty);
    expect(find.text('Pilih akun tujuan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'narrow transfer keeps totals above keyboard and rejects amount plus fee',
      (tester) async {
    final container =
        await open(tester, width: 320, height: 680, prefilledAmount: 30000);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Transfer'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await reveal(tester, const ValueKey('transaction-admin-switch'));
    await tester.tap(find.byKey(const ValueKey('transaction-admin-switch')));
    await tester.pumpAndSettle();
    await reveal(tester, const ValueKey('transaction-admin-fee'));
    await tester.enterText(
        find.byKey(const ValueKey('transaction-admin-fee')), '1000');
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('transaction-save'));
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(400));
    expect(find.textContaining('31.000'), findsWidgets);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(container.read(appStateProvider).requireValue.transactions, isEmpty);
    await reveal(tester, const ValueKey('transaction-amount'));
    expect(find.textContaining('Melebihi saldo'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('transaction-amount')), '10000');
    await tester.tap(save);
    await tester.pumpAndSettle();
    final state = container.read(appStateProvider).requireValue;
    expect(state.transactions, hasLength(2));
    expect(
        state.accounts.firstWhere((account) => account.id == 'wallet').balance,
        19000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'editing transfer note preserves amount, IDs, date, balances and fee',
      (tester) async {
    final when = DateTime(2026, 10, 20, 13, 25);
    final transfer = Transaction(
        id: 'transfer',
        type: TxType.transfer,
        amount: 10000,
        accountId: 'bank',
        toAccountId: 'cash',
        note: 'Lama',
        date: when);
    final fee = Transaction(
        id: 'fee',
        type: TxType.expense,
        amount: 1000,
        accountId: 'bank',
        category: 'Biaya Admin',
        linkedTransferId: transfer.id,
        date: when);
    final initial = _fixture().copyWith(transactions: [transfer, fee]);
    final container = await open(tester,
        width: 1100, storage: InMemoryStorage(initial), existing: transfer);
    expect(
        tester
            .widget<TextFormField>(
                find.byKey(const ValueKey('transaction-amount')))
            .enabled,
        false);
    expect(fields(tester).every((field) => field.onChanged == null), isTrue);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Masuk'))
            .onSelected,
        isNull);
    await reveal(tester, const ValueKey('transaction-admin-fee'));
    expect(
        tester
            .widget<TextFormField>(
                find.byKey(const ValueKey('transaction-admin-fee')))
            .enabled,
        false);
    await reveal(tester, const ValueKey('transaction-note'));
    await tester.enterText(
        find.byKey(const ValueKey('transaction-note')), 'Catatan diperbaiki');
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pumpAndSettle();
    final state = container.read(appStateProvider).requireValue;
    final saved = state.transactions.singleWhere((t) => t.id == transfer.id);
    expect(saved.note, 'Catatan diperbaiki');
    expect(saved.type, transfer.type);
    expect(saved.amount, transfer.amount);
    expect(saved.accountId, transfer.accountId);
    expect(saved.toAccountId, transfer.toAccountId);
    expect(saved.date, when);
    expect(
        state.transactions
            .singleWhere((t) => t.linkedTransferId == transfer.id)
            .amount,
        1000);
    for (final account in initial.accounts) {
      expect(state.accounts.firstWhere((a) => a.id == account.id).balance,
          account.balance);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rapid save taps cannot create the transaction twice',
      (tester) async {
    final storage = _PausedStorage(_fixture());
    final container =
        await open(tester, storage: storage, prefilledAmount: 1000);
    final save = find.byKey(const ValueKey('transaction-save'));
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 30));
    expect(storage.saves, 1);
    expect(container.read(appStateProvider).requireValue.transactions,
        hasLength(1));
    storage.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('transaction-amount')), findsNothing);
    expect((await storage.load()).transactions, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
