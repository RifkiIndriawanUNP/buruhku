import 'package:flutter/material.dart';

// ---------- palet ----------
const cW = Colors.white;
const g50 = Color(0xFFF7F7F7);
const g100 = Color(0xFFEFEFEF);
const g200 = Color(0xFFDDDDDD);
const g300 = Color(0xFFC2C2C2);
const g400 = Color(0xFFA3A3A3);
const g500 = Color(0xFF808080);
const g700 = Color(0xFF4A4A4A);
const g900 = Color(0xFF1C1C1C);

/// Latar halaman (abu-abu muda seperti menu Akun). Kartu putih rata di atasnya. Bukan putih murni.
const cBg = Color(0xFFF2F3F7);

const kGreen = Color(0xFF1FA75A);
const kStar = Color(0xFFFFB400); // semua bintang rating
const kGreenLt = Color(0xFF7BD39A);
const kGreenBg = Color(0xFFDDF4E6); // latar hijau muda (chip terpilih)
const kBgGray = cBg; // nama lain untuk cBg (dipakai kode v4)
const kLine = Color(0xFFDCDDE1); // garis tipis kartu dan tombol
const kRed = Color(0xFFE5484D);

// ---------- skala tipografi, jarak, radius ----------
// Pakai nilai di bawah ini untuk semua teks dan jarak baru. Jangan membuat ukuran lepas.

/// Skala tipografi (9 langkah). Judul tebal (w800), isi normal, keterangan abu-abu.
class AppText {
  static const display = TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1, color: g900); // angka besar
  static const headline = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: g900); // judul halaman/tab
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, color: g900); // judul bagian dan kartu besar
  static const subtitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: g900); // judul item daftar
  static const bodyLg = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35, color: g900); // isi utama dan input
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.3, color: g900); // isi biasa
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: g700); // label dan info kedua
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3, color: g500); // keterangan
  static const micro = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: g500); // tag dan lencana
}

/// Skala jarak (kelipatan 4, ditambah setengah langkah 2 dan 6).
class AppSpace {
  static const xxs = 2.0, xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

/// Skala radius: kecil 8, sedang 12, besar 16, kartu 22, pil penuh.
class AppRadius {
  static const sm = 8.0, md = 12.0, lg = 16.0, card = 22.0, pill = 999.0;
}

ThemeData buildTheme() {
  final b = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLine));
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(26));
  return ThemeData(
    useMaterial3: true,
    shadowColor: Colors.transparent, // tanpa bayangan di semua widget Material (gaya flat)
    colorScheme: const ColorScheme.light(
        primary: kGreen, onPrimary: cW, secondary: g700, onSecondary: cW, surface: cW, onSurface: g900,
        error: kRed, onError: cW, outline: kLine, outlineVariant: g200,
        primaryContainer: kGreenBg, onPrimaryContainer: g900, secondaryContainer: kGreenBg, onSecondaryContainer: g900),
    scaffoldBackgroundColor: kBgGray,
    textTheme: const TextTheme(
      displayLarge: AppText.display, headlineMedium: AppText.headline, titleLarge: AppText.title, titleMedium: AppText.subtitle,
      bodyLarge: AppText.bodyLg, bodyMedium: AppText.body, bodySmall: AppText.caption,
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700), labelMedium: AppText.label, labelSmall: AppText.micro),
    appBarTheme: const AppBarTheme(
        backgroundColor: kBgGray, foregroundColor: g900, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: g900, fontSize: 18, fontWeight: FontWeight.w800)),
    inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: cW,
        border: b, enabledBorder: b, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        focusedBorder: b.copyWith(borderSide: const BorderSide(color: kGreen, width: 1.5)),
        errorBorder: b.copyWith(borderSide: const BorderSide(color: kRed)),
        focusedErrorBorder: b.copyWith(borderSide: const BorderSide(color: kRed, width: 1.5)),
        disabledBorder: b.copyWith(borderSide: const BorderSide(color: g200)),
        labelStyle: const TextStyle(color: g500), errorStyle: const TextStyle(color: kRed)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: kGreen, foregroundColor: cW, minimumSize: const Size(64, 48), shape: pill,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: g900, backgroundColor: cW, side: const BorderSide(color: kLine), minimumSize: const Size(64, 48), shape: pill,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: g900)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: g900)),
    chipTheme: ChipThemeData(
        backgroundColor: cW, selectedColor: kGreenBg, side: const BorderSide(color: kLine), shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: g900, fontWeight: FontWeight.w600), checkmarkColor: kGreen),
    expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: cW, collapsedBackgroundColor: cW,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerTheme: const DividerThemeData(color: kLine, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cW, surfaceTintColor: Colors.transparent, showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: g900, contentTextStyle: const TextStyle(color: cW), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  );
}
