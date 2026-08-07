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
  static const Color primary = Color(0xFF1FB45C);
  static const Color secondary = Color(0xFF48E37F);
  static const Color accent = Color(0xFFFFB300);

  static const FlexSchemeColor _light = FlexSchemeColor(
    primary: Color(0xFF1E8E4B),
    primaryContainer: Color(0xFFBFF5D3),
    secondary: Color(0xFF37A16E),
    secondaryContainer: Color(0xFFC9EFDB),
    tertiary: Color(0xFFE08A00),
    tertiaryContainer: Color(0xFFFFE0A8),
    appBarColor: Color(0xFFDCF3E6),
    error: Color(0xFFBA1A1A),
  );

  static const FlexSchemeColor _dark = FlexSchemeColor(
    primary: Color(0xFF7FE98E),
    primaryContainer: Color(0xFF135A33),
    secondary: Color(0xFF9CE6B6),
    secondaryContainer: Color(0xFF226A41),
    tertiary: Color(0xFFFFB873),
    tertiaryContainer: Color(0xFF795600),
    appBarColor: Color(0xFF0F1E15),
    error: Color(0xFFFFB4AB),
  );

  static ThemeData light() => FlexThemeData.light(
        scheme: FlexScheme.green,
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
        scheme: FlexScheme.green,
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
