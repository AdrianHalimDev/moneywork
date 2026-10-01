import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/app_controller.dart';
import '../firebase/auth.dart';
import '../firebase/firebase_config.dart';
import '../firebase/key_manager.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../widgets/common.dart';
import '../widgets/update_checker.dart';

/// Layar profil & pengaturan.
///
/// - Tema: tersedia di semua mode.
/// - Akun (nama, email, ganti sandi, keluar, hapus akun): hanya saat
///   Firebase aktif dan pengguna sudah login.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isCloud = useFirebase && user != null && !user.isLocal;
    final themeMode =
        ref.watch(appStateProvider).valueOrNull?.themeMode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.profileTitle)),
      body: ListView(
        children: [
          if (isCloud) _ProfileHeader(user: user),
          _SectionLabel(AppLocalizations.of(context)!.sectionAppearance),
          _ThemeTile(current: themeMode),
          _SectionLabel(AppLocalizations.of(context)!.sectionLanguage),
          _LocaleTile(
              current:
                  ref.watch(appStateProvider).valueOrNull?.locale ?? 'system'),
          if (!kIsWeb) ...[
            _SectionLabel(AppLocalizations.of(context)!.sectionReminders),
            const _NotificationTile(),
            _SectionLabel(AppLocalizations.of(context)!.sectionApp),
            const _CheckUpdateTile(),
          ],
          if (isCloud) ...[
            _SectionLabel(AppLocalizations.of(context)!.sectionAccount),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(AppLocalizations.of(context)!.accountName),
              subtitle: Text(user.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditName(context, ref, user.displayName),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(AppLocalizations.of(context)!.changePassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePassword(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: Text(AppLocalizations.of(context)!.recoveryKey),
              subtitle: Text(AppLocalizations.of(context)!.recoveryKeySubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRecoveryKey(context, ref, user.uid),
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(AppLocalizations.of(context)!.logout),
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_forever, color: AppTheme.expense),
              title: Text(AppLocalizations.of(context)!.deleteAccount,
                  style: const TextStyle(color: AppTheme.expense)),
              subtitle:
                  Text(AppLocalizations.of(context)!.deleteAccountSubtitle),
              onTap: () => _showDeleteAccount(context, ref),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text('MoneyWork',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Text(user.initials,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
          ),
          const SizedBox(height: 12),
          Text(user.label, style: theme.textTheme.titleMedium),
          Text(user.email,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile({required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void set(String mode) =>
        ref.read(appStateProvider.notifier).setThemeMode(mode);

    String getLabel(String mode) {
      if (mode == 'light') return AppLocalizations.of(context)!.themeLight;
      if (mode == 'dark') return AppLocalizations.of(context)!.themeDark;
      return AppLocalizations.of(context)!.themeSystem;
    }

    return ListTile(
      leading: const Icon(Icons.brightness_medium_outlined),
      title: Text(AppLocalizations.of(context)!.sectionAppearance),
      subtitle: Text(getLabel(current)),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.sectionAppearance),
              content: RadioGroup<String>(
                groupValue: current,
                onChanged: (v) {
                  if (v == null) return;
                  set(v);
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: 'system',
                      title: Text(AppLocalizations.of(context)!.themeSystem),
                    ),
                    RadioListTile<String>(
                      value: 'light',
                      title: Text(AppLocalizations.of(context)!.themeLight),
                    ),
                    RadioListTile<String>(
                      value: 'dark',
                      title: Text(AppLocalizations.of(context)!.themeDark),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LocaleTile extends ConsumerWidget {
  const _LocaleTile({required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void set(String mode) =>
        ref.read(appStateProvider.notifier).setLocale(mode);
    String getLabel(String locale) {
      if (locale == 'id') return AppLocalizations.of(context)!.languageId;
      if (locale == 'en') return AppLocalizations.of(context)!.languageEn;
      if (locale == 'zh') return AppLocalizations.of(context)!.languageZh;
      return AppLocalizations.of(context)!.languageSystem;
    }

    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(AppLocalizations.of(context)!.sectionLanguage),
      subtitle: Text(getLabel(current)),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.languageDialogTitle),
              content: RadioGroup<String>(
                groupValue: current,
                onChanged: (v) {
                  if (v == null) return;
                  set(v);
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: 'system',
                      title: Text(AppLocalizations.of(context)!.languageSystem),
                    ),
                    RadioListTile<String>(
                      value: 'id',
                      title: Text(AppLocalizations.of(context)!.languageId),
                    ),
                    RadioListTile<String>(
                      value: 'en',
                      title: Text(AppLocalizations.of(context)!.languageEn),
                    ),
                    RadioListTile<String>(
                      value: 'zh',
                      title: Text(AppLocalizations.of(context)!.languageZh),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Toggle pengingat lokal: minta izin & jadwalkan reminder harian + wishlist.
class _NotificationTile extends ConsumerStatefulWidget {
  const _NotificationTile();

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final on = await NotificationService.instance.isEnabled();
    if (mounted) setState(() => _enabled = on);
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    final svc = NotificationService.instance;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(appStateProvider).valueOrNull;
    if (value) {
      final granted = await svc.requestPermissions();
      if (!mounted) return;
      if (granted) {
        await svc.scheduleDailyReminder(
          l10n,
          hour: state?.reminderHour ?? 20,
          minute: state?.reminderMinute ?? 0,
        );
        await svc.scheduleWishlistReminders(state?.wishlist ?? const [], l10n);
        if (!mounted) return;
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.reminderActiveDesc)));
      } else {
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.reminderNoPermission)));
      }
    } else {
      await svc.cancelAll();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderDisabled)));
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickTime() async {
    final state = ref.read(appStateProvider).valueOrNull;
    final initial = TimeOfDay(
      hour: state?.reminderHour ?? 20,
      minute: state?.reminderMinute ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: AppLocalizations.of(context)!.dailyReminderTime,
    );
    if (picked == null || !mounted) return;
    // Tangkap sebelum await berikutnya untuk hindari akses context lintas async.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = picked.format(context);
    // Simpan & jadwalkan ulang dengan jam baru.
    await ref
        .read(appStateProvider.notifier)
        .setReminderTime(picked.hour, picked.minute);
    await NotificationService.instance
        .scheduleDailyReminder(l10n, hour: picked.hour, minute: picked.minute);
    if (mounted) {
      setState(() {});
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.reminderDailySetTo(label))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider).valueOrNull;
    final time = TimeOfDay(
      hour: state?.reminderHour ?? 20,
      minute: state?.reminderMinute ?? 0,
    );
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined),
          title: Text(AppLocalizations.of(context)!.reminderTitle),
          subtitle: Text(AppLocalizations.of(context)!.reminderSubtitle),
          value: _enabled,
          onChanged: _busy ? null : _toggle,
        ),
        if (_enabled)
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(AppLocalizations.of(context)!.reminderTimeTitle),
            subtitle: Text(AppLocalizations.of(context)!
                .dailyReminderDesc(time.format(context))),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: _busy ? null : _pickTime,
          ),
      ],
    );
  }
}

// ============================================================================
// Cek pembaruan manual — preventif bila pengguna tak sengaja menekan "Lewati"
// pada dialog update otomatis. Mengambil rilis terbaru dari Firestore lalu,
// bila ada, langsung menampilkan dialog unduh & pasang yang sama.
// ============================================================================

class _CheckUpdateTile extends ConsumerStatefulWidget {
  const _CheckUpdateTile();

  @override
  ConsumerState<_CheckUpdateTile> createState() => _CheckUpdateTileState();
}

class _CheckUpdateTileState extends ConsumerState<_CheckUpdateTile> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final result =
        await ref.read(updateServiceProvider).checkForUpdateInteractive();
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result.status) {
      case UpdateStatus.available:
        await showUpdateDialog(context, result.release!);
      case UpdateStatus.upToDate:
        messenger.showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.alreadyLatestVersion)));
      case UpdateStatus.unsupported:
        messenger.showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.autoUpdateAndroidOnly)));
      case UpdateStatus.failed:
        messenger.showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.updateCheckFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.system_update_outlined),
      title: Text(AppLocalizations.of(context)!.updateCheck),
      subtitle: Text(AppLocalizations.of(context)!.updateCheckDesc),
      onTap: _busy ? null : _run,
    );
  }
}

