import 'package:contagem/core/constants/competition_periods.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompetitionPeriod.presets', () {
    test('ids únicos', () {
      final ids = CompetitionPeriod.presets.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('dias positivos e crescentes em ordem', () {
      int prev = 0;
      for (final p in CompetitionPeriod.presets) {
        expect(p.days, greaterThan(0));
        expect(p.days > prev, isTrue, reason: 'presets devem estar ordenados');
        expect(p.maxGoal, greaterThan(0));
        expect(p.label.trim(), isNotEmpty);
        prev = p.days;
      }
    });

    test('meta acompanha os dias (proporcional)', () {
      // 1 dia → 12; 3 dias → 36; 30 dias → 100; 90 dias → 260
      expect(CompetitionPeriod.presets.first.maxGoal, 12);
      expect(CompetitionPeriod.presets[2].maxGoal, 36);
      expect(CompetitionPeriod.presets[6].maxGoal, 180);
      expect(CompetitionPeriod.presets.last.maxGoal, 260);
    });
  });

  group('CompetitionPeriod.customGoal', () {
    test('~3,3 bebidas/dia com arredondamento', () {
      expect(CompetitionPeriod.customGoal(10), (10 * 3.3).round());
      expect(CompetitionPeriod.customGoal(30), 99);
      expect(CompetitionPeriod.customGoal(90), 297);
    });

    test('dias zero/negativos não lançam erro', () {
      expect(CompetitionPeriod.customGoal(0), 0);
      // valor negativo não é um período real, mas a fórmula não deve lançar
      expect(CompetitionPeriod.customGoal(-5), lessThanOrEqualTo(0));
    });
  });
}