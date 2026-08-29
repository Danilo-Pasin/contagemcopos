import 'package:contagem/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBrand (OGS)', () {
    test('nome e lema da festa', () {
      expect(AppBrand.name, 'OGS');
      expect(AppBrand.tagline, 'Copa da Ressaca');
    });
  });

  group('Janela fixa da festa', () {
    test('festa começa em 29/08/2026 22:00 local', () {
      final start = AppConfig.festaStart;
      expect(start.year, 2026);
      expect(start.month, 8);
      expect(start.day, 29);
      expect(start.hour, 22);
      expect(start.minute, 0);
    });

    test('festa termina em 30/08/2026 06:00 local', () {
      final end = AppConfig.festaEnd;
      expect(end.year, 2026);
      expect(end.month, 8);
      expect(end.day, 30);
      expect(end.hour, 6);
      expect(end.minute, 0);
    });

    test('a janela dura exatamente 8 horas', () {
      final duration = AppConfig.festaEnd.difference(AppConfig.festaStart);
      expect(duration, const Duration(hours: 8));
    });
  });
}
