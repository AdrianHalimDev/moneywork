import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/core/formatters.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/display_preferences.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/screens/accounts_screen.dart';

import 'helpers.dart';

AppState _fixture() => AppState(accounts: [
      Account(
          id: 'bank',
          name: 'BCA',
          type: AccountType.bank,
          balance: 120000,
          accountNumber: '1234567890',
          createdAt: DateTime(2026, 10, 22)),
      Account(
          id: 'wallet',
          name: 'GoPay',
          type: AccountType.ewallet,
          balance: 25000,
          createdAt: DateTime(2026, 10, 22)),
    ], accountOrder: const [
      'wallet',
      'bank'
    ], transactions: [
      Transaction(
          id: 'incoming',
          type: TxType.transfer,
          amount: 10000,
          accountId: 'wallet',
          toAccountId: 'bank',
          note: 'Transfer masuk',
          date: DateTime(2026, 10, 22, 12)),
      Transaction(
          id: 'expense',
          type: TxType.expense,
          amount: 7000,
          accountId: 'bank',
          category: 'Belanja',
          note: 'Beli buku',
          date: DateTime(2026, 10, 22, 11)),
      Transaction(
          id: 'unrelated',
          type: TxType.income,
          amount: 2222,
          accountId: 'wallet',
          note: 'Khusus dompet',
          date: DateTime(2026, 10, 22, 10)),
    ]);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  Future<ProviderContainer> mount(WidgetTester tester, double width,
      {double height = 1100}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(InMemoryStorage(_fixture())),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('id'),
        theme: width < 840 ? AppTheme.light() : AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AccountsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('account-card-bank')));
    await tester.tap(find.byKey(const ValueKey('account-card-bank')));
    await tester.pumpAndSettle();
    return container;
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets('account tap opens live details and relative history at $width',
        (tester) async {
      final container = await mount(tester, width);
      final detail = find.byKey(const ValueKey('account-detail-bank'));
      expect(detail, findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Transfer masuk'), findsOneWidget);
      expect(find.text('Beli buku'), findsOneWidget);
      expect(find.text('Khusus dompet'), findsNothing);
      expect(find.text(Fmt.rupiahSigned(10000)), findsOneWidget);
      expect(find.text(Fmt.rupiahSigned(-7000)), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);

      // Privacy follows the same provider while the detail route is open.
      await tester.tap(find.byKey(const ValueKey('toggle-amount-visibility')));
      await tester.pumpAndSettle();
      expect(container.read(amountsHiddenProvider), isTrue);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('account-detail-balance')))
              .data,
          'Rp ••••••');
      expect(find.text('1234567890'), findsNothing);
      expect(find.text(Fmt.rupiahSigned(10000)), findsNothing);
      expect(find.text(Fmt.rupiahSigned(-7000)), findsNothing);
      expect(container.read(appStateProvider).requireValue.totalCash, 145000);
      await tester.tap(find.byKey(const ValueKey('toggle-amount-visibility')));
      await tester.pumpAndSettle();

      // Updating and reordering cannot change which account the route shows.
      final controller = container.read(appStateProvider.notifier);
      final bank = container
          .read(appStateProvider)
          .requireValue
          .accounts
          .singleWhere((account) => account.id == 'bank');
      await controller
          .updateAccount(bank.copyWith(name: 'BCA Utama', balance: 125000));
      await controller.setAccountOrder(['bank', 'wallet']);
      await tester.pumpAndSettle();
      expect(find.text('BCA Utama'), findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('account-detail-balance')))
              .data,
          Fmt.rupiah(125000));
      expect(find.text('Khusus dompet'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('edit-account-details')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widgetList<TextFormField>(find.byType(TextFormField))
              .any((field) => field.controller?.text == 'BCA Utama'),
          isTrue);
      Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
      await tester.pumpAndSettle();
      expect(detail, findsOneWidget);

      // The account detail chooses its own ID even when it is not first.
      await controller.setAccountOrder(['wallet', 'bank']);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(detail))!;
      await tester.tap(find.text(l10n.focusRecordHere));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<DropdownButtonFormField<String>>(
                  find.byType(DropdownButtonFormField<String>))
              .initialValue,
          'bank');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'removing the account while its detail is open shows a safe empty state',
      (tester) async {
    final container = await mount(tester, 390);
    await container.read(appStateProvider.notifier).deleteAccount('bank');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-detail-bank')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-detail-balance')), findsNothing);
    expect(find.byKey(const ValueKey('edit-account-details')), findsNothing);
    final l10n = AppLocalizations.of(
        tester.element(find.byKey(const ValueKey('account-detail-bank'))))!;
    expect(find.text(l10n.focusAccountMissing), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'account metadata edit is keyboard safe and preserves a new live balance',
      (tester) async {
    final container = await mount(tester, 320, height: 680);
    await tester.tap(find.byKey(const ValueKey('edit-account-details')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('account-editor-name')));
    await tester.enterText(
        find.byKey(const ValueKey('account-editor-name')), 'BCA Keyboard');
    // A transaction arrives after opening the editor. Editing the name must
    // merge onto its new balance instead of restoring the original balance.
    await container
        .read(appStateProvider.notifier)
        .addTransaction(type: TxType.expense, amount: 1000, accountId: 'bank');
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('account-editor-save'));
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(400));
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-editor-name')), findsNothing);
    final account = container
        .read(appStateProvider)
        .requireValue
        .accounts
        .singleWhere((account) => account.id == 'bank');
    expect(account.name, 'BCA Keyboard');
    expect(account.balance, 119000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'an edited balance cannot overwrite a transaction arriving while editing',
      (tester) async {
    final container = await mount(tester, 390);
    await tester.tap(find.byKey(const ValueKey('edit-account-details')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('account-editor-balance')));
    await tester.enterText(
        find.byKey(const ValueKey('account-editor-balance')), '125000');
    await container
        .read(appStateProvider.notifier)
        .addTransaction(type: TxType.expense, amount: 1000, accountId: 'bank');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-editor-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-editor-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-editor-name')), findsOneWidget);
    expect(
        container
            .read(appStateProvider)
            .requireValue
            .accounts
            .singleWhere((account) => account.id == 'bank')
            .balance,
        119000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
