import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/models/transaction.dart' as model;
import 'package:moneywork/models/account.dart' as model;
import 'package:moneywork/screens/accounts_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:moneywork/l10n/app_localizations.dart';

import 'helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('AccountsScreen renders and opens add transaction dialog', (WidgetTester tester) async {
    final now = DateTime.now();
    // Setup state with a transaction to populate the category list for autocomplete
    final appState = AppState(
      accounts: [
        model.Account(id: 'a1', name: 'BCA', type: model.AccountType.bank, balance: 100000, createdAt: now)
      ],
      transactions: [
        model.Transaction(
          id: '1',
          accountId: 'a1',
          amount: 10000,
          date: now,
          type: model.TxType.expense,
          category: 'Makanan Enak',
          note: 'Makan siang',
        )
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(InMemoryStorage(appState)),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountsScreen(),
        ),
      ),
    );

    // Initial render and wait for loading to finish
    await tester.pumpAndSettle();

    expect(find.byType(AccountsScreen), findsOneWidget);

    // Find the add button (FAB)
    final addBtn = find.widgetWithText(FloatingActionButton, 'Catat Transaksi');
    expect(addBtn, findsOneWidget);

    // Tap to open dialog
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // The dialog should appear (Catat Transaksi text is used for FAB and Dialog Title)
    expect(find.text('Catat Transaksi'), findsNWidgets(2));
    
    // Find Kategori input
    final categoryField = find.widgetWithText(TextField, 'Kategori');
    expect(categoryField, findsOneWidget);

    // Type in category field to trigger autocomplete
    await tester.enterText(categoryField, 'Makan');
    await tester.pumpAndSettle();

    // Ensure autocomplete suggestion "Makanan Enak" appears
    expect(find.text('Makanan Enak'), findsWidgets);
  });
}
