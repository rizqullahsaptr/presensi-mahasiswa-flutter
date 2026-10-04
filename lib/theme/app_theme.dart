import 'package:flutter/material.dart';

/// Warna status kehadiran — semantik + label teks selalu ditampilkan
class StatusColors {
  static const hadir = Color(0xFF2E7D32); // hijau
  static const izin = Color(0xFF1565C0); // biru
  static const sakit = Color(0xFFF57F17); // kuning/amber
  static const alpha = Color(0xFFC62828); // merah

  static Color forStatus(String status) {
    switch (status) {
      case 'Hadir':
        return hadir;
      case 'Izin':
        return izin;
      case 'Sakit':
        return sakit;
      default:
        return alpha;
    }
  }
}

class AppTheme {
  static const Color primary = Color(0xFF1976D2); // biru utama
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color background = Color(0xFFF5F5F5); // abu-abu muda
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      backgroundColor: surface,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
