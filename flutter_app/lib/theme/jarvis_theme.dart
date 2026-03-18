/// Jarvis dark theme — matches the existing Control Center design.
library;

import 'package:flutter/material.dart';

abstract final class JarvisTheme {
  static const _bg = Color(0xFF0a0a14);
  static const _surface = Color(0xFF10101a);
  static const _border = Color(0xFF1e1e30);
  static const _text1 = Color(0xFFe0e0e8);
  static const _text2 = Color(0xFF8888a0);
  static const _accent = Color(0xFF00d4ff);
  static const _green = Color(0xFF00e676);
  static const _red = Color(0xFFff5252);
  static const _orange = Color(0xFFffab40);

  // Public color accessors
  static Color get accent => _accent;
  static Color get green => _green;
  static Color get red => _red;
  static Color get orange => _orange;
  static Color get surface => _surface;
  static Color get bg => _bg;
  static Color get border => _border;
  static Color get textPrimary => _text1;
  static Color get textSecondary => _text2;

  // Semantic color aliases
  static Color get success => _green;
  static Color get error => _red;
  static Color get warning => _orange;
  static const info = Color(0xFF448AFF);

  // Border radii
  static const cardRadius = 12.0;
  static const buttonRadius = 8.0;
  static const chipRadius = 20.0;

  // Spacing
  static const spacing = 16.0;
  static const spacingSm = 8.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  // Icon sizes
  static const iconSizeSm = 16.0;
  static const iconSizeMd = 24.0;
  static const iconSizeLg = 32.0;
  static const iconSizeXl = 48.0;

  // Light theme colors
  static const _lightBg = Color(0xFFF5F5F8);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightBorder = Color(0xFFE0E0E8);
  static const _lightText1 = Color(0xFF1A1A2E);
  static const _lightText2 = Color(0xFF6B6B80);
  static const _lightAccent = Color(0xFF0077CC);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _lightBg,
        colorScheme: const ColorScheme.light(
          primary: _lightAccent,
          secondary: _green,
          surface: _lightSurface,
          error: _red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: _lightText1,
          onError: Colors.white,
        ),
        cardColor: _lightSurface,
        dividerColor: _lightBorder,
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightSurface,
          foregroundColor: _lightText1,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightSurface,
          hintStyle: const TextStyle(color: _lightText2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightAccent),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _lightText1, fontSize: 15),
          bodyMedium: TextStyle(color: _lightText1, fontSize: 14),
          bodySmall: TextStyle(color: _lightText2, fontSize: 12),
          titleLarge: TextStyle(
              color: _lightText1, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: _lightText2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lightAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _lightAccent),
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          secondary: _green,
          surface: _surface,
          error: _red,
          onPrimary: _bg,
          onSecondary: _bg,
          onSurface: _text1,
          onError: Colors.white,
        ),
        cardColor: _surface,
        dividerColor: _border,
        appBarTheme: const AppBarTheme(
          backgroundColor: _surface,
          foregroundColor: _text1,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          hintStyle: const TextStyle(color: _text2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _text1, fontSize: 15),
          bodyMedium: TextStyle(color: _text1, fontSize: 14),
          bodySmall: TextStyle(color: _text2, fontSize: 12),
          titleLarge: TextStyle(
              color: _text1, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: _text2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _accent),
        ),
      );
}
