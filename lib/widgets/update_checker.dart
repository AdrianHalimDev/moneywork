import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    await showDialog<void>(
      context: context,
      barrierDismissible: !release.mandatory,
      builder: (_) => _UpdateDialog(release: release),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
            ? 'Pembaruan tersedia'
            : 'Pembaruan ${r.versionName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.mandatory)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Pembaruan ini wajib dipasang.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600)),
              ),
            Text(r.releaseNotes.isEmpty
                ? 'Versi baru aplikasi sudah tersedia.'
                : r.releaseNotes),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 6),
              Text('Mengunduh... $pct%',
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
                    child: const Text('Lewati'),
                  ),
                FilledButton(
                  onPressed: _startUpdate,
                  child: Text(_error == null ? 'Perbarui' : 'Coba lagi'),
                ),
              ],
      ),
    );
  }
}
