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
      expect(byId('aprendiz').required, 1);
      expect(byId('cachaceiro').required, 3);
      expect(byId('alcoolatra').required, 6);
      expect(byId('lenda').required, 9);
      expect(byId('reabilitacao').required, 12);
    });

    test('requiredDrinks ignora a meta (é fixo)', () {
      expect(byId('lenda').requiredDrinks(40), 9);
      expect(byId('lenda').requiredDrinks(100), 9);
      expect(byId('lenda').requiredDrinks(0), 9);
      expect(byId('reabilitacao').requiredDrinks(40), 12);
    });

    test('currentTier sobe exatamente na fronteira', () {
      expect(TitleSystem.currentTier(0, 40).id, 'aprendiz');
      // Aprendiz até 2
      expect(TitleSystem.currentTier(0, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(2, 40).id, 'aprendiz');
      // Cachaceiro a partir de 3
      expect(TitleSystem.currentTier(3, 40).id, 'cachaceiro');
      expect(TitleSystem.currentTier(5, 40).id, 'cachaceiro');
      // Alcoólatra a partir de 6
      expect(TitleSystem.currentTier(6, 40).id, 'alcoolatra');
      expect(TitleSystem.currentTier(8, 40).id, 'alcoolatra');
      // Lenda a partir de 9
      expect(TitleSystem.currentTier(9, 40).id, 'lenda');
      expect(TitleSystem.currentTier(11, 40).id, 'lenda');
      // Papo de Reabilitação a partir de 12
      expect(TitleSystem.currentTier(12, 40).id, 'reabilitacao');
      expect(TitleSystem.currentTier(500, 40).id, 'reabilitacao');
    });

    test('com zero ou poucas bebidas retorna o primeiro título', () {
      expect(TitleSystem.currentTier(0, 40).id, 'aprendiz');
      expect(TitleSystem.currentTier(3, 40).id, 'cachaceiro');
    });

    test('meta pequena não derruba em limite inválido', () {
      expect(TitleSystem.currentTier(0, 1).id, isNotNull);
      expect(TitleSystem.nextTier(0, 1), isNotNull);
      expect(TitleSystem.currentTier(99, 1).id, 'reabilitacao');
    });

    test('mesmo comportamento sem meta (maxGoal <= 0)', () {
      expect(TitleSystem.tiers.first.requiredDrinks(0), 1);
      expect(byId('reabilitacao').requiredDrinks(-5), 12);
      expect(TitleSystem.currentTier(0, 0).id, 'aprendiz');
      // 6 bebidas alcançam Alcoólatra; próximo é Lenda (9).
      expect(TitleSystem.currentTier(9, 0).id, 'lenda');
      expect(TitleSystem.nextTier(3, 0)?.id, 'alcoolatra');
      expect(TitleSystem.nextTier(9, 0)?.id, 'reabilitacao');
    });

    test('nextTier é o primeiro não alcançado', () {
      expect(TitleSystem.nextTier(0, 40)?.id, 'aprendiz');
      expect(TitleSystem.nextTier(2, 40)?.id, 'cachaceiro');
      expect(TitleSystem.nextTier(6, 40)?.id, 'lenda');
      expect(TitleSystem.nextTier(12, 40), isNull);
      expect(TitleSystem.nextTier(1000, 40), isNull);
    });

    test('progressToNext é 0..1 e 1 no topo', () {
      expect(TitleSystem.progressToNext(1, 40), 0);
      // entre Aprendiz (1) e Cachaceiro (3)
      expect(TitleSystem.progressToNext(2, 40), closeTo(0.5, 1e-9));
      expect(TitleSystem.progressToNext(2, 40), lessThan(1));
      expect(TitleSystem.progressToNext(12, 40), 1);
      // nunca negativo
      expect(TitleSystem.progressToNext(0, 40), inInclusiveRange(0, 1));
    });

    test('toString mostra emoji + nome', () {
      expect(byId('alcoolatra').toString(), '🤌 Alcoólatra');
      expect(TitleSystem.tiers.length, 5);
    });
  });
}