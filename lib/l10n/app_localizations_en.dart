// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MoneyWork';

  @override
  String get navHome => 'Home';

  @override
  String get navBills => 'Bills';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navInvestments => 'Assets';

  @override
  String get scanButton => 'Scan';

  @override
  String get featureComingSoon => 'Feature coming soon!';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get tooltipWishlist => 'Wishlist';

  @override
  String get tooltipReport => 'Report';

  @override
  String get tooltipProfile => 'Profile & Settings';

  @override
  String get tooltipForecast => '30-day cash flow forecast';

  @override
  String get tooltipImportStatementPdf => 'Import PDF bank statement';

  @override
  String importSuccess(int count) {
    return '$count transactions added. Check the save status.';
  }

  @override
  String get syncStatusLoading => 'Loading data';

  @override
  String get syncStatusSynced => 'Data saved';

  @override
  String get syncStatusPending => 'Saving changes';

  @override
  String get syncCache => 'Showing cached data; waiting for server';

  @override
  String get syncStatusError => 'Could not save changes';

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncLoadCloud => 'Load cloud version';

  @override
  String get syncDiscardTitle => 'Discard unsaved changes?';

  @override
  String get syncDiscardBody =>
      'The cloud version will load. Changes on this device that failed to save will be lost.';

  @override
  String get syncCancel => 'Cancel';

  @override
  String get syncContinue => 'Load cloud';

  @override
  String get errorLoadData => 'Failed to load data';

  @override
  String get savingTargetTitle => 'Saving Target';

  @override
  String get netWorthTitle => 'Net Worth';

  @override
  String get totalAssetsTitle => 'Total Assets';

  @override
  String get totalDebtTitle => 'Total Debt';

  @override
  String get cashTitle => 'Cash';

  @override
  String get investmentTitle => 'Investment';

  @override
  String get receivableTitle => 'Receivable';

  @override
  String get debtTitle => 'Debt';

  @override
  String get recentTransactionsTitle => 'Recent Transactions';

  @override
  String get noTransactionsMessage => 'No transactions yet.';

  @override
  String get titleAccounts => 'Accounts & Transactions';

  @override
  String get tooltipMonthlyExpenses => 'Monthly Expenses';

  @override
  String get fabAddAccount => 'Add Account';

  @override
  String get fabRecordTransaction => 'Record Transaction';

  @override
  String get errorLoadFailed => 'Failed to load';

  @override
  String get emptyAccountTitle => 'Add an account first';

  @override
  String get emptyAccountSubtitle =>
      'Monthly transactions need an account as a source/destination.';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get noTransactionsFilter => 'No transactions match the filter.';

  @override
  String get searchHint => 'Search notes / categories';

  @override
  String get tooltipClearFilter => 'Clear filter';

  @override
  String get filterAll => 'All';

  @override
  String get filterAllAccounts => 'All accounts';

  @override
  String get accountLabel => 'Account';

  @override
  String get myAccounts => 'My Accounts';

  @override
  String get titleBills => 'Bills';

  @override
  String get tooltipSplitBill => 'Split Bill';

  @override
  String get tooltipAddDebt => 'Add Debt';

  @override
  String get tooltipAddReceivable => 'Add Receivable';

  @override
  String get tabDebts => 'Debts & Installments';

  @override
  String get tabReceivables => 'Receivables';

  @override
  String get fabDebt => 'Debt';

  @override
  String get emptyDebtTitle => 'No debts';

  @override
  String get emptyDebtSubtitle =>
      'Great! If you have loans, credit cards, or installments,\nrecord them here to track your net worth.';

  @override
  String get totalDebtLabel => 'Total Debt';

  @override
  String get monthlyInstallment => 'Monthly';

  @override
  String get paidOff => 'Paid off';

  @override
  String get duePrefix => 'Due';

  @override
  String get perMonthSuffix => '/mo';

  @override
  String get payButton => 'Pay';

  @override
  String get fabReceivable => 'Receivable';

  @override
  String get emptyReceivableTitle => 'No receivables yet';

  @override
  String get emptyReceivableSubtitle =>
      'Record money your friends/others owe you.\nCan also be added from the split bill calculator.';

  @override
  String get totalReceivableLabel => 'Total Receivable';

  @override
  String get peopleCountSuffix => 'people';

  @override
  String get loansCountSuffix => 'loans';

  @override
  String get settled => 'settled';

  @override
  String get remaining => 'remaining';

  @override
  String get receiveFrom => 'Receive from';

  @override
  String get profileTitle => 'Profile & Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageId => 'Indonesia';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文 (Mandarin)';

  @override
  String get sectionReminders => 'Reminders';

  @override
  String get reminderTitle => 'Device Notifications';

  @override
  String get reminderSubtitle => 'Remind you to log transactions & track goals';

  @override
  String get reminderTimeTitle => 'Daily reminder time';

  @override
  String get reminderTimeSubtitle => 'Every day at';

  @override
  String get sectionApp => 'Application';

  @override
  String get updateTitle => 'Check for updates';

  @override
  String get updateSubtitle => 'Check & install the latest version';

  @override
  String get sectionAccount => 'Account';

  @override
  String get accountName => 'Name';

  @override
  String get changePassword => 'Change password';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeySubtitle => 'View/regenerate security key';

  @override
  String get logout => 'Log out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Permanently delete account & all data';

  @override
  String get languageDialogTitle => 'Choose Language';

  @override
  String get tabInvestments => 'Investments';

  @override
  String get tooltipUpdatePrices => 'Update all prices';

  @override
  String get tooltipStockTrade => 'Stock Trade (RDN)';

  @override
  String get fabInvestment => 'Investment';

  @override
  String get snackUpdatingPrices => 'Updating prices...';

  @override
  String get snackNoAutoPrices => 'No assets with automatic pricing.';

  @override
  String get snackPricesUpdated => 'prices updated.';

  @override
  String get snackPricesUpdateFailed1 => 'updated,';

  @override
  String get snackPricesUpdateFailed2 => 'failed out of';

  @override
  String get emptyInvestmentTitle => 'No investments yet';

  @override
  String get emptyInvestmentSubtitle =>
      'Add stocks, mutual funds, crypto, or gold\nto track your portfolio value.';

  @override
  String get totalPortfolioValue => 'Total Portfolio Value';

  @override
  String get qtyLot => 'lots';

  @override
  String get qtyUnit => 'units';

  @override
  String get updatedAtLabel => 'Updated at';

  @override
  String get addInvestment => 'Add Investment';

  @override
  String get editInvestment => 'Edit Investment';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'e.g., AAPL, Bitcoin, Gold';

  @override
  String get typeLabel => 'Type';

  @override
  String get tickerCryptoLabel => 'CoinGecko ID';

  @override
  String get tickerStockLabel => 'Stock Ticker';

  @override
  String get tickerCryptoHint => 'e.g., bitcoin, ethereum, solana';

  @override
  String get tickerStockHint => 'e.g., AAPL, TSLA';

  @override
  String get tickerCryptoHelper => 'For automatic price updates (optional)';

  @override
  String get tickerStockHelper =>
      'Automatic stock prices active after backend deployed';

  @override
  String get qtyLotLabel => 'Number of lots';

  @override
  String get qtyUnitLabel => 'Number of units';

  @override
  String get qtyLotHint => 'e.g., 5, 10';

  @override
  String get qtyUnitHint => 'e.g., 100, 0.5';

  @override
  String qtyLotHelper(String shares) {
    return '1 lot = $shares shares';
  }

  @override
  String get buyLotLabel => 'Buy price / share';

  @override
  String get buyUnitLabel => 'Buy price / unit';

  @override
  String get nowLotLabel => 'Current price / share';

  @override
  String get nowUnitLabel => 'Current price / unit';

  @override
  String get tooltipFetchPrice => 'Fetch current price';

  @override
  String get snackTickerEmpty => 'Please fill in the ticker/symbol first.';

  @override
  String get snackPriceUpdated => 'Price updated:';

  @override
  String get snackFailed => 'Failed.';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get saveButton => 'Save';

  @override
  String get addButton => 'Add';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get tradeStockTitle => 'Stock Trade';

  @override
  String get buyLabel => 'Buy';

  @override
  String get sellLabel => 'Sell';

  @override
  String get snackNoRdn =>
      'Create an \"RDN (Stock)\" account in the Accounts tab first for stock trading.';

  @override
  String get noStockToSell => 'No stocks to sell yet.';

  @override
  String get stockDropdownLabel => 'Stock';

  @override
  String get newStockOption => '+ New stock';

  @override
  String get stockNameLabel => 'Stock name';

  @override
  String get stockNameHint => 'e.g., AAPL';

  @override
  String get stockCodeLabel => 'Ticker (optional)';

  @override
  String get rdnAccountLabel => 'RDN Account';

  @override
  String lotQtyHelperSell(String lots) {
    return 'Own $lots lots';
  }

  @override
  String maxLotError(String lots) {
    return 'Max $lots';
  }

  @override
  String get pricePerShareLabel => 'Price/share';

  @override
  String get totalPayLabel => 'Total to pay';

  @override
  String get totalReceiveLabel => 'Total to receive';

  @override
  String get snackBuySuccess => 'Stock purchase recorded.';

  @override
  String get snackSellSuccess => 'Stock sale recorded.';

  @override
  String get tabWishlist => 'Wishlist';

  @override
  String get emptyWishlistTitle => 'Wishlist is empty';

  @override
  String get emptyWishlistSubtitle =>
      'Record items you want to buy with price,\nlink, and target date.';

  @override
  String get totalTargetBelanja => 'Total target';

  @override
  String barangBelumDibeli(String count) {
    return '$count items not bought yet';
  }

  @override
  String get sudahDibeli => 'Purchased';

  @override
  String get gagalMembukaLink => 'Cannot open link.';

  @override
  String get targetDateLabel => 'Target';

  @override
  String get savingPerMonthSuffix => '/mo';

  @override
  String savingProgressLabel(String saved, String total) {
    return 'Saved $saved / $total';
  }

  @override
  String savingMonthsRemaining(String months) {
    return ' · ~$months mo left';
  }

  @override
  String get tooltipCatatNabung => 'Record saving';

  @override
  String get tooltipBukaLink => 'Open link';

  @override
  String dialogNabungTitle(String name) {
    return 'Save for $name';
  }

  @override
  String dialogNabungSisa(String remaining) {
    return 'Remaining $remaining';
  }

  @override
  String get dialogNabungJumlah => 'Amount to save';

  @override
  String get dialogNabungAmbilDari => 'Take from account';

  @override
  String get dialogNabungTanpaPotong => 'Without deducting balance';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get recordButton => 'Record';

  @override
  String get addWishlist => 'Add Wishlist';

  @override
  String get editWishlist => 'Edit Wishlist';

  @override
  String get itemNameLabel => 'Item name';

  @override
  String get itemNameHint => 'e.g., iPhone, Bike, Laptop';

  @override
  String get estPriceLabel => 'Estimated price';

  @override
  String get linkOptionalLabel => 'Purchase link (optional)';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get targetDateOptionalLabel => 'Target date (optional)';

  @override
  String get selectDate => 'Select date';

  @override
  String get savingPlanOptional => 'Saving Plan (optional)';

  @override
  String get savePerMonthLabel => 'Save/mo';

  @override
  String get durationLabel => 'Duration';

  @override
  String get monthSuffix => 'mo';

  @override
  String get calcHelperText =>
      'Fill one, the other is calculated automatically.';

  @override
  String nabungSelamaHelper(String monthly, String months) {
    return 'Save $monthly/mo for $months months.';
  }

  @override
  String get saveFromAccountLabel => 'Save from account';

  @override
  String get noneOption => '—';

  @override
  String get reminderDayLabel => 'Saving reminder every date';

  @override
  String get noReminder => 'None';

  @override
  String dateSuffix(String date) {
    return 'Date $date';
  }

  @override
  String get exportReportTitle => 'Export Report';

  @override
  String get exportPeriodLabel => 'Period';

  @override
  String get exportTypeFormatLabel => 'Export Type & Format';

  @override
  String get exportMonthlyPdf => 'Monthly Report (PDF)';

  @override
  String get exportMonthlyExcel => 'Monthly Report (Excel)';

  @override
  String get exportAllExcel => 'Backup All Data (Excel)';

  @override
  String get exportAllExcelSubtitle =>
      'Exports all accounts, transactions, debts, receivables, wishlists, etc.';

  @override
  String get exportNowBtn => 'Export Now';

  @override
  String get snackPrepBackup => 'Preparing All Data Backup...';

  @override
  String snackPrepMonth(String month) {
    return 'Preparing $month...';
  }

  @override
  String get tabReport => 'Report';

  @override
  String get tooltipExport => 'Export Report';

  @override
  String get cashFlow6Months => '6-Month Cash Flow';

  @override
  String get assetComposition => 'Asset Composition';

  @override
  String get expenseByCategory => 'Expense by Category';

  @override
  String get summaryIncome => 'Income';

  @override
  String get summaryExpense => 'Expense';

  @override
  String get summaryNet => 'Net';

  @override
  String get emptyCashFlow => 'No cash flow to display yet.';

  @override
  String get pieAssetCash => 'Cash';

  @override
  String get pieAssetInvestment => 'Investment';

  @override
  String get pieAssetReceivable => 'Receivable';

  @override
  String get emptyAsset => 'No assets to display yet.';

  @override
  String get emptyCategory => 'No expenses this month.';

  @override
  String get tabMonthlyTx => 'Monthly Transactions';

  @override
  String get tooltipAddTemplate => 'Add template';

  @override
  String get emptyMonthlyTitle => 'No monthly transactions yet';

  @override
  String get emptyMonthlySubtitle =>
      'Set up routine costs (subscriptions, bills, savings), then\nrun them all at once every month.';

  @override
  String runBarIncome(String amount) {
    return 'In $amount';
  }

  @override
  String runBarExpense(String amount) {
    return 'Out $amount';
  }

  @override
  String runAllBtn(String count) {
    return 'Run All ($count)';
  }

  @override
  String get confirmRunTitle => 'Run monthly transactions?';

  @override
  String confirmRunContent(String count) {
    return '$count active transactions will be created with today\'s date. Account balances will be updated.';
  }

  @override
  String get confirmRunOk => 'Run';

  @override
  String runSuccessWithSkip(String created, String skipped) {
    return '$created transactions created, $skipped skipped (insufficient balance).';
  }

  @override
  String runSuccessAll(String created) {
    return '$created monthly transactions successfully run.';
  }

  @override
  String get addTemplate => 'Add Template';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get templateNameHint => 'e.g., Netflix, Electricity, Savings';

  @override
  String get templateCategoryHint => 'e.g., Subscriptions, Bills';

  @override
  String get segmentExpense => 'Expense';

  @override
  String get segmentIncome => 'Income';

  @override
  String get segmentTransfer => 'Transfer';

  @override
  String get amountLabel => 'Amount';

  @override
  String get fromAccountLabel => 'From account';

  @override
  String get toAccountLabel => 'To account';

  @override
  String get errorSelectAccount => 'Select destination account';

  @override
  String get errorSameAccount => 'Select a different account';

  @override
  String get categoryLabel => 'Category';

  @override
  String get addBillItem => 'Add Item';

  @override
  String get menuNameLabel => 'Item name';

  @override
  String get menuNameHint => 'e.g., Fried Rice';

  @override
  String get priceLabel => 'Price';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get noOtherBillsToSave => 'No bills for others to save.';

  @override
  String get saveSplitBillTitle => 'Save Split Bill';

  @override
  String get friendBillsLabel => 'Friends\' bills (as receivables):';

  @override
  String get myShareLabel => 'My share';

  @override
  String get fundFromAccountLabel => 'I am paying from account';

  @override
  String get doNotDeductBalance => '— Do not deduct balance';

  @override
  String personLabel(String number) {
    return 'Person $number';
  }

  @override
  String get totalOutFromAccount => 'Total out from account';

  @override
  String get totalReceivableRecorded => 'Total receivable recorded';

  @override
  String receivableSavedDeducted(String count, String amount) {
    return '$count receivables recorded, balance deducted $amount.';
  }

  @override
  String get splitBillNotePrefix => 'Split bill';

  @override
  String receivableSavedOnly(String count) {
    return '$count receivable(s) saved.';
  }

  @override
  String get tabSplitBill => 'Split Bill';

  @override
  String get personLabelOnly => 'Person';

  @override
  String get splitBillEmptyState => 'Add people first, then enter their items.';

  @override
  String get deletePersonTooltip => 'Remove person';

  @override
  String get meNotBilledLabel => 'Me (Not billed)';

  @override
  String get itemLabel => 'Item';

  @override
  String get sharedItemsLabel => 'Shared Items (split evenly)';

  @override
  String get addSharedItemLabel => 'Shared item';

  @override
  String get taxAndDiscountLabel => 'Tax, Fees & Discount';

  @override
  String get ppnLabel => 'Tax';

  @override
  String get serviceChargeLabel => 'Service';

  @override
  String get discountLabel => 'Discount';

  @override
  String get additionalFeesLabel => 'Additional fees';

  @override
  String get percentageLabel => 'Percentage';

  @override
  String get nominalLabel => 'Amount';

  @override
  String get splitDiscountEvenlyLabel => 'Split discount evenly';

  @override
  String get discountEvenlyDesc => 'Everyone gets an equal discount';

  @override
  String get discountProportionalDesc =>
      'Discount is proportional to order amount';

  @override
  String get detailsLabel => 'Details';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get totalLabel => 'Total';

  @override
  String get billPerPersonLabel => 'Bill per person';

  @override
  String get unnamedLabel => '(unnamed)';

  @override
  String get saveToReceivablesBtn => 'Save to Receivables';

  @override
  String get splitBillShare => 'Share';

  @override
  String get splitBillCopied => 'Split bill details copied.';

  @override
  String get splitBillShareFailed => 'Could not share split bill details.';

  @override
  String get createAccountSubtitle => 'Create a new account';

  @override
  String get loginSubtitle => 'Log into your account';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get loginButton => 'Log In';

  @override
  String get orDividerLabel => 'or';

  @override
  String get loginWithGoogleBtn => 'Sign in with Google';

  @override
  String get alreadyHaveAccountBtn => 'Already have an account? Log In';

  @override
  String get dontHaveAccountBtn => 'Don\'t have an account? Sign Up';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Invalid email format';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLen => 'Minimum 6 characters';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get passwordConfirmLabel => 'Confirm password';

  @override
  String get requiredField => 'Required field';

  @override
  String get passwordNotMatch => 'Passwords do not match';

  @override
  String get completeAccountTitle => 'Complete Account';

  @override
  String completeAccountDesc(String email) {
    return 'You signed in as $email. Create a password to finish registration. After this you can sign in with your email and password.';
  }

  @override
  String get saveAndContinueBtn => 'Save & Continue';

  @override
  String get logoutButton => 'Sign Out';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get invalidRecoveryKey => 'Invalid recovery key.';

  @override
  String get unlockDataTitle => 'Unlock Data';

  @override
  String get unlockRecoveryDesc =>
      'Enter your recovery key & new password to unlock data on this device.';

  @override
  String get unlockPasswordDesc =>
      'Enter your password to unlock data on this device. Only once per device.';

  @override
  String get unlockBtn => 'Unlock';

  @override
  String get forgotPasswordBtn => 'Forgot password?';

  @override
  String get recoveryKeyLabel => 'Recovery key';

  @override
  String get recoveryKeyHint => 'XXXX-XXXX-XXXX-...';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get unlockAndChangePassBtn => 'Unlock & Change Password';

  @override
  String get rememberPasswordBtn => 'I remember my password';

  @override
  String get upgradeSecurityTitle => 'Upgrade Data Security';

  @override
  String get upgradeSecurityDesc =>
      'Your financial data will now be encrypted before being saved to the cloud — not even the project owners can read it. Enter your password to begin.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get startEncryptionBtn => 'Start Encryption';

  @override
  String get saveRecoveryKeyTitle => 'Save Recovery Key';

  @override
  String get saveRecoveryKeyDesc =>
      'This is the only way to unlock your data if you forget your password. We do not store it. Copy & save it in a safe place (e.g. password manager). Without this and your password, your data cannot be recovered.';

  @override
  String get recoveryKeyCopied => 'Key copied.';

  @override
  String get copyKeyBtn => 'Copy key';

  @override
  String get iHaveSavedItBtn => 'I have saved it';

  @override
  String get addAccountFirst =>
      'Please add an account first in the Account tab.';

  @override
  String payDebtTitle(String name) {
    return 'Pay $name';
  }

  @override
  String debtRemainingLabel(String amount) {
    return 'Remaining debt: $amount';
  }

  @override
  String get payAmountLabel => 'Payment amount';

  @override
  String balanceHelper(String name, String amount) {
    return '$name balance: $amount';
  }

  @override
  String exceedsDebtRemaining(String amount) {
    return 'Exceeds remaining debt ($amount)';
  }

  @override
  String exceedsBalance(String amount) {
    return 'Exceeds balance ($amount)';
  }

  @override
  String get payFromLabel => 'Pay from';

  @override
  String get payNowBtn => 'Pay Now';

  @override
  String paymentRecorded(String amount) {
    return 'Payment of $amount recorded.';
  }

  @override
  String get editDebtTitle => 'Edit Debt';

  @override
  String get addDebtTitle => 'Add Debt';

  @override
  String get debtNameHint => 'e.g. Mortgage, Credit Card';

  @override
  String get debtRemainingInputLabel => 'Remaining debt';

  @override
  String get monthlyPaymentOptional => 'Monthly payment (optional)';

  @override
  String get dueDateOptional => 'Due date (optional)';

  @override
  String get selectDateBtn => 'Select date';

  @override
  String collectFromTitle(String name) {
    return 'Receive from $name';
  }

  @override
  String totalOutstanding(String amount) {
    return 'Total remaining: $amount';
  }

  @override
  String loanCount(int count) {
    return '$count loans';
  }

  @override
  String get fifoPaymentNote => 'Payment clears the oldest loan first.';

  @override
  String get amountReceivedLabel => 'Amount received';

  @override
  String exceedsTotalOutstanding(String amount) {
    return 'Exceeds total remaining ($amount)';
  }

  @override
  String get receiveIntoLabel => 'Receive into';

  @override
  String get receiveNowBtn => 'Receive Now';

  @override
  String receivedAmount(String amount) {
    return 'Received $amount.';
  }

  @override
  String get editReceivableTitle => 'Edit Receivable';

  @override
  String get addReceivableTitle => 'Add Receivable';

  @override
  String get personNameLabel => 'Person name';

  @override
  String get personNameHint => 'e.g. John';

  @override
  String get receivableAmountLabel => 'Receivable amount';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteReceivableHint => 'e.g. Dinner at X';

  @override
  String get fundNowTitle => 'I am funding this now';

  @override
  String get fundNowSubtitle => 'Money will be deducted from my account';

  @override
  String get reminderActiveDesc => 'Reminders active. Set the time below.';

  @override
  String get reminderNoPermission =>
      'Notification permission denied. Enable in Phone Settings.';

  @override
  String get reminderDisabled => 'Reminders are turned off.';

  @override
  String reminderDailySetTo(String time) {
    return 'Daily reminder set to $time.';
  }

  @override
  String get dailyReminderTime => 'Daily reminder time';

  @override
  String dailyReminderDesc(String time) {
    return 'Every day at $time';
  }

  @override
  String get alreadyLatestVersion =>
      'You are already using the latest version.';

  @override
  String get autoUpdateAndroidOnly =>
      'Auto-updates are only available on Android.';

  @override
  String get updateCheckFailed =>
      'Failed to check for updates. Check connection.';

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateCheckDesc => 'Check & install the latest version';

  @override
  String get renameTitle => 'Change Name';

  @override
  String get passwordChanged => 'Password successfully changed.';

  @override
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String recoveryKeyCreateFailed(String error) {
    return 'Failed to create recovery key: $error';
  }

  @override
  String get recoveryKeyNew => 'New Recovery Key';

  @override
  String get copy => 'Copy';

  @override
  String get done => 'Done';

  @override
  String get recoveryKeyNewDesc =>
      'For security reasons, the system does not store your old Recovery Key. We will create a NEW Recovery Key for you.';

  @override
  String get updateMandatory => 'This update is mandatory.';

  @override
  String downloading(String pct) {
    return 'Downloading... $pct%';
  }

  @override
  String get skip => 'Skip';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get accountNameHint => 'e.g. BCA, GoPay, Wallet';

  @override
  String get accountNumber => 'Account number';

  @override
  String get initialBalance => 'Initial balance';

  @override
  String get balance => 'Balance';

  @override
  String get editTx => 'Edit Transaction';

  @override
  String get noteOptionalTx => 'Note (optional)';

  @override
  String get date => 'Date';

  @override
  String get adminFeeOptional => 'Transfer fee (optional)';

  @override
  String get invalidAmount => 'Enter a valid amount';

  @override
  String get invalidAdminFee => 'Enter a valid admin fee';

  @override
  String get adminFeeDesc =>
      'Recipient receives full amount; admin fee is deducted from source';

  @override
  String totalOut(String amount) {
    return 'Total out from source: $amount';
  }

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get noTxTodayTitle => 'No transactions today';

  @override
  String get noTxTodayDesc =>
      'Record your income or expenses to stay on track.';

  @override
  String get salarySaveTitle => 'Got paid? Set some aside';

  @override
  String salarySaveDesc(String names) {
    return 'Don\'t forget to save for: $names.';
  }

  @override
  String timeToSaveTitle(String name) {
    return 'Time to save: $name';
  }

  @override
  String timeToSaveDescAmount(String amount) {
    return 'Save $amount this month.';
  }

  @override
  String get timeToSaveDescGeneral => 'Set aside funds for this goal.';

  @override
  String reportTitle(String periodName) {
    return 'MoneyWork Transaction Report - $periodName';
  }

  @override
  String reportPrintedOn(String date) {
    return 'Printed on: $date';
  }

  @override
  String get reportCashflowSummary => 'Cashflow Summary';

  @override
  String reportIncome(String amount) {
    return 'Income: $amount';
  }

  @override
  String reportExpense(String amount) {
    return 'Expense: $amount';
  }

  @override
  String reportNet(String amount) {
    return 'Net Balance: $amount';
  }

  @override
  String get reportExpenseByCategory => 'Expense by Category';

  @override
  String get reportTxDetail => 'Transaction Details';

  @override
  String get reportLegendOut => 'Out';

  @override
  String get reportLegendIn => 'In';

  @override
  String get reportType => 'Type';

  @override
  String get reportDate => 'Date';

  @override
  String get reportAmount => 'Amount';

  @override
  String get notifSaveTime => 'Time to save 💰';

  @override
  String notifSaveAmount(String amount, String name) {
    return 'Set aside $amount for $name.';
  }

  @override
  String notifSaveGeneral(String name) {
    return 'Time to save for $name.';
  }

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeEwallet => 'E-Wallet';

  @override
  String get accountTypeRdn => 'RDN (Stock)';

  @override
  String get debtTypeLoan => 'Loan';

  @override
  String get debtTypeCreditCard => 'Credit Card';

  @override
  String get debtTypeInstallment => 'Installment';

  @override
  String get debtTypeOther => 'Other';

  @override
  String get invTypeStock => 'Stock';

  @override
  String get invTypeMutualFund => 'Mutual Fund';

  @override
  String get invTypeCrypto => 'Crypto';

  @override
  String get invTypeGold => 'Gold';

  @override
  String get invTypeOther => 'Other';

  @override
  String get salaryAllocateTitle => 'Time to budget this month';

  @override
  String get salaryAllocateDesc =>
      'Salary is here, let\'s allocate it to various accounts and expenses.';

  @override
  String get highExpenseTitle => 'Daily expenses are quite high';

  @override
  String highExpenseDesc(String avg) {
    return 'Average $avg per day this month. Try to slow down.';
  }

  @override
  String get editAccountTitle => 'Edit Account';

  @override
  String get deleteTransactionWarning =>
      'The account balance will be adjusted accordingly. This action cannot be undone.';

  @override
  String get deleteAccountWarning =>
      'All transactions related to this account will also be deleted.';

  @override
  String get labelAccountName => 'Account name';

  @override
  String get hintAccountName => 'e.g. Chase, PayPal, Cash';

  @override
  String get validationRequired => 'Required';

  @override
  String get labelAccountType => 'Type';

  @override
  String get labelEwalletNumber => 'Phone / e-wallet account';

  @override
  String get labelBankNumber => 'Account number';

  @override
  String get hintOptional => 'optional';

  @override
  String get labelBalance => 'Balance';

  @override
  String get labelInitialBalance => 'Initial balance';

  @override
  String get validationInvalidNumber => 'Invalid number';

  @override
  String get recordTransactionTitle => 'Record Transaction';

  @override
  String get labelAmount => 'Amount';

  @override
  String helperBalance(String name, String balance) {
    return 'Balance of $name: $balance';
  }

  @override
  String get validationInvalidAmount => 'Enter a valid amount';

  @override
  String validationExceedBalance(String balance) {
    return 'Exceeds balance ($balance)';
  }

  @override
  String get labelFromAccount => 'From account';

  @override
  String get labelToAccount => 'To account';

  @override
  String get validationSelectDest => 'Select destination account';

  @override
  String get validationDiffAccount => 'Select a different account';

  @override
  String get adminFeeSubtitle =>
      'Deducted from source account, recorded separately';

  @override
  String get labelAdminFee => 'Admin fee';

  @override
  String get helperAdminFee =>
      'Destination receives full amount; fee deducted from source';

  @override
  String get validationAdminFee => 'Enter a valid admin fee';

  @override
  String get labelCategory => 'Category';

  @override
  String get hintCategory => 'e.g. Food, Salary, Transport';

  @override
  String get labelNote => 'Note (optional)';

  @override
  String get labelDate => 'Date';

  @override
  String get updateAvailable => 'Update available';

  @override
  String updateVersion(String version) {
    return 'Update $version';
  }

  @override
  String get updateDefaultNotes => 'A new version of the app is available.';

  @override
  String get updateBtn => 'Update';

  @override
  String get retryBtn => 'Retry';

  @override
  String get excelHeaderDate => 'Date';

  @override
  String get excelHeaderType => 'Type';

  @override
  String get excelHeaderCategory => 'Category';

  @override
  String get excelHeaderAmount => 'Amount';

  @override
  String get excelHeaderAccount => 'Account';

  @override
  String get excelHeaderNote => 'Note';

  @override
  String reportPrintedAt(String date) {
    return 'Printed on: $date';
  }

  @override
  String get legendIncome => 'Income';

  @override
  String get legendExpense => 'Expense';

  @override
  String get noTransactionPeriod => 'No transactions in this period.';

  @override
  String shareReportText(String period) {
    return 'MoneyWork Transaction Report $period';
  }

  @override
  String get excelHeaderBalance => 'Balance';

  @override
  String get excelHeaderBankNo => 'Account No.';

  @override
  String get excelHeaderCreatedAt => 'Created At';

  @override
  String get excelHeaderLender => 'Lender (Name)';

  @override
  String get excelHeaderDebtRemaining => 'Remaining Debt';

  @override
  String get excelHeaderMonthlyPayment => 'Monthly Payment';

  @override
  String get excelHeaderDueDate => 'Due Date';

  @override
  String get excelHeaderBorrower => 'Borrower (Name)';

  @override
  String get excelHeaderRecNote => 'Title/Note';

  @override
  String get excelHeaderRecRemaining => 'Remaining Receivable';

  @override
  String get excelHeaderAssetName => 'Asset Name';

  @override
  String get excelHeaderTicker => 'Ticker';

  @override
  String get excelHeaderQuantity => 'Quantity';

  @override
  String get excelHeaderBuyPrice => 'Buy Price';

  @override
  String get excelHeaderCurrentPrice => 'Current Price';

  @override
  String get excelHeaderTotalCost => 'Total Cost';

  @override
  String get excelHeaderTotalMarket => 'Total Market';

  @override
  String get excelHeaderReturn => 'Return (%)';

  @override
  String get excelHeaderItemName => 'Item Name';

  @override
  String get excelHeaderTargetPrice => 'Target Price';

  @override
  String get excelHeaderSaved => 'Saved';

  @override
  String get excelHeaderPriority => 'Priority';

  @override
  String get excelHeaderStatus => 'Status';

  @override
  String get excelHeaderTargetDate => 'Target Date';

  @override
  String get statusPurchased => 'Purchased';

  @override
  String get statusNotPurchased => 'Not Purchased';

  @override
  String get excelHeaderLabel => 'Label';

  @override
  String get excelHeaderNominal => 'Nominal';

  @override
  String get excelHeaderActiveStatus => 'Active Status';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String shareBackupText(String date) {
    return 'MoneyWork Full Data Backup ($date)';
  }

  @override
  String get excelSheetAccounts => 'Accounts';

  @override
  String get excelSheetTransactions => 'Transactions';

  @override
  String get excelSheetDebts => 'Debts';

  @override
  String get excelSheetReceivables => 'Receivables';

  @override
  String get excelSheetInvestments => 'Investments';

  @override
  String get excelSheetRecurring => 'Recurring';

  @override
  String get priceErrNoTicker => 'Please fill in the ticker/symbol first.';

  @override
  String get priceErrUnsupported =>
      'Auto-pricing is not available for this type.';

  @override
  String get priceErrFetch =>
      'Failed to fetch price. Check your internet connection.';

  @override
  String priceErrServer(int code) {
    return 'CoinGecko server error ($code).';
  }

  @override
  String priceErrNotFound(String id) {
    return 'Ticker \"$id\" not found on CoinGecko.';
  }

  @override
  String get priceErrStockNotReady =>
      'Stock auto-pricing not active (backend not deployed).';

  @override
  String priceErrStockServer(int code) {
    return 'Stock price server error ($code).';
  }

  @override
  String priceErrStockNotFound(String code) {
    return 'Stock code \"$code\" not found.';
  }

  @override
  String get categoryOther => 'Other';

  @override
  String errorLoadSession(String error) {
    return 'Failed to load session: $error';
  }

  @override
  String errorLoadSecurity(String error) {
    return 'Failed to load security status: $error';
  }

  @override
  String get notifDailyTitle => 'Record today\'s transactions';

  @override
  String get notifDailyBody =>
      'Don\'t forget to record your income & expenses in MoneyWork.';

  @override
  String get notifSaveTitle => 'Time to save 💰';

  @override
  String get receiptReview => 'Receipt Review';

  @override
  String get receiptVerified => '✅ Total matches — data is ready';

  @override
  String get receiptMismatch =>
      '⚠️ Total mismatch — please check the numbers below';

  @override
  String get receiptItemName => 'Item Name';

  @override
  String get receiptQty => 'Qty';

  @override
  String get receiptUnitPrice => 'Unit Price';

  @override
  String get receiptServiceCharge => 'Service Charge';

  @override
  String get receiptTax => 'Tax';

  @override
  String get receiptDiscount => 'Discount';

  @override
  String get receiptGrandTotalPaper => 'Grand Total (Paper)';

  @override
  String get receiptGrandTotalCalc => 'Grand Total (Calculated)';

  @override
  String get receiptSaveAsTransaction => 'Save as Transaction';

  @override
  String get receiptSplitBill => 'Split Bill';

  @override
  String get receiptScanning => 'Scanning receipt...';

  @override
  String get receiptScanFailed => 'Failed to scan receipt';

  @override
  String get scanFromCamera => 'Camera';

  @override
  String get scanFromGallery => 'Gallery';

  @override
  String get scanChooseSource => 'Choose Photo Source';

  @override
  String get assignItemsTitle => 'Assign Items';

  @override
  String get howManyPeople => 'How many people are splitting?';

  @override
  String get nextStep => 'Next';

  @override
  String get enterNames => 'Enter names for each person';

  @override
  String personNumber(int number) {
    return 'Person $number';
  }

  @override
  String selectItemsFor(String name) {
    return 'Select items for $name';
  }

  @override
  String get calculateSplit => 'Calculate Split';

  @override
  String get editTransactionTitle => 'Edit Transaction';
}
