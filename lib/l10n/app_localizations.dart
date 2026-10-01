import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('zh')
  ];

  /// Nama aplikasi
  ///
  /// In id, this message translates to:
  /// **'MoneyWork'**
  String get appTitle;

  /// Teks tab Beranda di navigasi bawah
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navHome;

  /// Teks tab Tagihan di navigasi bawah
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get navBills;

  /// Teks tab Akun di navigasi bawah
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get navAccounts;

  /// Teks tab Investasi di navigasi bawah
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get navInvestments;

  /// Label tombol Scan
  ///
  /// In id, this message translates to:
  /// **'Scan'**
  String get scanButton;

  /// Pesan saat fitur belum selesai dibuat
  ///
  /// In id, this message translates to:
  /// **'Fitur segera hadir!'**
  String get featureComingSoon;

  /// Label pengaturan bahasa
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguage;

  /// No description provided for @tooltipWishlist.
  ///
  /// In id, this message translates to:
  /// **'Wishlist'**
  String get tooltipWishlist;

  /// No description provided for @tooltipReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get tooltipReport;

  /// No description provided for @tooltipProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil & Pengaturan'**
  String get tooltipProfile;

  /// No description provided for @errorLoadData.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data'**
  String get errorLoadData;

  /// No description provided for @savingTargetTitle.
  ///
  /// In id, this message translates to:
  /// **'Target Tabungan'**
  String get savingTargetTitle;

  /// No description provided for @netWorthTitle.
  ///
  /// In id, this message translates to:
  /// **'Kekayaan Bersih'**
  String get netWorthTitle;

  /// No description provided for @totalAssetsTitle.
  ///
  /// In id, this message translates to:
  /// **'Total Aset'**
  String get totalAssetsTitle;

  /// No description provided for @totalDebtTitle.
  ///
  /// In id, this message translates to:
  /// **'Total Utang'**
  String get totalDebtTitle;

  /// No description provided for @cashTitle.
  ///
  /// In id, this message translates to:
  /// **'Kas'**
  String get cashTitle;

  /// No description provided for @investmentTitle.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get investmentTitle;

  /// No description provided for @receivableTitle.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get receivableTitle;

  /// No description provided for @debtTitle.
  ///
  /// In id, this message translates to:
  /// **'Utang'**
  String get debtTitle;

  /// No description provided for @recentTransactionsTitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Terbaru'**
  String get recentTransactionsTitle;

  /// No description provided for @noTransactionsMessage.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi.'**
  String get noTransactionsMessage;

  /// No description provided for @titleAccounts.
  ///
  /// In id, this message translates to:
  /// **'Akun & Transaksi'**
  String get titleAccounts;

  /// No description provided for @tooltipMonthlyExpenses.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Bulanan'**
  String get tooltipMonthlyExpenses;

  /// No description provided for @fabAddAccount.
  ///
  /// In id, this message translates to:
  /// **'Tambah Akun'**
  String get fabAddAccount;

  /// No description provided for @fabRecordTransaction.
  ///
  /// In id, this message translates to:
  /// **'Catat Transaksi'**
  String get fabRecordTransaction;

  /// No description provided for @errorLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat'**
  String get errorLoadFailed;

  /// No description provided for @emptyAccountTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan rekening dulu'**
  String get emptyAccountTitle;

  /// No description provided for @emptyAccountSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi bulanan butuh rekening sebagai sumber/tujuan.'**
  String get emptyAccountSubtitle;

  /// No description provided for @transactionHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Transaksi'**
  String get transactionHistory;

  /// No description provided for @noTransactionsFilter.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi yang cocok dengan filter.'**
  String get noTransactionsFilter;

  /// No description provided for @searchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari catatan / kategori'**
  String get searchHint;

  /// No description provided for @tooltipClearFilter.
  ///
  /// In id, this message translates to:
  /// **'Hapus filter'**
  String get tooltipClearFilter;

  /// No description provided for @filterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get filterAll;

  /// No description provided for @filterAllAccounts.
  ///
  /// In id, this message translates to:
  /// **'Semua akun'**
  String get filterAllAccounts;

  /// No description provided for @accountLabel.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get accountLabel;

  /// No description provided for @myAccounts.
  ///
  /// In id, this message translates to:
  /// **'Akun Saya'**
  String get myAccounts;

  /// No description provided for @titleBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get titleBills;

  /// No description provided for @tooltipSplitBill.
  ///
  /// In id, this message translates to:
  /// **'Split Bill'**
  String get tooltipSplitBill;

  /// No description provided for @tooltipAddDebt.
  ///
  /// In id, this message translates to:
  /// **'Tambah Utang'**
  String get tooltipAddDebt;

  /// No description provided for @tooltipAddReceivable.
  ///
  /// In id, this message translates to:
  /// **'Tambah Piutang'**
  String get tooltipAddReceivable;

  /// No description provided for @tabDebts.
  ///
  /// In id, this message translates to:
  /// **'Utang & Cicilan'**
  String get tabDebts;

  /// No description provided for @tabReceivables.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get tabReceivables;

  /// No description provided for @fabDebt.
  ///
  /// In id, this message translates to:
  /// **'Utang'**
  String get fabDebt;

  /// No description provided for @emptyDebtTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada utang'**
  String get emptyDebtTitle;

  /// No description provided for @emptyDebtSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Bagus! Kalau ada pinjaman, kartu kredit, atau cicilan,\ncatat di sini untuk hitung kekayaan bersih.'**
  String get emptyDebtSubtitle;

  /// No description provided for @totalDebtLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Utang'**
  String get totalDebtLabel;

  /// No description provided for @monthlyInstallment.
  ///
  /// In id, this message translates to:
  /// **'Cicilan/bln'**
  String get monthlyInstallment;

  /// No description provided for @paidOff.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get paidOff;

  /// No description provided for @duePrefix.
  ///
  /// In id, this message translates to:
  /// **'Tempo'**
  String get duePrefix;

  /// No description provided for @perMonthSuffix.
  ///
  /// In id, this message translates to:
  /// **'/bln'**
  String get perMonthSuffix;

  /// No description provided for @payButton.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get payButton;

  /// No description provided for @fabReceivable.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get fabReceivable;

  /// No description provided for @emptyReceivableTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada piutang'**
  String get emptyReceivableTitle;

  /// No description provided for @emptyReceivableSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Catat uang yang dipinjam teman/orang lain ke kamu.\nBisa juga dari kalkulator split bill.'**
  String get emptyReceivableSubtitle;

  /// No description provided for @totalReceivableLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Piutang'**
  String get totalReceivableLabel;

  /// No description provided for @peopleCountSuffix.
  ///
  /// In id, this message translates to:
  /// **'orang'**
  String get peopleCountSuffix;

  /// No description provided for @loansCountSuffix.
  ///
  /// In id, this message translates to:
  /// **'pinjaman'**
  String get loansCountSuffix;

  /// No description provided for @settled.
  ///
  /// In id, this message translates to:
  /// **'selesai'**
  String get settled;

  /// No description provided for @remaining.
  ///
  /// In id, this message translates to:
  /// **'sisa'**
  String get remaining;

  /// No description provided for @receiveFrom.
  ///
  /// In id, this message translates to:
  /// **'Terima dari'**
  String get receiveFrom;

  /// No description provided for @profileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil & Pengaturan'**
  String get profileTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get sectionAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @sectionLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa / Language'**
  String get sectionLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem (System Default)'**
  String get languageSystem;

  /// No description provided for @languageId.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get languageId;

  /// No description provided for @languageEn.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageZh.
  ///
  /// In id, this message translates to:
  /// **'中文 (Mandarin)'**
  String get languageZh;

  /// No description provided for @sectionReminders.
  ///
  /// In id, this message translates to:
  /// **'Pengingat'**
  String get sectionReminders;

  /// No description provided for @reminderTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengingat di HP'**
  String get reminderTitle;

  /// No description provided for @reminderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan catat transaksi harian & jadwal menabung'**
  String get reminderSubtitle;

  /// No description provided for @reminderTimeTitle.
  ///
  /// In id, this message translates to:
  /// **'Jam pengingat harian'**
  String get reminderTimeTitle;

  /// No description provided for @reminderTimeSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Setiap hari pukul'**
  String get reminderTimeSubtitle;

  /// No description provided for @sectionApp.
  ///
  /// In id, this message translates to:
  /// **'Aplikasi'**
  String get sectionApp;

  /// No description provided for @updateTitle.
  ///
  /// In id, this message translates to:
  /// **'Cek pembaruan'**
  String get updateTitle;

  /// No description provided for @updateSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Periksa & pasang versi terbaru'**
  String get updateSubtitle;

  /// No description provided for @sectionAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get sectionAccount;

  /// No description provided for @accountName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get accountName;

  /// No description provided for @changePassword.
  ///
  /// In id, this message translates to:
  /// **'Ganti kata sandi'**
  String get changePassword;

  /// No description provided for @recoveryKey.
  ///
  /// In id, this message translates to:
  /// **'Kunci pemulihan'**
  String get recoveryKey;

  /// No description provided for @recoveryKeySubtitle.
  ///
  /// In id, this message translates to:
  /// **'Lihat/buat ulang kunci keamanan'**
  String get recoveryKeySubtitle;

  /// No description provided for @logout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In id, this message translates to:
  /// **'Hapus akun'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Menghapus akun & seluruh data permanen'**
  String get deleteAccountSubtitle;

  /// No description provided for @languageDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Bahasa'**
  String get languageDialogTitle;

  /// No description provided for @tabInvestments.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get tabInvestments;

  /// No description provided for @tooltipUpdatePrices.
  ///
  /// In id, this message translates to:
  /// **'Perbarui semua harga'**
  String get tooltipUpdatePrices;

  /// No description provided for @tooltipStockTrade.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Saham (RDN)'**
  String get tooltipStockTrade;

  /// No description provided for @fabInvestment.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get fabInvestment;

  /// No description provided for @snackUpdatingPrices.
  ///
  /// In id, this message translates to:
  /// **'Memperbarui harga...'**
  String get snackUpdatingPrices;

  /// No description provided for @snackNoAutoPrices.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada aset dengan harga otomatis.'**
  String get snackNoAutoPrices;

  /// No description provided for @snackPricesUpdated.
  ///
  /// In id, this message translates to:
  /// **'harga diperbarui.'**
  String get snackPricesUpdated;

  /// No description provided for @snackPricesUpdateFailed1.
  ///
  /// In id, this message translates to:
  /// **'diperbarui,'**
  String get snackPricesUpdateFailed1;

  /// No description provided for @snackPricesUpdateFailed2.
  ///
  /// In id, this message translates to:
  /// **'gagal dari'**
  String get snackPricesUpdateFailed2;

  /// No description provided for @emptyInvestmentTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada investasi'**
  String get emptyInvestmentTitle;

  /// No description provided for @emptyInvestmentSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan saham, reksadana, crypto, atau emas\nuntuk melacak nilai portofoliomu.'**
  String get emptyInvestmentSubtitle;

  /// No description provided for @totalPortfolioValue.
  ///
  /// In id, this message translates to:
  /// **'Total Nilai Portofolio'**
  String get totalPortfolioValue;

  /// No description provided for @qtyLot.
  ///
  /// In id, this message translates to:
  /// **'lot'**
  String get qtyLot;

  /// No description provided for @qtyUnit.
  ///
  /// In id, this message translates to:
  /// **'unit'**
  String get qtyUnit;

  /// No description provided for @updatedAtLabel.
  ///
  /// In id, this message translates to:
  /// **'Diperbarui'**
  String get updatedAtLabel;

  /// No description provided for @addInvestment.
  ///
  /// In id, this message translates to:
  /// **'Tambah Investasi'**
  String get addInvestment;

  /// No description provided for @editInvestment.
  ///
  /// In id, this message translates to:
  /// **'Edit Investasi'**
  String get editInvestment;

  /// No description provided for @nameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. BBCA, Bitcoin, Emas'**
  String get nameHint;

  /// No description provided for @typeLabel.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get typeLabel;

  /// No description provided for @tickerCryptoLabel.
  ///
  /// In id, this message translates to:
  /// **'ID CoinGecko'**
  String get tickerCryptoLabel;

  /// No description provided for @tickerStockLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode saham'**
  String get tickerStockLabel;

  /// No description provided for @tickerCryptoHint.
  ///
  /// In id, this message translates to:
  /// **'mis. bitcoin, ethereum, solana'**
  String get tickerCryptoHint;

  /// No description provided for @tickerStockHint.
  ///
  /// In id, this message translates to:
  /// **'mis. BBCA, TLKM'**
  String get tickerStockHint;

  /// No description provided for @tickerCryptoHelper.
  ///
  /// In id, this message translates to:
  /// **'Untuk ambil harga otomatis (opsional)'**
  String get tickerCryptoHelper;

  /// No description provided for @tickerStockHelper.
  ///
  /// In id, this message translates to:
  /// **'Harga saham otomatis aktif setelah backend di-deploy'**
  String get tickerStockHelper;

  /// No description provided for @qtyLotLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah lot'**
  String get qtyLotLabel;

  /// No description provided for @qtyUnitLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah unit'**
  String get qtyUnitLabel;

  /// No description provided for @qtyLotHint.
  ///
  /// In id, this message translates to:
  /// **'mis. 5, 10'**
  String get qtyLotHint;

  /// No description provided for @qtyUnitHint.
  ///
  /// In id, this message translates to:
  /// **'mis. 100, 0.5'**
  String get qtyUnitHint;

  /// No description provided for @qtyLotHelper.
  ///
  /// In id, this message translates to:
  /// **'1 lot = {shares} lembar'**
  String qtyLotHelper(String shares);

  /// No description provided for @buyLotLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga beli / lembar'**
  String get buyLotLabel;

  /// No description provided for @buyUnitLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga beli / unit'**
  String get buyUnitLabel;

  /// No description provided for @nowLotLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga sekarang / lembar'**
  String get nowLotLabel;

  /// No description provided for @nowUnitLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga sekarang / unit'**
  String get nowUnitLabel;

  /// No description provided for @tooltipFetchPrice.
  ///
  /// In id, this message translates to:
  /// **'Ambil harga sekarang'**
  String get tooltipFetchPrice;

  /// No description provided for @snackTickerEmpty.
  ///
  /// In id, this message translates to:
  /// **'Isi dulu ticker/simbol asetnya.'**
  String get snackTickerEmpty;

  /// No description provided for @snackPriceUpdated.
  ///
  /// In id, this message translates to:
  /// **'Harga diperbarui:'**
  String get snackPriceUpdated;

  /// No description provided for @snackFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal.'**
  String get snackFailed;

  /// No description provided for @deleteLabel.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get deleteLabel;

  /// No description provided for @saveButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get saveButton;

  /// No description provided for @addButton.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get addButton;

  /// No description provided for @invalidNumber.
  ///
  /// In id, this message translates to:
  /// **'Angka tidak valid'**
  String get invalidNumber;

  /// No description provided for @tradeStockTitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Saham'**
  String get tradeStockTitle;

  /// No description provided for @buyLabel.
  ///
  /// In id, this message translates to:
  /// **'Beli'**
  String get buyLabel;

  /// No description provided for @sellLabel.
  ///
  /// In id, this message translates to:
  /// **'Jual'**
  String get sellLabel;

  /// No description provided for @snackNoRdn.
  ///
  /// In id, this message translates to:
  /// **'Buat akun jenis \"RDN (Saham)\" dulu di tab Akun untuk transaksi saham.'**
  String get snackNoRdn;

  /// No description provided for @noStockToSell.
  ///
  /// In id, this message translates to:
  /// **'Belum ada saham untuk dijual.'**
  String get noStockToSell;

  /// No description provided for @stockDropdownLabel.
  ///
  /// In id, this message translates to:
  /// **'Saham'**
  String get stockDropdownLabel;

  /// No description provided for @newStockOption.
  ///
  /// In id, this message translates to:
  /// **'+ Saham baru'**
  String get newStockOption;

  /// No description provided for @stockNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama saham'**
  String get stockNameLabel;

  /// No description provided for @stockNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. BBCA'**
  String get stockNameHint;

  /// No description provided for @stockCodeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode (opsional)'**
  String get stockCodeLabel;

  /// No description provided for @rdnAccountLabel.
  ///
  /// In id, this message translates to:
  /// **'Rekening RDN'**
  String get rdnAccountLabel;

  /// No description provided for @lotQtyHelperSell.
  ///
  /// In id, this message translates to:
  /// **'Punya {lots} lot'**
  String lotQtyHelperSell(String lots);

  /// No description provided for @maxLotError.
  ///
  /// In id, this message translates to:
  /// **'Maks {lots}'**
  String maxLotError(String lots);

  /// No description provided for @pricePerShareLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga/lembar'**
  String get pricePerShareLabel;

  /// No description provided for @totalPayLabel.
  ///
  /// In id, this message translates to:
  /// **'Total bayar'**
  String get totalPayLabel;

  /// No description provided for @totalReceiveLabel.
  ///
  /// In id, this message translates to:
  /// **'Total diterima'**
  String get totalReceiveLabel;

  /// No description provided for @snackBuySuccess.
  ///
  /// In id, this message translates to:
  /// **'Pembelian saham tercatat.'**
  String get snackBuySuccess;

  /// No description provided for @snackSellSuccess.
  ///
  /// In id, this message translates to:
  /// **'Penjualan saham tercatat.'**
  String get snackSellSuccess;

  /// No description provided for @tabWishlist.
  ///
  /// In id, this message translates to:
  /// **'Wishlist'**
  String get tabWishlist;

  /// No description provided for @emptyWishlistTitle.
  ///
  /// In id, this message translates to:
  /// **'Wishlist masih kosong'**
  String get emptyWishlistTitle;

  /// No description provided for @emptyWishlistSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Catat barang yang ingin dibeli beserta harga,\nlink, dan target tanggalnya.'**
  String get emptyWishlistSubtitle;

  /// No description provided for @totalTargetBelanja.
  ///
  /// In id, this message translates to:
  /// **'Total target belanja'**
  String get totalTargetBelanja;

  /// No description provided for @barangBelumDibeli.
  ///
  /// In id, this message translates to:
  /// **'{count} barang belum dibeli'**
  String barangBelumDibeli(String count);

  /// No description provided for @sudahDibeli.
  ///
  /// In id, this message translates to:
  /// **'Sudah Dibeli'**
  String get sudahDibeli;

  /// No description provided for @gagalMembukaLink.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa membuka link.'**
  String get gagalMembukaLink;

  /// No description provided for @targetDateLabel.
  ///
  /// In id, this message translates to:
  /// **'Target'**
  String get targetDateLabel;

  /// No description provided for @savingPerMonthSuffix.
  ///
  /// In id, this message translates to:
  /// **'/bln'**
  String get savingPerMonthSuffix;

  /// No description provided for @savingProgressLabel.
  ///
  /// In id, this message translates to:
  /// **'Terkumpul {saved} / {total}'**
  String savingProgressLabel(String saved, String total);

  /// No description provided for @savingMonthsRemaining.
  ///
  /// In id, this message translates to:
  /// **' · ~{months} bln lagi'**
  String savingMonthsRemaining(String months);

  /// No description provided for @tooltipCatatNabung.
  ///
  /// In id, this message translates to:
  /// **'Catat nabung'**
  String get tooltipCatatNabung;

  /// No description provided for @tooltipBukaLink.
  ///
  /// In id, this message translates to:
  /// **'Buka link'**
  String get tooltipBukaLink;

  /// No description provided for @dialogNabungTitle.
  ///
  /// In id, this message translates to:
  /// **'Nabung untuk {name}'**
  String dialogNabungTitle(String name);

  /// No description provided for @dialogNabungSisa.
  ///
  /// In id, this message translates to:
  /// **'Sisa {remaining}'**
  String dialogNabungSisa(String remaining);

  /// No description provided for @dialogNabungJumlah.
  ///
  /// In id, this message translates to:
  /// **'Jumlah ditabung'**
  String get dialogNabungJumlah;

  /// No description provided for @dialogNabungAmbilDari.
  ///
  /// In id, this message translates to:
  /// **'Ambil dari rekening'**
  String get dialogNabungAmbilDari;

  /// No description provided for @dialogNabungTanpaPotong.
  ///
  /// In id, this message translates to:
  /// **'Tanpa potong saldo'**
  String get dialogNabungTanpaPotong;

  /// No description provided for @cancelButton.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancelButton;

  /// No description provided for @recordButton.
  ///
  /// In id, this message translates to:
  /// **'Catat'**
  String get recordButton;

  /// No description provided for @addWishlist.
  ///
  /// In id, this message translates to:
  /// **'Tambah Wishlist'**
  String get addWishlist;

  /// No description provided for @editWishlist.
  ///
  /// In id, this message translates to:
  /// **'Edit Wishlist'**
  String get editWishlist;

  /// No description provided for @itemNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama barang'**
  String get itemNameLabel;

  /// No description provided for @itemNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. iPhone, Sepeda, Laptop'**
  String get itemNameHint;

  /// No description provided for @estPriceLabel.
  ///
  /// In id, this message translates to:
  /// **'Perkiraan harga'**
  String get estPriceLabel;

  /// No description provided for @linkOptionalLabel.
  ///
  /// In id, this message translates to:
  /// **'Link pembelian (opsional)'**
  String get linkOptionalLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In id, this message translates to:
  /// **'Prioritas'**
  String get priorityLabel;

  /// No description provided for @targetDateOptionalLabel.
  ///
  /// In id, this message translates to:
  /// **'Target tanggal (opsional)'**
  String get targetDateOptionalLabel;

  /// No description provided for @selectDate.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get selectDate;

  /// No description provided for @savingPlanOptional.
  ///
  /// In id, this message translates to:
  /// **'Rencana Menabung (opsional)'**
  String get savingPlanOptional;

  /// No description provided for @savePerMonthLabel.
  ///
  /// In id, this message translates to:
  /// **'Tabung/bln'**
  String get savePerMonthLabel;

  /// No description provided for @durationLabel.
  ///
  /// In id, this message translates to:
  /// **'Jangka'**
  String get durationLabel;

  /// No description provided for @monthSuffix.
  ///
  /// In id, this message translates to:
  /// **'bln'**
  String get monthSuffix;

  /// No description provided for @calcHelperText.
  ///
  /// In id, this message translates to:
  /// **'Isi salah satu, yang lain dihitung otomatis.'**
  String get calcHelperText;

  /// No description provided for @nabungSelamaHelper.
  ///
  /// In id, this message translates to:
  /// **'Nabung {monthly}/bln selama {months} bulan.'**
  String nabungSelamaHelper(String monthly, String months);

  /// No description provided for @saveFromAccountLabel.
  ///
  /// In id, this message translates to:
  /// **'Tabung dari rekening'**
  String get saveFromAccountLabel;

  /// No description provided for @noneOption.
  ///
  /// In id, this message translates to:
  /// **'—'**
  String get noneOption;

  /// No description provided for @reminderDayLabel.
  ///
  /// In id, this message translates to:
  /// **'Pengingat menabung tiap tanggal'**
  String get reminderDayLabel;

  /// No description provided for @noReminder.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada'**
  String get noReminder;

  /// No description provided for @dateSuffix.
  ///
  /// In id, this message translates to:
  /// **'Tanggal {date}'**
  String dateSuffix(String date);

  /// No description provided for @exportReportTitle.
  ///
  /// In id, this message translates to:
  /// **'Ekspor Laporan'**
  String get exportReportTitle;

  /// No description provided for @exportPeriodLabel.
  ///
  /// In id, this message translates to:
  /// **'Periode'**
  String get exportPeriodLabel;

  /// No description provided for @exportTypeFormatLabel.
  ///
  /// In id, this message translates to:
  /// **'Tipe Ekspor & Format'**
  String get exportTypeFormatLabel;

  /// No description provided for @exportMonthlyPdf.
  ///
  /// In id, this message translates to:
  /// **'Laporan Bulanan (PDF)'**
  String get exportMonthlyPdf;

  /// No description provided for @exportMonthlyExcel.
  ///
  /// In id, this message translates to:
  /// **'Laporan Bulanan (Excel)'**
  String get exportMonthlyExcel;

  /// No description provided for @exportAllExcel.
  ///
  /// In id, this message translates to:
  /// **'Backup Seluruh Data (Excel)'**
  String get exportAllExcel;

  /// No description provided for @exportAllExcelSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Mengekspor seluruh akun, transaksi, utang, piutang, wishlist, dll.'**
  String get exportAllExcelSubtitle;

  /// No description provided for @exportNowBtn.
  ///
  /// In id, this message translates to:
  /// **'Ekspor Sekarang'**
  String get exportNowBtn;

  /// No description provided for @snackPrepBackup.
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan Backup Seluruh Data...'**
  String get snackPrepBackup;

  /// No description provided for @snackPrepMonth.
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan {month}...'**
  String snackPrepMonth(String month);

  /// No description provided for @tabReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get tabReport;

  /// No description provided for @tooltipExport.
  ///
  /// In id, this message translates to:
  /// **'Export Laporan'**
  String get tooltipExport;

  /// No description provided for @cashFlow6Months.
  ///
  /// In id, this message translates to:
  /// **'Arus Kas 6 Bulan'**
  String get cashFlow6Months;

  /// No description provided for @assetComposition.
  ///
  /// In id, this message translates to:
  /// **'Komposisi Aset'**
  String get assetComposition;

  /// No description provided for @expenseByCategory.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran per Kategori'**
  String get expenseByCategory;

  /// No description provided for @summaryIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get summaryIncome;

  /// No description provided for @summaryExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get summaryExpense;

  /// No description provided for @summaryNet.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get summaryNet;

  /// No description provided for @emptyCashFlow.
  ///
  /// In id, this message translates to:
  /// **'Belum ada arus kas untuk ditampilkan.'**
  String get emptyCashFlow;

  /// No description provided for @pieAssetCash.
  ///
  /// In id, this message translates to:
  /// **'Kas'**
  String get pieAssetCash;

  /// No description provided for @pieAssetInvestment.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get pieAssetInvestment;

  /// No description provided for @pieAssetReceivable.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get pieAssetReceivable;

  /// No description provided for @emptyAsset.
  ///
  /// In id, this message translates to:
  /// **'Belum ada aset untuk ditampilkan.'**
  String get emptyAsset;

  /// No description provided for @emptyCategory.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pengeluaran di bulan ini.'**
  String get emptyCategory;

  /// No description provided for @tabMonthlyTx.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Bulanan'**
  String get tabMonthlyTx;

  /// No description provided for @tooltipAddTemplate.
  ///
  /// In id, this message translates to:
  /// **'Tambah template'**
  String get tooltipAddTemplate;

  /// No description provided for @emptyMonthlyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi bulanan'**
  String get emptyMonthlyTitle;

  /// No description provided for @emptyMonthlySubtitle.
  ///
  /// In id, this message translates to:
  /// **'Susun biaya rutin (langganan, tagihan, tabungan), lalu\njalankan semua sekaligus tiap bulan.'**
  String get emptyMonthlySubtitle;

  /// No description provided for @runBarIncome.
  ///
  /// In id, this message translates to:
  /// **'Masuk {amount}'**
  String runBarIncome(String amount);

  /// No description provided for @runBarExpense.
  ///
  /// In id, this message translates to:
  /// **'Keluar {amount}'**
  String runBarExpense(String amount);

  /// No description provided for @runAllBtn.
  ///
  /// In id, this message translates to:
  /// **'Jalankan Semua ({count})'**
  String runAllBtn(String count);

  /// No description provided for @confirmRunTitle.
  ///
  /// In id, this message translates to:
  /// **'Jalankan transaksi bulanan?'**
  String get confirmRunTitle;

  /// No description provided for @confirmRunContent.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi aktif akan dibuat dengan tanggal hari ini. Saldo rekening akan diperbarui.'**
  String confirmRunContent(String count);

  /// No description provided for @confirmRunOk.
  ///
  /// In id, this message translates to:
  /// **'Jalankan'**
  String get confirmRunOk;

  /// No description provided for @runSuccessWithSkip.
  ///
  /// In id, this message translates to:
  /// **'{created} transaksi dibuat, {skipped} dilewati (saldo kurang).'**
  String runSuccessWithSkip(String created, String skipped);

  /// No description provided for @runSuccessAll.
  ///
  /// In id, this message translates to:
  /// **'{created} transaksi bulanan berhasil dijalankan.'**
  String runSuccessAll(String created);

  /// No description provided for @addTemplate.
  ///
  /// In id, this message translates to:
  /// **'Tambah Template'**
  String get addTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In id, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// No description provided for @templateNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Netflix, Listrik, Nabung'**
  String get templateNameHint;

  /// No description provided for @templateCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Langganan, Tagihan'**
  String get templateCategoryHint;

  /// No description provided for @segmentExpense.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get segmentExpense;

  /// No description provided for @segmentIncome.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get segmentIncome;

  /// No description provided for @segmentTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get segmentTransfer;

  /// No description provided for @amountLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get amountLabel;

  /// No description provided for @fromAccountLabel.
  ///
  /// In id, this message translates to:
  /// **'Dari rekening'**
  String get fromAccountLabel;

  /// No description provided for @toAccountLabel.
  ///
  /// In id, this message translates to:
  /// **'Ke akun'**
  String get toAccountLabel;

  /// No description provided for @errorSelectAccount.
  ///
  /// In id, this message translates to:
  /// **'Pilih akun tujuan'**
  String get errorSelectAccount;

  /// No description provided for @errorSameAccount.
  ///
  /// In id, this message translates to:
  /// **'Pilih akun berbeda'**
  String get errorSameAccount;

  /// No description provided for @categoryLabel.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get categoryLabel;

  /// No description provided for @addBillItem.
  ///
  /// In id, this message translates to:
  /// **'Tambah Item'**
  String get addBillItem;

  /// No description provided for @menuNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama menu'**
  String get menuNameLabel;

  /// No description provided for @menuNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Nasi Goreng'**
  String get menuNameHint;

  /// No description provided for @priceLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get priceLabel;

  /// No description provided for @qtyLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get qtyLabel;

  /// No description provided for @noOtherBillsToSave.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tagihan orang lain untuk disimpan.'**
  String get noOtherBillsToSave;

  /// No description provided for @saveSplitBillTitle.
  ///
  /// In id, this message translates to:
  /// **'Simpan Split Bill'**
  String get saveSplitBillTitle;

  /// No description provided for @friendBillsLabel.
  ///
  /// In id, this message translates to:
  /// **'Tagihan teman (jadi piutang):'**
  String get friendBillsLabel;

  /// No description provided for @myShareLabel.
  ///
  /// In id, this message translates to:
  /// **'Bagian saya'**
  String get myShareLabel;

  /// No description provided for @fundFromAccountLabel.
  ///
  /// In id, this message translates to:
  /// **'Saya menalangi dari rekening'**
  String get fundFromAccountLabel;

  /// No description provided for @doNotDeductBalance.
  ///
  /// In id, this message translates to:
  /// **'— Jangan potong saldo'**
  String get doNotDeductBalance;

  /// No description provided for @personLabel.
  ///
  /// In id, this message translates to:
  /// **'Orang {number}'**
  String personLabel(String number);

  /// No description provided for @totalOutFromAccount.
  ///
  /// In id, this message translates to:
  /// **'Total keluar dari rekening'**
  String get totalOutFromAccount;

  /// No description provided for @totalReceivableRecorded.
  ///
  /// In id, this message translates to:
  /// **'Total piutang dicatat'**
  String get totalReceivableRecorded;

  /// No description provided for @receivableSavedDeducted.
  ///
  /// In id, this message translates to:
  /// **'{count} piutang dicatat, saldo dipotong {amount}.'**
  String receivableSavedDeducted(String count, String amount);

  /// No description provided for @splitBillNotePrefix.
  ///
  /// In id, this message translates to:
  /// **'Split bill'**
  String get splitBillNotePrefix;

  /// No description provided for @receivableSavedOnly.
  ///
  /// In id, this message translates to:
  /// **'{count} piutang tersimpan.'**
  String receivableSavedOnly(String count);

  /// No description provided for @tabSplitBill.
  ///
  /// In id, this message translates to:
  /// **'Split Bill'**
  String get tabSplitBill;

  /// No description provided for @personLabelOnly.
  ///
  /// In id, this message translates to:
  /// **'Orang'**
  String get personLabelOnly;

  /// No description provided for @splitBillEmptyState.
  ///
  /// In id, this message translates to:
  /// **'Tambah orang dulu, lalu masukkan pesanan masing-masing.'**
  String get splitBillEmptyState;

  /// No description provided for @deletePersonTooltip.
  ///
  /// In id, this message translates to:
  /// **'Hapus orang'**
  String get deletePersonTooltip;

  /// No description provided for @meNotBilledLabel.
  ///
  /// In id, this message translates to:
  /// **'Saya (tidak dipiutangkan)'**
  String get meNotBilledLabel;

  /// No description provided for @itemLabel.
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get itemLabel;

  /// No description provided for @sharedItemsLabel.
  ///
  /// In id, this message translates to:
  /// **'Item Bersama (dibagi rata)'**
  String get sharedItemsLabel;

  /// No description provided for @addSharedItemLabel.
  ///
  /// In id, this message translates to:
  /// **'Item bersama'**
  String get addSharedItemLabel;

  /// No description provided for @taxAndDiscountLabel.
  ///
  /// In id, this message translates to:
  /// **'Pajak, Biaya & Diskon'**
  String get taxAndDiscountLabel;

  /// No description provided for @ppnLabel.
  ///
  /// In id, this message translates to:
  /// **'PPN'**
  String get ppnLabel;

  /// No description provided for @serviceChargeLabel.
  ///
  /// In id, this message translates to:
  /// **'Service'**
  String get serviceChargeLabel;

  /// No description provided for @discountLabel.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get discountLabel;

  /// No description provided for @additionalFeesLabel.
  ///
  /// In id, this message translates to:
  /// **'Biaya tambahan'**
  String get additionalFeesLabel;

  /// No description provided for @percentageLabel.
  ///
  /// In id, this message translates to:
  /// **'Persentase'**
  String get percentageLabel;

  /// No description provided for @nominalLabel.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get nominalLabel;

  /// No description provided for @splitDiscountEvenlyLabel.
  ///
  /// In id, this message translates to:
  /// **'Bagi diskon rata'**
  String get splitDiscountEvenlyLabel;

  /// No description provided for @discountEvenlyDesc.
  ///
  /// In id, this message translates to:
  /// **'Tiap orang dapat potongan sama besar'**
  String get discountEvenlyDesc;

  /// No description provided for @discountProportionalDesc.
  ///
  /// In id, this message translates to:
  /// **'Potongan proporsional ke besar pesanan'**
  String get discountProportionalDesc;

  /// No description provided for @detailsLabel.
  ///
  /// In id, this message translates to:
  /// **'Rincian'**
  String get detailsLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @totalLabel.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @billPerPersonLabel.
  ///
  /// In id, this message translates to:
  /// **'Tagihan per orang'**
  String get billPerPersonLabel;

  /// No description provided for @unnamedLabel.
  ///
  /// In id, this message translates to:
  /// **'(tanpa nama)'**
  String get unnamedLabel;

  /// No description provided for @saveToReceivablesBtn.
  ///
  /// In id, this message translates to:
  /// **'Simpan ke Piutang'**
  String get saveToReceivablesBtn;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Buat akun baru'**
  String get createAccountSubtitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke akunmu'**
  String get loginSubtitle;

  /// No description provided for @registerButton.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get registerButton;

  /// No description provided for @loginButton.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginButton;

  /// No description provided for @orDividerLabel.
  ///
  /// In id, this message translates to:
  /// **'atau'**
  String get orDividerLabel;

  /// No description provided for @loginWithGoogleBtn.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get loginWithGoogleBtn;

  /// No description provided for @alreadyHaveAccountBtn.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun? Masuk'**
  String get alreadyHaveAccountBtn;

  /// No description provided for @dontHaveAccountBtn.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun? Daftar'**
  String get dontHaveAccountBtn;

  /// No description provided for @emailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In id, this message translates to:
  /// **'Email wajib diisi'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi'**
  String get passwordLabel;

  /// No description provided for @passwordRequired.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi wajib diisi'**
  String get passwordRequired;

  /// No description provided for @passwordMinLen.
  ///
  /// In id, this message translates to:
  /// **'Minimal 6 karakter'**
  String get passwordMinLen;

  /// No description provided for @nameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi'**
  String get nameRequired;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In id, this message translates to:
  /// **'Ulangi kata sandi'**
  String get passwordConfirmLabel;

  /// No description provided for @requiredField.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get requiredField;

  /// No description provided for @passwordNotMatch.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi tidak sama'**
  String get passwordNotMatch;

  /// No description provided for @completeAccountTitle.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi Akun'**
  String get completeAccountTitle;

  /// No description provided for @completeAccountDesc.
  ///
  /// In id, this message translates to:
  /// **'Kamu masuk sebagai {email}. Buat kata sandi untuk menyelesaikan pendaftaran. Setelah ini kamu bisa masuk dengan email + kata sandi.'**
  String completeAccountDesc(String email);

  /// No description provided for @saveAndContinueBtn.
  ///
  /// In id, this message translates to:
  /// **'Simpan & Lanjutkan'**
  String get saveAndContinueBtn;

  /// No description provided for @logoutButton.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get logoutButton;

  /// No description provided for @wrongPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi salah.'**
  String get wrongPassword;

  /// No description provided for @invalidRecoveryKey.
  ///
  /// In id, this message translates to:
  /// **'Kunci pemulihan tidak valid.'**
  String get invalidRecoveryKey;

  /// No description provided for @unlockDataTitle.
  ///
  /// In id, this message translates to:
  /// **'Buka Data'**
  String get unlockDataTitle;

  /// No description provided for @unlockRecoveryDesc.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kunci pemulihan & kata sandi baru untuk membuka data di perangkat ini.'**
  String get unlockRecoveryDesc;

  /// No description provided for @unlockPasswordDesc.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kata sandimu untuk membuka data di perangkat ini. Hanya sekali per perangkat.'**
  String get unlockPasswordDesc;

  /// No description provided for @unlockBtn.
  ///
  /// In id, this message translates to:
  /// **'Buka'**
  String get unlockBtn;

  /// No description provided for @forgotPasswordBtn.
  ///
  /// In id, this message translates to:
  /// **'Lupa kata sandi?'**
  String get forgotPasswordBtn;

  /// No description provided for @recoveryKeyLabel.
  ///
  /// In id, this message translates to:
  /// **'Kunci pemulihan'**
  String get recoveryKeyLabel;

  /// No description provided for @recoveryKeyHint.
  ///
  /// In id, this message translates to:
  /// **'XXXX-XXXX-XXXX-...'**
  String get recoveryKeyHint;

  /// No description provided for @newPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi baru'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Ulangi kata sandi baru'**
  String get confirmNewPasswordLabel;

  /// No description provided for @unlockAndChangePassBtn.
  ///
  /// In id, this message translates to:
  /// **'Buka & Ganti Sandi'**
  String get unlockAndChangePassBtn;

  /// No description provided for @rememberPasswordBtn.
  ///
  /// In id, this message translates to:
  /// **'Saya ingat kata sandi'**
  String get rememberPasswordBtn;

  /// No description provided for @upgradeSecurityTitle.
  ///
  /// In id, this message translates to:
  /// **'Tingkatkan Keamanan Data'**
  String get upgradeSecurityTitle;

  /// No description provided for @upgradeSecurityDesc.
  ///
  /// In id, this message translates to:
  /// **'Data keuanganmu kini akan dienkripsi sebelum disimpan di cloud — termasuk pemilik project pun tak bisa membacanya. Masukkan kata sandimu untuk memulai.'**
  String get upgradeSecurityDesc;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi saat ini'**
  String get currentPasswordLabel;

  /// No description provided for @startEncryptionBtn.
  ///
  /// In id, this message translates to:
  /// **'Mulai Enkripsi'**
  String get startEncryptionBtn;

  /// No description provided for @saveRecoveryKeyTitle.
  ///
  /// In id, this message translates to:
  /// **'Simpan Kunci Pemulihan'**
  String get saveRecoveryKeyTitle;

  /// No description provided for @saveRecoveryKeyDesc.
  ///
  /// In id, this message translates to:
  /// **'Ini adalah satu-satunya cara membuka datamu jika lupa kata sandi. Kami tidak menyimpannya. Salin & simpan di tempat aman (mis. password manager). Tanpa ini dan tanpa sandi, data tak bisa dikembalikan.'**
  String get saveRecoveryKeyDesc;

  /// No description provided for @recoveryKeyCopied.
  ///
  /// In id, this message translates to:
  /// **'Kunci disalin.'**
  String get recoveryKeyCopied;

  /// No description provided for @copyKeyBtn.
  ///
  /// In id, this message translates to:
  /// **'Salin kunci'**
  String get copyKeyBtn;

  /// No description provided for @iHaveSavedItBtn.
  ///
  /// In id, this message translates to:
  /// **'Saya sudah menyimpannya'**
  String get iHaveSavedItBtn;

  /// No description provided for @addAccountFirst.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan rekening dulu di tab Akun.'**
  String get addAccountFirst;

  /// No description provided for @payDebtTitle.
  ///
  /// In id, this message translates to:
  /// **'Bayar {name}'**
  String payDebtTitle(String name);

  /// No description provided for @debtRemainingLabel.
  ///
  /// In id, this message translates to:
  /// **'Sisa utang: {amount}'**
  String debtRemainingLabel(String amount);

  /// No description provided for @payAmountLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah bayar'**
  String get payAmountLabel;

  /// No description provided for @balanceHelper.
  ///
  /// In id, this message translates to:
  /// **'Saldo {name}: {amount}'**
  String balanceHelper(String name, String amount);

  /// No description provided for @exceedsDebtRemaining.
  ///
  /// In id, this message translates to:
  /// **'Melebihi sisa utang ({amount})'**
  String exceedsDebtRemaining(String amount);

  /// No description provided for @exceedsBalance.
  ///
  /// In id, this message translates to:
  /// **'Melebihi saldo ({amount})'**
  String exceedsBalance(String amount);

  /// No description provided for @payFromLabel.
  ///
  /// In id, this message translates to:
  /// **'Bayar dari'**
  String get payFromLabel;

  /// No description provided for @payNowBtn.
  ///
  /// In id, this message translates to:
  /// **'Bayar Sekarang'**
  String get payNowBtn;

  /// No description provided for @paymentRecorded.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran {amount} tercatat.'**
  String paymentRecorded(String amount);

  /// No description provided for @editDebtTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Utang'**
  String get editDebtTitle;

  /// No description provided for @addDebtTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Utang'**
  String get addDebtTitle;

  /// No description provided for @debtNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. KPR BTN, Kartu Kredit'**
  String get debtNameHint;

  /// No description provided for @debtRemainingInputLabel.
  ///
  /// In id, this message translates to:
  /// **'Sisa utang'**
  String get debtRemainingInputLabel;

  /// No description provided for @monthlyPaymentOptional.
  ///
  /// In id, this message translates to:
  /// **'Cicilan per bulan (opsional)'**
  String get monthlyPaymentOptional;

  /// No description provided for @dueDateOptional.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo (opsional)'**
  String get dueDateOptional;

  /// No description provided for @selectDateBtn.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get selectDateBtn;

  /// No description provided for @collectFromTitle.
  ///
  /// In id, this message translates to:
  /// **'Terima dari {name}'**
  String collectFromTitle(String name);

  /// No description provided for @totalOutstanding.
  ///
  /// In id, this message translates to:
  /// **'Sisa total: {amount}'**
  String totalOutstanding(String amount);

  /// No description provided for @loanCount.
  ///
  /// In id, this message translates to:
  /// **'{count} pinjaman'**
  String loanCount(int count);

  /// No description provided for @fifoPaymentNote.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran melunasi pinjaman paling lama dulu.'**
  String get fifoPaymentNote;

  /// No description provided for @amountReceivedLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah diterima'**
  String get amountReceivedLabel;

  /// No description provided for @exceedsTotalOutstanding.
  ///
  /// In id, this message translates to:
  /// **'Melebihi sisa total ({amount})'**
  String exceedsTotalOutstanding(String amount);

  /// No description provided for @receiveIntoLabel.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke'**
  String get receiveIntoLabel;

  /// No description provided for @receiveNowBtn.
  ///
  /// In id, this message translates to:
  /// **'Terima Sekarang'**
  String get receiveNowBtn;

  /// No description provided for @receivedAmount.
  ///
  /// In id, this message translates to:
  /// **'Diterima {amount}.'**
  String receivedAmount(String amount);

  /// No description provided for @editReceivableTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Piutang'**
  String get editReceivableTitle;

  /// No description provided for @addReceivableTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Piutang'**
  String get addReceivableTitle;

  /// No description provided for @personNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama orang'**
  String get personNameLabel;

  /// No description provided for @personNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Gama'**
  String get personNameHint;

  /// No description provided for @receivableAmountLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah piutang'**
  String get receivableAmountLabel;

  /// No description provided for @noteOptional.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get noteOptional;

  /// No description provided for @noteReceivableHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Makan di resto X'**
  String get noteReceivableHint;

  /// No description provided for @fundNowTitle.
  ///
  /// In id, this message translates to:
  /// **'Saya menalangi sekarang'**
  String get fundNowTitle;

  /// No description provided for @fundNowSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Uang keluar dari rekening saya'**
  String get fundNowSubtitle;

  /// No description provided for @reminderActiveDesc.
  ///
  /// In id, this message translates to:
  /// **'Pengingat aktif. Atur jamnya di bawah.'**
  String get reminderActiveDesc;

  /// No description provided for @reminderNoPermission.
  ///
  /// In id, this message translates to:
  /// **'Izin notifikasi ditolak. Aktifkan di Pengaturan HP.'**
  String get reminderNoPermission;

  /// No description provided for @reminderDisabled.
  ///
  /// In id, this message translates to:
  /// **'Pengingat dimatikan.'**
  String get reminderDisabled;

  /// No description provided for @reminderDailySetTo.
  ///
  /// In id, this message translates to:
  /// **'Pengingat harian diatur ke {time}.'**
  String reminderDailySetTo(String time);

  /// No description provided for @dailyReminderTime.
  ///
  /// In id, this message translates to:
  /// **'Jam pengingat harian'**
  String get dailyReminderTime;

  /// No description provided for @dailyReminderDesc.
  ///
  /// In id, this message translates to:
  /// **'Setiap hari pukul {time}'**
  String dailyReminderDesc(String time);

  /// No description provided for @alreadyLatestVersion.
  ///
  /// In id, this message translates to:
  /// **'Kamu sudah memakai versi terbaru.'**
  String get alreadyLatestVersion;

  /// No description provided for @autoUpdateAndroidOnly.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan otomatis hanya tersedia di Android.'**
  String get autoUpdateAndroidOnly;

  /// No description provided for @updateCheckFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memeriksa pembaruan. Periksa koneksi.'**
  String get updateCheckFailed;

  /// No description provided for @updateCheck.
  ///
  /// In id, this message translates to:
  /// **'Cek pembaruan'**
  String get updateCheck;

  /// No description provided for @updateCheckDesc.
  ///
  /// In id, this message translates to:
  /// **'Periksa & pasang versi terbaru'**
  String get updateCheckDesc;

  /// No description provided for @renameTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Nama'**
  String get renameTitle;

  /// No description provided for @passwordChanged.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi berhasil diganti.'**
  String get passwordChanged;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Akun?'**
  String get deleteAccountTitle;

  /// No description provided for @deletePermanently.
  ///
  /// In id, this message translates to:
  /// **'Hapus Permanen'**
  String get deletePermanently;

  /// No description provided for @recoveryKeyCreateFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat kunci pemulihan: {error}'**
  String recoveryKeyCreateFailed(String error);

  /// No description provided for @recoveryKeyNew.
  ///
  /// In id, this message translates to:
  /// **'Kunci Pemulihan Baru'**
  String get recoveryKeyNew;

  /// No description provided for @copy.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get copy;

  /// No description provided for @done.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get done;

  /// No description provided for @recoveryKeyNewDesc.
  ///
  /// In id, this message translates to:
  /// **'Demi keamanan, sistem tidak menyimpan Kunci Pemulihan lama Anda. Kami akan membuatkan Kunci Pemulihan yang BARU.'**
  String get recoveryKeyNewDesc;

  /// No description provided for @updateMandatory.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan ini wajib dipasang.'**
  String get updateMandatory;

  /// No description provided for @downloading.
  ///
  /// In id, this message translates to:
  /// **'Mengunduh... {pct}%'**
  String downloading(String pct);

  /// No description provided for @skip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get skip;

  /// No description provided for @editAccount.
  ///
  /// In id, this message translates to:
  /// **'Edit Akun'**
  String get editAccount;

  /// No description provided for @accountNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. BCA, GoPay, Dompet'**
  String get accountNameHint;

  /// No description provided for @accountNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor rekening'**
  String get accountNumber;

  /// No description provided for @initialBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal'**
  String get initialBalance;

  /// No description provided for @balance.
  ///
  /// In id, this message translates to:
  /// **'Saldo'**
  String get balance;

  /// No description provided for @editTx.
  ///
  /// In id, this message translates to:
  /// **'Edit Transaksi'**
  String get editTx;

  /// No description provided for @noteOptionalTx.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get noteOptionalTx;

  /// No description provided for @date.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get date;

  /// No description provided for @adminFeeOptional.
  ///
  /// In id, this message translates to:
  /// **'Biaya transfer (opsional)'**
  String get adminFeeOptional;

  /// No description provided for @invalidAmount.
  ///
  /// In id, this message translates to:
  /// **'Masukkan jumlah valid'**
  String get invalidAmount;

  /// No description provided for @invalidAdminFee.
  ///
  /// In id, this message translates to:
  /// **'Masukkan biaya admin valid'**
  String get invalidAdminFee;

  /// No description provided for @adminFeeDesc.
  ///
  /// In id, this message translates to:
  /// **'Tujuan tetap terima jumlah penuh; admin keluar dari sumber'**
  String get adminFeeDesc;

  /// No description provided for @totalOut.
  ///
  /// In id, this message translates to:
  /// **'Total keluar dari sumber: {amount}'**
  String totalOut(String amount);

  /// No description provided for @priorityLow.
  ///
  /// In id, this message translates to:
  /// **'Rendah'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In id, this message translates to:
  /// **'Sedang'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In id, this message translates to:
  /// **'Tinggi'**
  String get priorityHigh;

  /// No description provided for @noTxTodayTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi hari ini'**
  String get noTxTodayTitle;

  /// No description provided for @noTxTodayDesc.
  ///
  /// In id, this message translates to:
  /// **'Catat pemasukan atau pengeluaranmu biar tetap terpantau.'**
  String get noTxTodayDesc;

  /// No description provided for @salarySaveTitle.
  ///
  /// In id, this message translates to:
  /// **'Sudah gajian? Sisihkan untuk tabungan'**
  String get salarySaveTitle;

  /// No description provided for @salarySaveDesc.
  ///
  /// In id, this message translates to:
  /// **'Jangan lupa nabung untuk: {names}.'**
  String salarySaveDesc(String names);

  /// No description provided for @timeToSaveTitle.
  ///
  /// In id, this message translates to:
  /// **'Waktunya menabung: {name}'**
  String timeToSaveTitle(String name);

  /// No description provided for @timeToSaveDescAmount.
  ///
  /// In id, this message translates to:
  /// **'Sisihkan {amount} bulan ini.'**
  String timeToSaveDescAmount(String amount);

  /// No description provided for @timeToSaveDescGeneral.
  ///
  /// In id, this message translates to:
  /// **'Sisihkan dana untuk target ini.'**
  String get timeToSaveDescGeneral;

  /// No description provided for @reportTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Transaksi MoneyWork - {periodName}'**
  String reportTitle(String periodName);

  /// No description provided for @reportPrintedOn.
  ///
  /// In id, this message translates to:
  /// **'Dicetak pada: {date}'**
  String reportPrintedOn(String date);

  /// No description provided for @reportCashflowSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Arus Kas'**
  String get reportCashflowSummary;

  /// No description provided for @reportIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan: {amount}'**
  String reportIncome(String amount);

  /// No description provided for @reportExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran: {amount}'**
  String reportExpense(String amount);

  /// No description provided for @reportNet.
  ///
  /// In id, this message translates to:
  /// **'Sisa Saldo (Net): {amount}'**
  String reportNet(String amount);

  /// No description provided for @reportExpenseByCategory.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran per Kategori'**
  String get reportExpenseByCategory;

  /// No description provided for @reportTxDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail Transaksi'**
  String get reportTxDetail;

  /// No description provided for @reportLegendOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get reportLegendOut;

  /// No description provided for @reportLegendIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get reportLegendIn;

  /// No description provided for @reportType.
  ///
  /// In id, this message translates to:
  /// **'Tipe'**
  String get reportType;

  /// No description provided for @reportDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get reportDate;

  /// No description provided for @reportAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get reportAmount;

  /// No description provided for @notifSaveTime.
  ///
  /// In id, this message translates to:
  /// **'Waktunya menabung 💰'**
  String get notifSaveTime;

  /// No description provided for @notifSaveAmount.
  ///
  /// In id, this message translates to:
  /// **'Sisihkan {amount} untuk {name}.'**
  String notifSaveAmount(String amount, String name);

  /// No description provided for @notifSaveGeneral.
  ///
  /// In id, this message translates to:
  /// **'Saatnya menabung untuk {name}.'**
  String notifSaveGeneral(String name);

  /// No description provided for @accountTypeCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In id, this message translates to:
  /// **'Bank'**
  String get accountTypeBank;

  /// No description provided for @accountTypeEwallet.
  ///
  /// In id, this message translates to:
  /// **'E-Wallet'**
  String get accountTypeEwallet;

  /// No description provided for @accountTypeRdn.
  ///
  /// In id, this message translates to:
  /// **'RDN (Saham)'**
  String get accountTypeRdn;

  /// No description provided for @debtTypeLoan.
  ///
  /// In id, this message translates to:
  /// **'Pinjaman'**
  String get debtTypeLoan;

  /// No description provided for @debtTypeCreditCard.
  ///
  /// In id, this message translates to:
  /// **'Kartu Kredit'**
  String get debtTypeCreditCard;

  /// No description provided for @debtTypeInstallment.
  ///
  /// In id, this message translates to:
  /// **'Cicilan'**
  String get debtTypeInstallment;

  /// No description provided for @debtTypeOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get debtTypeOther;

  /// No description provided for @invTypeStock.
  ///
  /// In id, this message translates to:
  /// **'Saham'**
  String get invTypeStock;

  /// No description provided for @invTypeMutualFund.
  ///
  /// In id, this message translates to:
  /// **'Reksadana'**
  String get invTypeMutualFund;

  /// No description provided for @invTypeCrypto.
  ///
  /// In id, this message translates to:
  /// **'Crypto'**
  String get invTypeCrypto;

  /// No description provided for @invTypeGold.
  ///
  /// In id, this message translates to:
  /// **'Emas'**
  String get invTypeGold;

  /// No description provided for @invTypeOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get invTypeOther;

  /// No description provided for @salaryAllocateTitle.
  ///
  /// In id, this message translates to:
  /// **'Saatnya mengatur anggaran bulan ini'**
  String get salaryAllocateTitle;

  /// No description provided for @salaryAllocateDesc.
  ///
  /// In id, this message translates to:
  /// **'Gajian sudah masuk, yuk alokasikan ke berbagai akun dan pos pengeluaran.'**
  String get salaryAllocateDesc;

  /// No description provided for @highExpenseTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran harian cukup tinggi'**
  String get highExpenseTitle;

  /// No description provided for @highExpenseDesc.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata {avg} per hari bulan ini. Coba direm sedikit ya.'**
  String highExpenseDesc(String avg);

  /// No description provided for @editAccountTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Akun'**
  String get editAccountTitle;

  /// No description provided for @deleteTransactionWarning.
  ///
  /// In id, this message translates to:
  /// **'Saldo akun akan disesuaikan kembali. Tindakan ini tidak bisa dibatalkan.'**
  String get deleteTransactionWarning;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In id, this message translates to:
  /// **'Semua transaksi terkait akun ini juga akan dihapus.'**
  String get deleteAccountWarning;

  /// No description provided for @labelAccountName.
  ///
  /// In id, this message translates to:
  /// **'Nama akun'**
  String get labelAccountName;

  /// No description provided for @hintAccountName.
  ///
  /// In id, this message translates to:
  /// **'mis. BCA, GoPay, Dompet'**
  String get hintAccountName;

  /// No description provided for @validationRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get validationRequired;

  /// No description provided for @labelAccountType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get labelAccountType;

  /// No description provided for @labelEwalletNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor HP / akun e-wallet'**
  String get labelEwalletNumber;

  /// No description provided for @labelBankNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor rekening'**
  String get labelBankNumber;

  /// No description provided for @hintOptional.
  ///
  /// In id, this message translates to:
  /// **'opsional'**
  String get hintOptional;

  /// No description provided for @labelBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo'**
  String get labelBalance;

  /// No description provided for @labelInitialBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal'**
  String get labelInitialBalance;

  /// No description provided for @validationInvalidNumber.
  ///
  /// In id, this message translates to:
  /// **'Angka tidak valid'**
  String get validationInvalidNumber;

  /// No description provided for @recordTransactionTitle.
  ///
  /// In id, this message translates to:
  /// **'Catat Transaksi'**
  String get recordTransactionTitle;

  /// No description provided for @labelAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get labelAmount;

  /// No description provided for @helperBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo {name}: {balance}'**
  String helperBalance(String name, String balance);

  /// No description provided for @validationInvalidAmount.
  ///
  /// In id, this message translates to:
  /// **'Masukkan jumlah valid'**
  String get validationInvalidAmount;

  /// No description provided for @validationExceedBalance.
  ///
  /// In id, this message translates to:
  /// **'Melebihi saldo ({balance})'**
  String validationExceedBalance(String balance);

  /// No description provided for @labelFromAccount.
  ///
  /// In id, this message translates to:
  /// **'Dari akun'**
  String get labelFromAccount;

  /// No description provided for @labelToAccount.
  ///
  /// In id, this message translates to:
  /// **'Ke akun'**
  String get labelToAccount;

  /// No description provided for @validationSelectDest.
  ///
  /// In id, this message translates to:
  /// **'Pilih akun tujuan'**
  String get validationSelectDest;

  /// No description provided for @validationDiffAccount.
  ///
  /// In id, this message translates to:
  /// **'Pilih akun berbeda'**
  String get validationDiffAccount;

  /// No description provided for @adminFeeSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Dipotong dari akun sumber, dicatat terpisah'**
  String get adminFeeSubtitle;

  /// No description provided for @labelAdminFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya admin'**
  String get labelAdminFee;

  /// No description provided for @helperAdminFee.
  ///
  /// In id, this message translates to:
  /// **'Tujuan tetap terima jumlah penuh; admin keluar dari sumber'**
  String get helperAdminFee;

  /// No description provided for @validationAdminFee.
  ///
  /// In id, this message translates to:
  /// **'Masukkan biaya admin valid'**
  String get validationAdminFee;

  /// No description provided for @labelCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get labelCategory;

  /// No description provided for @hintCategory.
  ///
  /// In id, this message translates to:
  /// **'mis. Makan, Gaji, Transport'**
  String get hintCategory;

  /// No description provided for @labelNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get labelNote;

  /// No description provided for @labelDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get labelDate;

  /// No description provided for @updateAvailable.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan tersedia'**
  String get updateAvailable;

  /// No description provided for @updateVersion.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan {version}'**
  String updateVersion(String version);

  /// No description provided for @updateDefaultNotes.
  ///
  /// In id, this message translates to:
  /// **'Versi baru aplikasi sudah tersedia.'**
  String get updateDefaultNotes;

  /// No description provided for @updateBtn.
  ///
  /// In id, this message translates to:
  /// **'Perbarui'**
  String get updateBtn;

  /// No description provided for @retryBtn.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get retryBtn;

  /// No description provided for @excelHeaderDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get excelHeaderDate;

  /// No description provided for @excelHeaderType.
  ///
  /// In id, this message translates to:
  /// **'Tipe'**
  String get excelHeaderType;

  /// No description provided for @excelHeaderCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get excelHeaderCategory;

  /// No description provided for @excelHeaderAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah (Rp)'**
  String get excelHeaderAmount;

  /// No description provided for @excelHeaderAccount.
  ///
  /// In id, this message translates to:
  /// **'Rekening'**
  String get excelHeaderAccount;

  /// No description provided for @excelHeaderNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get excelHeaderNote;

  /// No description provided for @reportPrintedAt.
  ///
  /// In id, this message translates to:
  /// **'Dicetak pada: {date}'**
  String reportPrintedAt(String date);

  /// No description provided for @legendIncome.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get legendIncome;

  /// No description provided for @legendExpense.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get legendExpense;

  /// No description provided for @noTransactionPeriod.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi di periode ini.'**
  String get noTransactionPeriod;

  /// No description provided for @shareReportText.
  ///
  /// In id, this message translates to:
  /// **'Laporan Transaksi MoneyWork {period}'**
  String shareReportText(String period);

  /// No description provided for @excelHeaderBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo'**
  String get excelHeaderBalance;

  /// No description provided for @excelHeaderBankNo.
  ///
  /// In id, this message translates to:
  /// **'Rekening'**
  String get excelHeaderBankNo;

  /// No description provided for @excelHeaderCreatedAt.
  ///
  /// In id, this message translates to:
  /// **'Dibuat Pada'**
  String get excelHeaderCreatedAt;

  /// No description provided for @excelHeaderLender.
  ///
  /// In id, this message translates to:
  /// **'Pemberi Utang (Nama)'**
  String get excelHeaderLender;

  /// No description provided for @excelHeaderDebtRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa Utang'**
  String get excelHeaderDebtRemaining;

  /// No description provided for @excelHeaderMonthlyPayment.
  ///
  /// In id, this message translates to:
  /// **'Cicilan Bulanan'**
  String get excelHeaderMonthlyPayment;

  /// No description provided for @excelHeaderDueDate.
  ///
  /// In id, this message translates to:
  /// **'Jatuh Tempo'**
  String get excelHeaderDueDate;

  /// No description provided for @excelHeaderBorrower.
  ///
  /// In id, this message translates to:
  /// **'Peminjam (Nama)'**
  String get excelHeaderBorrower;

  /// No description provided for @excelHeaderRecNote.
  ///
  /// In id, this message translates to:
  /// **'Judul/Catatan'**
  String get excelHeaderRecNote;

  /// No description provided for @excelHeaderRecRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa Piutang'**
  String get excelHeaderRecRemaining;

  /// No description provided for @excelHeaderAssetName.
  ///
  /// In id, this message translates to:
  /// **'Nama Aset'**
  String get excelHeaderAssetName;

  /// No description provided for @excelHeaderTicker.
  ///
  /// In id, this message translates to:
  /// **'Ticker'**
  String get excelHeaderTicker;

  /// No description provided for @excelHeaderQuantity.
  ///
  /// In id, this message translates to:
  /// **'Kuantitas'**
  String get excelHeaderQuantity;

  /// No description provided for @excelHeaderBuyPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Beli'**
  String get excelHeaderBuyPrice;

  /// No description provided for @excelHeaderCurrentPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Saat Ini'**
  String get excelHeaderCurrentPrice;

  /// No description provided for @excelHeaderTotalCost.
  ///
  /// In id, this message translates to:
  /// **'Total Modal'**
  String get excelHeaderTotalCost;

  /// No description provided for @excelHeaderTotalMarket.
  ///
  /// In id, this message translates to:
  /// **'Total Pasar'**
  String get excelHeaderTotalMarket;

  /// No description provided for @excelHeaderReturn.
  ///
  /// In id, this message translates to:
  /// **'Return (%)'**
  String get excelHeaderReturn;

  /// No description provided for @excelHeaderItemName.
  ///
  /// In id, this message translates to:
  /// **'Nama Barang'**
  String get excelHeaderItemName;

  /// No description provided for @excelHeaderTargetPrice.
  ///
  /// In id, this message translates to:
  /// **'Target Harga'**
  String get excelHeaderTargetPrice;

  /// No description provided for @excelHeaderSaved.
  ///
  /// In id, this message translates to:
  /// **'Terkumpul'**
  String get excelHeaderSaved;

  /// No description provided for @excelHeaderPriority.
  ///
  /// In id, this message translates to:
  /// **'Prioritas'**
  String get excelHeaderPriority;

  /// No description provided for @excelHeaderStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get excelHeaderStatus;

  /// No description provided for @excelHeaderTargetDate.
  ///
  /// In id, this message translates to:
  /// **'Target Tgl'**
  String get excelHeaderTargetDate;

  /// No description provided for @statusPurchased.
  ///
  /// In id, this message translates to:
  /// **'Terbeli'**
  String get statusPurchased;

  /// No description provided for @statusNotPurchased.
  ///
  /// In id, this message translates to:
  /// **'Belum Terbeli'**
  String get statusNotPurchased;

  /// No description provided for @excelHeaderLabel.
  ///
  /// In id, this message translates to:
  /// **'Label'**
  String get excelHeaderLabel;

  /// No description provided for @excelHeaderNominal.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get excelHeaderNominal;

  /// No description provided for @excelHeaderActiveStatus.
  ///
  /// In id, this message translates to:
  /// **'Status Aktif'**
  String get excelHeaderActiveStatus;

  /// No description provided for @statusActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get statusInactive;

  /// No description provided for @shareBackupText.
  ///
  /// In id, this message translates to:
  /// **'Backup Seluruh Data MoneyWork ({date})'**
  String shareBackupText(String date);

  /// No description provided for @excelSheetAccounts.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get excelSheetAccounts;

  /// No description provided for @excelSheetTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get excelSheetTransactions;

  /// No description provided for @excelSheetDebts.
  ///
  /// In id, this message translates to:
  /// **'Utang'**
  String get excelSheetDebts;

  /// No description provided for @excelSheetReceivables.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get excelSheetReceivables;

  /// No description provided for @excelSheetInvestments.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get excelSheetInvestments;

  /// No description provided for @excelSheetRecurring.
  ///
  /// In id, this message translates to:
  /// **'Rutin'**
  String get excelSheetRecurring;

  /// No description provided for @priceErrNoTicker.
  ///
  /// In id, this message translates to:
  /// **'Isi dulu ticker/simbol asetnya.'**
  String get priceErrNoTicker;

  /// No description provided for @priceErrUnsupported.
  ///
  /// In id, this message translates to:
  /// **'Harga otomatis belum tersedia untuk jenis ini.'**
  String get priceErrUnsupported;

  /// No description provided for @priceErrFetch.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengambil harga. Periksa koneksi internetmu.'**
  String get priceErrFetch;

  /// No description provided for @priceErrServer.
  ///
  /// In id, this message translates to:
  /// **'Server CoinGecko error ({code}).'**
  String priceErrServer(int code);

  /// No description provided for @priceErrNotFound.
  ///
  /// In id, this message translates to:
  /// **'Ticker \"{id}\" tidak ditemukan di CoinGecko.'**
  String priceErrNotFound(String id);

  /// No description provided for @priceErrStockNotReady.
  ///
  /// In id, this message translates to:
  /// **'Harga saham otomatis belum aktif (backend belum di-deploy).'**
  String get priceErrStockNotReady;

  /// No description provided for @priceErrStockServer.
  ///
  /// In id, this message translates to:
  /// **'Server harga saham error ({code}).'**
  String priceErrStockServer(int code);

  /// No description provided for @priceErrStockNotFound.
  ///
  /// In id, this message translates to:
  /// **'Kode saham \"{code}\" tidak ditemukan.'**
  String priceErrStockNotFound(String code);

  /// No description provided for @categoryOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get categoryOther;

  /// No description provided for @errorLoadSession.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat sesi: {error}'**
  String errorLoadSession(String error);

  /// No description provided for @errorLoadSecurity.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat status keamanan: {error}'**
  String errorLoadSecurity(String error);

  /// No description provided for @notifDailyTitle.
  ///
  /// In id, this message translates to:
  /// **'Catat transaksi hari ini'**
  String get notifDailyTitle;

  /// No description provided for @notifDailyBody.
  ///
  /// In id, this message translates to:
  /// **'Jangan lupa catat pemasukan & pengeluaranmu di MoneyWork.'**
  String get notifDailyBody;

  /// No description provided for @notifSaveTitle.
  ///
  /// In id, this message translates to:
  /// **'Waktunya menabung 💰'**
  String get notifSaveTitle;

  /// No description provided for @receiptReview.
  ///
  /// In id, this message translates to:
  /// **'Review Bon'**
  String get receiptReview;

  /// No description provided for @receiptVerified.
  ///
  /// In id, this message translates to:
  /// **'✅ Total cocok — data siap digunakan'**
  String get receiptVerified;

  /// No description provided for @receiptMismatch.
  ///
  /// In id, this message translates to:
  /// **'⚠️ Total tidak cocok — periksa kembali angka di bawah'**
  String get receiptMismatch;

  /// No description provided for @receiptItemName.
  ///
  /// In id, this message translates to:
  /// **'Nama Barang'**
  String get receiptItemName;

  /// No description provided for @receiptQty.
  ///
  /// In id, this message translates to:
  /// **'Jml'**
  String get receiptQty;

  /// No description provided for @receiptUnitPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Satuan'**
  String get receiptUnitPrice;

  /// No description provided for @receiptServiceCharge.
  ///
  /// In id, this message translates to:
  /// **'Biaya Layanan'**
  String get receiptServiceCharge;

  /// No description provided for @receiptTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get receiptTax;

  /// No description provided for @receiptDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get receiptDiscount;

  /// No description provided for @receiptGrandTotalPaper.
  ///
  /// In id, this message translates to:
  /// **'Grand Total (Kertas)'**
  String get receiptGrandTotalPaper;

  /// No description provided for @receiptGrandTotalCalc.
  ///
  /// In id, this message translates to:
  /// **'Grand Total (Terhitung)'**
  String get receiptGrandTotalCalc;

  /// No description provided for @receiptSaveAsTransaction.
  ///
  /// In id, this message translates to:
  /// **'Simpan sbg Transaksi'**
  String get receiptSaveAsTransaction;

  /// No description provided for @receiptSplitBill.
  ///
  /// In id, this message translates to:
  /// **'Split Bill'**
  String get receiptSplitBill;

  /// No description provided for @receiptScanning.
  ///
  /// In id, this message translates to:
  /// **'Memindai bon...'**
  String get receiptScanning;

  /// No description provided for @receiptScanFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memindai bon'**
  String get receiptScanFailed;

  /// No description provided for @scanFromCamera.
  ///
  /// In id, this message translates to:
  /// **'Kamera'**
  String get scanFromCamera;

  /// No description provided for @scanFromGallery.
  ///
  /// In id, this message translates to:
  /// **'Galeri'**
  String get scanFromGallery;

  /// No description provided for @scanChooseSource.
  ///
  /// In id, this message translates to:
  /// **'Pilih Sumber Foto'**
  String get scanChooseSource;

  /// No description provided for @assignItemsTitle.
  ///
  /// In id, this message translates to:
  /// **'Bagi Pesanan'**
  String get assignItemsTitle;

  /// No description provided for @howManyPeople.
  ///
  /// In id, this message translates to:
  /// **'Berapa orang yang ikut bayar?'**
  String get howManyPeople;

  /// No description provided for @nextStep.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get nextStep;

  /// No description provided for @enterNames.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama tiap orang'**
  String get enterNames;

  /// No description provided for @personNumber.
  ///
  /// In id, this message translates to:
  /// **'Orang ke-{number}'**
  String personNumber(int number);

  /// No description provided for @selectItemsFor.
  ///
  /// In id, this message translates to:
  /// **'Pilih pesanan {name}'**
  String selectItemsFor(String name);

  /// No description provided for @calculateSplit.
  ///
  /// In id, this message translates to:
  /// **'Hitung Pembagian'**
  String get calculateSplit;

  /// No description provided for @editTransactionTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Transaksi'**
  String get editTransactionTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
