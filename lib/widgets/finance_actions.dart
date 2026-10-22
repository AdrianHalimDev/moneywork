import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/bank_statement_import_screen.dart';
import '../screens/receipt_scanner_screen.dart';
import '../services/bank_statement_import_service.dart';
import '../services/receipt_scanner_service.dart';

const _worker = 'https://moneywork-ocr.tompel-adrian-6ef.workers.dev';

Future<void> importBankStatement(
    BuildContext context, WidgetRef ref, AppState state) async {
  final l10n = AppLocalizations.of(context)!;
  final approval = await Navigator.of(context).push<StatementImportApproval>(
    MaterialPageRoute(
        builder: (_) => BankStatementImportScreen(
              accounts: state.orderedAccounts,
              existingTransactions: state.transactions,
              statementScanEndpoint: Uri.parse('$_worker/statement-scan'),
            )),
  );
  if (approval == null || !context.mounted) return;
  final result = await ref
      .read(appStateProvider.notifier)
      .importStatementTransactions(approval);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
    result.error ??
        [
          l10n.importSuccess(result.importedCount),
          if (result.skippedCount > 0) l10n.importSkipped(result.skippedCount),
        ].join(' '),
  )));
}

void showReceiptScanOptions(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in [
          (ImageSource.camera, Icons.camera_alt_outlined, l10n.scanFromCamera),
          (
            ImageSource.gallery,
            Icons.photo_library_outlined,
            l10n.scanFromGallery
          ),
        ])
          ListTile(
            leading: Icon(entry.$2),
            title: Text(entry.$3),
            onTap: () {
              Navigator.pop(sheetContext);
              _processImage(context, entry.$1);
            },
          ),
      ],
    )),
  );
}

Future<void> _processImage(BuildContext context, ImageSource source) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final image =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (image == null || !context.mounted) return;
    await _scanSelectedImage(context, image);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.receiptScanFailed)));
    }
  }
}

Future<void> _scanSelectedImage(BuildContext context, XFile image) async {
  final l10n = AppLocalizations.of(context)!;
  while (context.mounted) {
    if (!context.mounted) return;
    final root = Navigator.of(context, rootNavigator: true);
    var progressOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(l10n.receiptScanning))
            ]),
          )),
    );
    try {
      final result = await ReceiptScannerService(ocrEndpoint: '$_worker/scan')
          .scanReceipt(image);
      final bytes = await image.readAsBytes();
      if (!context.mounted) {
        if (root.mounted && progressOpen) root.pop();
        return;
      }
      root.pop();
      progressOpen = false;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReceiptReviewScreen(
              initialData: result, sourceImageBytes: bytes)));
      return;
    } catch (error) {
      if (progressOpen && root.mounted && root.canPop()) root.pop();
      if (!context.mounted) return;
      final retry = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: Text(l10n.receiptScanFailed),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l10n.focusScanRetryHint),
                      ExpansionTile(
                          title: Text(l10n.detailsLabel),
                          tilePadding: EdgeInsets.zero,
                          children: [SelectableText(error.toString())]),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(l10n.cancelButton)),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(l10n.retryBtn)),
                ],
              ));
      if (retry != true) return;
    }
  }
}
