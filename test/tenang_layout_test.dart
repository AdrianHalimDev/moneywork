import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/firebase/auth.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/investment.dart';
import 'package:moneywork/models/transaction.dart' as model;
import 'package:moneywork/router.dart';
import 'package:moneywork/screens/dashboard_screen.dart';
import 'package:moneywork/screens/investments_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'helpers.dart';

final day = DateTime(2026, 10, 21);
AppState fixture() => AppState(accounts: [
      Account(
          id: 'bca',
          name: 'BCA',
          type: AccountType.bank,
          balance: 15000000,
          createdAt: day),
      Account(
          id: 'wallet',
          name: 'GoPay',
          type: AccountType.ewallet,
          balance: 1400000,
          createdAt: day),
    ], investments: [
      Investment(
          id: 'bbca',
          name: 'BBCA',
          type: InvestmentType.stock,
          quantity: 3000,
          buyPrice: 7200,
          currentPrice: 8000,
          updatedAt: day),
      Investment(
          id: 'gold',
          name: 'Emas Antam',
          type: InvestmentType.gold,
          quantity: 10,
          buyPrice: 1880000,
          currentPrice: 2000000,
          updatedAt: day),
    ], transactions: [
      model.Transaction(
          id: 'coffee',
          accountId: 'bca',
          amount: 32000,
          type: model.TxType.expense,
          date: day,
          note: 'Kopi sore',
          category: 'Makan & minum'),
    ]);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    const directory = String.fromEnvironment('MONEYWORK_QA_FONT_DIR');
    if (directory.isNotEmpty) {
      final roboto = FontLoader('Roboto');
      for (final name in [
        'roboto-regular.ttf',
        'roboto-medium.ttf',
        'roboto-bold.ttf'
      ]) {
        roboto.addFont(Future.value(
            ByteData.sublistView(File('$directory/$name').readAsBytesSync())));
      }
      await roboto.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(
            File('$directory/MaterialIcons-Regular.otf').readAsBytesSync())));
      await icons.load();
    }
  });

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('tenang-capture')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/tenang-qa')..createSync(recursive: true);
      File('${dir.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
      'phone and web use Tenang shell, functional navigation and asset order',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = InMemoryStorage(fixture());
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(storage),
      authStateProvider.overrideWith((_) => Stream.value(const AppUser(
          uid: 'example',
          email: 'example@example.test',
          displayName: 'Adrian'))),
    ]);
    addTearDown(container.dispose);
    final router = createAppRouter(navigatorKey: GlobalKey<NavigatorState>());
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
            key: const ValueKey('tenang-capture'),
            child: MaterialApp.router(
                locale: const Locale('id'),
                theme: AppTheme.light(),
                debugShowCheckedModeBanner: false,
                darkTheme: AppTheme.dark(),
                routerConfig: router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales))));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Halo, Adrian.'), findsOneWidget);
    expect(find.text('Alat keuangan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'desktop-home');
    await tester.tap(find.text('Aset').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('investment-table')), findsOneWidget);
    await capture(tester, 'desktop-assets');
    await tester.tap(find.byKey(const ValueKey('reorder-assets')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('asset-up-gold')));
    await tester.tap(find.text('Simpan urutan'));
    await tester.pumpAndSettle();
    expect(container.read(appStateProvider).requireValue.investmentOrder,
        ['gold', 'bbca']);
    final rows = find.byType(DataTable).evaluate().single.widget as DataTable;
    expect(rows.rows.first.key, const ValueKey('investment-gold'));
    expect((await storage.load()).investmentOrder, ['gold', 'bbca']);
    ScaffoldMessenger.of(tester.element(find.byType(InvestmentsScreen)))
        .clearSnackBars();
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('investment-table')), findsNothing);
    expect(tester.takeException(), isNull);
    await capture(tester, 'phone-assets');
    // Drag ke bawah memakai API Flutter baru, lalu batal tanpa menyimpan.
    await tester.tap(find.byKey(const ValueKey('reorder-assets')));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ReorderableDragStartListener).first));
    await tester.pump();
    for (var step = 0; step < 14; step++) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('bbca'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('gold'))).dy));
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(container.read(appStateProvider).requireValue.investmentOrder,
        ['gold', 'bbca']);
    // Perubahan yang tiba saat editor terbuka harus direview ulang.
    await tester.tap(find.byKey(const ValueKey('reorder-assets')));
    await tester.pumpAndSettle();
    await container
        .read(appStateProvider.notifier)
        .setInvestmentOrder(['bbca', 'gold']);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan urutan'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Urutan berubah di perangkat lain. Tutup dan buka kembali pengaturan urutan.'),
        findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beranda').last);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    await capture(tester, 'phone-home');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    await capture(tester, 'phone-home-dark');
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-dashboard-balances')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('dashboard-cash-total')))
            .data,
        'Rp ••••••');
    expect(find.text('Rp 60.400.000'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [320.0, 760.0]) {
    for (final dark in [false, true]) {
      testWidgets('dashboard/assets fit width $width, large text, dark=$dark',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 960);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final screen in [
          const DashboardScreen(),
          const InvestmentsScreen()
        ]) {
          await tester.pumpWidget(ProviderScope(
              overrides: [
                storageProvider.overrideWithValue(InMemoryStorage(fixture())),
                authStateProvider
                    .overrideWith((_) => Stream.value(const AppUser.local())),
              ],
              child: MaterialApp(
                  locale: const Locale('id'),
                  theme: dark ? AppTheme.dark() : AppTheme.light(),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: const TextScaler.linear(1.6)),
                      child: child!),
                  home: screen)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (screen is InvestmentsScreen) {
            await tester
                .ensureVisible(find.byKey(const ValueKey('reorder-assets')));
            await tester.tap(find.byKey(const ValueKey('reorder-assets')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('Batal'));
            await tester.pumpAndSettle();
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    }
  }
}
