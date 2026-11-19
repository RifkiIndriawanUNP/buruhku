import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- palet terang dan gelap ----------
// Semua warna netral dibaca lewat getter di bawah, jadi kode lama (`g900`, `cW`, `kLine`, ...) tidak berubah,
// tetapi nilainya mengikuti mode. Warna merek (hijau, merah, bintang) sama di kedua mode.

class AppPalette {
  final Color cW, g50, g100, g200, g300, g400, g500, g700, g900, cBg, kLine, kLine2, kGreenBg;
  final Color kPh, kPhIcon, kAvatarBg, kAvatarIcon, kTrack, kWarnBg, kNavy, kSubGray;
  final Color kOkBg, kOkFg, kBadBg, kBadFg, kInfoBg, kInfoFg, kWaitBg, kWaitFg;
  final bool isDark;
  const AppPalette({
    required this.isDark,
    required this.cW, required this.g50, required this.g100, required this.g200, required this.g300, required this.g400,
    required this.g500, required this.g700, required this.g900, required this.cBg, required this.kLine, required this.kLine2,
    required this.kGreenBg, required this.kPh, required this.kPhIcon, required this.kAvatarBg, required this.kAvatarIcon,
    required this.kTrack, required this.kWarnBg, required this.kNavy, required this.kSubGray,
    required this.kOkBg, required this.kOkFg, required this.kBadBg, required this.kBadFg,
    required this.kInfoBg, required this.kInfoFg, required this.kWaitBg, required this.kWaitFg,
  });

  static const light = AppPalette(
    isDark: false,
    cW: Colors.white, g50: Color(0xFFF7F7F7), g100: Color(0xFFEFEFEF), g200: Color(0xFFDDDDDD), g300: Color(0xFFC2C2C2),
    g400: Color(0xFFA3A3A3), g500: Color(0xFF808080), g700: Color(0xFF4A4A4A), g900: Color(0xFF1C1C1C),
    cBg: Color(0xFFF2F3F7), kLine: Color(0xFFDCDDE1), kLine2: Color(0xFFE3E4E8), kGreenBg: Color(0xFFDDF4E6),
    kPh: Color(0xFFE4E5E9), kPhIcon: Color(0xFFB4B6BE), kAvatarBg: Color(0xFFDADADA), kAvatarIcon: Color(0xFFAEB0B8),
    kTrack: Color(0xFFEDEEF2), kWarnBg: Color(0xFFFFF4E0), kNavy: Color(0xFF1A2B5F), kSubGray: Color(0xFF8E8E93),
    kOkBg: Color(0xFFDDF5E7), kOkFg: Color(0xFF0B7A41), kBadBg: Color(0xFFFFE3E3), kBadFg: Color(0xFFC62828),
    kInfoBg: Color(0xFFE3EDFF), kInfoFg: Color(0xFF2751B8), kWaitBg: Color(0xFFFFF1D0), kWaitFg: Color(0xFF9A6B00),
  );

  /// Latar halaman paling gelap, kartu satu tingkat lebih terang (kebalikan dari mode terang).
  static const dark = AppPalette(
    isDark: true,
    cW: Color(0xFF1C1D22), g50: Color(0xFF202127), g100: Color(0xFF26272D), g200: Color(0xFF33353C), g300: Color(0xFF4A4D56),
    g400: Color(0xFF6B6E78), g500: Color(0xFF9A9DA6), g700: Color(0xFFC5C7CE), g900: Color(0xFFF1F2F5),
    cBg: Color(0xFF0F1013), kLine: Color(0xFF33353C), kLine2: Color(0xFF3A3C44), kGreenBg: Color(0xFF1B3A29),
    kPh: Color(0xFF2A2C32), kPhIcon: Color(0xFF5A5D66), kAvatarBg: Color(0xFF33353C), kAvatarIcon: Color(0xFF6B6E78),
    kTrack: Color(0xFF2A2C32), kWarnBg: Color(0xFF3A2E14), kNavy: Color(0xFF9DB4FF), kSubGray: Color(0xFFA0A3AB),
    kOkBg: Color(0xFF1B3A29), kOkFg: Color(0xFF6FD39A), kBadBg: Color(0xFF3F1D1F), kBadFg: Color(0xFFFF8A8D),
    kInfoBg: Color(0xFF1F2A44), kInfoFg: Color(0xFF8FB0FF), kWaitBg: Color(0xFF3A2E14), kWaitFg: Color(0xFFF2C14E),
  );

  /// Palet yang sedang dipakai. Diatur oleh [BuruhkuApp] sebelum membangun halaman.
  static AppPalette current = light;
}

