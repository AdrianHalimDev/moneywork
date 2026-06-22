import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/app_controller.dart';
import '../firebase/auth.dart';
import '../firebase/firebase_config.dart';
import '../services/notification_service.dart';

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
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: ListView(
        children: [
          if (isCloud) _ProfileHeader(user: user),
          const _SectionLabel('Tampilan'),
          _ThemeTile(current: themeMode),
          if (!kIsWeb) ...[
            const _SectionLabel('Pengingat'),
            const _NotificationTile(),
          ],
          if (isCloud) ...[
            const _SectionLabel('Akun'),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Nama'),
              subtitle: Text(user.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditName(context, ref, user.displayName),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Ganti kata sandi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePassword(context, ref),
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
              title: const Text('Keluar'),
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppTheme.expense),
              title: const Text('Hapus akun',
                  style: TextStyle(color: AppTheme.expense)),
              subtitle: const Text('Menghapus akun & seluruh data permanen'),
              onTap: () => _showDeleteAccount(context, ref),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text('MoneyWork',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
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
    return Column(
      children: [
        RadioListTile<String>(
          value: 'system',
          groupValue: current,
          onChanged: (v) => set(v!),
          title: const Text('Ikuti sistem'),
          secondary: const Icon(Icons.brightness_auto_outlined),
        ),
        RadioListTile<String>(
          value: 'light',
          groupValue: current,
          onChanged: (v) => set(v!),
          title: const Text('Terang'),
          secondary: const Icon(Icons.light_mode_outlined),
        ),
        RadioListTile<String>(
          value: 'dark',
          groupValue: current,
          onChanged: (v) => set(v!),
          title: const Text('Gelap'),
          secondary: const Icon(Icons.dark_mode_outlined),
        ),
      ],
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
    final state = ref.read(appStateProvider).valueOrNull;
    if (value) {
      final granted = await svc.requestPermissions();
      if (granted) {
        await svc.scheduleDailyReminder(
          hour: state?.reminderHour ?? 20,
          minute: state?.reminderMinute ?? 0,
        );
        await svc.scheduleWishlistReminders(state?.wishlist ?? const []);
        messenger.showSnackBar(const SnackBar(
            content: Text('Pengingat aktif. Atur jamnya di bawah.')));
      } else {
        messenger.showSnackBar(const SnackBar(
            content: Text('Izin notifikasi ditolak. Aktifkan di Pengaturan HP.')));
      }
    } else {
      await svc.cancelAll();
      messenger
          .showSnackBar(const SnackBar(content: Text('Pengingat dimatikan.')));
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
      helpText: 'Jam pengingat harian',
    );
    if (picked == null || !mounted) return;
    // Tangkap sebelum await berikutnya untuk hindari akses context lintas async.
    final messenger = ScaffoldMessenger.of(context);
    final label = picked.format(context);
    // Simpan & jadwalkan ulang dengan jam baru.
    await ref
        .read(appStateProvider.notifier)
        .setReminderTime(picked.hour, picked.minute);
    await NotificationService.instance
        .scheduleDailyReminder(hour: picked.hour, minute: picked.minute);
    if (mounted) {
      setState(() {});
      messenger.showSnackBar(
          SnackBar(content: Text('Pengingat harian diatur ke $label.')));
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
          title: const Text('Pengingat di HP'),
          subtitle: const Text(
              'Ingatkan catat transaksi harian & jadwal menabung'),
          value: _enabled,
          onChanged: _busy ? null : _toggle,
        ),
        if (_enabled)
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Jam pengingat harian'),
            subtitle: Text('Setiap hari pukul ${time.format(context)}'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: _busy ? null : _pickTime,
          ),
      ],
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
      title: const Text('Ubah Nama'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama tampilan'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
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
          child: const Text('Simpan'),
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
      title: const Text('Ganti Kata Sandi'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: currentCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Kata sandi saat ini'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Kata sandi baru'),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
            ),
          ],
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
                .changePassword(currentCtrl.text, newCtrl.text);
            if (error != null) {
              messenger.showSnackBar(SnackBar(content: Text(error)));
              return;
            }
            navigator.pop();
            messenger.showSnackBar(
                const SnackBar(content: Text('Kata sandi berhasil diganti.')));
          },
          child: const Text('Simpan'),
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
      title: const Text('Hapus Akun?'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Seluruh data (akun, transaksi, investasi, utang, wishlist) '
                'akan dihapus permanen dan tidak bisa dikembalikan.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Konfirmasi dengan kata sandi'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
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
          child: const Text('Hapus Permanen'),
        ),
      ],
    ),
  );
}
