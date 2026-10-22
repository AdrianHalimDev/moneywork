import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/storage.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:moneywork/widgets/sync_indicator.dart';

import 'helpers.dart';

class _LocalProbe extends LocalStorage {
  AppState snapshot = const AppState();
  int saveFailures = 0;

  @override
  Future<AppState> load() async => snapshot;

  @override
  Future<void> save(AppState state) async {
    if (saveFailures > 0) {
      saveFailures--;
      throw StateError('Perangkat penuh');
    }
    snapshot = state;
  }
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  test('labels distinguish local, confirmed cloud and staged offline state',
      () {
    expect(syncStatusLabel(const SyncStatus(SyncPhase.loading), l10n),
        l10n.syncStatusLoading);
    expect(syncStatusLabel(const SyncStatus(SyncPhase.synced), l10n),
        l10n.focusCloudSaved);
    expect(
        syncStatusLabel(const SyncStatus(SyncPhase.synced), l10n, local: true),
        l10n.focusLocalMode);
    expect(
        syncStatusLabel(const SyncStatus(SyncPhase.pending), l10n, local: true),
        l10n.syncStatusPending);
    expect(
        syncStatusLabel(
            const SyncStatus(SyncPhase.pending, savedOnDevice: true), l10n,
            local: true),
        l10n.focusLocalMode);
    expect(syncStatusLabel(const SyncStatus(SyncPhase.pending), l10n),
        l10n.syncStatusPending);
    expect(
        syncStatusLabel(
            const SyncStatus(SyncPhase.pending, savedOnDevice: true), l10n),
        l10n.focusDevicePending);
    expect(
        syncStatusLabel(
            const SyncStatus(SyncPhase.pending,
                message: 'cache', savedOnDevice: true),
            l10n),
        l10n.focusDevicePending);
  });

  test('error labels never claim unsaved changes are stored', () {
    expect(syncStatusLabel(const SyncStatus(SyncPhase.error), l10n),
        l10n.focusSyncFailed);
    expect(
        syncStatusLabel(const SyncStatus(SyncPhase.error), l10n, local: true),
        l10n.syncStatusError);
    expect(
        syncStatusLabel(
            const SyncStatus(SyncPhase.error, savedOnDevice: true), l10n),
        l10n.focusDevicePending);
    expect(
        syncStatusLabel(
            const SyncStatus(SyncPhase.error,
                savedOnDevice: true, conflict: true),
            l10n),
        l10n.focusConflict);
  });

  Future<ProviderContainer> mount(WidgetTester tester, SyncStatus status,
      {bool local = false}) async {
    final container = ProviderContainer(overrides: [
      storageProvider
          .overrideWithValue(local ? _LocalProbe() : InMemoryStorage()),
      syncStatusProvider.overrideWith((_) => status),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
            body: Column(children: [
          SyncIndicator(showLabel: true),
          SyncStatusBanner(),
        ])),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('local failure offers retry without cloud or connectivity advice',
      (tester) async {
    await mount(
        tester, const SyncStatus(SyncPhase.error, message: 'Perangkat penuh'),
        local: true);
    expect(find.text(l10n.syncStatusError), findsNWidgets(2));
    expect(find.text(l10n.syncRetry), findsOneWidget);
    expect(find.text(l10n.syncLoadCloud), findsNothing);
    expect(find.text(l10n.focusSyncHint), findsNothing);
    expect(find.text(l10n.focusDevicePending), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cloud offline edits retain device confirmation and recovery',
      (tester) async {
    await mount(
        tester,
        const SyncStatus(SyncPhase.error,
            savedOnDevice: true, message: 'unavailable'));
    expect(find.text(l10n.focusDevicePending), findsNWidgets(2));
    expect(find.text(l10n.focusSyncHint), findsOneWidget);
    expect(find.text(l10n.syncLoadCloud), findsOneWidget);
    expect(find.text(l10n.focusCloudSaved), findsNothing);
    await tester.tap(find.text(l10n.syncLoadCloud));
    await tester.pumpAndSettle();
    expect(find.text(l10n.syncDiscardTitle), findsOneWidget);
    await tester.tap(find.text(l10n.syncCancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.focusDevicePending), findsNWidgets(2));
  });

  testWidgets('cloud conflict is explicit and retains encrypted-device hint',
      (tester) async {
    await mount(
        tester,
        const SyncStatus(SyncPhase.error,
            savedOnDevice: true, conflict: true, message: 'conflict'));
    expect(find.text(l10n.focusConflict), findsNWidgets(2));
    expect(find.text(l10n.focusSyncHint), findsOneWidget);
    expect(find.text(l10n.syncLoadCloud), findsOneWidget);
    expect(find.text(l10n.focusCloudSaved), findsNothing);
  });

  testWidgets('local write retry preserves optimistic state until persisted',
      (tester) async {
    final storage = _LocalProbe()..saveFailures = 1;
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    final observed = <SyncStatus>[];
    final subscription =
        container.listen(syncStatusProvider, (_, next) => observed.add(next));
    addTearDown(subscription.close);
    await container.read(appStateProvider.notifier).setThemeMode('dark');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(container.read(appStateProvider).requireValue.themeMode, 'dark');
    expect(storage.snapshot.themeMode, 'system');
    expect(container.read(syncStatusProvider).phase, SyncPhase.error);
    expect(container.read(syncStatusProvider).savedOnDevice, isFalse);
    expect(
        observed.any((status) =>
            status.phase == SyncPhase.pending && !status.savedOnDevice),
        isTrue);
    await container.read(appStateProvider.notifier).retrySync();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(storage.snapshot.themeMode, 'dark');
    expect(container.read(syncStatusProvider).phase, SyncPhase.synced);
    expect(container.read(syncStatusProvider).savedOnDevice, isTrue);
  });
}
