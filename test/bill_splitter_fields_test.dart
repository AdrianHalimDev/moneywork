import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('rincian split bill dapat disalin', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BillSplitterScreen(
          initialPeople: [
            PersonAssignment(
                name: 'Alya',
                items: const [BillItem(name: 'Nasi', price: 10000)]),
          ],
          initialPpn: 1000,
          initialDiscount: 500,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final copyButton = find.text('Salin');
    await tester.scrollUntilVisible(copyButton, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(copyButton);
    await tester.pumpAndSettle();
    await tester.tap(copyButton);
    await tester.pump();

    expect(copiedText, contains('Alya'));
    expect(copiedText, contains('Nasi'));
    expect(copiedText, contains('PPN: Rp 1.000'));
    expect(copiedText, contains('Diskon: -Rp 500'));
  });
}
