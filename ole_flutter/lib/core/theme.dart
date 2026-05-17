import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0F0F12);
  static const Color surface = Color(0xFF1A1A1F);
  static const Color surfaceAlt = Color(0xFF22222A);
  static const Color border = Color(0xFF2D2D36);
  static const Color textPrimary = Color(0xFFE8E8EC);
  static const Color textSecondary = Color(0xFF9A9AA5);
  static const Color textMuted = Color(0xFF6A6A75);
  static const Color accent = Color(0xFFE50914);
  static const Color accentSoft = Color(0xFFFF4458);
  static const Color score = Color(0xFFFFB400);
  static const Color hot = Color(0xFFFF6B35);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          surface: bg,
          primary: accent,
          secondary: accentSoft,
          onSurface: textPrimary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: textPrimary, fontSize: 13),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12),
          titleLarge: TextStyle(
              color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          hintStyle: const TextStyle(color: textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: surfaceAlt,
            foregroundColor: textPrimary,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
        ),
      );
}
