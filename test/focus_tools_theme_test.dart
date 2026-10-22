import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/core/theme.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/display_preferences.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/screens/finance_tools_screen.dart';

import 'helpers.dart';

class _ThemeHarness extends ConsumerWidget {
  const _ThemeHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: const Locale('id'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: Column(children: [
        Consumer(
            builder: (context, previewRef, _) => Text(
                formatVisibleMoney(previewRef, 12500),
                key: const ValueKey('global-privacy-preview'))),
        const Expanded(child: FinanceToolsScreen()),
      ])),
    );
  }
}

void main() {
  Future<(ProviderContainer, InMemoryStorage)> mount(
      WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = InMemoryStorage();
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const _ThemeHarness()));
    await tester.pumpAndSettle();
    return (container, storage);
  }

  testWidgets('tools applies dark, light and system themes through controller',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final (container, storage) = await mount(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(FinanceToolsScreen)))!;
    for (final choice in [
      ('dark', l10n.themeDark, ThemeMode.dark, Brightness.dark),
      ('light', l10n.themeLight, ThemeMode.light, Brightness.light),
      ('system', l10n.themeSystem, ThemeMode.system, Brightness.light),
    ]) {
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice.$2).last);
      await tester.pumpAndSettle();
      expect(
          container.read(appStateProvider).requireValue.themeMode, choice.$1);
      expect(container.read(themeModeProvider), choice.$3);
      expect((await storage.load()).themeMode, choice.$1);
      expect(
          Theme.of(tester.element(find.byType(FinanceToolsScreen))).brightness,
          choice.$4);
      expect(tester.takeException(), isNull);
    }
    // System mode continues following the OS after the user selects it.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(FinanceToolsScreen))).brightness,
        Brightness.dark);
  });

  testWidgets('privacy switch updates consumers outside tools and keeps data',
      (tester) async {
    final (container, storage) = await mount(tester);
    final before = container.read(appStateProvider).requireValue.toJson();
    expect(find.text('Rp 12.500'), findsOneWidget);
    final toggle = find.byType(SwitchListTile);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(container.read(amountsHiddenProvider), isTrue);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('global-privacy-preview')))
            .data,
        'Rp ••••••');
    expect(container.read(appStateProvider).requireValue.toJson(), before);
    expect((await storage.load()).toJson(), const AppState().toJson());
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(container.read(amountsHiddenProvider), isFalse);
    expect(find.text('Rp 12.500'), findsOneWidget);
  });
}
