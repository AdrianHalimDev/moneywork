import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router.dart';
import '../services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Membungkus aplikasi dan memeriksa update sekali per sesi setelah pengguna
/// masuk. Jika ada rilis lebih baru, menampilkan dialog yang memandu unduh &
/// pasang APK. Update opsional yang sudah di-skip pengguna tidak ditampilkan
/// lagi sampai ada versi yang lebih baru lagi.
class UpdateChecker extends ConsumerStatefulWidget {
  const UpdateChecker({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  static const _skipKey = 'skipped_update_version_code';
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // Tunda hingga frame pertama selesai agar context siap untuk dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheck());
  }

  Future<void> _maybeCheck() async {
    if (_checked) return;
    _checked = true;

    final release = await ref.read(updateServiceProvider).checkForUpdate();
    if (release == null || !mounted) return;

    // Hormati pilihan "lewati versi ini" untuk update opsional.
    if (!release.mandatory) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt(_skipKey) == release.versionCode) return;
      if (!mounted) return;
    }

    // Tampilkan lewat context navigator root, bukan context widget ini.
    // UpdateChecker dipasang di `builder` MaterialApp.router sehingga berada
    // DI ATAS Navigator — showDialog dengan context-nya sendiri tak menemukan
    // Navigator (diam-diam gagal di release). Context root selalu punya Overlay.
    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext == null) return;

    // Aman: rootContext diambil tepat sebelum dipakai, tanpa await di antaranya.
    // ignore: use_build_context_synchronously
    await showUpdateDialog(rootContext, release);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Tampilkan dialog update untuk [release]. Dipakai pengecekan otomatis maupun
/// tombol "Cek pembaruan" manual di Profil. Mengembalikan setelah dialog
/// ditutup.
Future<void> showUpdateDialog(BuildContext context, AppRelease release) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !release.mandatory,
    builder: (_) => _UpdateDialog(release: release),
  );
}

/// Dialog update: tampilkan catatan rilis, lalu unduh + pasang APK.
class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({required this.release});
  final AppRelease release;

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    final service = ref.read(updateServiceProvider);
    try {
      final path = await service.downloadApk(
        widget.release.apkUrl,
        onProgress: (f) {
          if (mounted) setState(() => _progress = f);
        },
      );
      final err = await service.installApk(path);
      if (err != null && mounted) {
        setState(() {
          _downloading = false;
          _error = err;
        });
      }
      // Bila installer terbuka, biarkan dialog tetap ada — pengguna kembali
      // ke aplikasi lama bila membatalkan pemasangan.
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Gagal mengunduh pembaruan. Periksa koneksi lalu coba lagi.';
        });
      }
    }
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _UpdateCheckerState._skipKey, widget.release.versionCode);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.release;
    final pct = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    return PopScope(
      // Update wajib tidak boleh ditutup dengan tombol back.
      canPop: !r.mandatory && !_downloading,
      child: AlertDialog(
        title: Text(r.versionName.isEmpty
            ? AppLocalizations.of(context)!.updateAvailable
            : AppLocalizations.of(context)!.updateVersion(r.versionName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.mandatory)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(AppLocalizations.of(context)!.updateMandatory,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600)),
              ),
            Text(r.releaseNotes.isEmpty
                ? AppLocalizations.of(context)!.updateDefaultNotes
                : r.releaseNotes),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 6),
              Text(AppLocalizations.of(context)!.downloading(pct.toString()),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
        actions: _downloading
            ? null
            : [
                if (!r.mandatory)
                  TextButton(
                    onPressed: _skip,
                    child: Text(AppLocalizations.of(context)!.skip),
                  ),
                FilledButton(
                  onPressed: _startUpdate,
                  child: Text(_error == null ? AppLocalizations.of(context)!.updateBtn : AppLocalizations.of(context)!.retryBtn),
                ),
              ],
      ),
    );
  }
}
