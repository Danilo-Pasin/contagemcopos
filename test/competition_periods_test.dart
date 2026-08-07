import 'package:contagem/core/constants/competition_periods.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompetitionPeriod.presets', () {
    test('ids únicos', () {
      final ids = CompetitionPeriod.presets.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('duração positiva e ordenada', () {
      int prev = 0;
      for (final p in CompetitionPeriod.presets) {
        expect(p.totalHours, greaterThan(0));
        expect(p.totalHours > prev, isTrue,
            reason: 'presets devem estar em ordem crescente');
        expect(p.maxGoal, greaterThan(0));
        expect(p.label.trim(), isNotEmpty);
        prev = p.totalHours;
      }
    });

    test('inclui a opção de 8 horas', () {
      final eight = CompetitionPeriod.presets.firstWhere((p) => p.id == '8h');
      expect(eight.totalHours, 8);
      expect(eight.unit, DurationUnit.hours);
    });

    test('presets que o usuário pediu para remover não existem mais', () {
      final ids = CompetitionPeriod.presets.map((p) => p.id).toList();
      expect(ids.contains('2d'), isFalse);
      expect(ids.contains('3d'), isFalse);
      expect(ids.contains('2m'), isFalse);
    });

    test('conversões de unidade', () {
      expect(DurationUnit.hours.hoursPerOne, 1);
      expect(DurationUnit.days.hoursPerOne, 24);
      expect(DurationUnit.months.hoursPerOne, 720);
    });

    test('durationDays arredonda com piso 1', () {
      expect(CompetitionPeriod(id: 'x', label: 'x', value: 1, unit: DurationUnit.days).durationDays, 1);
      expect(CompetitionPeriod(id: 'x', label: 'x', value: 8, unit: DurationUnit.hours).durationDays, 1);
      expect(CompetitionPeriod(id: 'x', label: 'x', value: 30, unit: DurationUnit.hours).durationDays, 1);
      expect(CompetitionPeriod(id: 'x', label: 'x', value: 7, unit: DurationUnit.days).durationDays, 7);
    });
  });

  group('CompetitionPeriod.maxGoal', () {
    test('usa a meta explícita do preset', () {
      final oneDay = CompetitionPeriod.presets.firstWhere((p) => p.id == '1d');
      expect(oneDay.maxGoal, 12);
    });

    test('personalizado calcula ~3,3/dia com piso 1', () {
      CompetitionPeriod p(int value, DurationUnit unit) =>
          CompetitionPeriod(id: 'c', label: 'c', value: value, unit: unit);

      // 30 dias → ~99 bebidas
      expect(p(30, DurationUnit.days).maxGoal, 99);
      // 1 dia → 3 (piso 1, sem explosão)
      expect(p(1, DurationUnit.days).maxGoal, inInclusiveRange(1, 4));
      // 8 horas → 1..2
      expect(p(8, DurationUnit.hours).maxGoal, inInclusiveRange(1, 2));
    });
  });
}