import 'package:flutter/material.dart';

// Saytdagi `src/styles/tokens.css` ning nusxasi: ranglar, shriftlar, oraliqlar,
// burchaklar va soyalar faqat shu yerda. Palitra: o'rmon yashili, terrakota,
// xantal va po'stloq jigarrangi — iliq qog'oz fonida.

// ── Yuzalar ─────────────────────────────────────────────────────
const kBg = Color(0xFFFBF7F0);
const kSurface = Color(0xFFFFFFFF);
const kSurfaceMuted = Color(0xFFF4EEE4);
const kSurfaceSunken = Color(0xFFEBE3D6);
const kPaper = Color(0xFFFDF3E3);

// ── Matn ────────────────────────────────────────────────────────
const kInk = Color(0xFF1F2B24);
const kInkSoft = Color(0xFF3A4740);
const kMuted = Color(0xFF5D695F);
const kFaint = Color(0xFF8A938C);

// ── Chiziqlar ───────────────────────────────────────────────────
const kBorder = Color(0xFFE8E0D3);
const kBorderStrong = Color(0xFFD2C7B6);

// ── Brend: o'rmon yashili ───────────────────────────────────────
const kBrand = Color(0xFF2F4A33);
const kBrandHover = Color(0xFF243A28);
const kBrandSoft = Color(0xFFE4ECE0);
const kOnBrand = Color(0xFFFFFFFF);

// ── Amal: terrakota ─────────────────────────────────────────────
const kAccent = Color(0xFFBF4F27);
const kAccentHover = Color(0xFFA5421F);
const kAccentInk = Color(0xFF9C3E1C);
const kAccentSoft = Color(0xFFFBE5DA);
const kOnAccent = Color(0xFFFFFFFF);

// ── Ajratish: xantal ────────────────────────────────────────────
const kSun = Color(0xFFE6AC3F);
const kSunSoft = Color(0xFFFCEFD2);
const kOnSun = Color(0xFF2B2112);

/// Po'stloq jigarrangi — kichik belgilar uchun.
const kBark = Color(0xFF5A3A29);

// ── To'q bloklar (futer, kalkulyator) ───────────────────────────
const kDark = Color(0xFF1E3123);
const kDarkRaised = Color(0xFF28402E);
const kDarkLine = Color(0xFF3B5641);
const kOnDark = Color(0xFFF7F1E6);
const kOnDarkMuted = Color(0xFFB9C6B8);

// ── Hayvon fonlari: rasm foni kim uchunligini aytadi ────────────
const kTintCat = Color(0xFFFBE3D5);
const kTintDog = Color(0xFFE2EBDC);
const kTintBird = Color(0xFFFCEFCF);
const kTintFish = Color(0xFFDCEBF0);
const kTintSmall = Color(0xFFECE3F2);
const kTintOther = Color(0xFFF1EADF);

// ── Holatlar ────────────────────────────────────────────────────
const kSuccess = Color(0xFF2E7A4B);
const kSuccessSoft = Color(0xFFE2F1E6);
const kDanger = Color(0xFFB3261E);
const kDangerSoft = Color(0xFFFBE9E8);
const kWarning = Color(0xFF8A5300);
const kWarningSoft = Color(0xFFFDF0D9);

// ── Shriftlar: sarlavha va narx — Nunito, matn — Onest ──────────
const kFontDisplay = 'Nunito';
const kFontSans = 'Onest';

const kText2xs = 11.0;
const kTextXs = 12.0;
const kTextSm = 14.0;
const kTextMd = 16.0;
const kTextLg = 18.0;
const kTextXl = 22.0;
const kText2xl = 28.0;

/// `clamp(1.875rem, 1.4rem + 1.8vw, 2.625rem)`.
double text3xl(BuildContext context) => _clampVw(context, 30, 22.4, 1.8, 42);

/// `clamp(2.25rem, 1.5rem + 2.8vw, 3.5rem)`.
double textDisplay(BuildContext context) => _clampVw(context, 36, 24, 2.8, 56);

/// CSS `clamp(min, base + k·vw, max)`.
double clampVw(BuildContext context, double min, double base, double vw, double max) =>
    _clampVw(context, min, base, vw, max);

double _clampVw(BuildContext context, double min, double base, double vw, double max) {
  final width = MediaQuery.sizeOf(context).width;
  return (base + vw * width / 100).clamp(min, max).toDouble();
}

// ── Oraliqlar (4px to'r) ────────────────────────────────────────
const kSpace1 = 4.0;
const kSpace2 = 8.0;
const kSpace3 = 12.0;
const kSpace4 = 16.0;
const kSpace5 = 20.0;
const kSpace6 = 24.0;
const kSpace8 = 32.0;
const kSpace10 = 40.0;
const kSpace12 = 48.0;
const kSpace16 = 64.0;

/// Telefon kengligida yon chekka (`--gutter`).
const kGutter = 16.0;

// ── Burchaklar: logodagidek yumshoq ─────────────────────────────
const kRadiusXs = 6.0;
const kRadiusSm = 10.0;
const kRadiusMd = 14.0;
const kRadiusLg = 20.0;
const kRadiusXl = 28.0;
const kRadiusFull = 999.0;

// ── Soyalar: iliq va past ───────────────────────────────────────
const kShadowSm = [BoxShadow(color: Color(0x12402E18), blurRadius: 2, offset: Offset(0, 1))];
const kShadowMd = [BoxShadow(color: Color(0x17402E18), blurRadius: 24, offset: Offset(0, 8))];
const kShadowLg = [BoxShadow(color: Color(0x331F2B24), blurRadius: 60, offset: Offset(0, 24))];

/// Pastki menyu balandligi (`--mobile-nav-height`).
const kMobileNavHeight = 64.0;

/// Sahifa pastida suzuvchi menyu ostida qoladigan joy.
double navClearance(BuildContext context) =>
    kMobileNavHeight + kSpace2 + kSpace4 + MediaQuery.paddingOf(context).bottom;

const kEase = Cubic(0.2, 0.7, 0.2, 1);
const kEaseBounce = Cubic(0.34, 1.4, 0.64, 1);
const kDuration = Duration(milliseconds: 160);

// ── Matn uslublari ──────────────────────────────────────────────
TextStyle display(double size, {FontWeight weight = FontWeight.w900, Color color = kInk, double? height, double? letterSpacing}) =>
    TextStyle(fontFamily: kFontDisplay, fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

TextStyle sans(double size, {FontWeight weight = FontWeight.w400, Color color = kInk, double? height, double? letterSpacing}) =>
    TextStyle(fontFamily: kFontSans, fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

/// "XARIDNI BOSHLANG" kabi kichik katta harfli yorliq.
TextStyle eyebrow({Color color = kAccentInk}) =>
    sans(kTextXs, weight: FontWeight.w700, color: color, letterSpacing: kTextXs * .06);

ThemeData buildTheme() => ThemeData(
      fontFamily: kFontSans,
      colorScheme: ColorScheme.fromSeed(seedColor: kBrand, primary: kBrand, secondary: kAccent, surface: kBg),
      scaffoldBackgroundColor: kBg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      useMaterial3: true,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: kFontSans, fontSize: kTextMd, height: 1.55, color: kInk),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: kBrand,
        selectionColor: kSunSoft,
        selectionHandleColor: kBrand,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBrand),
    );
