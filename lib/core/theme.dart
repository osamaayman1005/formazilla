/// Design tokens and theme. Change colours here only; widgets never hardcode them.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bg = Color(0xFF0A1224);
  static const card = Color(0xFF141E36);
  static const chip = Color(0xFF1E2A46);
  static const line = Color(0xFF334161);
  static const text = Color(0xFFF5F7FC);
  static const muted = Color(0xFF949FBD);
  static const accent = Color(0xFF294DB8);
  static const accentLight = Color(0xFF8CB0FF);
  static const onAccent = Colors.white;
  static const danger = Color(0xFFE5675F);
}

class AppSpace {
  AppSpace._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const screen = 20.0;
}

class AppRadius {
  AppRadius._();

  static const card = 16.0;
  static const chip = 10.0;
  static const button = 14.0;
  static const pill = 999.0;
}

class AppText {
  AppText._();

  static const display = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text);
  static const title = TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text);
  static const section = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text);
  static const cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text);
  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text);
  static const chip = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const caption = TextStyle(fontSize: 13, color: AppColors.muted);
  static const small = TextStyle(fontSize: 12, color: AppColors.muted);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    surface: AppColors.bg,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      showDragHandle: true,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.card),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.chip,
      contentTextStyle: TextStyle(color: AppColors.text),
      actionTextColor: AppColors.accentLight,
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentLight, width: 1.5),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.accentLight),
  );
}
