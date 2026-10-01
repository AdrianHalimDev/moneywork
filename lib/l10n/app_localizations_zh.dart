// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MoneyWork';

  @override
  String get navHome => '首页';

  @override
  String get navBills => '账单';

  @override
  String get navAccounts => '账户';

  @override
  String get navInvestments => '投资';

  @override
  String get scanButton => '扫描';

  @override
  String get featureComingSoon => '功能即将推出！';

  @override
  String get settingsLanguage => '语言';

  @override
  String get tooltipWishlist => '愿望清单';

  @override
  String get tooltipReport => '报告';

  @override
  String get tooltipProfile => '个人资料和设置';

  @override
  String get tooltipForecast => '未来30天现金流预测';

  @override
  String get tooltipImportStatementPdf => '导入银行流水 PDF';

  @override
  String importSuccess(int count) {
    return '已添加 $count 笔交易。请检查保存状态。';
  }

  @override
  String get syncStatusLoading => '正在加载数据';

  @override
  String get syncStatusSynced => '数据已保存';

  @override
  String get syncStatusPending => '正在保存更改';

  @override
  String get syncCache => '正在显示缓存数据，等待服务器确认';

  @override
  String get syncStatusError => '保存更改失败';

  @override
  String get syncRetry => '重试';

  @override
  String get syncLoadCloud => '加载云端版本';

  @override
  String get syncDiscardTitle => '丢弃未保存的更改？';

  @override
  String get syncDiscardBody => '将加载云端版本。本设备上保存失败的更改将丢失。';

  @override
  String get syncCancel => '取消';

  @override
  String get syncContinue => '加载云端';

  @override
  String get errorLoadData => '加载数据失败';

  @override
  String get savingTargetTitle => '储蓄目标';

  @override
  String get netWorthTitle => '净资产';

  @override
  String get totalAssetsTitle => '总资产';

  @override
  String get totalDebtTitle => '总债务';

  @override
  String get cashTitle => '现金';

  @override
  String get investmentTitle => '投资';

  @override
  String get receivableTitle => '应收账款';

  @override
  String get debtTitle => '债务';

  @override
  String get recentTransactionsTitle => '最近交易';

  @override
  String get noTransactionsMessage => '还没有交易记录。';

  @override
  String get titleAccounts => '账户和交易';

  @override
  String get tooltipMonthlyExpenses => '每月支出';

  @override
  String get fabAddAccount => '添加账户';

  @override
  String get fabRecordTransaction => '记录交易';

  @override
  String get errorLoadFailed => '加载失败';

  @override
  String get emptyAccountTitle => '先添加一个账户';

  @override
  String get emptyAccountSubtitle => '月度交易需要一个账户作为来源/目的地。';

  @override
  String get transactionHistory => '交易记录';

  @override
  String get noTransactionsFilter => '没有符合过滤条件的交易。';

  @override
  String get searchHint => '搜索备注 / 类别';

  @override
  String get tooltipClearFilter => '清除过滤条件';

  @override
  String get filterAll => '全部';

  @override
  String get filterAllAccounts => '所有账户';

  @override
  String get accountLabel => '账户';

  @override
  String get myAccounts => '我的账户';

  @override
  String get titleBills => '账单';

  @override
  String get tooltipSplitBill => '拆分账单';

  @override
  String get tooltipAddDebt => '添加债务';

  @override
  String get tooltipAddReceivable => '添加应收账款';

  @override
  String get tabDebts => '债务和分期';

  @override
  String get tabReceivables => '应收账款';

  @override
  String get fabDebt => '债务';

  @override
  String get emptyDebtTitle => '没有债务';

  @override
  String get emptyDebtSubtitle => '太棒了！如果你有贷款、信用卡或分期付款，\n请在这里记录以便追踪你的净资产。';

  @override
  String get totalDebtLabel => '总债务';

  @override
  String get monthlyInstallment => '每月分期';

  @override
  String get paidOff => '已付清';

  @override
  String get duePrefix => '到期';

  @override
  String get perMonthSuffix => '/月';

  @override
  String get payButton => '支付';

  @override
  String get fabReceivable => '应收账款';

  @override
  String get emptyReceivableTitle => '还没有应收账款';

  @override
  String get emptyReceivableSubtitle => '记录您的朋友/其他人欠您的钱。\n也可以从分摊账单计算器添加。';

  @override
  String get totalReceivableLabel => '总应收账款';

  @override
  String get peopleCountSuffix => '人';

  @override
  String get loansCountSuffix => '笔借款';

  @override
  String get settled => '已结清';

  @override
  String get remaining => '剩余';

  @override
  String get receiveFrom => '收到来自';

  @override
  String get profileTitle => '个人资料和设置';

  @override
  String get sectionAppearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get sectionLanguage => '语言 / Language';

  @override
  String get languageSystem => '跟随系统 (System Default)';

  @override
  String get languageId => 'Indonesia';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文 (Mandarin)';

  @override
  String get sectionReminders => '提醒';

  @override
  String get reminderTitle => '设备通知';

  @override
  String get reminderSubtitle => '提醒您记录日常交易和储蓄目标';

  @override
  String get reminderTimeTitle => '每日提醒时间';

  @override
  String get reminderTimeSubtitle => '每天';

  @override
  String get sectionApp => '应用程序';

  @override
  String get updateTitle => '检查更新';

  @override
  String get updateSubtitle => '检查并安装最新版本';

  @override
  String get sectionAccount => '账户';

  @override
  String get accountName => '姓名';

  @override
  String get changePassword => '更改密码';

  @override
  String get recoveryKey => '恢复密钥';

  @override
  String get recoveryKeySubtitle => '查看/重新生成安全密钥';

  @override
  String get logout => '登出';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountSubtitle => '永久删除账户及所有数据';

  @override
  String get languageDialogTitle => '选择语言';

  @override
  String get tabInvestments => '投资';

  @override
  String get tooltipUpdatePrices => '更新所有价格';

  @override
  String get tooltipStockTrade => '股票交易 (RDN)';

  @override
  String get fabInvestment => '投资';

  @override
  String get snackUpdatingPrices => '正在更新价格...';

  @override
  String get snackNoAutoPrices => '没有自动定价的资产。';

  @override
  String get snackPricesUpdated => '个价格已更新。';

  @override
  String get snackPricesUpdateFailed1 => '个已更新,';

  @override
  String get snackPricesUpdateFailed2 => '个失败, 共';

  @override
  String get emptyInvestmentTitle => '还没有投资';

  @override
  String get emptyInvestmentSubtitle => '添加股票、共同基金、加密货币或黄金\n来跟踪您的投资组合价值。';

  @override
  String get totalPortfolioValue => '投资组合总价值';

  @override
  String get qtyLot => '手';

  @override
  String get qtyUnit => '单位';

  @override
  String get updatedAtLabel => '更新于';

  @override
  String get addInvestment => '添加投资';

  @override
  String get editInvestment => '编辑投资';

  @override
  String get nameLabel => '姓名';

  @override
  String get nameHint => '例如：AAPL，比特币，黄金';

  @override
  String get typeLabel => '类型';

  @override
  String get tickerCryptoLabel => 'CoinGecko ID';

  @override
  String get tickerStockLabel => '股票代码';

  @override
  String get tickerCryptoHint => '例如：bitcoin, ethereum, solana';

  @override
  String get tickerStockHint => '例如：AAPL, TSLA';

  @override
  String get tickerCryptoHelper => '用于自动更新价格（可选）';

  @override
  String get tickerStockHelper => '后端部署后股票自动定价将启用';

  @override
  String get qtyLotLabel => '手数';

  @override
  String get qtyUnitLabel => '单位数';

  @override
  String get qtyLotHint => '例如：5, 10';

  @override
  String get qtyUnitHint => '例如：100, 0.5';

  @override
  String qtyLotHelper(String shares) {
    return '1手 = $shares股';
  }

  @override
  String get buyLotLabel => '买入价 / 股';

  @override
  String get buyUnitLabel => '买入价 / 单位';

  @override
  String get nowLotLabel => '当前价 / 股';

  @override
  String get nowUnitLabel => '当前价 / 单位';

  @override
  String get tooltipFetchPrice => '获取当前价格';

  @override
  String get snackTickerEmpty => '请先填写代码/符号。';

  @override
  String get snackPriceUpdated => '价格已更新：';

  @override
  String get snackFailed => '失败。';

  @override
  String get deleteLabel => '删除';

  @override
  String get saveButton => '保存';

  @override
  String get addButton => '添加';

  @override
  String get invalidNumber => '无效数字';

  @override
  String get tradeStockTitle => '股票交易';

  @override
  String get buyLabel => '买入';

  @override
  String get sellLabel => '卖出';

  @override
  String get snackNoRdn => '请先在账户选项卡中创建“RDN（股票）”账户以进行股票交易。';

  @override
  String get noStockToSell => '还没有股票可卖出。';

  @override
  String get stockDropdownLabel => '股票';

  @override
  String get newStockOption => '+ 新股票';

  @override
  String get stockNameLabel => '股票名称';

  @override
  String get stockNameHint => '例如：AAPL';

  @override
  String get stockCodeLabel => '代码（可选）';

  @override
  String get rdnAccountLabel => 'RDN 账户';

  @override
  String lotQtyHelperSell(String lots) {
    return '拥有 $lots 手';
  }

  @override
  String maxLotError(String lots) {
    return '最大 $lots';
  }

  @override
  String get pricePerShareLabel => '价格/股';

  @override
  String get totalPayLabel => '总支付';

  @override
  String get totalReceiveLabel => '总收入';

  @override
  String get snackBuySuccess => '已记录股票买入。';

  @override
  String get snackSellSuccess => '已记录股票卖出。';

  @override
  String get tabWishlist => '心愿单';

  @override
  String get emptyWishlistTitle => '心愿单为空';

  @override
  String get emptyWishlistSubtitle => '记录您想购买的物品及其价格、\n链接和目标日期。';

  @override
  String get totalTargetBelanja => '总目标';

  @override
  String barangBelumDibeli(String count) {
    return '$count 件物品尚未购买';
  }

  @override
  String get sudahDibeli => '已购买';

  @override
  String get gagalMembukaLink => '无法打开链接。';

  @override
  String get targetDateLabel => '目标日期';

  @override
  String get savingPerMonthSuffix => '/月';

  @override
  String savingProgressLabel(String saved, String total) {
    return '已存 $saved / $total';
  }

  @override
  String savingMonthsRemaining(String months) {
    return ' · 约剩 $months 个月';
  }

  @override
  String get tooltipCatatNabung => '记录存款';

  @override
  String get tooltipBukaLink => '打开链接';

  @override
  String dialogNabungTitle(String name) {
    return '为 $name 存钱';
  }

  @override
  String dialogNabungSisa(String remaining) {
    return '剩余 $remaining';
  }

  @override
  String get dialogNabungJumlah => '存款金额';

  @override
  String get dialogNabungAmbilDari => '从账户扣除';

  @override
  String get dialogNabungTanpaPotong => '不扣除余额';

  @override
  String get cancelButton => '取消';

  @override
  String get recordButton => '记录';

  @override
  String get addWishlist => '添加心愿';

  @override
  String get editWishlist => '编辑心愿';

  @override
  String get itemNameLabel => '物品名称';

  @override
  String get itemNameHint => '例如：iPhone，自行车，笔记本电脑';

  @override
  String get estPriceLabel => '预计价格';

  @override
  String get linkOptionalLabel => '购买链接（可选）';

  @override
  String get priorityLabel => '优先级';

  @override
  String get targetDateOptionalLabel => '目标日期（可选）';

  @override
  String get selectDate => '选择日期';

  @override
  String get savingPlanOptional => '存款计划（可选）';

  @override
  String get savePerMonthLabel => '每月存';

  @override
  String get durationLabel => '期限';

  @override
  String get monthSuffix => '个月';

  @override
  String get calcHelperText => '填写其中一项，另一项将自动计算。';

  @override
  String nabungSelamaHelper(String monthly, String months) {
    return '每月存 $monthly，持续 $months 个月。';
  }

  @override
  String get saveFromAccountLabel => '从账户存钱';

  @override
  String get noneOption => '—';

  @override
  String get reminderDayLabel => '每月提醒日期';

  @override
  String get noReminder => '无';

  @override
  String dateSuffix(String date) {
    return '$date日';
  }

  @override
  String get exportReportTitle => '导出报告';

  @override
  String get exportPeriodLabel => '期间';

  @override
  String get exportTypeFormatLabel => '导出类型和格式';

  @override
  String get exportMonthlyPdf => '月度报告 (PDF)';

  @override
  String get exportMonthlyExcel => '月度报告 (Excel)';

  @override
  String get exportAllExcel => '备份所有数据 (Excel)';

  @override
  String get exportAllExcelSubtitle => '导出所有账户、交易、债务、应收账款、心愿单等。';

  @override
  String get exportNowBtn => '立即导出';

  @override
  String get snackPrepBackup => '正在准备所有数据备份...';

  @override
  String snackPrepMonth(String month) {
    return '正在准备 $month...';
  }

  @override
  String get tabReport => '报告';

  @override
  String get tooltipExport => '导出报告';

  @override
  String get cashFlow6Months => '6个月现金流';

  @override
  String get assetComposition => '资产组成';

  @override
  String get expenseByCategory => '按类别支出';

  @override
  String get summaryIncome => '收入';

  @override
  String get summaryExpense => '支出';

  @override
  String get summaryNet => '净额';

  @override
  String get emptyCashFlow => '暂无现金流显示。';

  @override
  String get pieAssetCash => '现金';

  @override
  String get pieAssetInvestment => '投资';

  @override
  String get pieAssetReceivable => '应收';

  @override
  String get emptyAsset => '暂无资产显示。';

  @override
  String get emptyCategory => '本月无支出。';

  @override
  String get tabMonthlyTx => '月度交易';

  @override
  String get tooltipAddTemplate => '添加模板';

  @override
  String get emptyMonthlyTitle => '还没有月度交易';

  @override
  String get emptyMonthlySubtitle => '设置常规费用（订阅、账单、储蓄），然后\n每个月一次性运行它们。';

  @override
  String runBarIncome(String amount) {
    return '收入 $amount';
  }

  @override
  String runBarExpense(String amount) {
    return '支出 $amount';
  }

  @override
  String runAllBtn(String count) {
    return '全部运行 ($count)';
  }

  @override
  String get confirmRunTitle => '运行月度交易？';

  @override
  String confirmRunContent(String count) {
    return '将创建 $count 笔有效交易，日期为今天。账户余额将更新。';
  }

  @override
  String get confirmRunOk => '运行';

  @override
  String runSuccessWithSkip(String created, String skipped) {
    return '已创建 $created 笔交易，跳过 $skipped 笔（余额不足）。';
  }

  @override
  String runSuccessAll(String created) {
    return '$created 笔月度交易成功运行。';
  }

  @override
  String get addTemplate => '添加模板';

  @override
  String get editTemplate => '编辑模板';

  @override
  String get templateNameHint => '例如：Netflix，电费，储蓄';

  @override
  String get templateCategoryHint => '例如：订阅，账单';

  @override
  String get segmentExpense => '支出';

  @override
  String get segmentIncome => '收入';

  @override
  String get segmentTransfer => '转账';

  @override
  String get amountLabel => '金额';

  @override
  String get fromAccountLabel => '资金来源账户';

  @override
  String get toAccountLabel => '到账户';

  @override
  String get errorSelectAccount => '选择目标账户';

  @override
  String get errorSameAccount => '选择不同的账户';

  @override
  String get categoryLabel => '类别';

  @override
  String get addBillItem => '添加项目';

  @override
  String get menuNameLabel => '项目名称';

  @override
  String get menuNameHint => '例如：炒饭';

  @override
  String get priceLabel => '价格';

  @override
  String get qtyLabel => '数量';

  @override
  String get noOtherBillsToSave => '没有其他人的账单需要保存。';

  @override
  String get saveSplitBillTitle => '保存分账';

  @override
  String get friendBillsLabel => '朋友的账单 (作为应收):';

  @override
  String get myShareLabel => '我的份额';

  @override
  String get fundFromAccountLabel => '我从账户垫付';

  @override
  String get doNotDeductBalance => '— 不扣除余额';

  @override
  String personLabel(String number) {
    return '第 $number 人';
  }

  @override
  String get totalOutFromAccount => '从账户支出的总额';

  @override
  String get totalReceivableRecorded => '记录的应收总额';

  @override
  String receivableSavedDeducted(String count, String amount) {
    return '已记录 $count 笔应收，余额已扣除 $amount。';
  }

  @override
  String get splitBillNotePrefix => '分账';

  @override
  String receivableSavedOnly(String count) {
    return '已保存 $count 笔应收。';
  }

  @override
  String get tabSplitBill => '分账';

  @override
  String get personLabelOnly => '人';

  @override
  String get splitBillEmptyState => '先添加人，然后输入他们各自的项目。';

  @override
  String get deletePersonTooltip => '移除人员';

  @override
  String get meNotBilledLabel => '我 (不计入应收)';

  @override
  String get itemLabel => '项目';

  @override
  String get sharedItemsLabel => '共享项目 (平分)';

  @override
  String get addSharedItemLabel => '共享项目';

  @override
  String get taxAndDiscountLabel => '税费、附加费和折扣';

  @override
  String get ppnLabel => '税';

  @override
  String get serviceChargeLabel => '服务费';

  @override
  String get discountLabel => '折扣';

  @override
  String get additionalFeesLabel => '附加费用';

  @override
  String get percentageLabel => '百分比';

  @override
  String get nominalLabel => '金额';

  @override
  String get splitDiscountEvenlyLabel => '平分折扣';

  @override
  String get discountEvenlyDesc => '每个人获得相同的折扣';

  @override
  String get discountProportionalDesc => '折扣按订单金额成比例';

  @override
  String get detailsLabel => '详情';

  @override
  String get subtotalLabel => '小计';

  @override
  String get totalLabel => '总计';

  @override
  String get billPerPersonLabel => '每人账单';

  @override
  String get unnamedLabel => '(未命名)';

  @override
  String get saveToReceivablesBtn => '保存为应收账款';

  @override
  String get splitBillShare => '分享';

  @override
  String get splitBillCopied => '分账详情已复制。';

  @override
  String get splitBillShareFailed => '无法分享分账详情。';

  @override
  String get createAccountSubtitle => '创建新账户';

  @override
  String get loginSubtitle => '登录您的账户';

  @override
  String get registerButton => '注册';

  @override
  String get loginButton => '登录';

  @override
  String get orDividerLabel => '或';

  @override
  String get loginWithGoogleBtn => '使用谷歌登录';

  @override
  String get alreadyHaveAccountBtn => '已经有账户了？登录';

  @override
  String get dontHaveAccountBtn => '还没有账户？注册';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get emailRequired => '电子邮件必填';

  @override
  String get emailInvalid => '电子邮件格式无效';

  @override
  String get passwordLabel => '密码';

  @override
  String get passwordRequired => '密码必填';

  @override
  String get passwordMinLen => '至少 6 个字符';

  @override
  String get nameRequired => '姓名必填';

  @override
  String get passwordConfirmLabel => '确认密码';

  @override
  String get requiredField => '必填字段';

  @override
  String get passwordNotMatch => '密码不匹配';

  @override
  String get completeAccountTitle => '完善账户';

  @override
  String completeAccountDesc(String email) {
    return '您已使用 $email 登录。创建一个密码以完成注册。之后，您可以使用您的电子邮件和密码登录。';
  }

  @override
  String get saveAndContinueBtn => '保存并继续';

  @override
  String get logoutButton => '登出';

  @override
  String get wrongPassword => '密码错误。';

  @override
  String get invalidRecoveryKey => '恢复密钥无效。';

  @override
  String get unlockDataTitle => '解锁数据';

  @override
  String get unlockRecoveryDesc => '输入您的恢复密钥和新密码以解锁此设备上的数据。';

  @override
  String get unlockPasswordDesc => '输入您的密码以解锁此设备上的数据。每台设备仅需一次。';

  @override
  String get unlockBtn => '解锁';

  @override
  String get forgotPasswordBtn => '忘记密码？';

  @override
  String get recoveryKeyLabel => '恢复密钥';

  @override
  String get recoveryKeyHint => 'XXXX-XXXX-XXXX-...';

  @override
  String get newPasswordLabel => '新密码';

  @override
  String get confirmNewPasswordLabel => '确认新密码';

  @override
  String get unlockAndChangePassBtn => '解锁并更改密码';

  @override
  String get rememberPasswordBtn => '我记得我的密码';

  @override
  String get upgradeSecurityTitle => '升级数据安全';

  @override
  String get upgradeSecurityDesc =>
      '您的财务数据现在将在保存到云端之前被加密 — 甚至项目所有者也无法读取它。输入您的密码以开始。';

  @override
  String get currentPasswordLabel => '当前密码';

  @override
  String get startEncryptionBtn => '开始加密';

  @override
  String get saveRecoveryKeyTitle => '保存恢复密钥';

  @override
  String get saveRecoveryKeyDesc =>
      '这是您忘记密码时解锁数据的唯一方法。我们不存储它。请复制并保存在安全的地方（例如密码管理器）。如果没有它和您的密码，您的数据将无法恢复。';

  @override
  String get recoveryKeyCopied => '密钥已复制。';

  @override
  String get copyKeyBtn => '复制密钥';

  @override
  String get iHaveSavedItBtn => '我已保存';

  @override
  String get addAccountFirst => '请先在“账户”选项卡中添加一个账户。';

  @override
  String payDebtTitle(String name) {
    return '支付 $name';
  }

  @override
  String debtRemainingLabel(String amount) {
    return '剩余债务: $amount';
  }

  @override
  String get payAmountLabel => '支付金额';

  @override
  String balanceHelper(String name, String amount) {
    return '$name 余额: $amount';
  }

  @override
  String exceedsDebtRemaining(String amount) {
    return '超过剩余债务 ($amount)';
  }

  @override
  String exceedsBalance(String amount) {
    return '超过余额 ($amount)';
  }

  @override
  String get payFromLabel => '支付自';

  @override
  String get payNowBtn => '立即支付';

  @override
  String paymentRecorded(String amount) {
    return '已记录 $amount 的付款。';
  }

  @override
  String get editDebtTitle => '编辑债务';

  @override
  String get addDebtTitle => '添加债务';

  @override
  String get debtNameHint => '例如：抵押贷款，信用卡';

  @override
  String get debtRemainingInputLabel => '剩余债务';

  @override
  String get monthlyPaymentOptional => '月供（可选）';

  @override
  String get dueDateOptional => '到期日（可选）';

  @override
  String get selectDateBtn => '选择日期';

  @override
  String collectFromTitle(String name) {
    return '收到来自 $name';
  }

  @override
  String totalOutstanding(String amount) {
    return '剩余总额: $amount';
  }

  @override
  String loanCount(int count) {
    return '$count 笔贷款';
  }

  @override
  String get fifoPaymentNote => '付款将优先结清最早的贷款。';

  @override
  String get amountReceivedLabel => '收到金额';

  @override
  String exceedsTotalOutstanding(String amount) {
    return '超过剩余总额 ($amount)';
  }

  @override
  String get receiveIntoLabel => '存入';

  @override
  String get receiveNowBtn => '立即接收';

  @override
  String receivedAmount(String amount) {
    return '已收到 $amount。';
  }

  @override
  String get editReceivableTitle => '编辑应收账款';

  @override
  String get addReceivableTitle => '添加应收账款';

  @override
  String get personNameLabel => '人员姓名';

  @override
  String get personNameHint => '例如：张三';

  @override
  String get receivableAmountLabel => '应收金额';

  @override
  String get noteOptional => '备注（可选）';

  @override
  String get noteReceivableHint => '例如：在 X 餐厅的晚餐';

  @override
  String get fundNowTitle => '我现在资助';

  @override
  String get fundNowSubtitle => '资金将从我的账户中扣除';

  @override
  String get reminderActiveDesc => '提醒已激活。在下方设置时间。';

  @override
  String get reminderNoPermission => '通知权限被拒绝。请在手机设置中启用。';

  @override
  String get reminderDisabled => '提醒已关闭。';

  @override
  String reminderDailySetTo(String time) {
    return '每日提醒设置为 $time。';
  }

  @override
  String get dailyReminderTime => '每日提醒时间';

  @override
  String dailyReminderDesc(String time) {
    return '每天 $time';
  }

  @override
  String get alreadyLatestVersion => '您已使用最新版本。';

  @override
  String get autoUpdateAndroidOnly => '自动更新仅在 Android 上可用。';

  @override
  String get updateCheckFailed => '检查更新失败。请检查网络连接。';

  @override
  String get updateCheck => '检查更新';

  @override
  String get updateCheckDesc => '检查并安装最新版本';

  @override
  String get renameTitle => '更改名称';

  @override
  String get passwordChanged => '密码修改成功。';

  @override
  String get deleteAccountTitle => '删除账户？';

  @override
  String get deletePermanently => '永久删除';

  @override
  String recoveryKeyCreateFailed(String error) {
    return '创建恢复密钥失败：$error';
  }

  @override
  String get recoveryKeyNew => '新恢复密钥';

  @override
  String get copy => '复制';

  @override
  String get done => '完成';

  @override
  String get recoveryKeyNewDesc => '出于安全原因，系统不会保存您的旧恢复密钥。我们将为您创建一个新的恢复密钥。';

  @override
  String get updateMandatory => '必须安装此更新。';

  @override
  String downloading(String pct) {
    return '下载中... $pct%';
  }

  @override
  String get skip => '跳过';

  @override
  String get editAccount => '编辑账户';

  @override
  String get accountNameHint => '例如：工商银行，支付宝，钱包';

  @override
  String get accountNumber => '账号';

  @override
  String get initialBalance => '初始余额';

  @override
  String get balance => '余额';

  @override
  String get editTx => '编辑交易';

  @override
  String get noteOptionalTx => '备注（可选）';

  @override
  String get date => '日期';

  @override
  String get adminFeeOptional => '转账费（可选）';

  @override
  String get invalidAmount => '请输入有效金额';

  @override
  String get invalidAdminFee => '请输入有效管理费';

  @override
  String get adminFeeDesc => '收款人收到全额；管理费从源账户扣除';

  @override
  String totalOut(String amount) {
    return '源账户总支出：$amount';
  }

  @override
  String get priorityLow => '低';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityHigh => '高';

  @override
  String get noTxTodayTitle => '今天没有交易';

  @override
  String get noTxTodayDesc => '记录您的收入或支出，掌握财务状况。';

  @override
  String get salarySaveTitle => '发工资了？存点钱吧';

  @override
  String salarySaveDesc(String names) {
    return '别忘了为以下目标存钱：$names。';
  }

  @override
  String timeToSaveTitle(String name) {
    return '该存钱了：$name';
  }

  @override
  String timeToSaveDescAmount(String amount) {
    return '这个月存 $amount。';
  }

  @override
  String get timeToSaveDescGeneral => '为这个目标存点资金吧。';

  @override
  String reportTitle(String periodName) {
    return 'MoneyWork 交易报告 - $periodName';
  }

  @override
  String reportPrintedOn(String date) {
    return '打印日期：$date';
  }

  @override
  String get reportCashflowSummary => '现金流摘要';

  @override
  String reportIncome(String amount) {
    return '收入：$amount';
  }

  @override
  String reportExpense(String amount) {
    return '支出：$amount';
  }

  @override
  String reportNet(String amount) {
    return '净余额：$amount';
  }

  @override
  String get reportExpenseByCategory => '按类别支出';

  @override
  String get reportTxDetail => '交易明细';

  @override
  String get reportLegendOut => '支出';

  @override
  String get reportLegendIn => '收入';

  @override
  String get reportType => '类型';

  @override
  String get reportDate => '日期';

  @override
  String get reportAmount => '金额';

  @override
  String get notifSaveTime => '存钱时间 💰';

  @override
  String notifSaveAmount(String amount, String name) {
    return '为 $name 存入 $amount。';
  }

  @override
  String notifSaveGeneral(String name) {
    return '是时候为 $name 存钱了。';
  }

  @override
  String get accountTypeCash => '现金';

  @override
  String get accountTypeBank => '银行';

  @override
  String get accountTypeEwallet => '电子钱包';

  @override
  String get accountTypeRdn => 'RDN（股票）';

  @override
  String get debtTypeLoan => '贷款';

  @override
  String get debtTypeCreditCard => '信用卡';

  @override
  String get debtTypeInstallment => '分期付款';

  @override
  String get debtTypeOther => '其他';

  @override
  String get invTypeStock => '股票';

  @override
  String get invTypeMutualFund => '共同基金';

  @override
  String get invTypeCrypto => '加密货币';

  @override
  String get invTypeGold => '黄金';

  @override
  String get invTypeOther => '其他';

  @override
  String get salaryAllocateTitle => '是时候安排本月预算了';

  @override
  String get salaryAllocateDesc => '工资到了，快分配到各个账户和支出项目吧。';

  @override
  String get highExpenseTitle => '每日支出较高';

  @override
  String highExpenseDesc(String avg) {
    return '本月平均每天 $avg。试着控制一下吧。';
  }

  @override
  String get editAccountTitle => '编辑账户';

  @override
  String get deleteTransactionWarning => '账户余额将相应调整。此操作无法撤销。';

  @override
  String get deleteAccountWarning => '与此账户相关的所有交易也将被删除。';

  @override
  String get labelAccountName => '账户名称';

  @override
  String get hintAccountName => '例如 招商银行、支付宝、现金';

  @override
  String get validationRequired => '必填';

  @override
  String get labelAccountType => '类型';

  @override
  String get labelEwalletNumber => '手机号 / 电子钱包账号';

  @override
  String get labelBankNumber => '银行卡号';

  @override
  String get hintOptional => '可选';

  @override
  String get labelBalance => '余额';

  @override
  String get labelInitialBalance => '初始余额';

  @override
  String get validationInvalidNumber => '数字无效';

  @override
  String get recordTransactionTitle => '记录交易';

  @override
  String get labelAmount => '金额';

  @override
  String helperBalance(String name, String balance) {
    return '$name 余额：$balance';
  }

  @override
  String get validationInvalidAmount => '请输入有效金额';

  @override
  String validationExceedBalance(String balance) {
    return '超过余额 ($balance)';
  }

  @override
  String get labelFromAccount => '从账户';

  @override
  String get labelToAccount => '到账户';

  @override
  String get validationSelectDest => '请选择目标账户';

  @override
  String get validationDiffAccount => '请选择不同的账户';

  @override
  String get adminFeeSubtitle => '从源账户扣除，单独记录';

  @override
  String get labelAdminFee => '手续费';

  @override
  String get helperAdminFee => '目标账户收到全额；手续费从源账户扣除';

  @override
  String get validationAdminFee => '请输入有效的手续费';

  @override
  String get labelCategory => '类别';

  @override
  String get hintCategory => '例如 餐饮、工资、交通';

  @override
  String get labelNote => '备注（可选）';

  @override
  String get labelDate => '日期';

  @override
  String get updateAvailable => '有可用更新';

  @override
  String updateVersion(String version) {
    return '更新 $version';
  }

  @override
  String get updateDefaultNotes => '新版本已发布。';

  @override
  String get updateBtn => '更新';

  @override
  String get retryBtn => '重试';

  @override
  String get excelHeaderDate => '日期';

  @override
  String get excelHeaderType => '类型';

  @override
  String get excelHeaderCategory => '类别';

  @override
  String get excelHeaderAmount => '金额';

  @override
  String get excelHeaderAccount => '账户';

  @override
  String get excelHeaderNote => '备注';

  @override
  String reportPrintedAt(String date) {
    return '打印日期：$date';
  }

  @override
  String get legendIncome => '收入';

  @override
  String get legendExpense => '支出';

  @override
  String get noTransactionPeriod => '该时间段无交易记录。';

  @override
  String shareReportText(String period) {
    return 'MoneyWork 交易报告 $period';
  }

  @override
  String get excelHeaderBalance => '余额';

  @override
  String get excelHeaderBankNo => '账号';

  @override
  String get excelHeaderCreatedAt => '创建日期';

  @override
  String get excelHeaderLender => '债权人（名称）';

  @override
  String get excelHeaderDebtRemaining => '剩余债务';

  @override
  String get excelHeaderMonthlyPayment => '月供';

  @override
  String get excelHeaderDueDate => '到期日';

  @override
  String get excelHeaderBorrower => '借款人（名称）';

  @override
  String get excelHeaderRecNote => '标题/备注';

  @override
  String get excelHeaderRecRemaining => '剩余应收';

  @override
  String get excelHeaderAssetName => '资产名称';

  @override
  String get excelHeaderTicker => '代码';

  @override
  String get excelHeaderQuantity => '数量';

  @override
  String get excelHeaderBuyPrice => '买入价';

  @override
  String get excelHeaderCurrentPrice => '当前价';

  @override
  String get excelHeaderTotalCost => '总成本';

  @override
  String get excelHeaderTotalMarket => '总市值';

  @override
  String get excelHeaderReturn => '收益率 (%)';

  @override
  String get excelHeaderItemName => '物品名称';

  @override
  String get excelHeaderTargetPrice => '目标价格';

  @override
  String get excelHeaderSaved => '已存';

  @override
  String get excelHeaderPriority => '优先级';

  @override
  String get excelHeaderStatus => '状态';

  @override
  String get excelHeaderTargetDate => '目标日期';

  @override
  String get statusPurchased => '已购买';

  @override
  String get statusNotPurchased => '未购买';

  @override
  String get excelHeaderLabel => '标签';

  @override
  String get excelHeaderNominal => '金额';

  @override
  String get excelHeaderActiveStatus => '启用状态';

  @override
  String get statusActive => '启用';

  @override
  String get statusInactive => '停用';

  @override
  String shareBackupText(String date) {
    return 'MoneyWork 全部数据备份 ($date)';
  }

  @override
  String get excelSheetAccounts => '账户';

  @override
  String get excelSheetTransactions => '交易';

  @override
  String get excelSheetDebts => '债务';

  @override
  String get excelSheetReceivables => '应收';

  @override
  String get excelSheetInvestments => '投资';

  @override
  String get excelSheetRecurring => '定期';

  @override
  String get priceErrNoTicker => '请先填写代码/符号。';

  @override
  String get priceErrUnsupported => '此类型暂不支持自动定价。';

  @override
  String get priceErrFetch => '获取价格失败。请检查网络连接。';

  @override
  String priceErrServer(int code) {
    return 'CoinGecko 服务器错误 ($code)。';
  }

  @override
  String priceErrNotFound(String id) {
    return '在 CoinGecko 上未找到代码 \"$id\"。';
  }

  @override
  String get priceErrStockNotReady => '股票自动定价尚未启用（后端未部署）。';

  @override
  String priceErrStockServer(int code) {
    return '股票价格服务器错误 ($code)。';
  }

  @override
  String priceErrStockNotFound(String code) {
    return '未找到股票代码 \"$code\"。';
  }

  @override
  String get categoryOther => '其他';

  @override
  String errorLoadSession(String error) {
    return '加载会话失败：$error';
  }

  @override
  String errorLoadSecurity(String error) {
    return '加载安全状态失败：$error';
  }

  @override
  String get notifDailyTitle => '记录今天的交易';

  @override
  String get notifDailyBody => '别忘了在 MoneyWork 中记录你的收支。';

  @override
  String get notifSaveTitle => '该存钱啦 💰';

  @override
  String get receiptReview => '账单审核';

  @override
  String get receiptVerified => '✅ 总计匹配 — 数据已就绪';

  @override
  String get receiptMismatch => '⚠️ 总计不匹配 — 请检查下方数字';

  @override
  String get receiptItemName => '商品名称';

  @override
  String get receiptQty => '数量';

  @override
  String get receiptUnitPrice => '单价';

  @override
  String get receiptServiceCharge => '服务费';

  @override
  String get receiptTax => '税';

  @override
  String get receiptDiscount => '折扣';

  @override
  String get receiptGrandTotalPaper => '总计（纸面）';

  @override
  String get receiptGrandTotalCalc => '总计（计算）';

  @override
  String get receiptSaveAsTransaction => '保存为交易';

  @override
  String get receiptSplitBill => '分账';

  @override
  String get receiptScanning => '正在扫描账单...';

  @override
  String get receiptScanFailed => '扫描账单失败';

  @override
  String get scanFromCamera => '相机';

  @override
  String get scanFromGallery => '相册';

  @override
  String get scanChooseSource => '选择照片来源';

  @override
  String get assignItemsTitle => '分配商品';

  @override
  String get howManyPeople => '有多少人参与分账？';

  @override
  String get nextStep => '下一步';

  @override
  String get enterNames => '输入每个人的姓名';

  @override
  String personNumber(int number) {
    return '第 $number 个人';
  }

  @override
  String selectItemsFor(String name) {
    return '选择 $name 的商品';
  }

  @override
  String get calculateSplit => '计算分账';

  @override
  String get editTransactionTitle => '编辑交易';
}
