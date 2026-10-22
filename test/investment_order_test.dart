import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/storage.dart';
import 'package:moneywork/firebase/record_codec.dart';
import 'package:moneywork/firebase/firestore_storage.dart';
import 'package:moneywork/models/investment.dart';
import 'package:moneywork/models/account.dart';

final assets = [
  for (var i = 0; i < 3; i++)
    Investment(
      id: '$i',
      name: 'Aset $i',
      type: InvestmentType.gold,
      quantity: i + 1,
      buyPrice: 1000,
      currentPrice: 1200,
      updatedAt: DateTime(2026, 10, 21),
    )
];

final accounts = [
  for (var i = 0; i < 3; i++)
    Account(
        id: 'bank-$i',
        name: 'Bank $i',
        type: AccountType.bank,
        balance: (i + 1) * 1000,
        createdAt: DateTime(2026, 10, 21))
];

/// Dua replika memakai codec/revisi yang sama dengan backend produksi.
/// Tidak menghubungi atau mengubah akun Firebase sungguhan.
class _Cloud {
  final records =
      RecordCodec.encode(AppState(investments: assets, accounts: accounts));
  late final revisions = {for (final key in records.keys) key: 1};
  final changes = StreamController<DisplayOrderUpdate>.broadcast(sync: true);
}

class _Replica implements StorageBackend, DisplayOrderSync {
  _Replica(this.cloud);
  final _Cloud cloud;
  Map<String, Map<String, dynamic>> baseline = {};
  Map<String, int> revisions = {};
  AppState? cache;
  bool offline = false;
  Completer<void>? gate;
  Completer<void>? loadGate;

  @override
  Future<AppState> load() async {
    baseline = Map.from(cloud.records);
    revisions = Map.from(cloud.revisions);
    if (loadGate != null) await loadGate!.future;
    return RecordCodec.decode(baseline);
  }

  @override
  Future<void> save(AppState state) async {
    cache = state;
    if (offline) throw StateError('offline');
    if (gate != null) await gate!.future;
    final desired = RecordCodec.encode(state);
    final changed = RecordCodec.changedKeys(baseline, desired);
    for (final key in changed) {
      if (revisions[key] != cloud.revisions[key]) {
        throw const SyncConflictException('conflict');
      }
    }
    for (final key in changed) {
      if (desired[key] == null) {
        cloud.records.remove(key);
        cloud.revisions.remove(key);
      } else {
        cloud.records[key] = desired[key]!;
        cloud.revisions[key] = (cloud.revisions[key] ?? 0) + 1;
      }
    }
    baseline = Map.from(desired);
    for (final key in changed) {
      if (cloud.revisions.containsKey(key)) {
        revisions[key] = cloud.revisions[key]!;
      }
    }
    for (final kind in DisplayOrderKind.values) {
      if (changed.contains(kind.recordKey)) {
        cloud.changes.add(DisplayOrderUpdate(
            kind == DisplayOrderKind.accounts
                ? state.accountOrder
                : state.investmentOrder,
            cloud.revisions[kind.recordKey]!,
            kind: kind));
      }
    }
  }

  @override
  Stream<DisplayOrderUpdate> watchDisplayOrders() => cloud.changes.stream;
  @override
  bool acceptDisplayOrder(DisplayOrderUpdate update) {
    final key = update.kind.recordKey;
    if (update.revision <= (revisions[key] ?? 0)) return false;
    baseline[key] = {'ids': update.ids};
    revisions[key] = update.revision;
    return true;
  }

  @override
  Future<void> cacheSyncedState(AppState state) async {
    cache = state;
  }

  @override
  Future<void> clear() async {
    cache = const AppState();
  }
}

Future<void> waitUntil(bool Function() condition) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('Expected asynchronous state was not reached');
}

