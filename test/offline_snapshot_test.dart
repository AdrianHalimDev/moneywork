import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/firebase/crypto_service.dart';
import 'package:moneywork/firebase/offline_snapshot.dart';
import 'package:moneywork/models/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('encrypted offline snapshot survives restart without plaintext', () async {
    final key = await CryptoService.instance.generateDek();
    final account = Account(
      id: 'account-1', name: 'Rahasia Bank', type: AccountType.bank,
      balance: 42000, createdAt: DateTime(2026, 1, 1),
    );
    final state = AppState(accounts: [account]);
    final store = OfflineSnapshotStore('user-1', keyProvider: () async => key);
    await store.save(OfflineSnapshot(
      state: state,
      baseline: {'accounts/account-1': {'name': 'Rahasia Bank'}},
      revisions: {'accounts/account-1': 7},
      pending: true,
      needsMigration: false,
    ));

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mw_offline_v1_user-1')!;
    expect(raw, isNot(contains('Rahasia Bank')));
    expect(raw, isNot(contains('42000')));
    final reopened = OfflineSnapshotStore('user-1', keyProvider: () async => key);
    final restored = await reopened.load();
    expect(restored!.state.accounts.single.name, 'Rahasia Bank');
    expect(restored.pending, isTrue);
    expect(restored.revisions['accounts/account-1'], 7);
    expect(restored.baseline['accounts/account-1']!['name'], 'Rahasia Bank');
  });

  test('snapshot cannot be read with another key or user ID', () async {
    final key = await CryptoService.instance.generateDek();
    final otherKey = await CryptoService.instance.generateDek();
    final store = OfflineSnapshotStore('user-1', keyProvider: () async => key);
    await store.save(const OfflineSnapshot(
      state: AppState(), baseline: {}, revisions: {}, pending: false,
      needsMigration: true,
    ));
    final wrongKey = OfflineSnapshotStore(
        'user-1', keyProvider: () async => otherKey);
    expect(wrongKey.load(), throwsFormatException);
    final otherUser = OfflineSnapshotStore(
        'user-2', keyProvider: () async => key);
    expect(await otherUser.load(), isNull);
  });
}
