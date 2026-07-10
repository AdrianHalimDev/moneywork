import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/auth.dart';
import '../firebase/key_manager.dart';
import '../firebase/key_session.dart';
import '../widgets/common.dart';

/// Layar migrasi keamanan untuk pengguna lama.
///
/// Pengguna yang sudah punya akun + sandi tapi datanya masih plaintext
/// (sebelum fitur E2EE) melewati layar ini sekali: masukkan sandi untuk
/// verifikasi, lalu app membuat kunci & recovery key, dan mengenkripsi ulang
/// data yang ada. Recovery key ditampilkan sekali — wajib disimpan.
class SecurityUpgradeScreen extends ConsumerStatefulWidget {
  const SecurityUpgradeScreen({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<SecurityUpgradeScreen> createState() =>
      _SecurityUpgradeScreenState();
}

class _SecurityUpgradeScreenState extends ConsumerState<SecurityUpgradeScreen> {
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _recoveryKey;

  @override
  void initState() {
    super.initState();
    // Bila sandi tertahan dari login/daftar barusan, isi otomatis agar
    // pengguna tak perlu mengetik ulang untuk mengaktifkan enkripsi.
    final pending = ref.read(keySessionProvider).pendingPassword;
    if (pending != null && pending.isNotEmpty) {
      _passCtrl.text = pending;
    }
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
    });
    final messenger = ScaffoldMessenger.of(context);

    // 1) Verifikasi sandi dengan re-auth.
    final reauth = await ref
        .read(authServiceProvider)
        .reauthenticate(_passCtrl.text);
    if (reauth != null) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text(reauth)));
      return;
    }

    // 2) Setup kunci E2EE + recovery key.
    try {
      final recovery = await KeyManager.instance.setup(
        uid: widget.uid,
        password: _passCtrl.text,
      );
      ref.read(keySessionProvider).markUnlocked(widget.uid);
      // Picu muat ulang state agar data lama (plaintext) dibaca lalu
      // ditulis ulang terenkripsi.
      ref.invalidate(securityStatusProvider);
      if (!mounted) return;
      setState(() {
        _recoveryKey = recovery;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_recoveryKey != null) {
      return _RecoveryKeyView(recoveryKey: _recoveryKey!);
    }
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.enhanced_encryption,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Tingkatkan Keamanan Data',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Data keuanganmu kini akan dienkripsi sebelum disimpan '
                    'di cloud — termasuk pemilik project pun tak bisa '
                    'membacanya. Masukkan kata sandimu untuk memulai.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 28),
                  PasswordField(
                    controller: _passCtrl,
                    labelText: 'Kata sandi saat ini',
                    prefixIcon: null,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Mulai Enkripsi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tampilan recovery key sekali jalan: user wajib salin/sebelum lanjut.
class _RecoveryKeyView extends StatelessWidget {
  const _RecoveryKeyView({required this.recoveryKey});
  final String recoveryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.key,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Simpan Kunci Pemulihan',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Ini adalah satu-satunya cara membuka datamu jika lupa kata '
                  'sandi. Kami tidak menyimpannya. Salin & simpan di tempat '
                  'aman (mis. password manager). Tanpa ini dan tanpa sandi, '
                  'data tak bisa dikembalikan.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    recoveryKey,
                    style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: recoveryKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kunci disalin.')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Salin kunci'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Saya sudah menyimpannya'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
