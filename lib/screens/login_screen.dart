import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/auth.dart';
import '../firebase/key_session.dart';
import '../widgets/common.dart';

/// Layar masuk / daftar dengan email & kata sandi.
///
/// Hanya tampil saat Firebase aktif dan belum ada sesi login.
/// Versi minimal: email + kata sandi saja (tanpa Google, tanpa opsi ingat
/// saya). Login & register adalah dua subtree terpisah yang ditukar biasa.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final service = ref.read(authServiceProvider);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final error = _isRegister
        ? await service.register(email, pass, name: _nameCtrl.text.trim())
        : await service.signIn(email, pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ref.read(keySessionProvider).setPendingPassword(pass);
  }
  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    final error = await ref.read(authServiceProvider).signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _toggleMode() => setState(() => _isRegister = !_isRegister);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                    Icon(Icons.savings,
                        size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('MoneyWork',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _isRegister ? l10n.createAccountSubtitle : l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 28),
                    _isRegister ? _buildRegisterForm(context) : _buildLoginForm(context),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isRegister ? l10n.registerButton : l10n.loginButton),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(l10n.orDividerLabel,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.outline)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _googleSignIn,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(l10n.loginWithGoogleBtn),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(_isRegister
                          ? l10n.alreadyHaveAccountBtn
                          : l10n.dontHaveAccountBtn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('login-form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          decoration: InputDecoration(
              labelText: l10n.emailLabel, prefixIcon: const Icon(Icons.mail_outline)),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return l10n.emailRequired;
            if (!s.contains('@')) return l10n.emailInvalid;
            return null;
          },
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _passCtrl,
          labelText: l10n.passwordLabel,
          validator: (v) {
            if ((v ?? '').isEmpty) return l10n.passwordRequired;
            if ((v ?? '').length < 6) return l10n.passwordMinLen;
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('register-form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          decoration: InputDecoration(
              labelText: l10n.nameLabel, prefixIcon: const Icon(Icons.person_outline)),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          decoration: InputDecoration(
              labelText: l10n.emailLabel, prefixIcon: const Icon(Icons.mail_outline)),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return l10n.emailRequired;
            if (!s.contains('@')) return l10n.emailInvalid;
            return null;
          },
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }
}
