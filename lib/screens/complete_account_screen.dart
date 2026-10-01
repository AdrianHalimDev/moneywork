import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/auth.dart';
import '../firebase/key_session.dart';
import '../widgets/common.dart';

/// Layar wajib lengkapi data untuk akun yang masuk via Google tetapi belum
/// punya kata sandi.
///
/// Setelah kata sandi dibuat (ditautkan ke akun), pengguna bisa masuk dengan
/// email + kata sandi dan mengelola akun (ganti sandi, hapus akun) layaknya
/// akun email biasa. Tersedia tombol Keluar agar pengguna tak terkunci.
class CompleteAccountScreen extends ConsumerStatefulWidget {
  const CompleteAccountScreen({super.key, required this.user});
  final AppUser user;

  @override
  ConsumerState<CompleteAccountScreen> createState() =>
      _CompleteAccountScreenState();
}

class _CompleteAccountScreenState
    extends ConsumerState<CompleteAccountScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final pass = _passCtrl.text;
    final error = await ref.read(authServiceProvider).linkPassword(pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // Sukses: simpan sandi transien agar gerbang E2EE bisa langsung menyiapkan
    // kunci (akun Google baru belum punya blob kunci). userChanges memancarkan
    // hasPassword=true, gerbang auth lanjut ke SecurityUpgradeScreen.
    ref.read(keySessionProvider).setPendingPassword(pass);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(l10n.completeAccountTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.completeAccountDesc(widget.user.email),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 28),
                  PasswordField(
                    controller: _passCtrl,
                    labelText: l10n.passwordLabel,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return l10n.passwordRequired;
                      if ((v ?? '').length < 6) return l10n.passwordMinLen;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  PasswordField(
                    controller: _confirmCtrl,
                    labelText: l10n.passwordConfirmLabel,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return l10n.requiredField;
                      if (v != _passCtrl.text) return l10n.passwordNotMatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.saveAndContinueBtn),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => ref.read(authServiceProvider).signOut(),
                    child: Text(l10n.logoutButton),
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
