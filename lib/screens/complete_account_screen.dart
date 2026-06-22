import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/auth.dart';

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
    final error =
        await ref.read(authServiceProvider).linkPassword(_passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // Sukses: userChanges memancarkan hasPassword=true, gerbang auth otomatis
    // berpindah ke aplikasi utama.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Text('Lengkapi Akun',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu masuk sebagai ${widget.user.email}. Buat kata sandi '
                    'untuk menyelesaikan pendaftaran. Setelah ini kamu bisa '
                    'masuk dengan email + kata sandi.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Kata sandi wajib diisi';
                      if ((v ?? '').length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Ulangi kata sandi',
                        prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Wajib diisi';
                      if (v != _passCtrl.text) return 'Kata sandi tidak sama';
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
                        : const Text('Simpan & Lanjutkan'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => ref.read(authServiceProvider).signOut(),
                    child: const Text('Keluar'),
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
