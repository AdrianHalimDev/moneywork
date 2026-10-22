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
import 'package:moneywork/models/investment.dart';
import 'package:moneywork/screens/investments_screen.dart';

import 'helpers.dart';

final asset = Investment(
  id: 'gold',
  name: 'Emas tabungan',
  type: InvestmentType.gold,
  quantity: 2,
  buyPrice: 200000,
  currentPrice: 250000,
  updatedAt: DateTime(2026, 10, 22),
);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    double width = 1200,
    bool dark = false,
    bool hidden = false,
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      storageProvider
          .overrideWithValue(InMemoryStorage(AppState(investments: [asset]))),
    ]);
    container.read(amountsHiddenProvider.notifier).state = hidden;
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('id'),
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const InvestmentsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openDetail(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Emas tabungan'));
    await tester.tap(find.text('Emas tabungan'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('investment-detail-gold')), findsOneWidget);
    expect(find.text('Detail aset'), findsOneWidget);
  }

  testWidgets('web table opens live asset details with edit and delete access',
      (tester) async {
    final container = await mount(tester);
    expect(find.byKey(const ValueKey('investment-table')), findsOneWidget);
    await openDetail(tester);
    expect(find.text(Fmt.rupiah(500000)), findsOneWidget);
    expect(find.text(Fmt.rupiah(400000)), findsOneWidget);
    expect(find.text('${Fmt.rupiahSigned(100000)} (+25.0%)'), findsOneWidget);

    await container.read(appStateProvider.notifier).updateInvestment(
        asset.copyWith(name: 'Emas berubah', currentPrice: 300000));
    await tester.pumpAndSettle();
    expect(find.text('Emas berubah'), findsOneWidget);
    expect(find.text(Fmt.rupiah(600000)), findsOneWidget);
    expect(find.text(Fmt.rupiah(500000)), findsNothing);
    await tester.tap(find.byKey(const ValueKey('edit-asset-detail')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Investasi'), findsOneWidget);
    expect(find.text('Emas berubah'), findsWidgets);
    await tester.ensureVisible(find.text('Hapus'));
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(container.read(appStateProvider).requireValue.investments, isEmpty);
    expect(
        find.text('Aset sudah dihapus atau tidak tersedia.'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-asset-detail')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'hidden amounts mask portfolio, allocation, table and live detail',
      (tester) async {
    final container = await mount(tester, hidden: true);
    expect(find.text(Fmt.rupiah(500000)), findsNothing);
    expect(find.textContaining('25.0%'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    await openDetail(tester);
    expect(find.text('Rp ••••••'), findsWidgets);
    expect(find.text(Fmt.rupiah(400000)), findsNothing);
    expect(find.text(Fmt.rupiah(200000)), findsNothing);
    expect(find.textContaining('25.0%'), findsNothing);
    expect(find.text('2 unit'), findsNothing);
    container.read(amountsHiddenProvider.notifier).state = false;
    await tester.pumpAndSettle();
    expect(find.text(Fmt.rupiah(500000)), findsOneWidget);
    expect(find.text('${Fmt.rupiahSigned(100000)} (+25.0%)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('phone asset detail and editor fit large text, dark=$dark',
        (tester) async {
      await mount(tester, width: 320, dark: dark, textScale: 1.6);
      expect(find.byKey(const ValueKey('investment-table')), findsNothing);
      await openDetail(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('edit-asset-detail')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Investasi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('investment-detail-gold')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
