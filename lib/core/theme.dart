/// Design tokens and theme. Change colours here only; widgets never hardcode them.
/// The design system is written up in DESIGN.md ("The Sticker Album").
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bg = Color(0xFF0A1224);
  static const card = Color(0xFF141E36);
  static const chip = Color(0xFF1E2A46);

  /// Outlines: printed slots, outlined buttons, fields. At least 3:1 on every navy.
  static const line = Color(0xFF5B6A8F);

  /// Dividers between rows.
  static const divider = Color(0xFF1E2A46);
  static const text = Color(0xFFF5F7FC);
  static const muted = Color(0xFF949FBD);
  static const accent = Color(0xFF294DB8);
  static const accentLight = Color(0xFF8CB0FF);
  static const onAccent = Colors.white;

  /// Secondary text on the navy band and on foils.
  static const onBand = Color(0xFFDCE6FF);

  /// Sticker paper (a logged set) and the ink printed on it.
  static const paper = Color(0xFFF5F7FC);
  static const paperInk = Color(0xFF0A1224);
  static const paperCaption = Color(0xFF5B6A8F);

  /// Selected number on the keypad's paper sticker ("typing replaces this").
  static const paperSelection = Color(0xFFC9D8FF);

  /// A logged set / logged cardio time: dark sticker with a light-blue edge.
  static const stickerFill = Color(0xFF141E36);
  static const stickerEdge = Color(0xFF8CB0FF);
  static const stickerInk = Color(0xFFF5F7FC);
  static const stickerCaption = Color(0xFF8CB0FF);
  static const danger = Color(0xFFE5675F);
  static const dangerOutline = Color(0xFFB0504F);
  static const scrim = Color(0xBF050914);
}

class AppSpace {
  AppSpace._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const screen = 16.0;
}

class AppRadius {
  AppRadius._();

  static const card = 16.0;
  static const chip = 8.0;
  static const sticker = 6.0;
  static const button = 28.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

class AppFonts {
  AppFonts._();

  static const body = 'Archivo';

  /// Condensed heavy numerals and band titles.
  static const condensed = 'ArchivoCondensed';
}

class AppText {
  AppText._();

  static const _tabular = [FontFeature.tabularFigures()];

  /// Screen headline: "Pull B is next".
  static const display = TextStyle(
      fontFamily: AppFonts.condensed, fontSize: 34, height: 1.05, fontWeight: FontWeight.w800, color: AppColors.text);
  static const title = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text);

  /// Exercise name inside the navy band.
  static const band = TextStyle(
      fontFamily: AppFonts.condensed, fontSize: 21, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.onAccent);
  static const section = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text);
  static const cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text);
  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text);

  /// Weight on a sticker, slot or the keypad.
  static const sticker = TextStyle(
      fontFamily: AppFonts.condensed,
      fontSize: 24,
      height: 1,
      fontWeight: FontWeight.w800,
      fontFeatures: _tabular,
      color: AppColors.paperInk);
  static const chip = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFeatures: _tabular);
  static const caption = TextStyle(fontSize: 13, color: AppColors.muted);
  static const small = TextStyle(fontSize: 12, color: AppColors.muted);
  static const label = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondaryContainer: AppColors.accent,
    onSecondaryContainer: AppColors.onAccent,
    surface: AppColors.bg,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.line,
    outlineVariant: AppColors.divider,
    error: AppColors.danger,
  );
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.body,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontFamily: AppFonts.body, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      showDragHandle: true,
      dragHandleColor: AppColors.line,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.card),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: pill,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.accentLight,
        side: const BorderSide(color: AppColors.line),
        shape: pill,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.accentLight,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.paper,
      contentTextStyle: TextStyle(fontFamily: AppFonts.body, color: AppColors.paperInk, fontSize: 14, fontWeight: FontWeight.w500),
      actionTextColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.accentLight, width: 2),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accentLight,
      selectionColor: AppColors.accent,
      selectionHandleColor: AppColors.accentLight,
    ),
  );
}
