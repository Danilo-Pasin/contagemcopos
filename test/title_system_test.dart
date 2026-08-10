import 'package:contagem/core/constants/title_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TitleSystem', () {
    TitleTier byId(String id) => TitleSystem.tiers.firstWhere((t) => t.id == id);

    test('patamares são monotônicos não-decrescentes para qualquer meta', () {
      for (final goal in [0, 1, 20, 40, 60, 100, 150]) {
        final reqs = TitleSystem.thresholdsFor(goal);
        for (var i = 0; i < reqs.length - 1; i++) {
          expect(
            reqs[i] <= reqs[i + 1],
            isTrue,
            reason: 'meta $goal: patamar $i não deve ser maior que o próximo',
          );
        }
      }
    });

    test('os títulos são por quantidade fixa de copos (não % da meta)', () {
      expect(byId('aprendiz').required, 5);
      expect(byId('cachaceiro').required, 10);
      expect(byId('rei_boteco').required, 15);
      expect(byId('lenda').required, 20);
      expect(byId('imperador').required, 30);
      expect(byId('mito').required, 40);
      expect(byId('deus').required, 50);
      expect(byId('aura').required, 67);
      expect(byId('alcoolatra').required, 76);
      expect(byId('sigma').required, 88);
      expect(byId('reabilitacao').required, 99);
    });

    test('requiredDrinks ignora a meta (é fixo)', () {
      expect(byId('lenda').requiredDrinks(40), 20);
      expect(byId('lenda').requiredDrinks(100), 20);
      expect(byId('lenda').requiredDrinks(0), 20);
      expect(byId('reabilitacao').requiredDrinks(40), 99);
    });

    test('currentTier sobe exatamente na fronteira', () {
      expect(TitleSystem.currentTier(0, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(4, 40).id, 'aprendiz');
      // Cachaceiro a partir de 10
      expect(TitleSystem.currentTier(5, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(9, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(10, 40).id, 'cachaceiro');
      expect(TitleSystem.currentTier(14, 40).id, 'cachaceiro');
      // Rei do Boteco a partir de 15
      expect(TitleSystem.currentTier(15, 40).id, 'rei_boteco');
      expect(TitleSystem.currentTier(19, 40).id, 'rei_boteco');
      // Lenda a partir de 20
      expect(TitleSystem.currentTier(20, 40).id, 'lenda');
      expect(TitleSystem.currentTier(29, 40).id, 'lenda');
      // Imperador a partir de 30
      expect(TitleSystem.currentTier(30, 40).id, 'imperador');
      // Mito a partir de 40
      expect(TitleSystem.currentTier(40, 40).id, 'mito');
      // Deus da Geladeira a partir de 50
      expect(TitleSystem.currentTier(50, 40).id, 'deus');
      // Fixos finais
      expect(TitleSystem.currentTier(67, 40).id, 'aura');
      expect(TitleSystem.currentTier(76, 40).id, 'alcoolatra');
      expect(TitleSystem.currentTier(88, 40).id, 'sigma');
      expect(TitleSystem.currentTier(99, 40).id, 'reabilitacao');
      expect(TitleSystem.currentTier(500, 40).id, 'reabilitacao');
    });

    test('com zero ou poucas bebidas retorna o primeiro título', () {
      expect(TitleSystem.currentTier(0, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(3, 40).id, 'aprendiz');
    });

    test('meta pequena não derruba em limite inválido', () {
      expect(TitleSystem.currentTier(0, 1).id, isNotNull);
      expect(TitleSystem.nextTier(0, 1), isNotNull);
      expect(TitleSystem.currentTier(99, 1).id, 'reabilitacao');
    });

    test('mesmo comportamento sem meta (maxGoal <= 0)', () {
      expect(TitleSystem.tiers.first.requiredDrinks(0), 5);
      expect(byId('reabilitacao').requiredDrinks(-5), 99);
      expect(TitleSystem.currentTier(0, 0).id, 'aprendiz');
      expect(TitleSystem.currentTier(20, 0).id, 'lenda');
      // 10 bebidas alcançam Cachaceiro; próximo é Rei do Boteco (15).
      expect(TitleSystem.nextTier(10, 0)?.id, 'rei_boteco');
      expect(TitleSystem.nextTier(20, 0)?.id, 'imperador');
    });

    test('nextTier é o primeiro não alcançado', () {
      expect(TitleSystem.nextTier(4, 40)?.id, 'aprendiz');
      expect(TitleSystem.nextTier(9, 40)?.id, 'cachaceiro');
      expect(TitleSystem.nextTier(47, 40)?.id, 'deus');
      // topo (>=99) não tem próximo
      expect(TitleSystem.nextTier(99, 40), isNull);
      expect(TitleSystem.nextTier(1000, 40), isNull);
    });

    test('progressToNext é 0..1 e 1 no topo', () {
      expect(TitleSystem.progressToNext(5, 40), 0);
      // entre Aprendiz (5) e Cachaceiro (10)
      expect(TitleSystem.progressToNext(7, 40), closeTo(0.4, 1e-9));
      expect(TitleSystem.progressToNext(9, 40), lessThan(1));
      expect(TitleSystem.progressToNext(99, 40), 1);
      // nunca negativo
      expect(TitleSystem.progressToNext(0, 40), inInclusiveRange(0, 1));
    });

    test('toString mostra emoji + nome', () {
      expect(byId('imperador').toString(), '🏆 Imperador do Copo');
      expect(TitleSystem.tiers.length, 11);
    });
  });
}