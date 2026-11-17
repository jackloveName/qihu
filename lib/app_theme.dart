import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFEFEDE4);
  static const canvas2 = Color(0xFFE6E3D8);
  static const paper = Color(0xFFFCFBF7);
  static const paper2 = Color(0xFFF5F3EB);
  static const paper3 = Color(0xFFEDEBE1);

  static const ink = Color(0xFF15211C);
  static const ink2 = Color(0xFF3A4A42);
  static const muted = Color(0xFF75817A);
  static const faint = Color(0xFFA6AEA8);

  static const hair = Color(0xFFE2DFD3);
  static const hair2 = Color(0xFFD3CFBE);

  static const brand = Color(0xFF1D4A3D);
  static const brand2 = Color(0xFF2C6A57);
  static const brand3 = Color(0xFF123027);
  static const brandWash = Color(0xFFE3ECE7);
  static const brandLine = Color(0xFFC6D8CF);

  static const brass = Color(0xFFA2854A);
  static const brass2 = Color(0xFFC6A663);
  static const brassWash = Color(0xFFF4EDDC);

  static const amber = Color(0xFFB0762F);
  static const amberWash = Color(0xFFF6EBD9);
  static const rose = Color(0xFFA85F58);
  static const roseWash = Color(0xFFF6E4E1);
  static const blue = Color(0xFF46688A);
  static const blueWash = Color(0xFFE4EBF2);

  static const shadow = Color(0x2415211C);
}

abstract final class AppText {
  static const sans = 'PingFang SC';
  static const serif = 'Songti SC';
  static const mono = 'SF Mono';

  static TextStyle display(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
    double height = 1.2,
    double spacing = -0.3,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontFamilyFallback: const ['Songti SC', 'STSong', 'PingFang SC'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );
  }

  static TextStyle body(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    double spacing = 0,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontFamilyFallback: const ['PingFang SC', 'Helvetica Neue', 'sans-serif'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  static TextStyle number(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w600,
    double spacing = -0.2,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontFamilyFallback: const ['Menlo', 'monospace'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: Color(0xFFF4F1E6),
    secondary: AppColors.brass,
    onSecondary: Color(0xFF241C0C),
    error: AppColors.rose,
    onError: Colors.white,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: AppText.sans,
    fontFamilyFallback: const ['PingFang SC', 'Helvetica Neue', 'sans-serif'],
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.brand,
      selectionColor: Color(0x442C6A57),
      selectionHandleColor: AppColors.brand,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      hintStyle: AppText.body(13, color: AppColors.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hair),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandLine),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink.withValues(alpha: 0.96),
      contentTextStyle: AppText.body(
        12,
        color: const Color(0xFFF2EFE4),
        weight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 104),
      elevation: 8,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
