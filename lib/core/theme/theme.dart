import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme
  static ThemeData light = FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: Color(0xFFFF3131),
      primaryContainer: Color(0xFFFF6B6B),
      secondary: Color(0xFFFF3131),
      secondaryContainer: Color(0xFFFFA6A6),
      tertiary: Color(0xFFFF6B6B),
      tertiaryContainer: Color(0xFFFFC1C1),
      appBarColor: Color(0xFFFFFFFF),
      error: Color(0xFFE53935),
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 0,
    scaffoldBackground: const Color(0xFFFFFFFF),
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 0,
      blendOnColors: false,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    fontFamily: GoogleFonts.poppins().fontFamily,
  );

  // Dark Theme
  static ThemeData dark = FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: Color(0xFFFF3131),
      primaryContainer: Color(0xFFFF6B6B),
      secondary: Color(0xFFFF3131),
      secondaryContainer: Color(0xFFFFA6A6),
      tertiary: Color(0xFFFF6B6B),
      tertiaryContainer: Color(0xFFFFC1C1),
      appBarColor: Color(0xFF1E1E1E),
      error: Color(0xFFE53935),
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 0, 
    scaffoldBackground: const Color(0xFF121212),
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 0,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    fontFamily: GoogleFonts.poppins().fontFamily,
  );
}
