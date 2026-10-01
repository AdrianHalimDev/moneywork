import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/storage.dart';
import 'package:moneywork/models/account.dart';

class _FlakyStorage implements StorageBackend {
  AppState saved = const AppState();
  bool fail = true;

  @override
  Future<AppState> load() async => saved;

  @override
  Future<void> save(AppState state) async {
    if (fail) throw StateError('network unavailable');
    saved = state;
  }

  @override
  Future<void> clear() async {
    saved = const AppState();
  }
}

void main() {
  test('failed save stays pending and retry sends the latest state', () async {
    final storage = _FlakyStorage();
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);
    await container.read(appStateProvider.notifier).addAccount(
      name: 'Bank', type: AccountType.bank, initialBalance: 1000,
    );
    await _waitForPhase(container, SyncPhase.error);
    expect(storage.saved.accounts, isEmpty);
    expect(container.read(appStateProvider).requireValue.accounts.length, 1);

    storage.fail = false;
    await container.read(appStateProvider.notifier).retrySync();
    await _waitForPhase(container, SyncPhase.synced);
    expect(storage.saved.accounts.single.balance, 1000);
  });
}

Future<void> _waitForPhase(ProviderContainer container, SyncPhase phase) async {
  for (var i = 0; i < 100; i++) {
    if (container.read(syncStatusProvider).phase == phase) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Sync status did not reach $phase');
}
