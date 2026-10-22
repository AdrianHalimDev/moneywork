import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/screens/accounts_screen.dart';
import 'helpers.dart';

AppState fixture() => AppState(accounts: [
      Account(
          id: 'bank',
          name: 'BCA',
          type: AccountType.bank,
          balance: 50000,
          createdAt: DateTime(2026, 10, 21)),
      Account(
          id: 'cash',
          name: 'Tunai',
          type: AccountType.cash,
          balance: 20000,
          createdAt: DateTime(2026, 10, 21)),
      Account(
          id: 'wallet',
          name: 'GoPay',
          type: AccountType.ewallet,
          balance: 30000,
          createdAt: DateTime(2026, 10, 21)),
    ]);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  Future<void> mount(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('id'),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountsScreen())));
    await tester.pumpAndSettle();
  }

  List<DropdownButtonFormField<String>> dropdowns(WidgetTester tester) => tester
      .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>))
      .toList();

  List<String?> options(WidgetTester tester, [int index = 0]) => tester
      .widget<DropdownButton<String>>(find.descendant(
        of: find.byType(DropdownButtonFormField<String>).at(index),
        matching: find.byWidgetPredicate((w) => w is DropdownButton<String>),
      ))
      .items!
      .map((item) => item.value)
      .toList();

  for (final width in [390.0, 1280.0]) {
    testWidgets(
        'account reorder changes list and new expense picker at width $width',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = InMemoryStorage(fixture());
      final container = ProviderContainer(
          overrides: [storageProvider.overrideWithValue(storage)]);
      addTearDown(container.dispose);
      await mount(tester, container);
      await tester.tap(find.byKey(const ValueKey('reorder-accounts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-up-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-up-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan urutan'));
      await tester.pumpAndSettle();
      expect(container.read(appStateProvider).requireValue.accountOrder,
          ['wallet', 'bank', 'cash']);
      expect((await storage.load()).accountOrder, ['wallet', 'bank', 'cash']);
      final walletPosition =
          tester.getTopLeft(find.byKey(const ValueKey('account-card-wallet')));
      final bankPosition =
          tester.getTopLeft(find.byKey(const ValueKey('account-card-bank')));
      expect(width < 650 ? walletPosition.dy : walletPosition.dx,
          lessThan(width < 650 ? bankPosition.dy : bankPosition.dx));
      ScaffoldMessenger.of(tester.element(find.byType(AccountsScreen)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reorder-accounts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-down-wallet')));
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(container.read(appStateProvider).requireValue.accountOrder,
          ['wallet', 'bank', 'cash']);
      await tester
          .tap(find.widgetWithText(FloatingActionButton, 'Catat Transaksi'));
      await tester.pumpAndSettle();
      final source = dropdowns(tester).single;
      expect(options(tester), ['wallet', 'bank', 'cash']);
      expect(source.initialValue, 'wallet');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Jumlah'), '1000');
      await tester.ensureVisible(
          find.byKey(const ValueKey('transaction-more-details')));
      await tester.tap(find.byKey(const ValueKey('transaction-more-details')));
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.byKey(const ValueKey('transaction-note')));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Catatan (opsional)'),
          'Uji urutan');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      final saved = container.read(appStateProvider).requireValue;
      expect(saved.transactions.single.accountId, 'wallet');
      expect(saved.accounts.firstWhere((a) => a.id == 'wallet').balance, 29000);
      expect(saved.accounts.firstWhere((a) => a.id == 'bank').balance, 50000);
      // Mengurutkan ulang tidak memindahkan rekening transaksi yang telah ada.
      await container
          .read(appStateProvider.notifier)
          .setAccountOrder(['cash', 'bank', 'wallet']);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Uji urutan'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Uji urutan'));
      await tester.pumpAndSettle();
      expect(dropdowns(tester).single.initialValue, 'wallet');
      expect(dropdowns(tester).single.onChanged, isNull);
      expect(options(tester), ['cash', 'bank', 'wallet']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'transfer source and destination follow preferred order and keep their IDs',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(InMemoryStorage(
          fixture().copyWith(accountOrder: ['wallet', 'cash', 'bank'])))
    ]);
    addTearDown(container.dispose);
    await mount(tester, container);
    await tester
        .tap(find.widgetWithText(FloatingActionButton, 'Catat Transaksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer').last);
    await tester.pumpAndSettle();
    final fields = dropdowns(tester);
    expect(fields.length, 2);
    expect(options(tester), ['wallet', 'cash', 'bank']);
    expect(options(tester, 1), ['cash', 'bank']);
    expect(fields.first.initialValue, 'wallet');
    expect(fields.last.initialValue, 'cash');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Jumlah'), '1000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final state = container.read(appStateProvider).requireValue;
    expect(state.transactions.single.type, TxType.transfer);
    expect(state.transactions.single.accountId, 'wallet');
    expect(state.transactions.single.toAccountId, 'cash');
    expect(state.accounts.firstWhere((a) => a.id == 'wallet').balance, 29000);
    expect(state.accounts.firstWhere((a) => a.id == 'cash').balance, 21000);
    expect(state.totalCash, 100000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
