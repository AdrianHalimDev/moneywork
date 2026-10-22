import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_controller.dart';
import '../data/storage.dart';
import '../l10n/app_localizations.dart';

String syncStatusLabel(SyncStatus status, AppLocalizations l10n,
        {bool local = false}) =>
    switch (status.phase) {
      SyncPhase.loading => l10n.syncStatusLoading,
      SyncPhase.synced => local ? l10n.focusLocalMode : l10n.focusCloudSaved,
      SyncPhase.pending => status.savedOnDevice || status.message == 'cache'
          ? local
              ? l10n.focusLocalMode
              : l10n.focusDevicePending
          : l10n.syncStatusPending,
      SyncPhase.error => local
          ? l10n.syncStatusError
          : status.conflict
              ? l10n.focusConflict
              : status.savedOnDevice
                  ? l10n.focusDevicePending
                  : l10n.focusSyncFailed,
    };

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key, this.showLabel = false});
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final l10n = AppLocalizations.of(context)!;
    final local = ref.watch(storageProvider) is LocalStorage;
    final label = syncStatusLabel(status, l10n, local: local);
    final icon = switch (status.phase) {
      SyncPhase.loading => Icons.cloud_sync_outlined,
      SyncPhase.synced =>
        local ? Icons.save_outlined : Icons.cloud_done_outlined,
      SyncPhase.pending => Icons.cloud_upload_outlined,
      SyncPhase.error => Icons.cloud_off_outlined,
    };
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
        message: label,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: status.phase == SyncPhase.error && !status.savedOnDevice
                    ? scheme.error
                    : scheme.primary),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall))
            ],
          ],
        ));
  }
}

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    if (status.phase == SyncPhase.synced || status.phase == SyncPhase.loading) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final local = ref.watch(storageProvider) is LocalStorage;
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
              status.phase == SyncPhase.error
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_upload_outlined,
              size: 20,
              color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(syncStatusLabel(status, l10n, local: local),
                  style: Theme.of(context).textTheme.labelLarge)),
        ]),
        if (status.savedOnDevice && !local)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l10n.focusSyncHint,
                  style: Theme.of(context).textTheme.bodySmall)),
        Wrap(spacing: 8, children: [
          TextButton(
              onPressed: () async {
                try {
                  await ref.read(appStateProvider.notifier).retrySync();
                } catch (_) {/* The sync status retains the failure. */}
              },
              child: Text(l10n.syncRetry)),
          if (status.message != null && status.message != 'cache')
            TextButton(
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.detailsLabel),
                          content: SingleChildScrollView(
                              child: SelectableText(status.message!)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(l10n.syncCancel))
                          ],
                        )),
                child: Text(l10n.detailsLabel)),
          if (status.phase == SyncPhase.error && !local)
            TextButton(
                onPressed: () => _loadCloud(context, ref, l10n),
                child: Text(l10n.syncLoadCloud)),
        ]),
      ]),
    ));
  }

  Future<void> _loadCloud(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    if (ref.read(storageProvider) is LocalStorage) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(l10n.syncDiscardTitle),
              content: Text(l10n.syncDiscardBody),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.syncCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.syncContinue)),
              ],
            ));
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(appStateProvider.notifier).discardPendingAndReload();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.focusSyncFailed)));
      }
    }
  }
}

class FriendlyLoadError extends ConsumerWidget {
  const FriendlyLoadError({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 32),
                const SizedBox(height: 12),
                Text(l10n.focusLoadFailed, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(appStateProvider.notifier)
                            .reloadFromStorage();
                      } catch (_) {/* Remain on the visible error state. */}
                    },
                    child: Text(l10n.syncRetry)),
              ],
            )));
  }
}
