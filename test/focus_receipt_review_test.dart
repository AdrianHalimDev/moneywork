import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/models/receipt.dart';
import 'package:moneywork/screens/receipt_scanner_screen.dart';

const mismatch = ReceiptScanResult(
  items: [
    ReceiptItem(itemName: 'Kopi', unitPrice: 10000, totalPrice: 10000),
  ],
  subtotal: 10000,
  grandTotal: 12000,
);

void main() {
  for (final width in [320.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('receipt review source and validation fit $width, dark=$dark',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final source = base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');
        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            locale: const Locale('id'),
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(width == 320 ? 1.6 : 1)),
              child: child!,
            ),
            home: ReceiptReviewScreen(
                initialData: mismatch, sourceImageBytes: source),
          ),
        ));
        await tester.pumpAndSettle();
        final save = find.widgetWithText(FilledButton, 'Simpan sbg Transaksi');
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(find.text('Selisih dengan dokumen'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (width >= 1000) {
          expect(find.byKey(const ValueKey('receipt-original-panel')),
              findsOneWidget);
        } else {
          expect(find.byKey(const ValueKey('receipt-original-panel')),
              findsNothing);
          await tester.tap(find.byKey(const ValueKey('receipt-view-original')));
          await tester.pumpAndSettle();
          expect(find.byType(InteractiveViewer), findsOneWidget);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        final total = find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Grand Total (Kertas)');
        await tester.scrollUntilVisible(total, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.enterText(total, '10000');
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
        expect(
            find.text('Total tidak sinkron (Selisih: Rp 2000)'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('deleting a receipt item keeps the next item editors attached',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReceiptReviewScreen(
          initialData: ReceiptScanResult(
            items: [
              ReceiptItem(
                  itemName: 'Kopi', unitPrice: 10000, totalPrice: 10000),
              ReceiptItem(itemName: 'Teh', unitPrice: 8000, totalPrice: 8000),
            ],
            subtotal: 18000,
            grandTotal: 18000,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final remove = find.byTooltip('Hapus').first;
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text('Kopi'), findsNothing);
    expect(find.text('Teh'), findsOneWidget);
    final price = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Harga Satuan');
    expect(tester.widget<TextField>(price).controller!.text, '8000');
    expect(tester.takeException(), isNull);
  });
}
