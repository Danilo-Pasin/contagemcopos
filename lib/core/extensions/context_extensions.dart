import 'package:flutter/material.dart';

/// Extensões úteis do BuildContext.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get tt => Theme.of(this).textTheme;
  ColorScheme get cs => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Breakpoints de responsividade.
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// Número ideal de colunas de grid responsivo.
  int get gridColumns {
    if (isDesktop) return 3;
    if (isTablet) return 2;
    return 1;
  }

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? cs.error : cs.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
