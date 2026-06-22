import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneywork/data/app_controller.dart';
import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/storage.dart';
import 'package:moneywork/models/account.dart';
import 'package:moneywork/models/debt.dart';
import 'package:moneywork/models/investment.dart';
import 'package:moneywork/models/receivable.dart';
import 'package:moneywork/models/recurring_transaction.dart';
import 'package:moneywork/models/transaction.dart';
import 'package:moneywork/models/wishlist_item.dart';
import 'package:moneywork/services/bill_splitter.dart';
import 'package:moneywork/services/reminders.dart';
import 'package:moneywork/services/report.dart';

/// Storage in-memory untuk menguji controller tanpa SharedPreferences/Firestore.
class InMemoryStorage implements StorageBackend {
  AppState _state;
  InMemoryStorage([this._state = const AppState()]);

  @override
  Future<AppState> load() async => _state;

  @override
  Future<void> save(AppState state) async => _state = state;

  @override
  Future<void> clear() async => _state = const AppState();
}

void main() {
  final now = DateTime(2026, 1, 1);

  // Fmt.date dkk memakai locale id_ID (di app diinisialisasi di main()).
  setUpAll(() => initializeDateFormatting('id_ID', null));

  group('AppState ringkasan kekayaan', () {
    test('net worth = kas + investasi - utang', () {
      final state = AppState(
        accounts: [
          Account(
              id: 'a',
              name: 'BCA',
              type: AccountType.bank,
              balance: 5000000,
              createdAt: now),
          Account(
              id: 'b',
              name: 'Tunai',
              type: AccountType.cash,
              balance: 1000000,
              createdAt: now),
        ],
        investments: [
          Investment(
            id: 'i',
            name: 'BBCA',
            type: InvestmentType.stock,
            quantity: 100,
            buyPrice: 9000,
            currentPrice: 10000,
            updatedAt: now,
          ),
        ],
        debts: [
          Debt(
              id: 'd',
              name: 'KTA',
              type: DebtType.loan,
              remaining: 2000000,
              createdAt: now),
        ],
      );

      expect(state.totalCash, 6000000);
      expect(state.totalInvestment, 1000000); // 100 * 10000
      expect(state.totalDebt, 2000000);
      expect(state.totalAssets, 7000000);
      expect(state.netWorth, 5000000); // 7jt - 2jt
    });

    test('state kosong menghasilkan nol', () {
      const state = AppState();
      expect(state.netWorth, 0);
      expect(state.totalAssets, 0);
    });
  });

  group('Investment untung-rugi', () {
    test('menghitung gain dan persentase', () {
      final inv = Investment(
        id: 'i',
        name: 'Emas',
        type: InvestmentType.gold,
        quantity: 10,
        buyPrice: 1000000,
        currentPrice: 1200000,
        updatedAt: now,
      );
      expect(inv.cost, 10000000);
      expect(inv.marketValue, 12000000);
      expect(inv.gain, 2000000);
      expect(inv.gainPercent, 20);
    });
  });

  group('Serialisasi JSON', () {
    test('AppState round-trip tetap konsisten', () {
      final state = AppState(
        accounts: [
          Account(
              id: 'a',
              name: 'BCA',
              type: AccountType.bank,
              balance: 5000000,
              createdAt: now),
        ],
        debts: [
          Debt(
              id: 'd',
              name: 'KTA',
              type: DebtType.loan,
              remaining: 2000000,
              createdAt: now),
        ],
      );

      final restored = AppState.fromJson(state.toJson());
      expect(restored.totalCash, state.totalCash);
      expect(restored.netWorth, state.netWorth);
      expect(restored.accounts.first.name, 'BCA');
      expect(restored.debts.first.type, DebtType.loan);
    });
  });

  group('Saham dalam lot', () {
    test('lots = quantity / 100', () {
      final saham = Investment(
        id: 's',
        name: 'BBCA',
        type: InvestmentType.stock,
        quantity: 500, // 5 lot
        buyPrice: 9000,
        currentPrice: 10000,
        updatedAt: now,
      );
      expect(saham.lots, 5);
      expect(saham.type.tradedInLots, isTrue);
      expect(saham.marketValue, 5000000); // 500 lembar * 10.000
      expect(saham.gain, 500000); // (10.000-9.000) * 500
    });

    test('jenis non-saham tidak pakai lot', () {
      expect(InvestmentType.crypto.tradedInLots, isFalse);
      expect(InvestmentType.gold.tradedInLots, isFalse);
    });
  });

  group('Bayar utang dari rekening', () {
    test('mengurangi saldo & sisa utang, lalu pembatalan memulihkan keduanya',
        () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 5000000,
              createdAt: now),
        ],
        debts: [
          Debt(
              id: 'kta',
              name: 'KTA',
              type: DebtType.loan,
              remaining: 3000000,
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);

      // Tunggu state awal termuat.
      await container.read(appStateProvider.future);
      final ctrl = container.read(appStateProvider.notifier);

      final err = await ctrl.payDebt(
        debtId: 'kta',
        accountId: 'bca',
        amount: 1000000,
      );
      expect(err, isNull);

      var state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 4000000); // 5jt - 1jt
      expect(state.debts.first.remaining, 2000000); // 3jt - 1jt
      expect(state.transactions.length, 1);
      expect(state.transactions.first.linkedDebtId, 'kta');

      // Batalkan: saldo & utang harus pulih.
      await ctrl.deleteTransaction(state.transactions.first.id);
      state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 5000000);
      expect(state.debts.first.remaining, 3000000);
      expect(state.transactions, isEmpty);
    });

    test('menolak pembayaran melebihi saldo', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 500000,
              createdAt: now),
        ],
        debts: [
          Debt(
              id: 'kta',
              name: 'KTA',
              type: DebtType.loan,
              remaining: 3000000,
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container.read(appStateProvider.notifier).payDebt(
            debtId: 'kta',
            accountId: 'bca',
            amount: 1000000,
          );
      expect(err, isNotNull);
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 500000); // tidak berubah
      expect(state.debts.first.remaining, 3000000);
    });
  });

  group('Profil & pengaturan', () {
    test('themeMode default system & round-trip JSON', () {
      const s = AppState();
      expect(s.themeMode, 'system');
      final restored = AppState.fromJson(s.copyWith(themeMode: 'dark').toJson());
      expect(restored.themeMode, 'dark');
    });

    test('setThemeMode menyimpan preferensi', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage()),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      await container.read(appStateProvider.notifier).setThemeMode('light');
      expect(container.read(appStateProvider).value!.themeMode, 'light');
    });

    test('clearAllData mengosongkan seluruh data', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'a',
              name: 'BCA',
              type: AccountType.bank,
              balance: 100,
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      await container.read(appStateProvider.notifier).clearAllData();
      final state = container.read(appStateProvider).value!;
      expect(state.accounts, isEmpty);
      expect(state.netWorth, 0);
    });
  });

  group('Piutang & net worth', () {
    test('piutang menambah aset & net worth', () {
      final state = AppState(
        accounts: [
          Account(
              id: 'a',
              name: 'BCA',
              type: AccountType.bank,
              balance: 1000000,
              createdAt: now),
        ],
        receivables: [
          Receivable(
              id: 'r',
              personName: 'Gama',
              remaining: 50000,
              createdAt: now),
        ],
      );
      expect(state.totalReceivable, 50000);
      expect(state.totalAssets, 1050000);
      expect(state.netWorth, 1050000);
    });

    test('collectReceivable: uang masuk rekening & piutang berkurang, '
        'pembatalan memulihkan', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 1000000,
              createdAt: now),
        ],
        receivables: [
          Receivable(
              id: 'r',
              personName: 'Gama',
              remaining: 50000,
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final ctrl = container.read(appStateProvider.notifier);

      final err = await ctrl.collectReceivable(
        receivableId: 'r',
        accountId: 'bca',
        amount: 30000,
      );
      expect(err, isNull);

      var state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 1030000);
      expect(state.receivables.first.remaining, 20000);
      expect(state.transactions.first.linkedReceivableId, 'r');

      await ctrl.deleteTransaction(state.transactions.first.id);
      state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 1000000);
      expect(state.receivables.first.remaining, 50000);
    });

    test('collectReceivable menolak jumlah melebihi sisa piutang', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 1000000,
              createdAt: now),
        ],
        receivables: [
          Receivable(
              id: 'r',
              personName: 'Gama',
              remaining: 50000,
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container
          .read(appStateProvider.notifier)
          .collectReceivable(
              receivableId: 'r', accountId: 'bca', amount: 99999);
      expect(err, isNotNull);
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 1000000); // tak berubah
      expect(state.receivables.first.remaining, 50000);
    });
  });

  group('Piutang per orang (grouping & FIFO)', () {
    test('groupByName menggabungkan nama beda kapital & spasi', () {
      final groups = ReceivableGroup.groupByName([
        Receivable(
            id: 'a',
            personName: 'Gama',
            remaining: 100000,
            createdAt: DateTime(2026, 1, 1)),
        Receivable(
            id: 'b',
            personName: 'gama ',
            remaining: 200000,
            createdAt: DateTime(2026, 1, 2)),
        Receivable(
            id: 'c',
            personName: 'Budi',
            remaining: 50000,
            createdAt: DateTime(2026, 1, 1)),
      ]);
      expect(groups.length, 2);
      final gama = groups.firstWhere((g) => g.key == 'gama');
      expect(gama.outstanding, 300000);
      expect(gama.openCount, 2);
      // Nama tampilan mengikuti entri terbaru ('gama ' -> trim 'gama').
      expect(gama.displayName, 'gama');
      // Item terurut paling lama dulu (FIFO).
      expect(gama.items.first.id, 'a');
    });

    test('collectFromPerson alokasi FIFO: 150rb melunasi 100rb dulu', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 1000000,
              createdAt: now),
        ],
        receivables: [
          Receivable(
              id: 'r1',
              personName: 'Gama',
              remaining: 100000,
              createdAt: DateTime(2026, 1, 1)),
          Receivable(
              id: 'r2',
              personName: 'Gama',
              remaining: 200000,
              createdAt: DateTime(2026, 1, 2)),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final ctrl = container.read(appStateProvider.notifier);

      final err = await ctrl.collectFromPerson(
        nameKey: 'gama',
        accountId: 'bca',
        amount: 150000,
      );
      expect(err, isNull);

      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 1150000);
      // r1 (paling lama) lunas, r2 sisa 50rb terpotong -> sisa 150rb.
      expect(state.receivables.firstWhere((r) => r.id == 'r1').remaining, 0);
      expect(state.receivables.firstWhere((r) => r.id == 'r2').remaining, 150000);
      // Dua transaksi income tercatat & tertaut ke pinjaman masing-masing.
      final linked = state.transactions
          .where((t) => t.linkedReceivableId != null)
          .map((t) => t.linkedReceivableId)
          .toSet();
      expect(linked, {'r1', 'r2'});
    });

    test('collectFromPerson menolak jumlah melebihi total sisa', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 1000000,
              createdAt: now),
        ],
        receivables: [
          Receivable(
              id: 'r1',
              personName: 'Gama',
              remaining: 100000,
              createdAt: DateTime(2026, 1, 1)),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container
          .read(appStateProvider.notifier)
          .collectFromPerson(nameKey: 'gama', accountId: 'bca', amount: 150000);
      expect(err, isNotNull);
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 1000000);
      expect(state.receivables.first.remaining, 100000);
    });
  });

  group('Transfer dengan biaya admin', () {
    AppState seed() => AppState(
          accounts: [
            Account(
                id: 'bca',
                name: 'BCA',
                type: AccountType.bank,
                balance: 1000000,
                createdAt: now),
            Account(
                id: 'gopay',
                name: 'GoPay',
                type: AccountType.ewallet,
                balance: 0,
                createdAt: now),
          ],
        );

    test('admin keluar dari sumber, tujuan terima penuh, tercatat terpisah',
        () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seed())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container.read(appStateProvider.notifier).addTransaction(
            type: TxType.transfer,
            amount: 50000,
            accountId: 'bca',
            toAccountId: 'gopay',
            adminFee: 1000,
          );
      expect(err, isNull);

      final state = container.read(appStateProvider).value!;
      final bca = state.accounts.firstWhere((a) => a.id == 'bca');
      final gopay = state.accounts.firstWhere((a) => a.id == 'gopay');
      // BCA keluar 51rb (50rb transfer + 1rb admin), GoPay terima penuh 50rb.
      expect(bca.balance, 949000);
      expect(gopay.balance, 50000);

      // Admin tercatat sebagai pengeluaran terpisah berkategori "Biaya Admin".
      final admin = state.transactions
          .where((t) => t.type == TxType.expense && t.category == 'Biaya Admin')
          .toList();
      expect(admin.length, 1);
      expect(admin.first.amount, 1000);
      expect(admin.first.accountId, 'bca');
      // Tertaut ke transfernya.
      final transfer =
          state.transactions.firstWhere((t) => t.type == TxType.transfer);
      expect(admin.first.linkedTransferId, transfer.id);
    });

    test('hapus transfer ikut menghapus biaya admin (cascade)', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seed())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final ctrl = container.read(appStateProvider.notifier);

      await ctrl.addTransaction(
        type: TxType.transfer,
        amount: 50000,
        accountId: 'bca',
        toAccountId: 'gopay',
        adminFee: 1000,
      );
      final transferId = container
          .read(appStateProvider)
          .value!
          .transactions
          .firstWhere((t) => t.type == TxType.transfer)
          .id;

      await ctrl.deleteTransaction(transferId);

      final state = container.read(appStateProvider).value!;
      // Kedua transaksi terhapus & saldo pulih sepenuhnya.
      expect(state.transactions, isEmpty);
      expect(state.accounts.firstWhere((a) => a.id == 'bca').balance, 1000000);
      expect(state.accounts.firstWhere((a) => a.id == 'gopay').balance, 0);
    });

    test('admin ditolak bila saldo tak cukup untuk transfer + admin', () async {
      final tight = AppState(accounts: [
        Account(
            id: 'bca',
            name: 'BCA',
            type: AccountType.bank,
            balance: 50500,
            createdAt: now),
        Account(
            id: 'gopay',
            name: 'GoPay',
            type: AccountType.ewallet,
            balance: 0,
            createdAt: now),
      ]);
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(tight)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      // 50rb + 1rb admin = 51rb > 50.5rb tersedia.
      final err = await container.read(appStateProvider.notifier).addTransaction(
            type: TxType.transfer,
            amount: 50000,
            accountId: 'bca',
            toAccountId: 'gopay',
            adminFee: 1000,
          );
      expect(err, isNotNull);
      final state = container.read(appStateProvider).value!;
      expect(state.transactions, isEmpty);
      expect(state.accounts.firstWhere((a) => a.id == 'bca').balance, 50500);
    });
  });

  group('Split bill', () {
    test('bagi rata PPN proporsional, jumlah per orang = grand total', () {
      // A pesan nasi goreng 20rb, B pesan 15rb. PPN 11%, tanpa service/diskon.
      final result = BillSplitter.calculate(
        people: const [
          BillPerson(name: 'A', items: [BillItem(name: 'Nasgor', price: 20000)]),
          BillPerson(name: 'B', items: [BillItem(name: 'Nasgor', price: 15000)]),
        ],
        ppnRate: 0.11,
      );
      expect(result.subtotal, 35000);
      expect(result.taxAmount, closeTo(3850, 0.01));
      expect(result.grandTotal, closeTo(38850, 0.01));
      // A: 20000*1.11=22200, B: 15000*1.11=16650
      expect(result.shares[0].total, 22200);
      expect(result.shares[1].total, 16650);
      final sum = result.shares.fold<double>(0, (s, x) => s + x.total);
      expect(sum, result.grandTotal.roundToDouble());
    });

    test('item bersama dibagi rata', () {
      // Roti goreng 15rb dibagi 2; A juga pesan nasgor 20rb. PPN 0 biar jelas.
      final result = BillSplitter.calculate(
        people: const [
          BillPerson(name: 'A', items: [BillItem(name: 'Nasgor', price: 20000)]),
          BillPerson(name: 'B'),
        ],
        sharedItems: const [BillItem(name: 'Roti', price: 15000)],
        ppnRate: 0,
      );
      // A = 20000 + 7500 = 27500, B = 7500
      expect(result.shares[0].subtotal, 27500);
      expect(result.shares[1].subtotal, 7500);
      expect(result.grandTotal, 35000);
    });

    test('service & PPN dihitung sebelum diskon, diskon dipotong terakhir', () {
      final result = BillSplitter.calculate(
        people: const [
          BillPerson(name: 'A', items: [BillItem(name: 'X', price: 100000)]),
        ],
        discount: 10000,
        serviceRate: 0.05,
        ppnRate: 0.11,
      );
      // subtotal 100000, service 5000, ppn (105000*0.11)=11550,
      // totalWithTax 116550, diskon 10000 dipotong terakhir, grand 106550
      expect(result.discount, 10000);
      expect(result.serviceAmount, closeTo(5000, 0.01));
      expect(result.taxAmount, closeTo(11550, 0.01));
      expect(result.grandTotal, closeTo(106550, 0.01));
    });

    test('diskon dibagi rata: tiap orang dapat potongan sama', () {
      // A 30rb, B 90rb, diskon 12rb, tanpa pajak.
      final result = BillSplitter.calculate(
        people: const [
          BillPerson(name: 'A', items: [BillItem(name: 'X', price: 30000)]),
          BillPerson(name: 'B', items: [BillItem(name: 'Y', price: 90000)]),
        ],
        discount: 12000,
        ppnRate: 0,
        splitDiscountEvenly: true,
      );
      // diskon rata 6rb/orang: A=30000-6000=24000, B=90000-6000=84000
      expect(result.shares[0].total, 24000);
      expect(result.shares[1].total, 84000);
      expect(result.grandTotal, 108000);
      final sum = result.shares.fold<double>(0, (s, x) => s + x.total);
      expect(sum, result.grandTotal.roundToDouble());
    });

    test('diskon proporsional berbeda dari rata', () {
      // Kasus sama, tapi proporsional: A bayar lebih besar dari versi rata.
      final result = BillSplitter.calculate(
        people: const [
          BillPerson(name: 'A', items: [BillItem(name: 'X', price: 30000)]),
          BillPerson(name: 'B', items: [BillItem(name: 'Y', price: 90000)]),
        ],
        discount: 12000,
        ppnRate: 0,
        splitDiscountEvenly: false,
      );
      // proporsional: A=25%*108000=27000, B=75%*108000=81000
      expect(result.shares[0].total, 27000);
      expect(result.shares[1].total, 81000);
      expect(result.grandTotal, 108000);
    });

    test('diskon rata dipotong setelah PPN, jumlah = grand total', () {
      final result = BillSplitter.calculate(
        people: const [
          BillPerson(name: 'A', items: [BillItem(name: 'X', price: 30000)]),
          BillPerson(name: 'B', items: [BillItem(name: 'Y', price: 90000)]),
        ],
        discount: 12000,
        ppnRate: 0.11,
        splitDiscountEvenly: true,
      );
      // subtotal 120000, ppn 13200, totalWithTax 133200,
      // diskon 12000 terakhir → grand 121200. Diskon rata 6000/orang:
      // A=30000*1.11-6000=27300, B=90000*1.11-6000=93900
      expect(result.grandTotal, closeTo(121200, 0.01));
      expect(result.shares[0].total, 27300);
      expect(result.shares[1].total, 93900);
      final sum = result.shares.fold<double>(0, (s, x) => s + x.total);
      expect(sum, result.grandTotal.roundToDouble());
    });
  });

  group('Laporan', () {
    final jan = DateTime(2026, 1, 1);
    final txns = [
      Transaction(
          id: '1',
          type: TxType.income,
          amount: 5000000,
          accountId: 'a',
          category: 'Gaji',
          date: DateTime(2026, 1, 5)),
      Transaction(
          id: '2',
          type: TxType.expense,
          amount: 200000,
          accountId: 'a',
          category: 'Makan',
          date: DateTime(2026, 1, 10)),
      Transaction(
          id: '3',
          type: TxType.expense,
          amount: 100000,
          accountId: 'a',
          category: 'Makan',
          date: DateTime(2026, 1, 12)),
      Transaction(
          id: '4',
          type: TxType.expense,
          amount: 50000,
          accountId: 'a',
          category: 'Transport',
          date: DateTime(2026, 1, 15)),
      // Transfer harus diabaikan dari pemasukan/pengeluaran.
      Transaction(
          id: '5',
          type: TxType.transfer,
          amount: 1000000,
          accountId: 'a',
          toAccountId: 'b',
          date: DateTime(2026, 1, 20)),
      // Bulan lain — tidak ikut Januari.
      Transaction(
          id: '6',
          type: TxType.expense,
          amount: 999999,
          accountId: 'a',
          category: 'Makan',
          date: DateTime(2026, 2, 3)),
    ];

    test('ringkasan bulanan abaikan transfer', () {
      final s = Report.forMonth(txns, jan);
      expect(s.income, 5000000);
      expect(s.expense, 350000); // 200k + 100k + 50k, transfer diabaikan
      expect(s.net, 4650000);
    });

    test('breakdown kategori urut terbesar & gabung kategori sama', () {
      final cats = Report.expenseByCategory(txns, jan);
      expect(cats.length, 2);
      expect(cats.first.label, 'Makan'); // 300k > 50k
      expect(cats.first.amount, 300000);
      expect(cats[1].label, 'Transport');
    });

    test('lastMonths menghasilkan jumlah bulan yang benar & urut naik', () {
      final series = Report.lastMonths(txns, DateTime(2026, 2), count: 3);
      expect(series.length, 3);
      expect(series.first.month, DateTime(2025, 12));
      expect(series.last.month, DateTime(2026, 2));
      expect(series.last.expense, 999999); // Feb
    });

    test('monthsWithData unik & terbaru dulu', () {
      final months = Report.monthsWithData(txns);
      expect(months.length, 2);
      expect(months.first, DateTime(2026, 2)); // terbaru dulu
      expect(months.last, DateTime(2026, 1));
    });
  });

  group('Transaksi bulanan (recurring)', () {
    AppState seed() => AppState(
          accounts: [
            Account(
                id: 'bca',
                name: 'BCA',
                type: AccountType.bank,
                balance: 1000000,
                createdAt: now),
          ],
          recurring: [
            RecurringTransaction(
                id: 'r1',
                label: 'Netflix',
                type: TxType.expense,
                amount: 50000,
                accountId: 'bca',
                createdAt: now),
            RecurringTransaction(
                id: 'r2',
                label: 'Nonaktif',
                type: TxType.expense,
                amount: 30000,
                accountId: 'bca',
                enabled: false,
                createdAt: now),
          ],
        );

    test('runAllRecurring hanya jalankan yang aktif & update saldo', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seed())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final res =
          await container.read(appStateProvider.notifier).runAllRecurring();
      expect(res.created, 1); // r2 nonaktif
      expect(res.skipped, 0);
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 950000); // 1jt - 50k
      expect(state.transactions.length, 1);
    });

    test('runAllRecurring lewati template bila saldo kurang', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 10000,
              createdAt: now),
        ],
        recurring: [
          RecurringTransaction(
              id: 'r1',
              label: 'Mahal',
              type: TxType.expense,
              amount: 50000,
              accountId: 'bca',
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final res =
          await container.read(appStateProvider.notifier).runAllRecurring();
      expect(res.created, 0);
      expect(res.skipped, 1);
      expect(container.read(appStateProvider).value!.accounts.first.balance,
          10000);
    });
  });

  group('Piutang dengan talangan', () {
    test('menalangi: kas turun, piutang naik, net worth tetap', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 1000000,
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final before = container.read(appStateProvider).value!.netWorth;

      final err = await container.read(appStateProvider.notifier).addReceivable(
            personName: 'Gama',
            remaining: 200000,
            fundingAccountId: 'bca',
          );
      expect(err, isNull);
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 800000);
      expect(state.totalReceivable, 200000);
      expect(state.netWorth, before); // tetap: kas -200k, piutang +200k
      expect(state.transactions.length, 1); // tercatat sebagai talangan
    });

    test('menalangi ditolak bila saldo kurang', () async {
      final initial = AppState(
        accounts: [
          Account(
              id: 'bca',
              name: 'BCA',
              type: AccountType.bank,
              balance: 100000,
              createdAt: now),
        ],
      );
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(initial)),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container.read(appStateProvider.notifier).addReceivable(
            personName: 'Gama',
            remaining: 500000,
            fundingAccountId: 'bca',
          );
      expect(err, isNotNull);
      final state = container.read(appStateProvider).value!;
      expect(state.receivables, isEmpty);
      expect(state.accounts.first.balance, 100000);
    });
  });

  group('Wishlist menabung', () {
    test('getter cicilan & progres', () {
      final w = WishlistItem(
        id: 'w',
        name: 'Laptop',
        price: 1000000,
        monthlySaving: 200000,
        savedAmount: 400000,
        createdAt: now,
      );
      expect(w.hasSavingPlan, isTrue);
      expect(w.remainingToSave, 600000);
      expect(w.savingProgress, closeTo(0.4, 0.001));
      expect(w.monthsRemaining, 3); // 600k / 200k
    });
  });

  group('Pengingat', () {
    final today = DateTime(2026, 3, 10);
    test('deteksi belum ada transaksi hari ini', () {
      expect(Reminders.hasTransactionToday(const [], today), isFalse);
      final txns = [
        Transaction(
            id: '1',
            type: TxType.expense,
            amount: 1000,
            accountId: 'a',
            date: today),
      ];
      expect(Reminders.hasTransactionToday(txns, today), isTrue);
    });

    test('deteksi gaji bulan ini', () {
      final txns = [
        Transaction(
            id: '1',
            type: TxType.income,
            amount: 5000000,
            accountId: 'a',
            category: 'Gaji',
            date: DateTime(2026, 3, 1)),
      ];
      expect(Reminders.receivedSalaryThisMonth(txns, today), isTrue);
      expect(Reminders.receivedSalaryThisMonth(const [], today), isFalse);
    });

    test('build memunculkan banner gajian->nabung', () {
      final txns = [
        Transaction(
            id: '1',
            type: TxType.income,
            amount: 5000000,
            accountId: 'a',
            category: 'Gaji',
            date: today),
      ];
      final wishlist = [
        WishlistItem(
            id: 'w',
            name: 'Laptop',
            price: 1000000,
            monthlySaving: 200000,
            createdAt: now),
      ];
      final reminders =
          Reminders.build(transactions: txns, wishlist: wishlist, now: today);
      // Ada transaksi hari ini, jadi tidak ada banner "belum ada transaksi".
      expect(reminders.any((r) => r.id == 'no-tx-today'), isFalse);
      expect(reminders.any((r) => r.id == 'salary-save'), isTrue);
    });
  });

  group('Transaksi saham (RDN)', () {
    AppState seedRdn({double balance = 10000000}) => AppState(
          accounts: [
            Account(
                id: 'rdn',
                name: 'RDN BCA',
                type: AccountType.rdn,
                balance: balance,
                createdAt: now),
          ],
        );

    test('beli saham baru: RDN turun, posisi dibuat dalam lembar', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedRdn())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      // Beli 5 lot @ 9000 = 500 lembar * 9000 = 4.500.000
      final err = await container.read(appStateProvider.notifier).buyStock(
            name: 'BBCA',
            ticker: 'BBCA',
            rdnAccountId: 'rdn',
            lots: 5,
            pricePerShare: 9000,
          );
      expect(err, isNull);
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 5500000); // 10jt - 4,5jt
      expect(state.investments.length, 1);
      final inv = state.investments.first;
      expect(inv.quantity, 500);
      expect(inv.lots, 5);
      expect(inv.buyPrice, 9000);
    });

    test('beli tambahan: harga beli rata-rata tertimbang', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedRdn())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final ctrl = container.read(appStateProvider.notifier);

      await ctrl.buyStock(
          name: 'BBCA', rdnAccountId: 'rdn', lots: 5, pricePerShare: 9000);
      final id = container.read(appStateProvider).value!.investments.first.id;
      // Beli lagi 5 lot @ 11000.
      await ctrl.buyStock(
          investmentId: id,
          rdnAccountId: 'rdn',
          lots: 5,
          pricePerShare: 11000);

      final inv = container.read(appStateProvider).value!.investments.first;
      expect(inv.quantity, 1000); // 10 lot
      expect(inv.buyPrice, 10000); // (500*9000 + 500*11000)/1000
    });

    test('jual sebagian: lot berkurang, RDN bertambah', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedRdn())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final ctrl = container.read(appStateProvider.notifier);

      await ctrl.buyStock(
          name: 'BBCA', rdnAccountId: 'rdn', lots: 5, pricePerShare: 9000);
      final id = container.read(appStateProvider).value!.investments.first.id;
      // RDN sekarang 5,5jt. Jual 2 lot @ 10000 = 200*10000 = 2.000.000.
      final err = await ctrl.sellStock(
          investmentId: id, rdnAccountId: 'rdn', lots: 2, pricePerShare: 10000);
      expect(err, isNull);

      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 7500000); // 5,5jt + 2jt
      expect(state.investments.first.quantity, 300); // 3 lot tersisa
      expect(state.investments.first.buyPrice, 9000); // tak berubah saat jual
    });

    test('jual seluruh lot menghapus posisi', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedRdn())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final ctrl = container.read(appStateProvider.notifier);

      await ctrl.buyStock(
          name: 'BBCA', rdnAccountId: 'rdn', lots: 5, pricePerShare: 9000);
      final id = container.read(appStateProvider).value!.investments.first.id;
      await ctrl.sellStock(
          investmentId: id, rdnAccountId: 'rdn', lots: 5, pricePerShare: 9500);

      expect(container.read(appStateProvider).value!.investments, isEmpty);
    });

    test('beli ditolak bila saldo RDN kurang', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedRdn(balance: 100000))),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container.read(appStateProvider.notifier).buyStock(
            name: 'BBCA',
            rdnAccountId: 'rdn',
            lots: 5,
            pricePerShare: 9000,
          );
      expect(err, isNotNull);
      final state = container.read(appStateProvider).value!;
      expect(state.investments, isEmpty);
      expect(state.accounts.first.balance, 100000);
    });
  });

  group('Split bill dengan sumber dana', () {
    AppState seedAcc({double balance = 1000000}) => AppState(
          accounts: [
            Account(
                id: 'bca',
                name: 'BCA',
                type: AccountType.bank,
                balance: balance,
                createdAt: now),
          ],
        );

    test('teman jadi piutang+talangan, bagian sendiri jadi pengeluaran',
        () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedAcc())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final before = container.read(appStateProvider).value!.netWorth;

      // 2 teman @ 50rb, bagian sendiri 30rb. Total keluar 130rb.
      final err = await container.read(appStateProvider.notifier).splitBillPayment(
            fundingAccountId: 'bca',
            shares: const [
              (name: 'Gama', amount: 50000),
              (name: 'Rina', amount: 50000),
            ],
            ownerShare: 30000,
          );
      expect(err, isNull);

      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 870000); // 1jt - 130rb
      expect(state.totalReceivable, 100000); // 2 x 50rb
      expect(state.receivables.length, 2);
      expect(state.transactions.length, 3); // 2 talangan + 1 bagian sendiri
      // Net worth turun tepat sebesar bagian sendiri (talangan netral).
      expect(state.netWorth, before - 30000);
    });

    test('tanpa bagian sendiri: net worth tetap (semua talangan)', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedAcc())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final before = container.read(appStateProvider).value!.netWorth;

      await container.read(appStateProvider.notifier).splitBillPayment(
            fundingAccountId: 'bca',
            shares: const [(name: 'Gama', amount: 80000)],
          );
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 920000);
      expect(state.totalReceivable, 80000);
      expect(state.netWorth, before); // kas -80rb, piutang +80rb
    });

    test('ditolak bila saldo tidak cukup', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seedAcc(balance: 50000))),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container.read(appStateProvider.notifier).splitBillPayment(
            fundingAccountId: 'bca',
            shares: const [(name: 'Gama', amount: 100000)],
          );
      expect(err, isNotNull);
      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 50000); // tak berubah
      expect(state.receivables, isEmpty);
      expect(state.transactions, isEmpty);
    });
  });

  group('Nabung wishlist', () {
    AppState seed({double balance = 1000000, double price = 500000}) =>
        AppState(
          accounts: [
            Account(
                id: 'bca',
                name: 'BCA',
                type: AccountType.bank,
                balance: balance,
                createdAt: now),
          ],
          wishlist: [
            WishlistItem(
                id: 'w1',
                name: 'Laptop',
                price: price,
                createdAt: now),
          ],
        );

    test('memotong saldo akun & mencatat pengeluaran', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seed())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container
          .read(appStateProvider.notifier)
          .contributeToWish('w1', 200000, accountId: 'bca');
      expect(err, isNull);

      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 800000); // 1jt - 200rb
      expect(state.wishlist.first.savedAmount, 200000);
      expect(state.wishlist.first.purchased, isFalse);
      expect(state.transactions.length, 1);
      expect(state.transactions.first.category, 'Nabung');
    });

    test('tanpa akun: hanya catat progres, saldo tetap', () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seed())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container
          .read(appStateProvider.notifier)
          .contributeToWish('w1', 200000);
      expect(err, isNull);

      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 1000000); // tak berubah
      expect(state.wishlist.first.savedAmount, 200000);
      expect(state.transactions, isEmpty);
    });

    test('otomatis selesai & dibatasi sisa target saat tabungan penuh',
        () async {
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(InMemoryStorage(seed())),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      // Setor lebih dari sisa (500rb) — hanya 500rb yang dipotong.
      final err = await container
          .read(appStateProvider.notifier)
          .contributeToWish('w1', 900000, accountId: 'bca');
      expect(err, isNull);

      final state = container.read(appStateProvider).value!;
      expect(state.wishlist.first.savedAmount, 500000); // tak melebihi harga
      expect(state.wishlist.first.purchased, isTrue); // selesai otomatis
      expect(state.accounts.first.balance, 500000); // hanya 500rb terpotong
      expect(state.transactions.first.amount, 500000);
    });

    test('ditolak bila saldo tidak cukup', () async {
      final container = ProviderContainer(overrides: [
        storageProvider
            .overrideWithValue(InMemoryStorage(seed(balance: 50000))),
      ]);
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);

      final err = await container
          .read(appStateProvider.notifier)
          .contributeToWish('w1', 100000, accountId: 'bca');
      expect(err, isNotNull);

      final state = container.read(appStateProvider).value!;
      expect(state.accounts.first.balance, 50000); // tak berubah
      expect(state.wishlist.first.savedAmount, 0);
      expect(state.transactions, isEmpty);
    });
  });
}
