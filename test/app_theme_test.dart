import 'package:contagem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light expõe um ThemeData válido no modo claro', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.primaryColor, isNotNull);
      expect(theme.useMaterial3, isTrue);
    });

    test('dark expõe um ThemeData válido no modo escuro', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, isNotNull);
      expect(theme.useMaterial3, isTrue);
    });

    test('os dois temas têm esquema consistente (cores definidas)', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.colorScheme.primary, isNotNull);
      expect(dark.colorScheme.primary, isNotNull);
    });

    test('usa a fonte Inter bundled (sem fetch em runtime)', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(dark.textTheme.bodyMedium?.fontFamily, 'Inter');
    });
  });
}