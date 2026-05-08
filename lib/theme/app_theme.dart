import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors ───────────────────────────────────────────────
  static const Color background   = Color(0xFF0D0D0D);
  static const Color surface      = Color(0xFF161616);
  static const Color surfaceHigh  = Color(0xFF1E1E1E);
  static const Color border       = Color(0xFF2A2A2A);
  static const Color accent       = Color(0xFFC8FF00);
  static const Color accentDim    = Color(0xFF1F2A00);
  static const Color textPrimary  = Color(0xFFEEEEEE);
  static const Color textSecondary= Color(0xFF666666);
  static const Color textMuted    = Color(0xFF444444);

  static const Color purple       = Color(0xFF7F77DD);
  static const Color purpleDim    = Color(0xFF1A1A2E);
  static const Color green        = Color(0xFF639922);
  static const Color greenDim     = Color(0xFF1A2A1A);
  static const Color pink         = Color(0xFFD4537E);
  static const Color pinkDim      = Color(0xFF2A1A1A);
  static const Color teal         = Color(0xFF1D9E75);
  static const Color tealDim      = Color(0xFF1A2020);
  static const Color amber        = Color(0xFFEF9F27);
  static const Color amberDim     = Color(0xFF2A1A00);

  // ── Theme ────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: accent,
      onPrimary: background,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge : TextStyle(color: textPrimary,   fontSize: 32, fontWeight: FontWeight.w500),
      headlineMedium: TextStyle(color: textPrimary,  fontSize: 20, fontWeight: FontWeight.w500),
      titleMedium  : TextStyle(color: textPrimary,   fontSize: 15, fontWeight: FontWeight.w500),
      bodyMedium   : TextStyle(color: textSecondary, fontSize: 13),
      labelSmall   : TextStyle(color: textMuted,     fontSize: 10, letterSpacing: 0.1),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: border, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    ),
    dividerColor: border,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: background,
      selectedItemColor: accent,
      unselectedItemColor: textMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}