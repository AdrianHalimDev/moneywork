import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/screens/report_screen.dart';

import 'helpers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  testWidgets('export format changes whether the period picker is shown',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [storageProvider.overrideWithValue(InMemoryStorage())],
      child: const MaterialApp(
        locale: Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();
    expect(find.text('Periode'), findsOneWidget);

    await tester.tap(find.text('Backup Seluruh Data (Excel)'));
    await tester.pumpAndSettle();
    expect(find.text('Periode'), findsNothing);
  });
}
