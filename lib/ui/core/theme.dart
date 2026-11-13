import 'package:flutter/material.dart';

// ---------- palet grayscale ----------
const cW = Colors.white;
const g50 = Color(0xFFF7F7F7);
const g100 = Color(0xFFEFEFEF);
const g200 = Color(0xFFDDDDDD);
const g300 = Color(0xFFC2C2C2);
const g400 = Color(0xFFA3A3A3);
const g500 = Color(0xFF808080);
const g700 = Color(0xFF4A4A4A);
const g900 = Color(0xFF1C1C1C);

const kGreen = Color(0xFF1FA75A);
const kGreenLt = Color(0xFF7BD39A);

ThemeData buildTheme() {
  final b = OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: g300));
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
        primary: g900, onPrimary: cW, secondary: g700, onSecondary: cW, surface: cW, onSurface: g900,
        error: g900, onError: cW, outline: g300, outlineVariant: g200,
        primaryContainer: g200, onPrimaryContainer: g900, secondaryContainer: g200, onSecondaryContainer: g900),
    scaffoldBackgroundColor: cW,
    appBarTheme: const AppBarTheme(
        backgroundColor: cW, foregroundColor: g900, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        surfaceTintColor: Colors.transparent, shape: Border(bottom: BorderSide(color: g200)),
        titleTextStyle: TextStyle(color: g900, fontSize: 18, fontWeight: FontWeight.w600)),
    inputDecorationTheme: InputDecorationTheme(
        border: b, enabledBorder: b, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        focusedBorder: b.copyWith(borderSide: const BorderSide(color: g900, width: 1.5)),
        errorBorder: b.copyWith(borderSide: const BorderSide(color: g700)),
        focusedErrorBorder: b.copyWith(borderSide: const BorderSide(color: g900, width: 1.5)),
        labelStyle: const TextStyle(color: g500), errorStyle: const TextStyle(color: g700)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: g900, foregroundColor: cW, minimumSize: const Size(64, 46), shape: shape)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: g900, side: const BorderSide(color: g900), minimumSize: const Size(64, 46), shape: shape)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: g900)),
    dividerTheme: const DividerThemeData(color: g200, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: cW, surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(backgroundColor: g900, contentTextStyle: TextStyle(color: cW), behavior: SnackBarBehavior.floating),
  );
}