bool get isDarkMode => AppPalette.current.isDark;

Color get cW => AppPalette.current.cW;
Color get g50 => AppPalette.current.g50;
Color get g100 => AppPalette.current.g100;
Color get g200 => AppPalette.current.g200;
Color get g300 => AppPalette.current.g300;
Color get g400 => AppPalette.current.g400;
Color get g500 => AppPalette.current.g500;
Color get g700 => AppPalette.current.g700;
Color get g900 => AppPalette.current.g900;

/// Latar halaman (abu-abu muda seperti menu Akun). Kartu rata di atasnya. Bukan putih murni.
Color get cBg => AppPalette.current.cBg;
Color get kBgGray => AppPalette.current.cBg; // nama lain untuk cBg (dipakai kode v4)
Color get kLine => AppPalette.current.kLine; // garis tipis kartu dan tombol
Color get kLine2 => AppPalette.current.kLine2; // garis pil tidak terpilih, jalur bar
Color get kGreenBg => AppPalette.current.kGreenBg; // latar hijau muda (chip terpilih)
Color get kPh => AppPalette.current.kPh; // latar placeholder foto
Color get kPhIcon => AppPalette.current.kPhIcon;
Color get kAvatarBg => AppPalette.current.kAvatarBg;
Color get kAvatarIcon => AppPalette.current.kAvatarIcon;
Color get kTrack => AppPalette.current.kTrack;
Color get kWarnBg => AppPalette.current.kWarnBg;
Color get kNavy => AppPalette.current.kNavy; // bintang & ikon statistik
Color get kSubGray => AppPalette.current.kSubGray;
Color get kOkBg => AppPalette.current.kOkBg;
Color get kOkFg => AppPalette.current.kOkFg;
Color get kBadBg => AppPalette.current.kBadBg;
Color get kBadFg => AppPalette.current.kBadFg;
Color get kInfoBg => AppPalette.current.kInfoBg;
Color get kInfoFg => AppPalette.current.kInfoFg;
Color get kWaitBg => AppPalette.current.kWaitBg;
Color get kWaitFg => AppPalette.current.kWaitFg;

const kGreen = Color(0xFF1FA75A);
const kStar = Color(0xFFFFB400); // semua bintang rating
const kGreenLt = Color(0xFF7BD39A);
const kRed = Color(0xFFE5484D);


// ---------- pilihan tampilan (terang / gelap / ikuti sistem) ----------

enum AppThemeMode { system, light, dark }

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();
  static const _key = 'theme_mode';

  /// Default adalah [AppThemeMode.light] (Mode Terang bawaan aplikasi).
  AppThemeMode mode = AppThemeMode.light;

  Future<void> load() async {
    try {
      final v = (await SharedPreferences.getInstance()).getString(_key);
      mode = AppThemeMode.values.firstWhere((m) => m.name == v, orElse: () => AppThemeMode.light);
    } catch (_) {}
  }

  Future<void> set(AppThemeMode m) async {
    if (m == mode) return;
    mode = m;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, m.name);
    } catch (_) {}
  }

  Future<void> toggleDark() async {
    await set(mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark);
  }

  static String label(AppThemeMode m) => switch (m) {
        AppThemeMode.system => 'Ikuti sistem',
        AppThemeMode.light => 'Terang (Bawaan)',
        AppThemeMode.dark => 'Gelap',
      };

  /// Gelap atau tidak, untuk [platform] (kecerahan sistem) saat ini.
  bool resolveDark(Brightness platform) => switch (mode) {
        AppThemeMode.dark => true,
        AppThemeMode.light => false,
        AppThemeMode.system => platform == Brightness.dark,
      };
}

// ---------- skala tipografi, jarak, radius ----------
// Pakai nilai di bawah ini untuk semua teks dan jarak baru. Jangan membuat ukuran lepas.

/// Skala tipografi (9 langkah). Judul tebal (w800), isi normal, keterangan abu-abu.
class AppText {
  static TextStyle get display => TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1, color: g900); // angka besar
  static TextStyle get headline => TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: g900); // judul halaman/tab
  static TextStyle get title => TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, color: g900); // judul bagian dan kartu besar
  static TextStyle get subtitle => TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: g900); // judul item daftar
  static TextStyle get bodyLg => TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35, color: g900); // isi utama dan input
  static TextStyle get body => TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.3, color: g900); // isi biasa
  static TextStyle get label => TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: g700); // label dan info kedua
  static TextStyle get caption => TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3, color: g500); // keterangan
  static TextStyle get micro => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: g500); // tag dan lencana
}