// ============================================================================
// Dialog: ubah nama
// ============================================================================

Future<void> _showEditName(
    BuildContext context, WidgetRef ref, String current) async {
  final ctrl = TextEditingController(text: current);
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.renameTitle),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.nameLabel),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? AppLocalizations.of(context)!.nameRequired
              : null,
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final error = await ref
                .read(authServiceProvider)
                .updateName(ctrl.text.trim());
            navigator.pop();
            if (error != null) {
              messenger.showSnackBar(SnackBar(content: Text(error)));
            }
          },
          child: Text(AppLocalizations.of(context)!.saveButton),
        ),
      ],
    ),
  );
}

// ============================================================================
// Dialog: ganti kata sandi
// ============================================================================

Future<void> _showChangePassword(BuildContext context, WidgetRef ref) async {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.changePassword),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PasswordField(
              controller: currentCtrl,
              labelText: AppLocalizations.of(context)!.currentPasswordLabel,
              prefixIcon: null,
              validator: (v) => (v == null || v.isEmpty)
                  ? AppLocalizations.of(context)!.requiredField
                  : null,
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: newCtrl,
              labelText: AppLocalizations.of(context)!.newPasswordLabel,
              prefixIcon: null,
              validator: (v) => (v == null || v.length < 6)
                  ? AppLocalizations.of(context)!.passwordMinLen
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelButton)),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final l10n = AppLocalizations.of(context)!;
            final error = await ref
                .read(authServiceProvider)
                .changePassword(currentCtrl.text, newCtrl.text);
            if (!context.mounted) return;
            if (error != null) {
              messenger.showSnackBar(SnackBar(content: Text(error)));
              return;
            }
            navigator.pop();
            messenger
                .showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
          },
          child: Text(AppLocalizations.of(context)!.saveButton),
        ),
      ],
    ),
  );
}

