import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/display_preferences.dart';
import 'package:moneywork/firebase/auth.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/debt.dart';
import 'package:moneywork/models/investment.dart';
import 'package:moneywork/models/receivable.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/screens/dashboard_screen.dart';
import 'package:moneywork/screens/finance_tools_screen.dart';

import 'helpers.dart';

AppState focusFixture() {
  final day = DateTime.now();
  return AppState(
    accounts: [
      Account(
          id: 'bank',
          name: 'BCA',
          type: AccountType.bank,
          balance: 50000,
          createdAt: day),
      Account(
          id: 'cash',
          name: 'Tunai',
          type: AccountType.cash,
          balance: 30000,
          createdAt: day),
    ],
    accountOrder: const ['cash', 'bank'],
    investments: [
      Investment(
          id: 'gold',
          name: 'Emas',
          type: InvestmentType.gold,
          quantity: 1,
          buyPrice: 150000,
          currentPrice: 200000,
          updatedAt: day),
    ],
    debts: [
      Debt(
          id: 'loan',
          name: 'Pinjaman',
          type: DebtType.loan,
          remaining: 40000,
          createdAt: day),
    ],
    receivables: [
      Receivable(
          id: 'friend', personName: 'Budi', remaining: 10000, createdAt: day),
    ],
    // Include unsorted and historical records to exercise the presentation
    // against the same monthly semantics as reports, without moving balances.
    transactions: [
      Transaction(
          id: 'last-month',
          type: TxType.expense,
          amount: 99000,
          accountId: 'bank',
          date: DateTime(day.year, day.month - 1, 1),
          note: 'Bulan lalu'),
      Transaction(
          id: 'income',
          type: TxType.income,
          amount: 30000,
          accountId: 'bank',
          date: day,
          note: 'Pemasukan bulan ini'),
      Transaction(
          id: 'coffee',
          type: TxType.expense,
          amount: 3200,
          accountId: 'cash',
          date: day,
          note: 'Kopi terbaru'),
      Transaction(
          id: 'historical',
          type: TxType.expense,
          amount: 5000,
          accountId: 'bank',
          date: day,
          balanceApplied: false,
          note: 'Mutasi historis'),
      Transaction(
          id: 'transfer',
          type: TxType.transfer,
          amount: 20000,
          accountId: 'bank',
          toAccountId: 'cash',
          date: day),
      Transaction(
          id: 'admin',
          type: TxType.expense,
          amount: 1000,
          accountId: 'bank',
          linkedTransferId: 'transfer',
          date: day,
          note: 'Biaya admin'),
    ],
  );
}

Future<ProviderContainer> mountDashboard(WidgetTester tester,
    {AppState? state,
    double width = 390,
    bool dark = false,
    double textScale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1100);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(overrides: [
    storageProvider.overrideWithValue(InMemoryStorage(state ?? focusFixture())),
    authStateProvider.overrideWith((_) => Stream.value(const AppUser.local())),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('id'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!),
      home: const DashboardScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

String keyedText(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

Future<void> scrollTo(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(find.byKey(ValueKey(key)), 350,
      scrollable: find
          .descendant(
              of: find.byKey(const ValueKey('dashboard-scroll')),
              matching: find.byType(Scrollable))
          .first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  testWidgets('daily dashboard separates cash, monthly flows and net worth',
      (tester) async {
    final container = await mountDashboard(tester);
    expect(keyedText(tester, 'dashboard-cash-total'), 'Rp 80.000');
    expect(keyedText(tester, 'dashboard-month-income'), 'Rp 30.000');
    expect(keyedText(tester, 'dashboard-month-expense'), 'Rp 9.200');
    expect(keyedText(tester, 'dashboard-month-net'), '+Rp 20.800');
    final record = find.byKey(const ValueKey('dashboard-record'));
    expect(
        tester.getTopLeft(record).dy,
        lessThan(tester
            .getTopLeft(find.byKey(const ValueKey('dashboard-month-summary')))
            .dy));
    await scrollTo(tester, 'dashboard-account-cash');
    expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('dashboard-account-cash')))
            .dy,
        lessThan(tester
            .getTopLeft(find.byKey(const ValueKey('dashboard-account-bank')))
            .dy));
    await scrollTo(tester, 'dashboard-net-worth-total');
    expect(keyedText(tester, 'dashboard-net-worth-total'), 'Rp 250.000');
    expect(container.read(appStateProvider).requireValue.totalCash, 80000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy masks every dashboard amount while keeping activity',
      (tester) async {
    final container = await mountDashboard(tester);
    final original = container.read(appStateProvider).requireValue.toJson();
    await tester.tap(find.byKey(const ValueKey('toggle-dashboard-balances')));
    await tester.pumpAndSettle();
    expect(container.read(amountsHiddenProvider), isTrue);
    expect(keyedText(tester, 'dashboard-cash-total'), 'Rp ••••••');
    expect(keyedText(tester, 'dashboard-month-income'), 'Rp ••••••');
    expect(keyedText(tester, 'dashboard-month-expense'), 'Rp ••••••');
    await scrollTo(tester, 'dashboard-tx-coffee-amount');
    expect(find.text('Kopi terbaru'), findsOneWidget);
    expect(keyedText(tester, 'dashboard-tx-coffee-amount'), 'Rp ••••••');
    await scrollTo(tester, 'dashboard-net-worth-total');
    expect(keyedText(tester, 'dashboard-net-worth-total'), 'Rp ••••••');
    expect(container.read(appStateProvider).requireValue.toJson(), original);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tools remain reachable from a labeled entry', (tester) async {
    await mountDashboard(tester);
    await tester.tap(find.byKey(const ValueKey('dashboard-tools')));
    await tester.pumpAndSettle();
    expect(find.byType(FinanceToolsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 760.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('dashboard fits $width, large text, dark=$dark',
          (tester) async {
        await mountDashboard(tester, width: width, dark: dark, textScale: 1.6);
        expect(tester.takeException(), isNull);
        expect(
            Theme.of(tester.element(find.byType(DashboardScreen))).brightness,
            dark ? Brightness.dark : Brightness.light);
        await scrollTo(tester, 'dashboard-net-worth-total');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
