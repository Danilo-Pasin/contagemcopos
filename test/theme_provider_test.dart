import 'package:contagem/core/constants/storage_keys.dart';
import 'package:contagem/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefsWith(String? saved) async {
  SharedPreferences.setMockInitialValues(
    saved == null ? {} : {StorageKeys.themeMode: saved},
  );
  return SharedPreferences.getInstance();
}

void main() {
  group('ThemeModeNotifier', () {
    test('padrão é system quando nada está salvo', () async {
      final n = ThemeModeNotifier(await _prefsWith(null));
      expect(n.state, ThemeMode.system);
    });

    test('carrega "light" salvo', () async {
      final n = ThemeModeNotifier(await _prefsWith('light'));
      expect(n.state, ThemeMode.light);
    });

    test('carrega "dark" salvo', () async {
      final n = ThemeModeNotifier(await _prefsWith('dark'));
      expect(n.state, ThemeMode.dark);
    });

    test('toggle alterna entre dark e light (e nunca fica em system)', () async {
      final n = ThemeModeNotifier(await _prefsWith('dark'));
      await n.toggle();
      expect(n.state, ThemeMode.light);
      await n.toggle();
      expect(n.state, ThemeMode.dark);
    });

    test('persiste o novo valor no SharedPreferences', () async {
      final prefs = await _prefsWith('dark');
      final n = ThemeModeNotifier(prefs);
      await n.toggle();
      expect(prefs.getString(StorageKeys.themeMode), 'light');
    });
  });
}