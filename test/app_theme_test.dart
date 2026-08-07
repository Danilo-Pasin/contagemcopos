import 'dart:async';

import 'package:contagem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cria o tema absorvendo o erro assíncrono do google_fonts (que tenta
/// carregar a fonte e falha em ambiente de teste), sem derrubar o teste.
T _buildTheme<T>(T Function() fn) =>
    runZonedGuarded(fn, (_, __) {}) as T;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppTheme', () {
    test('light expõe um ThemeData válido no modo claro', () {
      final theme = _buildTheme(AppTheme.light);
      expect(theme.brightness, Brightness.light);
      expect(theme.primaryColor, isNotNull);
      expect(theme.useMaterial3, isTrue);
    });

    test('dark expõe um ThemeData válido no modo escuro', () {
      final theme = _buildTheme(AppTheme.dark);
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, isNotNull);
      expect(theme.useMaterial3, isTrue);
    });

    test('os dois temas têm esquema consistente (cores definidas)', () {
      final light = _buildTheme(AppTheme.light);
      final dark = _buildTheme(AppTheme.dark);
      expect(light.colorScheme.primary, isNotNull);
      expect(dark.colorScheme.primary, isNotNull);
    });
  });
}