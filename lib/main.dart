import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'data/app_controller.dart';
import 'firebase/auth.dart';
import 'firebase/firebase_config.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Format tanggal & angka Indonesia.
  await initializeDateFormatting('id_ID', null);
  // Inisialisasi Firebase hanya bila diaktifkan (lihat firebase_config.dart).
  if (useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const ProviderScope(child: MoneyWorkApp()));
}

class MoneyWorkApp extends ConsumerWidget {
  const MoneyWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'MoneyWork',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Gerbang autentikasi: membungkus seluruh aplikasi tanpa mengubah router.
      // Mode lokal melewati ini sepenuhnya.
      builder: (context, child) => _AuthGate(child: child ?? const SizedBox()),
    );
  }
}

/// Menentukan apakah menampilkan aplikasi atau layar login.
///
/// - Firebase nonaktif → langsung tampilkan aplikasi (tanpa login).
/// - Firebase aktif → ikuti status login: belum login tampilkan [LoginScreen],
///   sudah login tampilkan aplikasi.
class _AuthGate extends ConsumerWidget {
  const _AuthGate({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!useFirebase) return child;

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Gagal memuat sesi: $e')),
      ),
      data: (user) => user == null ? const LoginScreen() : child,
    );
  }
}
