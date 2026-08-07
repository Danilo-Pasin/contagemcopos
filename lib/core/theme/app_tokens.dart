import 'package:flutter/material.dart';

/// Tokens de design reutilizáveis — espaçamentos, raios, gradientes, vidro.
class AppSpacing {
  const AppSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  const AppRadius._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}

/// Tokens de layout responsivo — larguras máximas do app.
///
/// Mantêm o conteúdo centralizado e legível tanto no mobile quanto no desktop,
/// evitando que botões e cards se estiquem por toda a tela em monitores largos.
class AppLayout {
  const AppLayout._();

  /// Largura máxima do conteúdo principal (centralizado).
  static const double maxContentWidth = 560;

  /// Largura máxima de botões primários (evita "botão x tela" no PC).
  static const double maxButtonWidth = 400;

  /// Padding horizontal padrão do bloco de conteúdo responsivo.
  static const EdgeInsets contentPadding =
      EdgeInsets.symmetric(horizontal: AppSpacing.md);
}

/// Alturas padrão de botões.
class AppButtonSizes {
  const AppButtonSizes._();
  static const double compact = 44;
  static const double regular = 54;
  static const double large = 62;
}

/// Gradientes premium usados em botões, headers e destaques.
class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
  );

  static const LinearGradient silver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
  );

  static const LinearGradient bronze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD7A46B), Color(0xFF8D5A2B)],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1330), Color(0xFF0B0E14)],
  );
}
