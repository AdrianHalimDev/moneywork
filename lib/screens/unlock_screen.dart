import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../firebase/auth.dart';
import '../firebase/crypto_service.dart';
import '../firebase/key_manager.dart';
import '../firebase/key_session.dart';
import '../widgets/common.dart';

/// Layar membuka kunci data di perangkat/sesi baru.
///
/// Muncul bila kunci E2EE sudah dibuat (ada blob di server) tapi DEK belum
/// ada di perangkat ini — mis. baru masuk lewat Google di perangkat baru,
/// atau setelah logout. Cukup sekali per perangkat: setelah ini DEK di-cache
/// di Keystore/Keychain.
///
/// Dua jalur: kata sandi, atau kunci pemulihan (saat lupa sandi).
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passCtrl = TextEditingController();
  final _recoveryCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _useRecovery = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _recoveryCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await KeyManager.instance.unlockWithPassword(
          uid: widget.uid, password: _passCtrl.text);
      ref.read(keySessionProvider).markUnlocked(widget.uid);
      ref.invalidate(securityStatusProvider);
    } on WrongKeyException {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.wrongPassword)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.snackFailed} $e')));
    }
  }

  Future<void> _submitRecovery() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await KeyManager.instance.unlockWithRecoveryKey(
        uid: widget.uid,
        recoveryKey: _recoveryCtrl.text,
        newPassword: _newPassCtrl.text,
      );
      ref.read(keySessionProvider).markUnlocked(widget.uid);
      ref.invalidate(securityStatusProvider);
    } on WrongKeyException {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.invalidRecoveryKey)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.snackFailed} $e')));
    }
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_person_outlined,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(l10n.unlockDataTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _useRecovery
                        ? l10n.unlockRecoveryDesc
                        : l10n.unlockPasswordDesc,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 28),
                  if (!_useRecovery) ...[
                    PasswordField(
                      controller: _passCtrl,
                      labelText: l10n.passwordLabel,
                      prefixIcon: null,
                      textInputAction: TextInputAction.go,
                      onFieldSubmitted: (_) => _submitPassword(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submitPassword,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.unlockBtn),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _useRecovery = true),
                      child: Text(l10n.forgotPasswordBtn),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _recoveryCtrl,
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: const [NoComposingFormatter()],
                      decoration: InputDecoration(
                        labelText: l10n.recoveryKeyLabel,
                        hintText: l10n.recoveryKeyHint,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    PasswordField(
                      controller: _newPassCtrl,
                      labelText: l10n.newPasswordLabel,
                      prefixIcon: null,
                      validator: (v) =>
                          (v == null || v.length < 6) ? l10n.passwordMinLen : null,
                    ),
                    const SizedBox(height: 12),
                    PasswordField(
                      controller: _confirmCtrl,
                      labelText: l10n.confirmNewPasswordLabel,
                      prefixIcon: null,
                      validator: (v) =>
                          v != _newPassCtrl.text ? l10n.passwordNotMatch : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submitRecovery,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.unlockAndChangePassBtn),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _useRecovery = false),
                      child: Text(l10n.rememberPasswordBtn),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            await ref.read(authServiceProvider).signOut();
                          },
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
