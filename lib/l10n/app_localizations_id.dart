// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'MoneyWork';

  @override
  String get navHome => 'Beranda';

  @override
  String get navBills => 'Tagihan';

  @override
  String get navAccounts => 'Akun';

  @override
  String get navInvestments => 'Investasi';

  @override
  String get scanButton => 'Scan';

  @override
  String get featureComingSoon => 'Fitur segera hadir!';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get tooltipWishlist => 'Wishlist';

  @override
  String get tooltipReport => 'Laporan';

  @override
  String get tooltipProfile => 'Profil & Pengaturan';

  @override
  String get tooltipForecast => 'Proyeksi arus kas 30 hari';

  @override
  String get tooltipImportStatementPdf => 'Impor mutasi rekening PDF';

  @override
  String importSuccess(int count) {
    return '$count transaksi ditambahkan. Periksa status penyimpanan.';
  }

  @override
  String get syncStatusLoading => 'Memuat data';

  @override
  String get syncStatusSynced => 'Data tersimpan';

  @override
  String get syncStatusPending => 'Menyimpan perubahan';

  @override
  String get syncCache => 'Data dari cache; menunggu konfirmasi server';

  @override
  String get syncStatusError => 'Gagal menyimpan perubahan';

  @override
  String get syncRetry => 'Coba lagi';

  @override
  String get syncLoadCloud => 'Muat versi cloud';

  @override
  String get syncDiscardTitle => 'Buang perubahan yang belum tersimpan?';

  @override
  String get syncDiscardBody =>
      'Versi cloud akan dimuat. Perubahan di perangkat ini yang gagal tersimpan akan hilang.';

  @override
  String get syncCancel => 'Batal';

  @override
  String get syncContinue => 'Muat cloud';

  @override
  String get errorLoadData => 'Gagal memuat data';

  @override
  String get savingTargetTitle => 'Target Tabungan';

  @override
  String get netWorthTitle => 'Kekayaan Bersih';

  @override
  String get totalAssetsTitle => 'Total Aset';

  @override
  String get totalDebtTitle => 'Total Utang';

  @override
  String get cashTitle => 'Kas';

  @override
  String get investmentTitle => 'Investasi';

  @override
  String get receivableTitle => 'Piutang';

  @override
  String get debtTitle => 'Utang';

  @override
  String get recentTransactionsTitle => 'Transaksi Terbaru';

  @override
  String get noTransactionsMessage => 'Belum ada transaksi.';

  @override
  String get titleAccounts => 'Akun & Transaksi';

  @override
  String get tooltipMonthlyExpenses => 'Transaksi Bulanan';

  @override
  String get fabAddAccount => 'Tambah Akun';

  @override
  String get fabRecordTransaction => 'Catat Transaksi';

  @override
  String get errorLoadFailed => 'Gagal memuat';

  @override
  String get emptyAccountTitle => 'Tambahkan rekening dulu';

  @override
  String get emptyAccountSubtitle =>
      'Transaksi bulanan butuh rekening sebagai sumber/tujuan.';

  @override
  String get transactionHistory => 'Riwayat Transaksi';

  @override
  String get noTransactionsFilter =>
      'Tidak ada transaksi yang cocok dengan filter.';

  @override
  String get searchHint => 'Cari catatan / kategori';

  @override
  String get tooltipClearFilter => 'Hapus filter';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterAllAccounts => 'Semua akun';

  @override
  String get accountLabel => 'Akun';

  @override
  String get myAccounts => 'Akun Saya';

  @override
  String get titleBills => 'Tagihan';

  @override
  String get tooltipSplitBill => 'Split Bill';

  @override
  String get tooltipAddDebt => 'Tambah Utang';

  @override
  String get tooltipAddReceivable => 'Tambah Piutang';

  @override
  String get tabDebts => 'Utang & Cicilan';

  @override
  String get tabReceivables => 'Piutang';

  @override
  String get fabDebt => 'Utang';

  @override
  String get emptyDebtTitle => 'Tidak ada utang';

  @override
  String get emptyDebtSubtitle =>
      'Bagus! Kalau ada pinjaman, kartu kredit, atau cicilan,\ncatat di sini untuk hitung kekayaan bersih.';

  @override
  String get totalDebtLabel => 'Total Utang';

  @override
  String get monthlyInstallment => 'Cicilan/bln';

  @override
  String get paidOff => 'Lunas';

  @override
  String get duePrefix => 'Tempo';

  @override
  String get perMonthSuffix => '/bln';

  @override
  String get payButton => 'Bayar';

  @override
  String get fabReceivable => 'Piutang';

  @override
  String get emptyReceivableTitle => 'Belum ada piutang';

  @override
  String get emptyReceivableSubtitle =>
      'Catat uang yang dipinjam teman/orang lain ke kamu.\nBisa juga dari kalkulator split bill.';

  @override
  String get totalReceivableLabel => 'Total Piutang';

  @override
  String get peopleCountSuffix => 'orang';

  @override
  String get loansCountSuffix => 'pinjaman';

  @override
  String get settled => 'selesai';

  @override
  String get remaining => 'sisa';

  @override
  String get receiveFrom => 'Terima dari';

  @override
  String get profileTitle => 'Profil & Pengaturan';

  @override
  String get sectionAppearance => 'Tampilan';

  @override
  String get themeSystem => 'Ikuti sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get sectionLanguage => 'Bahasa / Language';

  @override
  String get languageSystem => 'Ikuti sistem (System Default)';

  @override
  String get languageId => 'Indonesia';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文 (Mandarin)';

  @override
  String get sectionReminders => 'Pengingat';

  @override
  String get reminderTitle => 'Pengingat di HP';

  @override
  String get reminderSubtitle =>
      'Ingatkan catat transaksi harian & jadwal menabung';

  @override
  String get reminderTimeTitle => 'Jam pengingat harian';

  @override
  String get reminderTimeSubtitle => 'Setiap hari pukul';

  @override
  String get sectionApp => 'Aplikasi';

  @override
  String get updateTitle => 'Cek pembaruan';

  @override
  String get updateSubtitle => 'Periksa & pasang versi terbaru';

  @override
  String get sectionAccount => 'Akun';

  @override
  String get accountName => 'Nama';

  @override
  String get changePassword => 'Ganti kata sandi';

  @override
  String get recoveryKey => 'Kunci pemulihan';

  @override
  String get recoveryKeySubtitle => 'Lihat/buat ulang kunci keamanan';

  @override
  String get logout => 'Keluar';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get deleteAccountSubtitle => 'Menghapus akun & seluruh data permanen';

  @override
  String get languageDialogTitle => 'Pilih Bahasa';

  @override
  String get tabInvestments => 'Investasi';

  @override
  String get tooltipUpdatePrices => 'Perbarui semua harga';

  @override
  String get tooltipStockTrade => 'Transaksi Saham (RDN)';

  @override
  String get fabInvestment => 'Investasi';

  @override
  String get snackUpdatingPrices => 'Memperbarui harga...';

  @override
  String get snackNoAutoPrices => 'Tidak ada aset dengan harga otomatis.';

  @override
  String get snackPricesUpdated => 'harga diperbarui.';

  @override
  String get snackPricesUpdateFailed1 => 'diperbarui,';

  @override
  String get snackPricesUpdateFailed2 => 'gagal dari';

  @override
  String get emptyInvestmentTitle => 'Belum ada investasi';

  @override
  String get emptyInvestmentSubtitle =>
      'Tambahkan saham, reksadana, crypto, atau emas\nuntuk melacak nilai portofoliomu.';

  @override
  String get totalPortfolioValue => 'Total Nilai Portofolio';

  @override
  String get qtyLot => 'lot';

  @override
  String get qtyUnit => 'unit';

  @override
  String get updatedAtLabel => 'Diperbarui';

  @override
  String get addInvestment => 'Tambah Investasi';

  @override
  String get editInvestment => 'Edit Investasi';

  @override
  String get nameLabel => 'Nama';

  @override
  String get nameHint => 'mis. BBCA, Bitcoin, Emas';

  @override
  String get typeLabel => 'Jenis';

  @override
  String get tickerCryptoLabel => 'ID CoinGecko';

  @override
  String get tickerStockLabel => 'Kode saham';

  @override
  String get tickerCryptoHint => 'mis. bitcoin, ethereum, solana';

  @override
  String get tickerStockHint => 'mis. BBCA, TLKM';

  @override
  String get tickerCryptoHelper => 'Untuk ambil harga otomatis (opsional)';

  @override
  String get tickerStockHelper =>
      'Harga saham otomatis aktif setelah backend di-deploy';

  @override
  String get qtyLotLabel => 'Jumlah lot';

  @override
  String get qtyUnitLabel => 'Jumlah unit';

  @override
  String get qtyLotHint => 'mis. 5, 10';

  @override
  String get qtyUnitHint => 'mis. 100, 0.5';

  @override
  String qtyLotHelper(String shares) {
    return '1 lot = $shares lembar';
  }

  @override
  String get buyLotLabel => 'Harga beli / lembar';

  @override
  String get buyUnitLabel => 'Harga beli / unit';

  @override
  String get nowLotLabel => 'Harga sekarang / lembar';

  @override
  String get nowUnitLabel => 'Harga sekarang / unit';

  @override
  String get tooltipFetchPrice => 'Ambil harga sekarang';

  @override
  String get snackTickerEmpty => 'Isi dulu ticker/simbol asetnya.';

  @override
  String get snackPriceUpdated => 'Harga diperbarui:';

  @override
  String get snackFailed => 'Gagal.';

  @override
  String get deleteLabel => 'Hapus';

  @override
  String get saveButton => 'Simpan';

  @override
  String get addButton => 'Tambah';

  @override
  String get invalidNumber => 'Angka tidak valid';

  @override
  String get tradeStockTitle => 'Transaksi Saham';

  @override
  String get buyLabel => 'Beli';

  @override
  String get sellLabel => 'Jual';

  @override
  String get snackNoRdn =>
      'Buat akun jenis \"RDN (Saham)\" dulu di tab Akun untuk transaksi saham.';

  @override
  String get noStockToSell => 'Belum ada saham untuk dijual.';

  @override
  String get stockDropdownLabel => 'Saham';

  @override
  String get newStockOption => '+ Saham baru';

  @override
  String get stockNameLabel => 'Nama saham';

  @override
  String get stockNameHint => 'mis. BBCA';

  @override
  String get stockCodeLabel => 'Kode (opsional)';

  @override
  String get rdnAccountLabel => 'Rekening RDN';

  @override
  String lotQtyHelperSell(String lots) {
    return 'Punya $lots lot';
  }

  @override
  String maxLotError(String lots) {
    return 'Maks $lots';
  }

  @override
  String get pricePerShareLabel => 'Harga/lembar';

  @override
  String get totalPayLabel => 'Total bayar';

  @override
  String get totalReceiveLabel => 'Total diterima';

  @override
  String get snackBuySuccess => 'Pembelian saham tercatat.';

  @override
  String get snackSellSuccess => 'Penjualan saham tercatat.';

  @override
  String get tabWishlist => 'Wishlist';

  @override
  String get emptyWishlistTitle => 'Wishlist masih kosong';

  @override
  String get emptyWishlistSubtitle =>
      'Catat barang yang ingin dibeli beserta harga,\nlink, dan target tanggalnya.';

  @override
  String get totalTargetBelanja => 'Total target belanja';

  @override
  String barangBelumDibeli(String count) {
    return '$count barang belum dibeli';
  }

  @override
  String get sudahDibeli => 'Sudah Dibeli';

  @override
  String get gagalMembukaLink => 'Tidak bisa membuka link.';

  @override
  String get targetDateLabel => 'Target';

  @override
  String get savingPerMonthSuffix => '/bln';

  @override
  String savingProgressLabel(String saved, String total) {
    return 'Terkumpul $saved / $total';
  }

  @override
  String savingMonthsRemaining(String months) {
    return ' · ~$months bln lagi';
  }

  @override
  String get tooltipCatatNabung => 'Catat nabung';

  @override
  String get tooltipBukaLink => 'Buka link';

  @override
  String dialogNabungTitle(String name) {
    return 'Nabung untuk $name';
  }

  @override
  String dialogNabungSisa(String remaining) {
    return 'Sisa $remaining';
  }

  @override
  String get dialogNabungJumlah => 'Jumlah ditabung';

  @override
  String get dialogNabungAmbilDari => 'Ambil dari rekening';

  @override
  String get dialogNabungTanpaPotong => 'Tanpa potong saldo';

  @override
  String get cancelButton => 'Batal';

  @override
  String get recordButton => 'Catat';

  @override
  String get addWishlist => 'Tambah Wishlist';

  @override
  String get editWishlist => 'Edit Wishlist';

  @override
  String get itemNameLabel => 'Nama barang';

  @override
  String get itemNameHint => 'mis. iPhone, Sepeda, Laptop';

  @override
  String get estPriceLabel => 'Perkiraan harga';

  @override
  String get linkOptionalLabel => 'Link pembelian (opsional)';

  @override
  String get priorityLabel => 'Prioritas';

  @override
  String get targetDateOptionalLabel => 'Target tanggal (opsional)';

  @override
  String get selectDate => 'Pilih tanggal';

  @override
  String get savingPlanOptional => 'Rencana Menabung (opsional)';

  @override
  String get savePerMonthLabel => 'Tabung/bln';

  @override
  String get durationLabel => 'Jangka';

  @override
  String get monthSuffix => 'bln';

  @override
  String get calcHelperText => 'Isi salah satu, yang lain dihitung otomatis.';

  @override
  String nabungSelamaHelper(String monthly, String months) {
    return 'Nabung $monthly/bln selama $months bulan.';
  }

  @override
  String get saveFromAccountLabel => 'Tabung dari rekening';

  @override
  String get noneOption => '—';

  @override
  String get reminderDayLabel => 'Pengingat menabung tiap tanggal';

  @override
  String get noReminder => 'Tidak ada';

  @override
  String dateSuffix(String date) {
    return 'Tanggal $date';
  }

  @override
  String get exportReportTitle => 'Ekspor Laporan';

  @override
  String get exportPeriodLabel => 'Periode';

  @override
  String get exportTypeFormatLabel => 'Tipe Ekspor & Format';

  @override
  String get exportMonthlyPdf => 'Laporan Bulanan (PDF)';

  @override
  String get exportMonthlyExcel => 'Laporan Bulanan (Excel)';

  @override
  String get exportAllExcel => 'Backup Seluruh Data (Excel)';

  @override
  String get exportAllExcelSubtitle =>
      'Mengekspor seluruh akun, transaksi, utang, piutang, wishlist, dll.';

  @override
  String get exportNowBtn => 'Ekspor Sekarang';

  @override
  String get snackPrepBackup => 'Menyiapkan Backup Seluruh Data...';

  @override
  String snackPrepMonth(String month) {
    return 'Menyiapkan $month...';
  }

  @override
  String get tabReport => 'Laporan';

  @override
  String get tooltipExport => 'Export Laporan';

  @override
  String get cashFlow6Months => 'Arus Kas 6 Bulan';

  @override
  String get assetComposition => 'Komposisi Aset';

  @override
  String get expenseByCategory => 'Pengeluaran per Kategori';

  @override
  String get summaryIncome => 'Pemasukan';

  @override
  String get summaryExpense => 'Pengeluaran';

  @override
  String get summaryNet => 'Selisih';

  @override
  String get emptyCashFlow => 'Belum ada arus kas untuk ditampilkan.';

  @override
  String get pieAssetCash => 'Kas';

  @override
  String get pieAssetInvestment => 'Investasi';

  @override
  String get pieAssetReceivable => 'Piutang';

  @override
  String get emptyAsset => 'Belum ada aset untuk ditampilkan.';

  @override
  String get emptyCategory => 'Tidak ada pengeluaran di bulan ini.';

  @override
  String get tabMonthlyTx => 'Transaksi Bulanan';

  @override
  String get tooltipAddTemplate => 'Tambah template';

  @override
  String get emptyMonthlyTitle => 'Belum ada transaksi bulanan';

  @override
  String get emptyMonthlySubtitle =>
      'Susun biaya rutin (langganan, tagihan, tabungan), lalu\njalankan semua sekaligus tiap bulan.';

  @override
  String runBarIncome(String amount) {
    return 'Masuk $amount';
  }

  @override
  String runBarExpense(String amount) {
    return 'Keluar $amount';
  }

  @override
  String runAllBtn(String count) {
    return 'Jalankan Semua ($count)';
  }

  @override
  String get confirmRunTitle => 'Jalankan transaksi bulanan?';

  @override
  String confirmRunContent(String count) {
    return '$count transaksi aktif akan dibuat dengan tanggal hari ini. Saldo rekening akan diperbarui.';
  }

  @override
  String get confirmRunOk => 'Jalankan';

  @override
  String runSuccessWithSkip(String created, String skipped) {
    return '$created transaksi dibuat, $skipped dilewati (saldo kurang).';
  }

  @override
  String runSuccessAll(String created) {
    return '$created transaksi bulanan berhasil dijalankan.';
  }

  @override
  String get addTemplate => 'Tambah Template';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get templateNameHint => 'mis. Netflix, Listrik, Nabung';

  @override
  String get templateCategoryHint => 'mis. Langganan, Tagihan';

  @override
  String get segmentExpense => 'Keluar';

  @override
  String get segmentIncome => 'Masuk';

  @override
  String get segmentTransfer => 'Transfer';

  @override
  String get amountLabel => 'Jumlah';

  @override
  String get fromAccountLabel => 'Dari rekening';

  @override
  String get toAccountLabel => 'Ke akun';

  @override
  String get errorSelectAccount => 'Pilih akun tujuan';

  @override
  String get errorSameAccount => 'Pilih akun berbeda';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get addBillItem => 'Tambah Item';

  @override
  String get menuNameLabel => 'Nama menu';

  @override
  String get menuNameHint => 'mis. Nasi Goreng';

  @override
  String get priceLabel => 'Harga';

  @override
  String get qtyLabel => 'Jumlah';

  @override
  String get noOtherBillsToSave =>
      'Tidak ada tagihan orang lain untuk disimpan.';

  @override
  String get saveSplitBillTitle => 'Simpan Split Bill';

  @override
  String get friendBillsLabel => 'Tagihan teman (jadi piutang):';

  @override
  String get myShareLabel => 'Bagian saya';

  @override
  String get fundFromAccountLabel => 'Saya menalangi dari rekening';

  @override
  String get doNotDeductBalance => '— Jangan potong saldo';

  @override
  String personLabel(String number) {
    return 'Orang $number';
  }

  @override
  String get totalOutFromAccount => 'Total keluar dari rekening';

  @override
  String get totalReceivableRecorded => 'Total piutang dicatat';

  @override
  String receivableSavedDeducted(String count, String amount) {
    return '$count piutang dicatat, saldo dipotong $amount.';
  }

  @override
  String get splitBillNotePrefix => 'Split bill';

  @override
  String receivableSavedOnly(String count) {
    return '$count piutang tersimpan.';
  }

  @override
  String get tabSplitBill => 'Split Bill';

  @override
  String get personLabelOnly => 'Orang';

  @override
  String get splitBillEmptyState =>
      'Tambah orang dulu, lalu masukkan pesanan masing-masing.';

  @override
  String get deletePersonTooltip => 'Hapus orang';

  @override
  String get meNotBilledLabel => 'Saya (tidak dipiutangkan)';

  @override
  String get itemLabel => 'Item';

  @override
  String get sharedItemsLabel => 'Item Bersama (dibagi rata)';

  @override
  String get addSharedItemLabel => 'Item bersama';

  @override
  String get taxAndDiscountLabel => 'Pajak, Biaya & Diskon';

  @override
  String get ppnLabel => 'PPN';

  @override
  String get serviceChargeLabel => 'Service';

  @override
  String get discountLabel => 'Diskon';

  @override
  String get additionalFeesLabel => 'Biaya tambahan';

  @override
  String get percentageLabel => 'Persentase';

  @override
  String get nominalLabel => 'Nominal';

  @override
  String get splitDiscountEvenlyLabel => 'Bagi diskon rata';

  @override
  String get discountEvenlyDesc => 'Tiap orang dapat potongan sama besar';

  @override
  String get discountProportionalDesc =>
      'Potongan proporsional ke besar pesanan';

  @override
  String get detailsLabel => 'Rincian';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get totalLabel => 'Total';

  @override
  String get billPerPersonLabel => 'Tagihan per orang';

  @override
  String get unnamedLabel => '(tanpa nama)';

  @override
  String get saveToReceivablesBtn => 'Simpan ke Piutang';

  @override
  String get splitBillShare => 'Bagikan';

  @override
  String get splitBillCopied => 'Rincian split bill disalin.';

  @override
  String get splitBillShareFailed => 'Gagal membagikan rincian split bill.';

  @override
  String get createAccountSubtitle => 'Buat akun baru';

  @override
  String get loginSubtitle => 'Masuk ke akunmu';

  @override
  String get registerButton => 'Daftar';

  @override
  String get loginButton => 'Masuk';

  @override
  String get orDividerLabel => 'atau';

  @override
  String get loginWithGoogleBtn => 'Masuk dengan Google';

  @override
  String get alreadyHaveAccountBtn => 'Sudah punya akun? Masuk';

  @override
  String get dontHaveAccountBtn => 'Belum punya akun? Daftar';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Email wajib diisi';

  @override
  String get emailInvalid => 'Format email tidak valid';

  @override
  String get passwordLabel => 'Kata sandi';

  @override
  String get passwordRequired => 'Kata sandi wajib diisi';

  @override
  String get passwordMinLen => 'Minimal 6 karakter';

  @override
  String get nameRequired => 'Nama wajib diisi';

  @override
  String get passwordConfirmLabel => 'Ulangi kata sandi';

  @override
  String get requiredField => 'Wajib diisi';

  @override
  String get passwordNotMatch => 'Kata sandi tidak sama';

  @override
  String get completeAccountTitle => 'Lengkapi Akun';

  @override
  String completeAccountDesc(String email) {
    return 'Kamu masuk sebagai $email. Buat kata sandi untuk menyelesaikan pendaftaran. Setelah ini kamu bisa masuk dengan email + kata sandi.';
  }

  @override
  String get saveAndContinueBtn => 'Simpan & Lanjutkan';

  @override
  String get logoutButton => 'Keluar';

  @override
  String get wrongPassword => 'Kata sandi salah.';

  @override
  String get invalidRecoveryKey => 'Kunci pemulihan tidak valid.';

  @override
  String get unlockDataTitle => 'Buka Data';

  @override
  String get unlockRecoveryDesc =>
      'Masukkan kunci pemulihan & kata sandi baru untuk membuka data di perangkat ini.';

  @override
  String get unlockPasswordDesc =>
      'Masukkan kata sandimu untuk membuka data di perangkat ini. Hanya sekali per perangkat.';

  @override
  String get unlockBtn => 'Buka';

  @override
  String get forgotPasswordBtn => 'Lupa kata sandi?';

  @override
  String get recoveryKeyLabel => 'Kunci pemulihan';

  @override
  String get recoveryKeyHint => 'XXXX-XXXX-XXXX-...';

  @override
  String get newPasswordLabel => 'Kata sandi baru';

  @override
  String get confirmNewPasswordLabel => 'Ulangi kata sandi baru';

  @override
  String get unlockAndChangePassBtn => 'Buka & Ganti Sandi';

  @override
  String get rememberPasswordBtn => 'Saya ingat kata sandi';

  @override
  String get upgradeSecurityTitle => 'Tingkatkan Keamanan Data';

  @override
  String get upgradeSecurityDesc =>
      'Data keuanganmu kini akan dienkripsi sebelum disimpan di cloud — termasuk pemilik project pun tak bisa membacanya. Masukkan kata sandimu untuk memulai.';

  @override
  String get currentPasswordLabel => 'Kata sandi saat ini';

  @override
  String get startEncryptionBtn => 'Mulai Enkripsi';

  @override
  String get saveRecoveryKeyTitle => 'Simpan Kunci Pemulihan';

  @override
  String get saveRecoveryKeyDesc =>
      'Ini adalah satu-satunya cara membuka datamu jika lupa kata sandi. Kami tidak menyimpannya. Salin & simpan di tempat aman (mis. password manager). Tanpa ini dan tanpa sandi, data tak bisa dikembalikan.';

  @override
  String get recoveryKeyCopied => 'Kunci disalin.';

  @override
  String get copyKeyBtn => 'Salin kunci';

  @override
  String get iHaveSavedItBtn => 'Saya sudah menyimpannya';

  @override
  String get addAccountFirst => 'Tambahkan rekening dulu di tab Akun.';

  @override
  String payDebtTitle(String name) {
    return 'Bayar $name';
  }

  @override
  String debtRemainingLabel(String amount) {
    return 'Sisa utang: $amount';
  }

  @override
  String get payAmountLabel => 'Jumlah bayar';

  @override
  String balanceHelper(String name, String amount) {
    return 'Saldo $name: $amount';
  }

  @override
  String exceedsDebtRemaining(String amount) {
    return 'Melebihi sisa utang ($amount)';
  }

  @override
  String exceedsBalance(String amount) {
    return 'Melebihi saldo ($amount)';
  }

  @override
  String get payFromLabel => 'Bayar dari';

  @override
  String get payNowBtn => 'Bayar Sekarang';

  @override
  String paymentRecorded(String amount) {
    return 'Pembayaran $amount tercatat.';
  }

  @override
  String get editDebtTitle => 'Edit Utang';

  @override
  String get addDebtTitle => 'Tambah Utang';

  @override
  String get debtNameHint => 'mis. KPR BTN, Kartu Kredit';

  @override
  String get debtRemainingInputLabel => 'Sisa utang';

  @override
  String get monthlyPaymentOptional => 'Cicilan per bulan (opsional)';

  @override
  String get dueDateOptional => 'Jatuh tempo (opsional)';

  @override
  String get selectDateBtn => 'Pilih tanggal';

  @override
  String collectFromTitle(String name) {
    return 'Terima dari $name';
  }

  @override
  String totalOutstanding(String amount) {
    return 'Sisa total: $amount';
  }

  @override
  String loanCount(int count) {
    return '$count pinjaman';
  }

  @override
  String get fifoPaymentNote =>
      'Pembayaran melunasi pinjaman paling lama dulu.';

  @override
  String get amountReceivedLabel => 'Jumlah diterima';

  @override
  String exceedsTotalOutstanding(String amount) {
    return 'Melebihi sisa total ($amount)';
  }

  @override
  String get receiveIntoLabel => 'Masuk ke';

  @override
  String get receiveNowBtn => 'Terima Sekarang';

  @override
  String receivedAmount(String amount) {
    return 'Diterima $amount.';
  }

  @override
  String get editReceivableTitle => 'Edit Piutang';

  @override
  String get addReceivableTitle => 'Tambah Piutang';

  @override
  String get personNameLabel => 'Nama orang';

  @override
  String get personNameHint => 'mis. Gama';

  @override
  String get receivableAmountLabel => 'Jumlah piutang';

  @override
  String get noteOptional => 'Catatan (opsional)';

  @override
  String get noteReceivableHint => 'mis. Makan di resto X';

  @override
  String get fundNowTitle => 'Saya menalangi sekarang';

  @override
  String get fundNowSubtitle => 'Uang keluar dari rekening saya';

  @override
  String get reminderActiveDesc => 'Pengingat aktif. Atur jamnya di bawah.';

  @override
  String get reminderNoPermission =>
      'Izin notifikasi ditolak. Aktifkan di Pengaturan HP.';

  @override
  String get reminderDisabled => 'Pengingat dimatikan.';

  @override
  String reminderDailySetTo(String time) {
    return 'Pengingat harian diatur ke $time.';
  }

  @override
  String get dailyReminderTime => 'Jam pengingat harian';

  @override
  String dailyReminderDesc(String time) {
    return 'Setiap hari pukul $time';
  }

  @override
  String get alreadyLatestVersion => 'Kamu sudah memakai versi terbaru.';

  @override
  String get autoUpdateAndroidOnly =>
      'Pembaruan otomatis hanya tersedia di Android.';

  @override
  String get updateCheckFailed => 'Gagal memeriksa pembaruan. Periksa koneksi.';

  @override
  String get updateCheck => 'Cek pembaruan';

  @override
  String get updateCheckDesc => 'Periksa & pasang versi terbaru';

  @override
  String get renameTitle => 'Ubah Nama';

  @override
  String get passwordChanged => 'Kata sandi berhasil diganti.';

  @override
  String get deleteAccountTitle => 'Hapus Akun?';

  @override
  String get deletePermanently => 'Hapus Permanen';

  @override
  String recoveryKeyCreateFailed(String error) {
    return 'Gagal membuat kunci pemulihan: $error';
  }

  @override
  String get recoveryKeyNew => 'Kunci Pemulihan Baru';

  @override
  String get copy => 'Salin';

  @override
  String get done => 'Selesai';

  @override
  String get recoveryKeyNewDesc =>
      'Demi keamanan, sistem tidak menyimpan Kunci Pemulihan lama Anda. Kami akan membuatkan Kunci Pemulihan yang BARU.';

  @override
  String get updateMandatory => 'Pembaruan ini wajib dipasang.';

  @override
  String downloading(String pct) {
    return 'Mengunduh... $pct%';
  }

  @override
  String get skip => 'Lewati';

  @override
  String get editAccount => 'Edit Akun';

  @override
  String get accountNameHint => 'mis. BCA, GoPay, Dompet';

  @override
  String get accountNumber => 'Nomor rekening';

  @override
  String get initialBalance => 'Saldo awal';

  @override
  String get balance => 'Saldo';

  @override
  String get editTx => 'Edit Transaksi';

  @override
  String get noteOptionalTx => 'Catatan (opsional)';

  @override
  String get date => 'Tanggal';

  @override
  String get adminFeeOptional => 'Biaya transfer (opsional)';

  @override
  String get invalidAmount => 'Masukkan jumlah valid';

  @override
  String get invalidAdminFee => 'Masukkan biaya admin valid';

  @override
  String get adminFeeDesc =>
      'Tujuan tetap terima jumlah penuh; admin keluar dari sumber';

  @override
  String totalOut(String amount) {
    return 'Total keluar dari sumber: $amount';
  }

  @override
  String get priorityLow => 'Rendah';

  @override
  String get priorityMedium => 'Sedang';

  @override
  String get priorityHigh => 'Tinggi';

  @override
  String get noTxTodayTitle => 'Belum ada transaksi hari ini';

  @override
  String get noTxTodayDesc =>
      'Catat pemasukan atau pengeluaranmu biar tetap terpantau.';

  @override
  String get salarySaveTitle => 'Sudah gajian? Sisihkan untuk tabungan';

  @override
  String salarySaveDesc(String names) {
    return 'Jangan lupa nabung untuk: $names.';
  }

  @override
  String timeToSaveTitle(String name) {
    return 'Waktunya menabung: $name';
  }

  @override
  String timeToSaveDescAmount(String amount) {
    return 'Sisihkan $amount bulan ini.';
  }

  @override
  String get timeToSaveDescGeneral => 'Sisihkan dana untuk target ini.';

  @override
  String reportTitle(String periodName) {
    return 'Laporan Transaksi MoneyWork - $periodName';
  }

  @override
  String reportPrintedOn(String date) {
    return 'Dicetak pada: $date';
  }

  @override
  String get reportCashflowSummary => 'Ringkasan Arus Kas';

  @override
  String reportIncome(String amount) {
    return 'Pemasukan: $amount';
  }

  @override
  String reportExpense(String amount) {
    return 'Pengeluaran: $amount';
  }

  @override
  String reportNet(String amount) {
    return 'Sisa Saldo (Net): $amount';
  }

  @override
  String get reportExpenseByCategory => 'Pengeluaran per Kategori';

  @override
  String get reportTxDetail => 'Detail Transaksi';

  @override
  String get reportLegendOut => 'Keluar';

  @override
  String get reportLegendIn => 'Masuk';

  @override
  String get reportType => 'Tipe';

  @override
  String get reportDate => 'Tanggal';

  @override
  String get reportAmount => 'Jumlah';

  @override
  String get notifSaveTime => 'Waktunya menabung 💰';

  @override
  String notifSaveAmount(String amount, String name) {
    return 'Sisihkan $amount untuk $name.';
  }

  @override
  String notifSaveGeneral(String name) {
    return 'Saatnya menabung untuk $name.';
  }

  @override
  String get accountTypeCash => 'Tunai';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeEwallet => 'E-Wallet';

  @override
  String get accountTypeRdn => 'RDN (Saham)';

  @override
  String get debtTypeLoan => 'Pinjaman';

  @override
  String get debtTypeCreditCard => 'Kartu Kredit';

  @override
  String get debtTypeInstallment => 'Cicilan';

  @override
  String get debtTypeOther => 'Lainnya';

  @override
  String get invTypeStock => 'Saham';

  @override
  String get invTypeMutualFund => 'Reksadana';

  @override
  String get invTypeCrypto => 'Crypto';

  @override
  String get invTypeGold => 'Emas';

  @override
  String get invTypeOther => 'Lainnya';

  @override
  String get salaryAllocateTitle => 'Saatnya mengatur anggaran bulan ini';

  @override
  String get salaryAllocateDesc =>
      'Gajian sudah masuk, yuk alokasikan ke berbagai akun dan pos pengeluaran.';

  @override
  String get highExpenseTitle => 'Pengeluaran harian cukup tinggi';

  @override
  String highExpenseDesc(String avg) {
    return 'Rata-rata $avg per hari bulan ini. Coba direm sedikit ya.';
  }

  @override
  String get editAccountTitle => 'Edit Akun';

  @override
  String get deleteTransactionWarning =>
      'Saldo akun akan disesuaikan kembali. Tindakan ini tidak bisa dibatalkan.';

  @override
  String get deleteAccountWarning =>
      'Semua transaksi terkait akun ini juga akan dihapus.';

  @override
  String get labelAccountName => 'Nama akun';

  @override
  String get hintAccountName => 'mis. BCA, GoPay, Dompet';

  @override
  String get validationRequired => 'Wajib diisi';

  @override
  String get labelAccountType => 'Jenis';

  @override
  String get labelEwalletNumber => 'Nomor HP / akun e-wallet';

  @override
  String get labelBankNumber => 'Nomor rekening';

  @override
  String get hintOptional => 'opsional';

  @override
  String get labelBalance => 'Saldo';

  @override
  String get labelInitialBalance => 'Saldo awal';

  @override
  String get validationInvalidNumber => 'Angka tidak valid';

  @override
  String get recordTransactionTitle => 'Catat Transaksi';

  @override
  String get labelAmount => 'Jumlah';

  @override
  String helperBalance(String name, String balance) {
    return 'Saldo $name: $balance';
  }

  @override
  String get validationInvalidAmount => 'Masukkan jumlah valid';

  @override
  String validationExceedBalance(String balance) {
    return 'Melebihi saldo ($balance)';
  }

  @override
  String get labelFromAccount => 'Dari akun';

  @override
  String get labelToAccount => 'Ke akun';

  @override
  String get validationSelectDest => 'Pilih akun tujuan';

  @override
  String get validationDiffAccount => 'Pilih akun berbeda';

  @override
  String get adminFeeSubtitle => 'Dipotong dari akun sumber, dicatat terpisah';

  @override
  String get labelAdminFee => 'Biaya admin';

  @override
  String get helperAdminFee =>
      'Tujuan tetap terima jumlah penuh; admin keluar dari sumber';

  @override
  String get validationAdminFee => 'Masukkan biaya admin valid';

  @override
  String get labelCategory => 'Kategori';

  @override
  String get hintCategory => 'mis. Makan, Gaji, Transport';

  @override
  String get labelNote => 'Catatan (opsional)';

  @override
  String get labelDate => 'Tanggal';

  @override
  String get updateAvailable => 'Pembaruan tersedia';

  @override
  String updateVersion(String version) {
    return 'Pembaruan $version';
  }

  @override
  String get updateDefaultNotes => 'Versi baru aplikasi sudah tersedia.';

  @override
  String get updateBtn => 'Perbarui';

  @override
  String get retryBtn => 'Coba lagi';

  @override
  String get excelHeaderDate => 'Tanggal';

  @override
  String get excelHeaderType => 'Tipe';

  @override
  String get excelHeaderCategory => 'Kategori';

  @override
  String get excelHeaderAmount => 'Jumlah (Rp)';

  @override
  String get excelHeaderAccount => 'Rekening';

  @override
  String get excelHeaderNote => 'Catatan';

  @override
  String reportPrintedAt(String date) {
    return 'Dicetak pada: $date';
  }

  @override
  String get legendIncome => 'Masuk';

  @override
  String get legendExpense => 'Keluar';

  @override
  String get noTransactionPeriod => 'Tidak ada transaksi di periode ini.';

  @override
  String shareReportText(String period) {
    return 'Laporan Transaksi MoneyWork $period';
  }

  @override
  String get excelHeaderBalance => 'Saldo';

  @override
  String get excelHeaderBankNo => 'Rekening';

  @override
  String get excelHeaderCreatedAt => 'Dibuat Pada';

  @override
  String get excelHeaderLender => 'Pemberi Utang (Nama)';

  @override
  String get excelHeaderDebtRemaining => 'Sisa Utang';

  @override
  String get excelHeaderMonthlyPayment => 'Cicilan Bulanan';

  @override
  String get excelHeaderDueDate => 'Jatuh Tempo';

  @override
  String get excelHeaderBorrower => 'Peminjam (Nama)';

  @override
  String get excelHeaderRecNote => 'Judul/Catatan';

  @override
  String get excelHeaderRecRemaining => 'Sisa Piutang';

  @override
  String get excelHeaderAssetName => 'Nama Aset';

  @override
  String get excelHeaderTicker => 'Ticker';

  @override
  String get excelHeaderQuantity => 'Kuantitas';

  @override
  String get excelHeaderBuyPrice => 'Harga Beli';

  @override
  String get excelHeaderCurrentPrice => 'Harga Saat Ini';

  @override
  String get excelHeaderTotalCost => 'Total Modal';

  @override
  String get excelHeaderTotalMarket => 'Total Pasar';

  @override
  String get excelHeaderReturn => 'Return (%)';

  @override
  String get excelHeaderItemName => 'Nama Barang';

  @override
  String get excelHeaderTargetPrice => 'Target Harga';

  @override
  String get excelHeaderSaved => 'Terkumpul';

  @override
  String get excelHeaderPriority => 'Prioritas';

  @override
  String get excelHeaderStatus => 'Status';

  @override
  String get excelHeaderTargetDate => 'Target Tgl';

  @override
  String get statusPurchased => 'Terbeli';

  @override
  String get statusNotPurchased => 'Belum Terbeli';

  @override
  String get excelHeaderLabel => 'Label';

  @override
  String get excelHeaderNominal => 'Nominal';

  @override
  String get excelHeaderActiveStatus => 'Status Aktif';

  @override
  String get statusActive => 'Aktif';

  @override
  String get statusInactive => 'Nonaktif';

  @override
  String shareBackupText(String date) {
    return 'Backup Seluruh Data MoneyWork ($date)';
  }

  @override
  String get excelSheetAccounts => 'Akun';

  @override
  String get excelSheetTransactions => 'Transaksi';

  @override
  String get excelSheetDebts => 'Utang';

  @override
  String get excelSheetReceivables => 'Piutang';

  @override
  String get excelSheetInvestments => 'Investasi';

  @override
  String get excelSheetRecurring => 'Rutin';

  @override
  String get priceErrNoTicker => 'Isi dulu ticker/simbol asetnya.';

  @override
  String get priceErrUnsupported =>
      'Harga otomatis belum tersedia untuk jenis ini.';

  @override
  String get priceErrFetch =>
      'Gagal mengambil harga. Periksa koneksi internetmu.';

  @override
  String priceErrServer(int code) {
    return 'Server CoinGecko error ($code).';
  }

  @override
  String priceErrNotFound(String id) {
    return 'Ticker \"$id\" tidak ditemukan di CoinGecko.';
  }

  @override
  String get priceErrStockNotReady =>
      'Harga saham otomatis belum aktif (backend belum di-deploy).';

  @override
  String priceErrStockServer(int code) {
    return 'Server harga saham error ($code).';
  }

  @override
  String priceErrStockNotFound(String code) {
    return 'Kode saham \"$code\" tidak ditemukan.';
  }

  @override
  String get categoryOther => 'Lainnya';

  @override
  String errorLoadSession(String error) {
    return 'Gagal memuat sesi: $error';
  }

  @override
  String errorLoadSecurity(String error) {
    return 'Gagal memuat status keamanan: $error';
  }

  @override
  String get notifDailyTitle => 'Catat transaksi hari ini';

  @override
  String get notifDailyBody =>
      'Jangan lupa catat pemasukan & pengeluaranmu di MoneyWork.';

  @override
  String get notifSaveTitle => 'Waktunya menabung 💰';

  @override
  String get receiptReview => 'Review Bon';

  @override
  String get receiptVerified => '✅ Total cocok — data siap digunakan';

  @override
  String get receiptMismatch =>
      '⚠️ Total tidak cocok — periksa kembali angka di bawah';

  @override
  String get receiptItemName => 'Nama Barang';

  @override
  String get receiptQty => 'Jml';

  @override
  String get receiptUnitPrice => 'Harga Satuan';

  @override
  String get receiptServiceCharge => 'Biaya Layanan';

  @override
  String get receiptTax => 'Pajak';

  @override
  String get receiptDiscount => 'Diskon';

  @override
  String get receiptGrandTotalPaper => 'Grand Total (Kertas)';

  @override
  String get receiptGrandTotalCalc => 'Grand Total (Terhitung)';

  @override
  String get receiptSaveAsTransaction => 'Simpan sbg Transaksi';

  @override
  String get receiptSplitBill => 'Split Bill';

  @override
  String get receiptScanning => 'Memindai bon...';

  @override
  String get receiptScanFailed => 'Gagal memindai bon';

  @override
  String get scanFromCamera => 'Kamera';

  @override
  String get scanFromGallery => 'Galeri';

  @override
  String get scanChooseSource => 'Pilih Sumber Foto';

  @override
  String get assignItemsTitle => 'Bagi Pesanan';

  @override
  String get howManyPeople => 'Berapa orang yang ikut bayar?';

  @override
  String get nextStep => 'Lanjut';

  @override
  String get enterNames => 'Masukkan nama tiap orang';

  @override
  String personNumber(int number) {
    return 'Orang ke-$number';
  }

  @override
  String selectItemsFor(String name) {
    return 'Pilih pesanan $name';
  }

  @override
  String get calculateSplit => 'Hitung Pembagian';

  @override
  String get editTransactionTitle => 'Edit Transaksi';
}
