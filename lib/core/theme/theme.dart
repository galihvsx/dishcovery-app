import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light = FlexThemeData.light(
    scheme: FlexScheme.shadRed,
    useMaterial3ErrorColors: true,
    swapLegacyOnMaterial3: true,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      adaptiveRadius: FlexAdaptive.all(),
      defaultRadius: 24.0,
      defaultRadiusAdaptive: 24.0,
      checkboxSchemeColor: SchemeColor.primary,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorIsFilled: true,
      inputDecoratorIsDense: true,
      inputDecoratorBackgroundAlpha: 14,
      inputDecoratorBorderSchemeColor: SchemeColor.primary,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorRadius: 10.0,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorFocusedBorderWidth: 1.0,
      inputDecoratorPrefixIconSchemeColor: SchemeColor.onPrimaryFixedVariant,
      chipBlendColors: true,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    visualDensity: VisualDensity.comfortable,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  static ThemeData dark = FlexThemeData.dark(
    scheme: FlexScheme.shadRed,
    useMaterial3ErrorColors: true,
    swapLegacyOnMaterial3: true,
    darkIsTrueBlack: true,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      adaptiveRadius: FlexAdaptive.all(),
      defaultRadius: 24.0,
      defaultRadiusAdaptive: 24.0,
      checkboxSchemeColor: SchemeColor.primary,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorIsFilled: true,
      inputDecoratorIsDense: true,
      inputDecoratorBackgroundAlpha: 45,
      inputDecoratorBorderSchemeColor: SchemeColor.primary,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorRadius: 10.0,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorFocusedBorderWidth: 1.0,
      inputDecoratorPrefixIconSchemeColor: SchemeColor.primaryFixed,
      chipBlendColors: true,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    visualDensity: VisualDensity.comfortable,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