/// Skala jarak (kelipatan 4, ditambah setengah langkah 2 dan 6).
class AppSpace {
  static const xxs = 2.0, xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

/// Skala radius: kecil 8, sedang 12, besar 16, kartu 22, pil penuh.
class AppRadius {
  static const sm = 8.0, md = 12.0, lg = 16.0, card = 22.0, pill = 999.0;
}

/// Tema Material untuk satu palet. Dipakai sebagai `theme` (terang) dan `darkTheme` (gelap).
ThemeData buildTheme([AppPalette p = AppPalette.light]) {
  final b = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.kLine));
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(26));
  TextStyle t(double size, FontWeight w, {double? h, Color? c}) => TextStyle(fontSize: size, fontWeight: w, height: h, color: c ?? p.g900);
  final scheme = (p.isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
    primary: kGreen, onPrimary: Colors.white, secondary: p.g700, onSecondary: p.cW, surface: p.cW, onSurface: p.g900,
    error: kRed, onError: Colors.white, outline: p.kLine, outlineVariant: p.g200,
    primaryContainer: p.kGreenBg, onPrimaryContainer: p.g900, secondaryContainer: p.kGreenBg, onSecondaryContainer: p.g900,
    surfaceContainerHighest: p.g100, surfaceContainerHigh: p.g100, surfaceContainer: p.g50, surfaceContainerLow: p.g50, surfaceContainerLowest: p.cW,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: p.isDark ? Brightness.dark : Brightness.light,
    shadowColor: Colors.transparent, // tanpa bayangan di semua widget Material (gaya flat)
    colorScheme: scheme,
    scaffoldBackgroundColor: p.cBg,
    canvasColor: p.cW,
    textTheme: TextTheme(
      displayLarge: t(34, FontWeight.w800, h: 1.1), headlineMedium: t(22, FontWeight.w800, h: 1.2), titleLarge: t(18, FontWeight.w800, h: 1.25),
      titleMedium: t(16, FontWeight.w700, h: 1.3), bodyLarge: t(15, FontWeight.w500, h: 1.35), bodyMedium: t(14, FontWeight.w400, h: 1.3),
      bodySmall: t(12, FontWeight.w500, h: 1.3, c: p.g500),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.g900), labelMedium: t(13, FontWeight.w600, h: 1.3, c: p.g700),
      labelSmall: t(11, FontWeight.w600, h: 1.2, c: p.g500)),
    appBarTheme: AppBarTheme(
        backgroundColor: p.cBg, foregroundColor: p.g900, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: p.g900, fontSize: 18, fontWeight: FontWeight.w800)),
    inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: p.cW,
        border: b, enabledBorder: b, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        focusedBorder: b.copyWith(borderSide: const BorderSide(color: kGreen, width: 1.5)),
        errorBorder: b.copyWith(borderSide: const BorderSide(color: kRed)),
        focusedErrorBorder: b.copyWith(borderSide: const BorderSide(color: kRed, width: 1.5)),
        disabledBorder: b.copyWith(borderSide: BorderSide(color: p.g200)),
        labelStyle: TextStyle(color: p.g500), hintStyle: TextStyle(color: p.g400), errorStyle: const TextStyle(color: kRed)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: kGreen, foregroundColor: Colors.white, minimumSize: const Size(64, 48), shape: pill,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: p.g900, backgroundColor: p.cW, side: BorderSide(color: p.kLine), minimumSize: const Size(64, 48), shape: pill,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.g900)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: p.g900)),
    iconTheme: IconThemeData(color: p.g900),
    listTileTheme: ListTileThemeData(iconColor: p.g900, textColor: p.g900),
    chipTheme: ChipThemeData(
        backgroundColor: p.cW, selectedColor: p.kGreenBg, side: BorderSide(color: p.kLine), shape: const StadiumBorder(),
        labelStyle: TextStyle(color: p.g900, fontWeight: FontWeight.w600), checkmarkColor: kGreen),
    expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: p.cW, collapsedBackgroundColor: p.cW,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerTheme: DividerThemeData(color: p.kLine, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(backgroundColor: p.cW, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(color: p.cW, surfaceTintColor: Colors.transparent, textStyle: TextStyle(color: p.g900, fontSize: 14)),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.cW, surfaceTintColor: Colors.transparent, showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.g100 : const Color(0xFF1C1C1C), contentTextStyle: TextStyle(color: p.isDark ? p.g900 : Colors.white),
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  );
}
