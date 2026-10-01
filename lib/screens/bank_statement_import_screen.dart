import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/bank_statement_import_service.dart';
import '../widgets/responsive_layout.dart';

/// Memilih PDF mutasi, menampilkan hasil ekstraksi dan mengembalikan pilihan
/// transaksi. Tidak menyimpan transaksi; pemanggil melakukan satu bulk commit.
class BankStatementImportScreen extends StatefulWidget {
  const BankStatementImportScreen({
    super.key,
    required this.accounts,
    required this.existingTransactions,
    required this.statementScanEndpoint,
  });

  final List<Account> accounts;
  final List<Transaction> existingTransactions;
  final Uri statementScanEndpoint;

  @override
  State<BankStatementImportScreen> createState() =>
      _BankStatementImportScreenState();
}

class _BankStatementImportScreenState extends State<BankStatementImportScreen> {
  Uint8List? _pdfBytes;
  String? _fileName;
  String? _accountId;
  BankStatementDocument? _document;
  final Map<int, StatementTransactionDraft> _edited = {};
  final Set<int> _selected = {};
  bool _consent = false;
  bool _busy = false;
  bool _applyToBalance = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _accountId = widget.accounts
          .where((a) => a.type == AccountType.bank || a.type == AccountType.ewallet)
          .firstOrNull?.id ?? widget.accounts.first.id;
    }
  }

  List<ReviewedStatementRow> get _reviewedRows {
    final document = _document;
    final accountId = _accountId;
    if (document == null || accountId == null) return const [];
    return BankStatementImportService.reviewDuplicates(
      accountId: accountId,
      imported: [
        for (var i = 0; i < document.rows.length; i++)
          _edited[i] ?? document.rows[i],
      ],
      existing: widget.existingTransactions,
    );
  }

  double? get _reviewBalanceDifference {
    final document = _document;
    if (document?.openingBalance == null ||
        document?.closingBalance == null) {
      return null;
    }
    final net = _reviewedRows.fold<double>(0, (sum, reviewed) {
      final row = reviewed.draft;
      return sum + (row.type == TxType.income ? row.amount : -row.amount);
    });
    return document!.openingBalance! + net - document.closingBalance!;
  }

  void _selectRecommended() {
    _selected.clear();
    final rows = _reviewedRows;
    for (var i = 0; i < rows.length; i++) {
      if (!rows[i].possibleDuplicate) _selected.add(i);
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      if (result == null || !mounted) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const BankStatementImportException(
            'File tidak bisa dibaca. Simpan PDF ke perangkat, lalu pilih lagi.');
      }
      BankStatementImportService.validatePdf(bytes);
      setState(() {
        _pdfBytes = bytes;
        _fileName = file.name;
        _document = null;
        _edited.clear();
        _selected.clear();
        _consent = false;
        _error = null;
      });
    } on BankStatementImportException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'PDF tidak bisa dipilih. Periksa izin file dan coba lagi.');
      }
    }
  }

  Future<void> _scanPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null || !_consent) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = BankStatementImportService(
        endpoint: widget.statementScanEndpoint);
    try {
      final document = await service.scanPdf(bytes);
      if (!mounted) return;
      setState(() {
        _document = document;
        _pdfBytes = null;
        _edited.clear();
        _selectRecommended();
      });
    } on BankStatementImportException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Gagal membaca PDF mutasi. Coba lagi beberapa saat.');
      }
    } finally {
      service.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editRow(int index) async {
    final original = _edited[index] ?? _document!.rows[index];
    final dateController = TextEditingController(
        text: '${original.date.year.toString().padLeft(4, '0')}-'
            '${original.date.month.toString().padLeft(2, '0')}-'
            '${original.date.day.toString().padLeft(2, '0')}');
    final amountController = TextEditingController(
        text: original.amount == original.amount.roundToDouble()
            ? original.amount.toStringAsFixed(0)
            : original.amount.toStringAsFixed(2).replaceAll('.', ','));
    final noteController = TextEditingController(text: original.note);
    final categoryController = TextEditingController(text: original.category);
    var type = original.type;
    String? validationError;
    final changed = await showDialog<StatementTransactionDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(_text.editTransaction),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dateController,
                    decoration: InputDecoration(
                      labelText: _text.date,
                      hintText: 'YYYY-MM-DD',
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TxType>(
                    initialValue: type,
                    decoration: InputDecoration(labelText: _text.direction),
                    items: [
                      DropdownMenuItem(value: TxType.expense,
                          child: Text(_text.debit)),
                      DropdownMenuItem(value: TxType.income,
                          child: Text(_text.credit)),
                    ],
                    onChanged: (value) => setDialogState(() => type = value ?? type),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: _text.amount,
                        prefixText: 'Rp '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: InputDecoration(labelText: _text.description),
                    maxLength: 200,
                  ),
                  TextFormField(
                    controller: categoryController,
                    decoration: InputDecoration(labelText: _text.category),
                    maxLength: 80,
                  ),
                  if (validationError != null)
                    Text(validationError!, style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_text.cancel),
            ),
            FilledButton(
              onPressed: () {
                final date = BankStatementImportService.parseIsoDate(
                    dateController.text);
                final amount = BankStatementImportService.parseMoney(
                    amountController.text);
                if (date == null || amount == null || amount <= 0 ||
                    noteController.text.trim().isEmpty) {
                  setDialogState(() => validationError = _text.invalidEdit);
                  return;
                }
                Navigator.pop(dialogContext, original.copyWith(
                  date: date,
                  type: type,
                  amount: amount,
                  note: noteController.text.trim(),
                  category: categoryController.text.trim(),
                ));
              },
              child: Text(_text.save),
            ),
          ],
        ),
      ),
    );
    dateController.dispose();
    amountController.dispose();
    noteController.dispose();
    categoryController.dispose();
    if (changed != null && mounted) {
      setState(() => _edited[index] = changed);
    }
  }

  Future<void> _approve() async {
    final accountId = _accountId;
    final document = _document;
    if (accountId == null || document == null || _selected.isEmpty) return;
    final reviewed = _reviewedRows;
    final picked = _selected.toList()..sort();
    final selectedRows = [for (final i in picked) reviewed[i].draft];
    final duplicateCount = picked.where((i) => reviewed[i].possibleDuplicate).length;
    final income = selectedRows.where((r) => r.type == TxType.income)
        .fold<double>(0, (sum, r) => sum + r.amount);
    final expense = selectedRows.where((r) => r.type == TxType.expense)
        .fold<double>(0, (sum, r) => sum + r.amount);
    final balanceDifference = _reviewBalanceDifference;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text.confirmTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_text.confirmSummary(selectedRows.length,
                  Fmt.rupiah(income), Fmt.rupiah(expense))),
              const SizedBox(height: 8),
              Text(_applyToBalance
                  ? _text.balanceWillChange
                  : _text.historyOnly),
              if (duplicateCount > 0) ...[
                const SizedBox(height: 8),
                Text(_text.duplicatesSelected(duplicateCount)),
              ],
              if (document.issues.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_text.rowsUnreadable(document.issues.length)),
              ],
              if (balanceDifference != null && balanceDifference.abs() > 1) ...[
                const SizedBox(height: 8),
                Text(_text.balanceMismatch(Fmt.rupiah(balanceDifference.abs()))),
              ],
              const SizedBox(height: 8),
              Text(_text.reviewReminder),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_text.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_text.importButton),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, StatementImportApproval(
        accountId: accountId,
        rows: selectedRows,
        applyToBalance: _applyToBalance,
      ));
    }
  }

  _BankImportText get _text =>
      _BankImportText(Localizations.localeOf(context).languageCode);

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final document = _document;
    final reviewed = _reviewedRows;
    return Scaffold(
      appBar: AppBar(title: Text(text.title)),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(text.intro, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (widget.accounts.isEmpty)
              Text(text.noAccounts)
            else
              DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: InputDecoration(labelText: text.destinationAccount),
                items: [
                  for (final account in widget.accounts)
                    DropdownMenuItem(value: account.id, child: Text(account.name)),
                ],
                onChanged: _busy ? null : (value) => setState(() {
                  _accountId = value;
                  _selectRecommended();
                }),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(text.choosePdf),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(_fileName!, overflow: TextOverflow.ellipsis),
            ],
            if (_pdfBytes != null && document == null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.privacyDisclosure),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _consent,
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _consent = value ?? false),
                        title: Text(text.consent),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy || !_consent ? null : _scanPdf,
                          icon: _busy
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.document_scanner_outlined),
                          label: Text(_busy ? text.scanning : text.scanButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
            ],
            if (document != null) ...[
              const SizedBox(height: 20),
              Text(text.reviewTitle(document.rows.length, document.pageCount),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(text.reviewReminder),
              if (document.issues.isNotEmpty) ...[
                const SizedBox(height: 8),
                _WarningCard(text.rowsUnreadable(document.issues.length)),
                for (final issue in document.issues)
                  Text(text.rowIssue(issue.row, issue.reason),
                      style: Theme.of(context).textTheme.bodySmall),
              ],
              if (_reviewBalanceDifference case final difference?)
                if (difference.abs() > 1) ...[
                  const SizedBox(height: 8),
                  _WarningCard(text.balanceMismatch(Fmt.rupiah(difference.abs()))),
                ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(_selectRecommended),
                child: Text(text.selectRecommended),
              ),
              for (var i = 0; i < reviewed.length; i++)
                _transactionCard(i, reviewed[i], text),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _applyToBalance,
                onChanged: (value) => setState(() => _applyToBalance = value),
                title: Text(text.applyBalanceTitle),
                subtitle: Text(text.applyBalanceSubtitle),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _selected.isEmpty ? null : _approve,
                icon: const Icon(Icons.save_outlined),
                label: Text(text.importCount(_selected.length)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _transactionCard(int index, ReviewedStatementRow reviewed,
      _BankImportText text) {
    final row = reviewed.draft;
    final selected = _selected.contains(index);
    final color = row.type == TxType.income
        ? Colors.green.shade700 : Theme.of(context).colorScheme.error;
    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (value) => setState(() {
              if (value == true) {
                _selected.add(index);
              } else {
                _selected.remove(index);
              }
            }),
            title: Text(Fmt.rupiahSigned(
                row.type == TxType.income ? row.amount : -row.amount),
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            subtitle: Text('${Fmt.date(row.date)} • ${row.note}'
                '${row.page == null ? '' : ' • ${text.page} ${row.page}'}'),
            secondary: IconButton(
              tooltip: text.editTransaction,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editRow(index),
            ),
          ),
          if (reviewed.possibleDuplicate)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(reviewed.duplicateInFile
                    ? text.duplicateInFile : text.possibleDuplicate,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(message),
        ),
      );
}

/// Salinan singkat untuk alur baru; mengikuti bahasa UI tanpa menambah
/// ketergantungan pada kelas l10n yang dihasilkan kode.
class _BankImportText {
  const _BankImportText(this.language);
  final String language;

  String _pick(String id, String en, String zh) =>
      switch (language) {'en' => en, 'zh' => zh, _ => id};

  String get title => _pick('Impor Mutasi PDF', 'Import PDF Statement', '导入 PDF 对账单');
  String get intro => _pick(
      'Impor transaksi dari PDF mutasi bulanan bank atau e-wallet. Periksa setiap baris sebelum menyimpan.',
      'Import transactions from a monthly bank or e-wallet PDF statement. Review every row before saving.',
      '从银行或电子钱包月度 PDF 对账单导入交易。保存前请检查每一行。');
  String get noAccounts => _pick('Buat akun terlebih dahulu.',
      'Create an account first.', '请先创建账户。');
  String get destinationAccount => _pick('Akun tujuan', 'Destination account', '目标账户');
  String get choosePdf => _pick('Pilih PDF mutasi', 'Choose statement PDF', '选择对账单 PDF');
  String get privacyDisclosure => _pick(
      'PDF mutasi lengkap, termasuk informasi rekening yang tercetak, akan dikirim ke Cloudflare Worker MoneyWork dan Gemini untuk ekstraksi. Data transaksi hanya disimpan setelah Anda meninjaunya.',
      'The full statement PDF, including any printed account details, will be sent to the MoneyWork Cloudflare Worker and Gemini for extraction. Transactions are saved only after your review.',
      '完整的对账单 PDF（包括其中的账户信息）将发送至 MoneyWork Cloudflare Worker 和 Gemini 进行提取。交易仅在您审核后保存。');
  String get consent => _pick('Saya setuju mengirim PDF ini untuk dianalisis.',
      'I agree to send this PDF for analysis.', '我同意发送此 PDF 进行分析。');
  String get scanButton => _pick('Baca PDF', 'Read PDF', '读取 PDF');
  String get scanning => _pick('Membaca PDF...', 'Reading PDF...', '正在读取 PDF...');
  String reviewTitle(int rows, int pages) => _pick(
      'Tinjau $rows transaksi dari $pages halaman',
      'Review $rows transactions from $pages pages',
      '检查 $pages 页中的 $rows 笔交易');
  String get reviewReminder => _pick(
      'Hasil pembacaan PDF bisa keliru. Bandingkan tanggal, nominal, dan uraian dengan dokumen asli.',
      'PDF extraction can be wrong. Compare dates, amounts, and descriptions with the original document.',
      'PDF 识别结果可能有误。请与原文档核对日期、金额和说明。');
  String get selectRecommended => _pick('Pilih semua kecuali duplikat',
      'Select all except duplicates', '选择除重复项外的所有交易');
  String get page => _pick('hlm.', 'page', '页');
  String get possibleDuplicate => _pick(
      'Mungkin sudah tercatat — tidak dipilih otomatis',
      'Possibly already recorded — not selected automatically',
      '可能已记录 — 默认不选择');
  String get duplicateInFile => _pick(
      'Baris serupa ada di PDF ini — tidak dipilih otomatis',
      'Similar row in this PDF — not selected automatically',
      '此 PDF 中有相似记录 — 默认不选择');
  String get editTransaction => _pick('Koreksi transaksi',
      'Correct transaction', '修正交易');
  String get date => _pick('Tanggal', 'Date', '日期');
  String get direction => _pick('Arah mutasi', 'Direction', '交易方向');
  String get debit => _pick('Debit / keluar', 'Debit / out', '借记 / 支出');
  String get credit => _pick('Kredit / masuk', 'Credit / in', '贷记 / 收入');
  String get amount => _pick('Nominal', 'Amount', '金额');
  String get invalidEdit => _pick(
      'Isi tanggal YYYY-MM-DD, nominal positif, dan uraian.',
      'Enter a YYYY-MM-DD date, a positive amount, and a description.',
      '请输入 YYYY-MM-DD 日期、正数金额和说明。');
  String get description => _pick('Uraian', 'Description', '说明');
  String get category => _pick('Kategori', 'Category', '类别');
  String get cancel => _pick('Batal', 'Cancel', '取消');
  String get save => _pick('Simpan', 'Save', '保存');
  String get applyBalanceTitle => _pick('Terapkan ke saldo saat ini',
      'Apply to current balance', '计入当前余额');
  String get applyBalanceSubtitle => _pick(
      'Default mati: catat sebagai riwayat tanpa mengubah saldo. Hidupkan hanya bila saldo akun sekarang belum mencakup mutasi ini.',
      'Off by default: record history without changing the balance. Turn on only if the current account balance does not yet include these transactions.',
      '默认关闭：仅记录历史，不改变余额。仅当当前账户余额尚未包含这些交易时才打开。');
  String importCount(int count) => _pick('Tinjau impor $count transaksi',
      'Review import of $count transactions', '检查导入 $count 笔交易');
  String get confirmTitle => _pick('Konfirmasi impor', 'Confirm import', '确认导入');
  String confirmSummary(int count, String income, String expense) => _pick(
      '$count transaksi dipilih. Pemasukan $income, pengeluaran $expense.',
      '$count transactions selected. Income $income, expenses $expense.',
      '已选择 $count 笔交易。收入 $income，支出 $expense。');
  String get balanceWillChange => _pick(
      'Saldo saat ini akan berubah sesuai transaksi yang diimpor.',
      'Current balance will change according to the imported transactions.',
      '当前余额将随导入交易变化。');
  String get historyOnly => _pick('Saldo saat ini tidak akan berubah.',
      'Current balance will not change.', '当前余额不会改变。');
  String duplicatesSelected(int count) => _pick(
      '$count transaksi yang ditandai kemungkinan duplikat tetap dipilih.',
      '$count possible duplicates are still selected.',
      '仍选择了 $count 笔可能重复的交易。');
  String rowsUnreadable(int count) => _pick(
      '$count baris tidak valid tidak akan diimpor. Periksa PDF dan catat manual bila perlu.',
      '$count invalid rows will not be imported. Check the PDF and record them manually if needed.',
      '$count 行无效且不会导入。请检查 PDF，必要时手动记录。');
  String rowIssue(int row, String reason) => _pick('Baris $row: $reason',
      'Row $row: $reason', '第 $row 行：$reason');
  String balanceMismatch(String amount) => _pick(
      'Selisih saldo awal + mutasi - saldo akhir: $amount. Periksa baris yang hilang atau keliru.',
      'Opening balance + transactions differs from closing balance by $amount. Check for missing or incorrect rows.',
      '期初余额加交易与期末余额相差 $amount。请检查缺失或错误的记录。');
  String get importButton => _pick('Setujui & impor', 'Approve & import', '批准并导入');
}
