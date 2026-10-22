import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/display_preferences.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/debt.dart';
import 'package:moneywork/models/receivable.dart';
import 'package:moneywork/models/recurring_transaction.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/models/wishlist_item.dart';
import 'package:moneywork/screens/cash_flow_forecast_screen.dart';
import 'package:moneywork/screens/monthly_expenses_screen.dart';
import 'package:moneywork/screens/report_screen.dart';
import 'package:moneywork/screens/tagihan_screen.dart';
import 'package:moneywork/screens/wishlist_screen.dart';

import 'helpers.dart';

AppState privacyFixture() {
  final day = DateTime.now();
  return AppState(
    accounts: [
      Account(
          id: 'bank',
          name: 'BCA',
          type: AccountType.bank,
          balance: 80000,
          createdAt: day)
    ],
    transactions: [
      Transaction(
          id: 'tx',
          type: TxType.expense,
          amount: 12000,
          accountId: 'bank',
          date: day,
          category: 'Makan',
          note: 'Makan siang')
    ],
    debts: [
      Debt(
          id: 'loan',
          name: 'Pinjaman',
          type: DebtType.loan,
          remaining: 60000,
          monthlyPayment: 10000,
          dueDate: day.add(const Duration(days: 5)),
          createdAt: day)
    ],
    receivables: [
      Receivable(
          id: 'rcv', personName: 'Budi', remaining: 15000, createdAt: day)
    ],
    recurring: [
      RecurringTransaction(
          id: 'monthly',
          label: 'Langganan',
          type: TxType.expense,
          amount: 7000,
          accountId: 'bank',
          dueDay: day.day,
          createdAt: day)
    ],
    wishlist: [
      WishlistItem(
          id: 'wish',
          name: 'Headphone',
          price: 150000,
          savedAmount: 25000,
          monthlySaving: 10000,
          createdAt: day)
    ],
  );
}

List<String> monetaryTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .where((text) => RegExp(r'Rp\s*\d').hasMatch(text))
    .toList();

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  for (final screen in <String, Widget>{
    'report': const ReportScreen(),
    'forecast': const CashFlowForecastScreen(),
    'wishlist': const WishlistScreen(),
    'monthly': const MonthlyExpensesScreen(),
    'bills': const TagihanScreen(),
  }.entries) {
    testWidgets('${screen.key} honors global privacy without changing data',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = InMemoryStorage(privacyFixture());
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(storage),
        amountsHiddenProvider.overrideWith((_) => true),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('id'),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: screen.value),
      ));
      await tester.pumpAndSettle();
      final before = container.read(appStateProvider).requireValue.toJson();
      expect(monetaryTexts(tester), isEmpty);
      expect(find.textContaining('Rp ••••••'), findsWidgets);
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(PieChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);
      if (screen.key == 'wishlist') {
        expect(find.byType(LinearProgressIndicator), findsNothing);
      }
      if (screen.key == 'bills') {
        final l10n =
            AppLocalizations.of(tester.element(find.byType(TagihanScreen)))!;
        await tester.tap(find.text(l10n.tabReceivables));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Budi'));
        await tester.pumpAndSettle();
        expect(monetaryTexts(tester), isEmpty);
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('toggle-amount-visibility')));
      await tester.pumpAndSettle();
      expect(container.read(amountsHiddenProvider), isFalse);
      expect(monetaryTexts(tester), isNotEmpty);
      expect(container.read(appStateProvider).requireValue.toJson(), before);
      expect((await storage.load()).accounts.single.balance, 80000);
      expect(tester.takeException(), isNull);
    });
  }
}
