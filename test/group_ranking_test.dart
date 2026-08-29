import 'package:contagem/data/repositories/group_repository.dart';
import 'package:contagem/domain/entities/group_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Constrói a linha de um grupo como devolvida pelo Supabase (ctg_groups).
Map<String, dynamic> _groupRow({
  required String id,
  String? name = 'Grupo',
  String? emoji = '🍻',
}) =>
    {'id': id, 'name': name, 'cover_emoji': emoji};

/// Constrói a linha de uma bebida como devolvida pelo Supabase (ctg_drinks).
Map<String, dynamic> _drinkRow(String? groupId) => {'group_id': groupId};

void main() {
  group('GroupRank', () {
    test('guarda todos os campos', () {
      const rank = GroupRank(
        groupId: 'g1',
        name: 'Boteco',
        coverEmoji: '🍻',
        totalDrinks: 7,
      );
      expect(rank.groupId, 'g1');
      expect(rank.name, 'Boteco');
      expect(rank.coverEmoji, '🍻');
      expect(rank.totalDrinks, 7);
    });
  });

  group('aggregateGroupRanking — agregação pura', () {
    test('soma bebidas por grupo (múltiplas linhas por grupo)', () {
      final groups = [
        _groupRow(id: 'g1', name: 'Time A'),
        _groupRow(id: 'g2', name: 'Time B'),
      ];
      final drinks = [
        _drinkRow('g1'),
        _drinkRow('g1'),
        _drinkRow('g2'),
        _drinkRow('g1'),
      ];
      final ranks = aggregateGroupRanking(groups, drinks);
      final byId = {for (final r in ranks) r.groupId: r.totalDrinks};
      expect(byId['g1'], 3);
      expect(byId['g2'], 1);
    });

    test('ordena do maior para o menor total', () {
      final groups = [
        _groupRow(id: 'a', name: 'Pouco'),
        _groupRow(id: 'b', name: 'Muito'),
        _groupRow(id: 'c', name: 'Meio'),
      ];
      final drinks = [
        _drinkRow('a'),
        _drinkRow('b'), _drinkRow('b'), _drinkRow('b'),
        _drinkRow('c'), _drinkRow('c'),
      ];
      final ranks = aggregateGroupRanking(groups, drinks);
      expect(ranks.map((r) => r.groupId).toList(), ['b', 'c', 'a']);
    });

    test('grupo sem bebidas fica com total 0', () {
      final groups = [_groupRow(id: 'g1', name: 'Time A')];
      final ranks = aggregateGroupRanking(groups, []);
      expect(ranks.single.totalDrinks, 0);
    });

    test('bebida com group_id nulo é ignorada na contagem', () {
      final groups = [_groupRow(id: 'g1', name: 'Time A')];
      final drinks = [_drinkRow(null), _drinkRow('g1'), _drinkRow(null)];
      final ranks = aggregateGroupRanking(groups, drinks);
      expect(ranks.single.totalDrinks, 1);
    });

    test('bebida de grupo inexistente nos grupos não influencia', () {
      final groups = [_groupRow(id: 'g1', name: 'Time A')];
      final drinks = [_drinkRow('g1'), _drinkRow('fantasma')];
      final ranks = aggregateGroupRanking(groups, drinks);
      expect(ranks.single.totalDrinks, 1);
    });

    test('fallbacks para name/emoji quando ausentes', () {
      final groups = [
        {'id': 'g1'},
      ];
      final ranks = aggregateGroupRanking(groups, []);
      expect(ranks.single.name, 'Grupo');
      expect(ranks.single.coverEmoji, '🍻');
    });

    test('vazio preserva name e cover_emoji fornecidos', () {
      final groups = [
        _groupRow(id: 'g1', name: 'Boteco', emoji: '🥃'),
      ];
      final ranks = aggregateGroupRanking(groups, []);
      expect(ranks.single.name, 'Boteco');
      expect(ranks.single.coverEmoji, '🥃');
    });
  });
}
