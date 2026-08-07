import 'package:contagem/core/constants/title_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TitleSystem', () {
    test('ordena os títulos do menor para o maior', () {
      for (var i = 0; i < TitleSystem.tiers.length - 1; i++) {
        expect(
          TitleSystem.tiers[i].percentage <
              TitleSystem.tiers[i + 1].percentage,
          isTrue,
          reason: '${TitleSystem.tiers[i].id} deve ser menor que o próximo',
        );
      }
    });

    test('requiredDrinks arredonda para cima com @percentual', () {
      // 10% de 40 = 4
      expect(TitleSystem.tiers.first.requiredDrinks(40), 4);
      // 25% de 40 = 10
      expect(TitleSystem.tiers[1].requiredDrinks(40), 10);
      // 100% de 40 = 40
      expect(TitleSystem.tiers[4].requiredDrinks(40), 40);
      // 120% de 40 = 48
      expect(TitleSystem.tiers[5].requiredDrinks(40), 48);
      // 150% de 40 = 60
      expect(TitleSystem.tiers[6].requiredDrinks(40), 60);
    });

    test('currentTier sobe exatamente na fronteira', () {
      // meta 40: Aprendiz a partir de 4
      expect(TitleSystem.currentTier(4, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(9, 40).id, 'aprendiz');
      // Cachaceiro a partir de 10
      expect(TitleSystem.currentTier(10, 40).id, 'cachaceiro');
      // Rei do Boteco a partir de 20
      expect(TitleSystem.currentTier(20, 40).id, 'rei_boteco');
      // Lenda a partir de 30
      expect(TitleSystem.currentTier(30, 40).id, 'lenda');
      // Imperador a partir de 40
      expect(TitleSystem.currentTier(40, 40).id, 'imperador');
      // Mito a partir de 48
      expect(TitleSystem.currentTier(48, 40).id, 'mito');
      // Deus da Geladeira a partir de 60
      expect(TitleSystem.currentTier(60, 40).id, 'deus');
      expect(TitleSystem.currentTier(999, 40).id, 'deus');
    });

    test('com zero ou poucas bebidas retorna o primeiro título', () {
      expect(TitleSystem.currentTier(0, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(3, 40).id, 'aprendiz');
    });

    test('meta muito pequena não derruba em limite inválido', () {
      // meta 1: requer 100% => 1, e 120% => 2. Nunca deve estourar.
      expect(TitleSystem.currentTier(0, 1).id, isNotNull);
      expect(TitleSystem.nextTier(0, 1), isNotNull);
    });

    test('nextTier é o primeiro não alcançado', () {
      expect(TitleSystem.nextTier(4, 40)?.id, 'cachaceiro');
      expect(TitleSystem.nextTier(47, 40)?.id, 'mito');
      // topo (>=150%) não tem próximo
      expect(TitleSystem.nextTier(60, 40), isNull);
      expect(TitleSystem.nextTier(1000, 40), isNull);
    });

test('progressToNext é 0..1 e 1 no topo', () {
      expect(TitleSystem.progressToNext(4, 40), 0);
      expect(TitleSystem.progressToNext(7, 40), closeTo(0.5, 1e-9));
      expect(TitleSystem.progressToNext(9, 40), lessThan(1));
      expect(TitleSystem.progressToNext(60, 40), 1);
      // nunca negativo
      expect(TitleSystem.progressToNext(0, 40), inInclusiveRange(0, 1));
    });

    test('toString mostra emoji + nome', () {
      expect(TitleSystem.tiers[4].toString(), '🏆 Imperador do Copo');
    });
  });
}