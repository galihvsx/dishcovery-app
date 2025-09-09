import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme
  static ThemeData light =
      FlexThemeData.light(
        scheme: FlexScheme.shadBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          bottomNavigationBarElevation: 8,
          bottomNavigationBarOpacity: 1.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        // Add custom text theme using Google Fonts
        fontFamily: GoogleFonts.poppins().fontFamily,
      ).copyWith(
        // Explicit bottom navigation bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      );

  // Dark Theme
  static ThemeData dark =
      FlexThemeData.dark(
        scheme: FlexScheme.shadBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          bottomNavigationBarElevation: 8,
          bottomNavigationBarOpacity: 1.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        // Add custom text theme using Google Fonts
        fontFamily: GoogleFonts.poppins().fontFamily,
      ).copyWith(
        // Explicit bottom navigation bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
