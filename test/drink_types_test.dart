import 'package:contagem/core/constants/drink_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kDrinkTypes', () {
    test('contém os 6 tipos vigentes', () {
      expect(kDrinkTypes.length, 6);
      expect(kDrinkTypes.map((t) => t.id),
          containsAll(['cerveja', 'copo', 'vinho', 'espumante', 'destilado', 'drink']));
    });

    test('não contém tipos removidos', () {
      final ids = kDrinkTypes.map((t) => t.id).toSet();
      expect(ids.contains('longneck'), isFalse);
      expect(ids.contains('energetico'), isFalse);
      expect(ids.contains('sem_alcool'), isFalse);
      expect(ids.contains('outro'), isFalse);
    });

    test('ids são únicos', () {
      final ids = kDrinkTypes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('cada tipo tem emoji e label', () {
      for (final t in kDrinkTypes) {
        expect(t.label.trim(), isNotEmpty);
        expect(t.emoji.trim(), isNotEmpty);
      }
    });
  });

  group('drinkTypeById', () {
    test('resolve ids conhecidos', () {
      expect(drinkTypeById('cerveja')?.label, 'Cerveja');
      expect(drinkTypeById('copo')?.label, 'Copão');
      expect(drinkTypeById('drink')?.label, 'Drinque');
    });

    test('retorna null para null/desconhecido', () {
      expect(drinkTypeById(null), isNull);
      expect(drinkTypeById('tequila'), isNull);
      expect(drinkTypeById(''), isNull);
    });
  });
}