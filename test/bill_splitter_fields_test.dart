import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/screens/bill_splitter_screen.dart';
import 'package:moneywork/screens/receipt_assign_screen.dart';
import 'package:moneywork/services/bill_splitter.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  testWidgets('nominal OCR dan persentase saling memperbarui', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BillSplitterScreen(
          initialPeople: [
            PersonAssignment(
                name: 'A',
                items: const [BillItem(name: 'Makan', price: 10000)]),
          ],
          initialService: 500,
          initialPpn: 1000,
          initialDiscount: 100,
          initialAdditionalFees: 250,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final percentFields = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Persentase');
    final amountFields = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Nominal');
    expect(percentFields, findsNWidgets(2));
    expect(amountFields, findsNWidgets(2));
    expect(tester.widget<TextField>(percentFields.first).controller!.text, '5');
    expect(
        tester.widget<TextField>(amountFields.last).controller!.text, '1.000');

    await tester.ensureVisible(percentFields.last);
    await tester.enterText(percentFields.last, '10');
    await tester.pump();
    expect(
        tester.widget<TextField>(amountFields.last).controller!.text, '1.050');

    await tester.ensureVisible(amountFields.first);
    await tester.enterText(amountFields.first, '1000');
    await tester.pump();
    expect(
        tester.widget<TextField>(percentFields.first).controller!.text, '10');
    expect(
        tester.widget<TextField>(amountFields.last).controller!.text, '1.100');
  });
}