void main() {
  test('legacy data, duplicate/deleted IDs and new assets retain every asset',
      () {
    final legacy = AppState.fromJson(
        AppState(investments: assets).toJson()..remove('investmentOrder'));
    expect(legacy.orderedInvestments.map((a) => a.id), ['0', '1', '2']);
    final ordered =
        legacy.copyWith(investmentOrder: ['2', 'deleted', '2', '0']);
    expect(ordered.orderedInvestments.map((a) => a.id), ['2', '0', '1']);
    expect(ordered.totalInvestment, legacy.totalInvestment);
    expect(AppState.fromJson(ordered.toJson()).investmentOrder,
        ['2', 'deleted', '2', '0']);
  });

  test('record map iteration cannot change preferred order or asset values',
      () {
    final before = AppState(investments: assets);
    final after = before.copyWith(investmentOrder: ['2', '0', '1']);
    final encoded = RecordCodec.encode(after);
    expect(RecordCodec.changedKeys(RecordCodec.encode(before), encoded),
        {RecordCodec.investmentOrderKey});
    final reversed = Map<String, Map<String, dynamic>>.fromEntries(
        encoded.entries.toList().reversed);
    final loaded = RecordCodec.decode(reversed);
    expect(loaded.orderedInvestments.map((a) => a.id), ['2', '0', '1']);
    expect(loaded.totalInvestment, before.totalInvestment);
    final deviceTwo = RecordCodec.encode(before.copyWith(locale: 'en'));
    final merged = RecordCodec.decode({
      ...deviceTwo,
      RecordCodec.investmentOrderKey: encoded[RecordCodec.investmentOrderKey]!
    });
    expect(merged.locale, 'en');
    expect(merged.investmentOrder, ['2', '0', '1']);
  });

  late _Cloud cloud;
  late _Replica one, two;
  late ProviderContainer first, second;
  setUp(() async {
    cloud = _Cloud();
    one = _Replica(cloud);
    two = _Replica(cloud);
    first =
        ProviderContainer(overrides: [storageProvider.overrideWithValue(one)]);
    second =
        ProviderContainer(overrides: [storageProvider.overrideWithValue(two)]);
    await first.read(appStateProvider.future);
    await second.read(appStateProvider.future);
  });
  tearDown(() async {
    first.dispose();
    second.dispose();
    await cloud.changes.close();
  });

  test('open devices receive order and persist it through later edits/restart',
      () async {
    await first
        .read(appStateProvider.notifier)
        .setInvestmentOrder(['2', '0', '1']);
    await waitUntil(() => const ListEquality<String>().equals(
        second.read(appStateProvider).requireValue.investmentOrder,
        ['2', '0', '1']));
    expect(two.cache!.investmentOrder, ['2', '0', '1']);
    final revision = cloud.revisions[RecordCodec.investmentOrderKey];
    await second.read(appStateProvider.notifier).setLocale('en');
    await waitUntil(
        () => second.read(syncStatusProvider).phase == SyncPhase.synced);
    expect(cloud.revisions[RecordCodec.investmentOrderKey], revision);
    final reopened = await _Replica(cloud).load();
    expect(reopened.investmentOrder, ['2', '0', '1']);
    expect(reopened.locale, 'en');
    expect(reopened.totalInvestment,
        AppState(investments: assets).totalInvestment);
  });

  test('remote ordering waits for unrelated local save without losing locale',
      () async {
    one.gate = Completer<void>();
    await first.read(appStateProvider.notifier).setLocale('en');
    await waitUntil(
        () => first.read(syncStatusProvider).phase == SyncPhase.pending);
    await second
        .read(appStateProvider.notifier)
        .setInvestmentOrder(['1', '2', '0']);
    await waitUntil(
        () => second.read(syncStatusProvider).phase == SyncPhase.synced);
    one.gate!.complete();
    await waitUntil(() =>
        first.read(appStateProvider).requireValue.investmentOrder.isNotEmpty);
    expect(first.read(appStateProvider).requireValue.locale, 'en');
    expect(first.read(appStateProvider).requireValue.investmentOrder,
        ['1', '2', '0']);
  });

  test(
      'offline concurrent orders conflict and keep local work until cloud chosen',
      () async {
    one.offline = true;
    await first
        .read(appStateProvider.notifier)
        .setInvestmentOrder(['2', '1', '0']);
    await waitUntil(
        () => first.read(syncStatusProvider).phase == SyncPhase.error);
    await second
        .read(appStateProvider.notifier)
        .setInvestmentOrder(['1', '0', '2']);
    await waitUntil(
        () => second.read(syncStatusProvider).phase == SyncPhase.synced);
    expect(first.read(appStateProvider).requireValue.investmentOrder,
        ['2', '1', '0']);
    one.offline = false;
    await first.read(appStateProvider.notifier).retrySync();
    await waitUntil(
        () => first.read(syncStatusProvider).phase == SyncPhase.error);
    expect(first.read(syncStatusProvider).message, contains('conflict'));
    expect(
        cloud.records[RecordCodec.investmentOrderKey]!['ids'], ['1', '0', '2']);
    await first.read(appStateProvider.notifier).discardPendingAndReload();
    expect(first.read(appStateProvider).requireValue.investmentOrder,
        ['1', '0', '2']);
  });

  test('invalid order cannot silently lose or duplicate an asset', () async {
    final ctrl = first.read(appStateProvider.notifier);
    await expectLater(ctrl.setInvestmentOrder(['0', '1']), throwsStateError);
    await expectLater(
        ctrl.setInvestmentOrder(['0', '0', '2']), throwsStateError);
    await expectLater(
        ctrl.setInvestmentOrder(['0', '1', 'missing']), throwsStateError);
    expect(first.read(appStateProvider).requireValue.investmentOrder, isEmpty);
  });

  test(
      'remote ordering during reload is applied after the snapshot, edits wait',
      () async {
    one.loadGate = Completer<void>();
    final controller = first.read(appStateProvider.notifier);
    final reload = controller.reloadFromStorage();
    await expectLater(
        controller.setInvestmentOrder(['0', '2', '1']), throwsStateError);
    await second
        .read(appStateProvider.notifier)
        .setInvestmentOrder(['2', '0', '1']);
    await waitUntil(
        () => second.read(syncStatusProvider).phase == SyncPhase.synced);
    one.loadGate!.complete();
    await reload;
    expect(first.read(appStateProvider).requireValue.investmentOrder,
        ['2', '0', '1']);
  });

  test('legacy accounts and stale IDs preserve balances and every live account',
      () {
    final original = AppState(accounts: accounts);
    final legacy = AppState.fromJson(original.toJson()..remove('accountOrder'));
    expect(legacy.orderedAccounts.map((a) => a.id),
        ['bank-0', 'bank-1', 'bank-2']);
    final ordered = legacy
        .copyWith(accountOrder: ['bank-2', 'deleted', 'bank-2', 'bank-0']);
    expect(ordered.orderedAccounts.map((a) => a.id),
        ['bank-2', 'bank-0', 'bank-1']);
    final encoded = RecordCodec.encode(ordered);
    expect(RecordCodec.changedKeys(RecordCodec.encode(original), encoded),
        {RecordCodec.accountOrderKey});
    final loaded =
        RecordCodec.decode(Map.fromEntries(encoded.entries.toList().reversed));
    expect(loaded.orderedAccounts.map((a) => a.id),
        ['bank-2', 'bank-0', 'bank-1']);
    expect(loaded.totalCash, original.totalCash);
  });

  test(
      'account order reaches open devices and survives restart and preference edits',
      () async {
    await first
        .read(appStateProvider.notifier)
        .setAccountOrder(['bank-2', 'bank-0', 'bank-1']);
    await waitUntil(() =>
        second.read(appStateProvider).requireValue.accountOrder.isNotEmpty);
    expect(second.read(appStateProvider).requireValue.accountOrder,
        ['bank-2', 'bank-0', 'bank-1']);
    expect(two.cache!.accountOrder, ['bank-2', 'bank-0', 'bank-1']);
    await second.read(appStateProvider.notifier).setLocale('en');
    await waitUntil(
        () => second.read(syncStatusProvider).phase == SyncPhase.synced);
    final reopened = await _Replica(cloud).load();
    expect(reopened.accountOrder, ['bank-2', 'bank-0', 'bank-1']);
    expect(reopened.totalCash, 6000);
  });

  test('simultaneous account and asset orders use independent revisions',
      () async {
    await Future.wait([
      first
          .read(appStateProvider.notifier)
          .setAccountOrder(['bank-2', 'bank-1', 'bank-0']),
      second
          .read(appStateProvider.notifier)
          .setInvestmentOrder(['1', '2', '0']),
    ]);
    await waitUntil(() =>
        first.read(syncStatusProvider).phase == SyncPhase.synced &&
        second.read(syncStatusProvider).phase == SyncPhase.synced);
    for (final device in [first, second]) {
      final value = device.read(appStateProvider).requireValue;
      expect(value.accountOrder, ['bank-2', 'bank-1', 'bank-0']);
      expect(value.investmentOrder, ['1', '2', '0']);
      expect(value.totalCash, 6000);
    }
  });

  test(
      'conflicting offline account orders preserve local work until cloud chosen',
      () async {
    one.offline = true;
    await first
        .read(appStateProvider.notifier)
        .setAccountOrder(['bank-2', 'bank-1', 'bank-0']);
    await waitUntil(
        () => first.read(syncStatusProvider).phase == SyncPhase.error);
    await second
        .read(appStateProvider.notifier)
        .setAccountOrder(['bank-1', 'bank-0', 'bank-2']);
    await waitUntil(
        () => second.read(syncStatusProvider).phase == SyncPhase.synced);
    one.offline = false;
    await first.read(appStateProvider.notifier).retrySync();
    await waitUntil(
        () => first.read(syncStatusProvider).phase == SyncPhase.error);
    expect(first.read(syncStatusProvider).message, contains('conflict'));
    expect(first.read(appStateProvider).requireValue.accountOrder,
        ['bank-2', 'bank-1', 'bank-0']);
    await first.read(appStateProvider.notifier).discardPendingAndReload();
    expect(first.read(appStateProvider).requireValue.accountOrder,
        ['bank-1', 'bank-0', 'bank-2']);
    expect(first.read(appStateProvider).requireValue.totalCash, 6000);
  });

  test('invalid account order cannot lose or duplicate an account', () async {
    final controller = first.read(appStateProvider.notifier);
    await expectLater(controller.setAccountOrder(['bank-0']), throwsStateError);
    await expectLater(
        controller.setAccountOrder(['bank-0', 'bank-0', 'bank-1']),
        throwsStateError);
    await expectLater(
        controller.setAccountOrder(['bank-0', 'bank-1', 'missing']),
        throwsStateError);
  });
}
