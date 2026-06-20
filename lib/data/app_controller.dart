import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/formatters.dart';
import '../firebase/auth.dart';
import '../firebase/firebase_config.dart';
import '../firebase/firestore_storage.dart';
import '../models/account.dart';
import '../models/debt.dart';
import '../models/investment.dart';
import '../models/receivable.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../models/wishlist_item.dart';
import '../services/price_service.dart';
import 'app_state.dart';
import 'storage.dart';

const _uuid = Uuid();

/// Backend penyimpanan aktif, dipilih berdasarkan status login:
///
/// - Firebase nonaktif  → selalu [LocalStorage] (data di perangkat).
/// - Firebase aktif + login → [FirestoreStorage] terisolasi per-UID,
///   sehingga tiap pengguna punya data sendiri yang tersinkron antar device.
/// - Firebase aktif + belum login → [LocalStorage] sementara (UI menahan
///   di layar login, jadi data ini tidak benar-benar terpakai).
final storageProvider = Provider<StorageBackend>((ref) {
  if (!useFirebase) return LocalStorage();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null || user.isLocal) return LocalStorage();
  return FirestoreStorage(user.uid);
});

/// Layanan harga investasi. [stockProxyBase] menunjuk ke Cloudflare Worker
/// yang memproksi harga saham IDX dari Yahoo Finance; crypto langsung ke
/// CoinGecko tanpa proxy.
final priceServiceProvider = Provider<PriceService>(
  (ref) => PriceService(
    stockProxyBase: 'https://moneywork-quote.tompel-adrian-6ef.workers.dev',
  ),
);

/// Sumber kebenaran tunggal untuk seluruh data aplikasi.
final appStateProvider =
    AsyncNotifierProvider<AppController, AppState>(AppController.new);

/// Preferensi tema aktif, diturunkan dari [AppState]. Dipakai di MaterialApp.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(appStateProvider).valueOrNull?.themeMode ?? 'system';
  return switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// Controller yang memuat, memutasi, dan mempertahankan [AppState].
///
/// Setiap mutasi: (1) hitung state baru, (2) tulis ke storage,
/// (3) update state UI. Saldo akun dijaga konsisten dengan transaksi.
class AppController extends AsyncNotifier<AppState> {
  // Watch agar build ulang otomatis saat backend berganti (login/logout).
  StorageBackend get _storage => ref.read(storageProvider);

  @override
  Future<AppState> build() {
    final storage = ref.watch(storageProvider);
    return storage.load();
  }

  Future<void> _commit(AppState next) async {
    state = AsyncData(next);
    await _storage.save(next);
  }

  AppState get _current => state.valueOrNull ?? const AppState();

  /// Ubah preferensi tema ('system' | 'light' | 'dark'), tersimpan & sinkron.
  Future<void> setThemeMode(String mode) async {
    await _commit(_current.copyWith(themeMode: mode));
  }

  /// Hapus seluruh data pengguna dari penyimpanan dan reset state.
  /// Dipakai saat menghapus akun.
  Future<void> clearAllData() async {
    await _storage.clear();
    state = const AsyncData(AppState());
  }

  // ---------------------------------------------------------------------------
  // Akun
  // ---------------------------------------------------------------------------