// ============================================================================
// Dialog: hapus akun
// ============================================================================

Future<void> _showDeleteAccount(BuildContext context, WidgetRef ref) async {
  final passCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.deleteAccountTitle),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.deleteAccountSubtitle),
            const SizedBox(height: 16),
            PasswordField(
              controller: passCtrl,
              labelText: AppLocalizations.of(context)!.currentPasswordLabel,
              prefixIcon: null,
              validator: (v) => (v == null || v.isEmpty)
                  ? AppLocalizations.of(context)!.requiredField
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelButton)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.expense),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final auth = ref.read(authServiceProvider);

            // 1) Verifikasi ulang dengan kata sandi.
            final reauth = await auth.reauthenticate(passCtrl.text);
            if (reauth != null) {
              messenger.showSnackBar(SnackBar(content: Text(reauth)));
              return;
            }
            // 2) Hapus data Firestore selagi masih terautentikasi.
            await ref.read(appStateProvider.notifier).clearAllData();
            // 3) Hapus akun auth.
            final error = await auth.deleteCurrentUser();
            navigator.pop();
            if (error != null) {
              messenger.showSnackBar(SnackBar(content: Text(error)));
            }
// Sukses: authStateProvider berpindah ke layar login.
          },
          child: Text(AppLocalizations.of(context)!.deletePermanently),
        ),
      ],
    ),
  );
}

// ============================================================================
// Dialog: lihat/buat ulang kunci pemulihan
// ============================================================================

Future<void> _showRecoveryKey(
    BuildContext context, WidgetRef ref, String uid) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RecoveryKeyDialog(uid: uid),
  );
}

class _RecoveryKeyDialog extends ConsumerStatefulWidget {
  const _RecoveryKeyDialog({required this.uid});
  final String uid;
  @override
  ConsumerState<_RecoveryKeyDialog> createState() => _RecoveryKeyDialogState();
}

class _RecoveryKeyDialogState extends ConsumerState<_RecoveryKeyDialog> {
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _newKey;

  Future<void> _verifyAndGenerate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);

    // 1) Verifikasi kata sandi
    final reauth =
        await ref.read(authServiceProvider).reauthenticate(_passCtrl.text);
    if (reauth != null) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text(reauth)));
      return;
    }

    // 2) Buat ulang kunci pemulihan
    try {
      final newKey =
          await KeyManager.instance.regenerateRecoveryKey(widget.uid);
      if (!mounted) return;
      setState(() {
        _newKey = newKey;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .recoveryKeyCreateFailed(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_newKey != null) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.recoveryKeyNew),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.saveRecoveryKeyDesc,
              style: const TextStyle(color: AppTheme.expense),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _newKey!,
                style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _newKey!));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.recoveryKeyCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(AppLocalizations.of(context)!.copy),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.done),
          )
        ],
      );
    }

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.recoveryKey),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.recoveryKeyNewDesc),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passCtrl,
              labelText: AppLocalizations.of(context)!.currentPasswordLabel,
              prefixIcon: null,
              validator: (v) => (v == null || v.isEmpty)
                  ? AppLocalizations.of(context)!.requiredField
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelButton),
        ),
        FilledButton(
          onPressed: _loading ? null : _verifyAndGenerate,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(AppLocalizations.of(context)!.recoveryKeyNew),
        ),
      ],
    );
  }
}
