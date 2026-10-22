import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/firebase/auth.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/screens/dashboard_screen.dart';
import 'package:moneywork/screens/cash_flow_forecast_screen.dart';

import 'package:moneywork/l10n/app_localizations.dart';

import 'helpers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  testWidgets('DashboardScreen prioritizes balance and opens labeled tools',
      (WidgetTester tester) async {
    final now = DateTime(2026, 1, 1);
    final initial = AppState(
      accounts: [
        Account(
            id: 'bca',
            name: 'BCA',
            type: AccountType.bank,
            balance: 5000000,
            createdAt: now),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(InMemoryStorage(initial)),
          authStateProvider
              .overrideWith((_) => Stream.value(const AppUser.local())),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DashboardScreen(),
        ),
      ),
    );

    // Pada awalnya mungkin akan menampilkan loading state
    if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    }

    // Tunggu hingga loading selesai
    await tester.pumpAndSettle();

    // Pastikan app bar tampil
    expect(find.text('MoneyWork'), findsOneWidget);

    expect(find.text('Saldo rekening'), findsOneWidget);

    // 5000000 diformat menjadi Rp 5.000.000. Akan muncul 3 kali di Dashboard:
    // 1 di Net Worth, 1 di Total Assets, 1 di rincian Kas.
    expect(find.text('Rp 5.000.000'), findsWidgets);

    // Pastikan "Transaksi Terbaru" tampil
    await tester.scrollUntilVisible(find.text('Transaksi Terbaru'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Transaksi Terbaru'), findsOneWidget);

    // Pastikan label "Belum ada transaksi." tampil
    expect(find.text('Belum ada transaksi.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-tools')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proyeksi arus kas'));
    await tester.pumpAndSettle();
    expect(find.byType(CashFlowForecastScreen), findsOneWidget);
    expect(find.text('Proyeksi arus kas'), findsOneWidget);
  });
}
