import 'package:flutter/material.dart';

/// Tema aplikasi MoneyWork — warna hijau "uang" dengan Material 3.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF1B7A4B); // hijau finansial

  // Warna semantik untuk arus kas & status.
  static const Color income = Color(0xFF2E7D32);
  static const Color expense = Color(0xFFC62828);
  static const Color debt = Color(0xFFE65100);
  static const Color investment = Color(0xFF1565C0);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return _base(scheme.copyWith(
      primary: const Color(0xFF226548),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE5EEE4),
      onPrimaryContainer: const Color(0xFF184F36),
      surface: const Color(0xFFF5F7F3),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      onSurface: const Color(0xFF24322A),
      onSurfaceVariant: const Color(0xFF647367),
      outlineVariant: const Color(0xFFDCE4DC),
    ));
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _base(scheme.copyWith(
      primary: const Color(0xFFACDBBC),
      onPrimary: const Color(0xFF163322),
      primaryContainer: const Color(0xFF293E2E),
      onPrimaryContainer: const Color(0xFFDAEFDF),
      surface: const Color(0xFF131B17),
      surfaceContainerLowest: const Color(0xFF1D2821),
      surfaceContainerLow: const Color(0xFF1D2821),
      onSurface: const Color(0xFFEDF4EE),
      onSurfaceVariant: const Color(0xFFB2C2B5),
      outlineVariant: const Color(0xFF35463A),
    ));
  }

  static Color heroBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF234F37)
          : const Color(0xFF184F36);
  static const heroForeground = Color(0xFFF1F8EF);

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w600),
      ),
      dividerColor: scheme.outlineVariant,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        height: 76,
        elevation: 0,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        shape: CircularNotchedRectangle(),
        height: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