  Future<void> addAccount({
    required String name,
    required AccountType type,
    double initialBalance = 0,
    String accountNumber = '',
  }) async {
    final account = Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      balance: initialBalance,
      accountNumber: accountNumber,
      createdAt: DateTime.now(),
    );
    await _commit(_current.copyWith(
      accounts: [..._current.accounts, account],
    ));
  }

  Future<void> updateAccount(Account account) async {
    final accounts = _current.accounts
        .map((a) => a.id == account.id ? account : a)
        .toList();
    await _commit(_current.copyWith(accounts: accounts));
  }

  /// Hapus akun beserta transaksi yang terkait dengannya.
  Future<void> deleteAccount(String id) async {
    final accounts = _current.accounts.where((a) => a.id != id).toList();
    final transactions = _current.transactions
        .where((t) => t.accountId != id && t.toAccountId != id)
        .toList();
    await _commit(_current.copyWith(
      accounts: accounts,
      transactions: transactions,
    ));
  }

  // ---------------------------------------------------------------------------
  // Transaksi (menjaga saldo akun tetap konsisten)
  // ---------------------------------------------------------------------------

  /// Terapkan dampak transaksi ke saldo akun. [reverse] untuk membatalkan.
  List<Account> _applyTx(
    List<Account> accounts,
    Transaction tx, {
    bool reverse = false,
  }) {
    final factor = reverse ? -1 : 1;
    return accounts.map((a) {
      var balance = a.balance;
      if (a.id == tx.accountId) {
        balance += tx.signedAmount * factor;
      }
      // Transfer menambah saldo akun tujuan.
      if (tx.type == TxType.transfer && a.id == tx.toAccountId) {
        balance += tx.amount * factor;
      }
      return a.copyWith(balance: balance);
    }).toList();
  }

  /// Catat transaksi baru.
  ///
  /// Mengembalikan `null` jika berhasil, atau pesan error bila saldo akun
  /// tidak cukup untuk pengeluaran/transfer (saldo tidak boleh minus).
  Future<String?> addTransaction({
    required TxType type,
    required double amount,
    required String accountId,
    String? toAccountId,
    String category = '',
    String note = '',
    DateTime? date,
  }) async {
    // Validasi saldo untuk pengeluaran & transfer.
    if (type != TxType.income) {
      final source =
          _current.accounts.firstWhere((a) => a.id == accountId);
      if (amount > source.balance) {
        return 'Saldo ${source.name} tidak cukup. '
            'Tersedia ${Fmt.rupiah(source.balance)}.';
      }
    }

    final tx = Transaction(
      id: _uuid.v4(),
      type: type,
      amount: amount,
      accountId: accountId,
      toAccountId: toAccountId,
      category: category,
      note: note,
      date: date ?? DateTime.now(),
    );
    await _commit(_current.copyWith(
      transactions: [tx, ..._current.transactions],
      accounts: _applyTx(_current.accounts, tx),
    ));
    return null;
  }

  /// Hapus transaksi dan kembalikan dampaknya ke saldo akun.
  /// Jika transaksi adalah pembayaran utang / penerimaan piutang,
  /// sisa utang / piutang dipulihkan.
  Future<void> deleteTransaction(String id) async {
    final tx = _current.transactions.firstWhere((t) => t.id == id);
    final transactions =
        _current.transactions.where((t) => t.id != id).toList();

    // Pulihkan sisa utang bila ini transaksi pembayaran utang.
    var debts = _current.debts;
    if (tx.linkedDebtId != null) {
      debts = debts
          .map((d) => d.id == tx.linkedDebtId
              ? d.copyWith(remaining: d.remaining + tx.amount)
              : d)
          .toList();
    }

    // Pulihkan sisa piutang bila ini transaksi penerimaan piutang.
    var receivables = _current.receivables;
    if (tx.linkedReceivableId != null) {
      receivables = receivables
          .map((r) => r.id == tx.linkedReceivableId
              ? r.copyWith(remaining: r.remaining + tx.amount)
              : r)
          .toList();
    }

    await _commit(_current.copyWith(
      transactions: transactions,
      accounts: _applyTx(_current.accounts, tx, reverse: true),
      debts: debts,
      receivables: receivables,
    ));
  }

  // ---------------------------------------------------------------------------
  // Investasi
  // ---------------------------------------------------------------------------

  Future<void> addInvestment({
    required String name,
    required InvestmentType type,
    required double quantity,
    required double buyPrice,
    required double currentPrice,
    String ticker = '',
  }) async {
    final inv = Investment(
      id: _uuid.v4(),
      name: name,
      type: type,
      quantity: quantity,
      buyPrice: buyPrice,
      currentPrice: currentPrice,
      ticker: ticker,
      updatedAt: DateTime.now(),
    );
    await _commit(_current.copyWith(
      investments: [..._current.investments, inv],
    ));
  }

  Future<void> updateInvestment(Investment investment) async {
    final investments = _current.investments
        .map((i) => i.id == investment.id ? investment : i)
        .toList();
    await _commit(_current.copyWith(investments: investments));
  }

  /// Perbarui harga sekarang sebuah investasi dari sumber online.
  /// Mengembalikan `null` jika berhasil, atau pesan error bila gagal.
  Future<String?> refreshPrice(String investmentId) async {
    final match = _current.investments.where((i) => i.id == investmentId);
    if (match.isEmpty) return 'Investasi tidak ditemukan.';
    final inv = match.first;

    final service = ref.read(priceServiceProvider);
    final result = await service.fetch(inv);
    if (!result.ok) return result.error;

    await updateInvestment(inv.copyWith(
      currentPrice: result.price,
      updatedAt: DateTime.now(),
    ));
    return null;
  }

  Future<void> deleteInvestment(String id) async {
    final investments =
        _current.investments.where((i) => i.id != id).toList();
    await _commit(_current.copyWith(investments: investments));
  }

  // ---------------------------------------------------------------------------
  // Utang
  // ---------------------------------------------------------------------------

  Future<void> addDebt({
    required String name,
    required DebtType type,
    required double remaining,
    double monthlyPayment = 0,
    DateTime? dueDate,
  }) async {
    final debt = Debt(
      id: _uuid.v4(),
      name: name,
      type: type,
      remaining: remaining,
      monthlyPayment: monthlyPayment,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await _commit(_current.copyWith(debts: [..._current.debts, debt]));
  }

  Future<void> updateDebt(Debt debt) async {
    final debts =
        _current.debts.map((d) => d.id == debt.id ? debt : d).toList();
    await _commit(_current.copyWith(debts: debts));
  }

  Future<void> deleteDebt(String id) async {
    final debts = _current.debts.where((d) => d.id != id).toList();
    await _commit(_current.copyWith(debts: debts));
  }

  /// Bayar utang dari sebuah rekening.
  ///
  /// Dalam satu langkah: saldo rekening berkurang, sisa utang berkurang, dan
  /// transaksi pengeluaran tercatat (tertaut ke utang lewat [Transaction.linkedDebtId]).
  /// Mengembalikan `null` bila berhasil, atau pesan error.
  Future<String?> payDebt({
    required String debtId,
    required String accountId,
    required double amount,
    DateTime? date,
  }) async {
    if (amount <= 0) return 'Masukkan jumlah pembayaran yang valid.';

    final debtMatch = _current.debts.where((d) => d.id == debtId);
    if (debtMatch.isEmpty) return 'Utang tidak ditemukan.';
    final debt = debtMatch.first;

    final accMatch = _current.accounts.where((a) => a.id == accountId);
    if (accMatch.isEmpty) return 'Rekening tidak ditemukan.';
    final account = accMatch.first;

    if (amount > debt.remaining) {
      return 'Jumlah melebihi sisa utang (${Fmt.rupiah(debt.remaining)}).';
    }
    if (amount > account.balance) {
      return 'Saldo ${account.name} tidak cukup. '
          'Tersedia ${Fmt.rupiah(account.balance)}.';
    }

    final tx = Transaction(
      id: _uuid.v4(),
      type: TxType.expense,
      amount: amount,
      accountId: accountId,
      category: 'Bayar Utang',
      note: debt.name,
      linkedDebtId: debtId,
      date: date ?? DateTime.now(),
    );

    final debts = _current.debts
        .map((d) =>
            d.id == debtId ? d.copyWith(remaining: d.remaining - amount) : d)
        .toList();

    await _commit(_current.copyWith(
      transactions: [tx, ..._current.transactions],
      accounts: _applyTx(_current.accounts, tx),
      debts: debts,
    ));
    return null;
  }

  // ---------------------------------------------------------------------------
  // Piutang (uang yang dipinjam orang lain ke kita)
  // ---------------------------------------------------------------------------

  /// Tambah piutang. Jika [fundingAccountId] diisi, uang dianggap keluar dari
  /// rekening tersebut sekarang (mencatat pengeluaran "Talangan") — berguna
  /// saat kita menalangi pembayaran orang lain. Net worth tetap karena kas
  /// turun sementara piutang naik.
  ///
  /// Mengembalikan `null` bila berhasil, atau pesan error bila saldo kurang.
  Future<String?> addReceivable({
    required String personName,
    required double remaining,
    String note = '',
    DateTime? dueDate,
    String? fundingAccountId,
  }) async {
    final r = Receivable(
      id: _uuid.v4(),
      personName: personName,
      remaining: remaining,
      note: note,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    // Tanpa pendanaan: cukup catat piutang.
    if (fundingAccountId == null) {
      await _commit(
          _current.copyWith(receivables: [..._current.receivables, r]));
      return null;
    }

    final accMatch = _current.accounts.where((a) => a.id == fundingAccountId);
    if (accMatch.isEmpty) return 'Rekening sumber tidak ditemukan.';
    final account = accMatch.first;
    if (remaining > account.balance) {
      return 'Saldo ${account.name} tidak cukup untuk menalangi '
          '(tersedia ${Fmt.rupiah(account.balance)}).';
    }

    final tx = Transaction(
      id: _uuid.v4(),
      type: TxType.expense,
      amount: remaining,
      accountId: fundingAccountId,
      category: 'Talangan',
      note: 'Piutang $personName',
      date: DateTime.now(),
    );

    await _commit(_current.copyWith(
      receivables: [..._current.receivables, r],
      transactions: [tx, ..._current.transactions],
      accounts: _applyTx(_current.accounts, tx),
    ));
    return null;
  }

  Future<void> updateReceivable(Receivable receivable) async {
    final receivables = _current.receivables
        .map((r) => r.id == receivable.id ? receivable : r)
        .toList();
    await _commit(_current.copyWith(receivables: receivables));
  }

  Future<void> deleteReceivable(String id) async {
    final receivables = _current.receivables.where((r) => r.id != id).toList();
    await _commit(_current.copyWith(receivables: receivables));
  }

  /// Terima pembayaran piutang ke sebuah rekening.
  ///
  /// Dalam satu langkah: saldo rekening bertambah (income), sisa piutang
  /// berkurang, dan transaksi tercatat (tertaut lewat [Transaction.linkedReceivableId]).
  /// Mengembalikan `null` bila berhasil, atau pesan error.
  Future<String?> collectReceivable({
    required String receivableId,
    required String accountId,
    required double amount,
    DateTime? date,
  }) async {
    if (amount <= 0) return 'Masukkan jumlah penerimaan yang valid.';

    final match = _current.receivables.where((r) => r.id == receivableId);
    if (match.isEmpty) return 'Piutang tidak ditemukan.';
    final receivable = match.first;

    final accMatch = _current.accounts.where((a) => a.id == accountId);
    if (accMatch.isEmpty) return 'Rekening tidak ditemukan.';

    if (amount > receivable.remaining) {
      return 'Jumlah melebihi sisa piutang (${Fmt.rupiah(receivable.remaining)}).';
    }

    final tx = Transaction(
      id: _uuid.v4(),
      type: TxType.income,
      amount: amount,
      accountId: accountId,
      category: 'Terima Piutang',
      note: receivable.personName,
      linkedReceivableId: receivableId,
      date: date ?? DateTime.now(),
    );

    final receivables = _current.receivables
        .map((r) => r.id == receivableId
            ? r.copyWith(remaining: r.remaining - amount)
            : r)
        .toList();

    await _commit(_current.copyWith(
      transactions: [tx, ..._current.transactions],
      accounts: _applyTx(_current.accounts, tx),
      receivables: receivables,
    ));
    return null;
  }

  // ---------------------------------------------------------------------------
  // Wishlist
  // ---------------------------------------------------------------------------

  Future<void> addWish({
    required String name,
    required double price,
    String url = '',
    WishPriority priority = WishPriority.medium,
    DateTime? targetDate,
    double monthlySaving = 0,
    int durationMonths = 0,
    int reminderDay = 0,
    String? savingAccountId,
  }) async {
    final wish = WishlistItem(
      id: _uuid.v4(),
      name: name,
      price: price,
      url: url,
      priority: priority,
      targetDate: targetDate,
      monthlySaving: monthlySaving,
      durationMonths: durationMonths,
      reminderDay: reminderDay,
      savingAccountId: savingAccountId,
      createdAt: DateTime.now(),
    );
    await _commit(_current.copyWith(wishlist: [..._current.wishlist, wish]));
  }

  Future<void> updateWish(WishlistItem wish) async {
    final wishlist =
        _current.wishlist.map((w) => w.id == wish.id ? wish : w).toList();
    await _commit(_current.copyWith(wishlist: wishlist));
  }

  Future<void> deleteWish(String id) async {
    final wishlist = _current.wishlist.where((w) => w.id != id).toList();
    await _commit(_current.copyWith(wishlist: wishlist));
  }

  Future<void> toggleWishPurchased(String id) async {
    final wishlist = _current.wishlist
        .map((w) => w.id == id ? w.copyWith(purchased: !w.purchased) : w)
        .toList();
    await _commit(_current.copyWith(wishlist: wishlist));
  }

  /// Catat setoran tabungan untuk sebuah wishlist (menambah [savedAmount]).
  ///
  /// Ini melacak progres menabung, bukan memindahkan uang nyata — pencatatan
  /// pengeluaran saat benar-benar membeli dilakukan lewat transaksi biasa.
  Future<void> contributeToWish(String id, double amount) async {
    if (amount <= 0) return;
    final wishlist = _current.wishlist.map((w) {
      if (w.id != id) return w;
      return w.copyWith(savedAmount: w.savedAmount + amount);
    }).toList();
    await _commit(_current.copyWith(wishlist: wishlist));
  }

  // ---------------------------------------------------------------------------
  // Transaksi bulanan berulang (monthly expenses)
  // ---------------------------------------------------------------------------

  Future<void> addRecurring({
    required String label,
    required TxType type,
    required double amount,
    required String accountId,
    String? toAccountId,
    String category = '',
  }) async {
    final r = RecurringTransaction(
      id: _uuid.v4(),
      label: label,
      type: type,
      amount: amount,
      accountId: accountId,
      toAccountId: toAccountId,
      category: category,
      createdAt: DateTime.now(),
    );
    await _commit(_current.copyWith(recurring: [..._current.recurring, r]));
  }

  Future<void> updateRecurring(RecurringTransaction recurring) async {
    final list = _current.recurring
        .map((r) => r.id == recurring.id ? recurring : r)
        .toList();
    await _commit(_current.copyWith(recurring: list));
  }

  Future<void> deleteRecurring(String id) async {
    final list = _current.recurring.where((r) => r.id != id).toList();
    await _commit(_current.copyWith(recurring: list));
  }

  Future<void> toggleRecurringEnabled(String id) async {
    final list = _current.recurring
        .map((r) => r.id == id ? r.copyWith(enabled: !r.enabled) : r)
        .toList();
    await _commit(_current.copyWith(recurring: list));
  }

  /// Jalankan semua template berulang yang aktif menjadi transaksi nyata
  /// bertanggal [date] (default hari ini), dalam satu langkah.
  ///
  /// Mengembalikan jumlah transaksi yang dibuat. Template yang saldonya tidak
  /// cukup untuk pengeluaran/transfer dilewati (dihitung di [skipped]).
  Future<({int created, int skipped})> runAllRecurring({
    DateTime? date,
  }) async {
    final when = date ?? DateTime.now();
    var accounts = _current.accounts;
    final newTxns = <Transaction>[];
    var skipped = 0;

    for (final r in _current.recurring) {
      if (!r.enabled) continue;

      // Validasi saldo untuk pengeluaran & transfer.
      if (r.type != TxType.income) {
        final srcMatch = accounts.where((a) => a.id == r.accountId);
        if (srcMatch.isEmpty || r.amount > srcMatch.first.balance) {
          skipped++;
          continue;
        }
      }

      final tx = Transaction(
        id: _uuid.v4(),
        type: r.type,
        amount: r.amount,
        accountId: r.accountId,
        toAccountId: r.toAccountId,
        category: r.category,
        note: r.label,
        date: when,
      );
      accounts = _applyTx(accounts, tx);
      newTxns.add(tx);
    }

    if (newTxns.isNotEmpty) {
      await _commit(_current.copyWith(
        transactions: [...newTxns, ..._current.transactions],
        accounts: accounts,
      ));
    }
    return (created: newTxns.length, skipped: skipped);
  }
}
