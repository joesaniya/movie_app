import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
// CINEPLEX — WARM EDITORIAL LUXURY THEME
// Aesthetic: Film-noir meets modern editorial.
// Palette: Warm charcoal, aged gold, cream, deep crimson.
// Fonts: Playfair Display (display) + DM Sans (body)
// ═══════════════════════════════════════════════

class AppTheme {
  // ── PALETTE ──────────────────────────────────
  static const Color inkBlack = Color(0xFF141210);
  static const Color charcoal = Color(0xFF1E1B18);
  static const Color graphite = Color(0xFF2C2822);
  static const Color warmGray = Color(0xFF3D3830);
  static const Color dustGray = Color(0xFF5C5449);
  static const Color ashGray = Color(0xFF8A8278);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color parchment = Color(0xFFEDE5D4);
  static const Color canvas = Color(0xFFD4C9B4);

  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFE8C470);
  static const Color goldDim = Color(0xFF8B6E2C);
  static const Color amber = Color(0xFFB8832A);

  static const Color crimson = Color(0xFFB33A3A);
  static const Color crimsonSoft = Color(0xFFCC4444);
  static const Color rose = Color(0xFFE8A0A0);

  static const Color jade = Color(0xFF3A7A5C);
  static const Color jadeSoft = Color(0xFF4A9A72);

  // ── SEMANTIC ─────────────────────────────────
  static const Color primaryColor = gold;
  static const Color accentColor = crimson;
  static const Color successColor = jade;
  static const Color errorColor = crimson;
  static const Color warningColor = amber;
  static const Color infoColor = Color(0xFF4A7BA8);
  static const Color surfaceColor = charcoal;
  static const Color backgroundColor = inkBlack;

  // ── TEXT ──────────────────────────────────────
  static const Color textPrimary = cream;
  static const Color textSecondary = canvas;
  static const Color textMuted = ashGray;
  static const Color textDisabled = dustGray;

  // ── GRADIENTS ────────────────────────────────
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [inkBlack, Color(0xFF1A1612), charcoal],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, amber],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF252018), Color(0xFF1C1914)],
  );

  static LinearGradient posterGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, inkBlack.withOpacity(0.6), inkBlack],
    stops: const [0.3, 0.7, 1.0],
  );

  // ── SHADOWS ──────────────────────────────────
  static List<BoxShadow> get goldGlow => [
    BoxShadow(color: gold.withOpacity(0.25), blurRadius: 20, spreadRadius: 0),
    BoxShadow(color: gold.withOpacity(0.08), blurRadius: 40, spreadRadius: 4),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(color: gold.withOpacity(0.04), blurRadius: 40, spreadRadius: 2),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.8),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // ── BORDER RADIUS ────────────────────────────
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 28.0;

  // ── THEME DATA ───────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: inkBlack,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: crimson,
      surface: charcoal,
      error: crimson,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: inkBlack,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: cream),
      titleTextStyle: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: cream,
        letterSpacing: 0.3,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: cream,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: cream,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: cream,
        letterSpacing: -0.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: cream,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: cream,
      ),
      titleLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: cream,
      ),
      titleMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: cream,
      ),
      titleSmall: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: canvas,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: cream,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: canvas,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ashGray,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: gold,
        letterSpacing: 0.8,
      ),
      labelMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ashGray,
        letterSpacing: 1.2,
      ),
      labelSmall: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: dustGray,
        letterSpacing: 1.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: graphite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: warmGray, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: warmGray, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'DMSans',
        color: dustGray,
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'DMSans',
        color: ashGray,
        fontSize: 14,
      ),
      prefixIconColor: ashGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: inkBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cream,
        side: const BorderSide(color: warmGray, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: charcoal,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: BorderSide(color: warmGray.withOpacity(0.5), width: 0.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: graphite,
      contentTextStyle: const TextStyle(
        fontFamily: 'DMSans',
        color: cream,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: charcoal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
        side: BorderSide(color: warmGray, width: 0.5),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: cream,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: warmGray.withOpacity(0.4),
      thickness: 0.5,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: graphite,
      selectedColor: gold.withOpacity(0.2),
      side: BorderSide(color: warmGray, width: 0.5),
      labelStyle: const TextStyle(
        fontFamily: 'DMSans',
        fontSize: 12,
        color: canvas,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: inkBlack,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
    ),
  );
}
