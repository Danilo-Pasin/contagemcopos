import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System — tema light e dark do app Contagem.
///
/// Inspirado em Discord/Spotify/Linear: tons profundos, acentos vibrantes,
/// glassmorphism, bordas arredondadas e sombras discretas.
class AppTheme {
  const AppTheme._();

  // Marcas de cor
  static const Color primary = Color(0xFF7C4DFF);
  static const Color secondary = Color(0xFFE040FB);
  static const Color accent = Color(0xFFFFB300);

  static const FlexSchemeColor _light = FlexSchemeColor(
    primary: Color(0xFF6C3CE0),
    primaryContainer: Color(0xFFE9DEFF),
    secondary: Color(0xFFC218C0),
    secondaryContainer: Color(0xFFFFD6F4),
    tertiary: Color(0xFFE08A00),
    tertiaryContainer: Color(0xFFFFE0A8),
    appBarColor: Color(0xFFE9DEFF),
    error: Color(0xFFBA1A1A),
  );

  static const FlexSchemeColor _dark = FlexSchemeColor(
    primary: Color(0xFFCFBCFF),
    primaryContainer: Color(0xFF4A29A8),
    secondary: Color(0xFFFFABEE),
    secondaryContainer: Color(0xFF821980),
    tertiary: Color(0xFFFFB873),
    tertiaryContainer: Color(0xFF795600),
    appBarColor: Color(0xFF161322),
    error: Color(0xFFFFB4AB),
  );

  static ThemeData light() => FlexThemeData.light(
        scheme: FlexScheme.deepPurple,
        colors: _light,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 18,
        appBarStyle: FlexAppBarStyle.surface,
        appBarOpacity: 0.9,
        transparentStatusBar: true,
        tabBarStyle: FlexTabBarStyle.forAppBar,
        tooltipsMatchBackground: true,
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnLevel: 20,
          blendOnColors: true,
          useM2StyleDividerInM3: true,
          filledButtonRadius: 16,
          elevatedButtonRadius: 16,
          outlinedButtonRadius: 16,
          textButtonRadius: 16,
          cardRadius: 22,
          chipRadius: 12,
          drawerRadius: 22,
          bottomSheetRadius: 28,
          inputDecoratorRadius: 14,
          inputDecoratorUnfocusedBorderIsColored: false,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
        fontFamily: GoogleFonts.inter().fontFamily,
      );

  static ThemeData dark() => FlexThemeData.dark(
        scheme: FlexScheme.deepPurple,
        colors: _dark,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 26,
        appBarStyle: FlexAppBarStyle.surface,
        appBarOpacity: 0.9,
        transparentStatusBar: true,
        scaffoldBackground: const Color(0xFF0B0E14),
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnLevel: 30,
          blendOnColors: true,
          useM2StyleDividerInM3: true,
          filledButtonRadius: 16,
          elevatedButtonRadius: 16,
          outlinedButtonRadius: 16,
          textButtonRadius: 16,
          cardRadius: 22,
          chipRadius: 12,
          drawerRadius: 22,
          bottomSheetRadius: 28,
          inputDecoratorRadius: 14,
          inputDecoratorUnfocusedBorderIsColored: false,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
        fontFamily: GoogleFonts.inter().fontFamily,
      );
}
