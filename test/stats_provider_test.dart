import 'package:contagem/domain/entities/participant_entity.dart';
import 'package:contagem/presentation/providers/stats_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

ParticipantEntity _participant(String id, String name) => ParticipantEntity(
      id: id,
      groupId: 'g1',
      anonId: 'anon-$id',
      name: name,
      joinedAt: DateTime(2026, 1, 1),
    );

Map<String, dynamic> _row({
  String createdAt = '2026-08-10T12:00:00Z',
  String? type = 'cerveja',
  String? pid = 'p1',
}) =>
    {'created_at': createdAt, 'drink_type': type, 'participant_id': pid};

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR', null));

  group('aggregateDrinkRows — agregação pura', () {
    test('agrega por dia e ordena cronologicamente (dias fora de ordem)', () {
      final rows = [
        _row(createdAt: '2026-08-10T12:00:00Z'),
        _row(createdAt: '2026-07-28T12:00:00Z'),
        _row(createdAt: '2026-08-10T15:00:00Z'),
        _row(createdAt: '2026-08-05T09:00:00Z'),
      ];
      final agg = aggregateDrinkRows(rows, [_participant('p1', 'Ana')]);
      expect(agg.daily.map((d) => d.label).toList(), [
        '28/07',
        '05/08',
        '10/08',
      ]);
      expect(agg.daily.last.value, 2);
    });

    test('created_at inválido é ignorado sem quebrar a agregação', () {
      final rows = [
        _row(createdAt: 'nao-e-data'),
        _row(createdAt: '2026-08-10T12:00:00Z'),
        _row(createdAt: ''), // vazio
      ];
      final agg = aggregateDrinkRows(rows, []);
      expect(agg.daily.length, 1);
      expect(agg.daily.single.value, 1);
    });

    test('participante ausente no ranking cai para nome genérico', () {
      final agg = aggregateDrinkRows(
        [_row(pid: 'desconhecido')],
        [_participant('p1', 'Ana')],
      );
      expect(agg.perPerson.single.name, 'Participante');
      expect(agg.perPerson.single.total, 1);
    });

    test('tipos por pessoa ordenados por contagem desc + total correto', () {
      final rows = [
        _row(type: 'cerveja', pid: 'p1'),
        _row(type: 'cerveja', pid: 'p1'),
        _row(type: 'caipirinha', pid: 'p1'),
        _row(type: 'refri', pid: 'p1'),
      ];
      final agg = aggregateDrinkRows(rows, [_participant('p1', 'Ana')]);
      final person = agg.perPerson.single;
      expect(person.total, 4);
      expect(person.types.first.typeId, 'cerveja');
      expect(person.types.first.value, 2);
      expect(person.types.map((t) => t.typeId), [
        'cerveja',
        'caipirinha',
        'refri',
      ]);
    });

    test('pessoas ordenadas por total desc; drink_type nulo vira sem_tipo',
        () {
      final rows = [
        _row(pid: 'p1', type: null),
        _row(pid: 'p2', type: 'cerveja'),
        _row(pid: 'p2', type: 'cerveja'),
      ];
      final agg = aggregateDrinkRows(rows,
          [_participant('p1', 'Ana'), _participant('p2', 'Bia')]);
      expect(agg.perPerson.map((p) => p.name).toList(), ['Bia', 'Ana']);
      expect(agg.perPerson[1].types.single.typeId, 'sem_tipo');
    });
  });

  group('StatsNotifier — TTL e invalidação', () {
    late int fetchCount;
    late Future<List<Map<String, dynamic>>> Function(String) fetcher;
    late DateTime currentTime;

    StatsNotifier buildNotifier({String? groupId = 'g1'}) {
      fetchCount = 0;
      currentTime = DateTime(2026, 8, 25, 12);
      return StatsNotifier(
        fetchRows: (gid) async {
          fetchCount++;
          return fetcher(gid);
        },
        currentGroupId: () => groupId,
        currentRanking: () => const [],
        ttl: const Duration(seconds: 60),
        now: () => currentTime,
      );
    }

    setUp(() {
      fetcher = (_) async => [
            _row(createdAt: '2026-08-10T12:00:00Z'),
          ];
    });

    Future<void> settle() async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    test('ensureFresh carrega na primeira chamada (fetchedAt nulo)', () async {
      final notifier = buildNotifier();
      notifier.ensureFresh();
      await settle();
      expect(fetchCount, 1);
      expect(notifier.state.hasData, isTrue);
      expect(notifier.state.loading, isFalse);
      expect(notifier.state.fetchedAt, isNotNull);
    });

    test('ensureFresh dentro do TTL não refaz o fetch', () async {
      final notifier = buildNotifier();
      notifier.ensureFresh();
      await settle();
      currentTime = currentTime.add(const Duration(seconds: 30));
      notifier.ensureFresh();
      await settle();
      expect(fetchCount, 1);
    });

    test('ensureFresh após o TTL recarrega em background (stale-while-revalidate)',
        () async {
      final notifier = buildNotifier();
      notifier.ensureFresh();
      await settle();
      currentTime = currentTime.add(const Duration(seconds: 61));
      notifier.ensureFresh();
      await settle();
      expect(fetchCount, 2);
      expect(notifier.state.hasData, isTrue); // dados mantidos
      expect(notifier.state.fetchedAt, currentTime); // base do TTL renovada
    });

    test('forceRefresh ignora o TTL', () async {
      final notifier = buildNotifier();
      notifier.ensureFresh();
      await settle();
      notifier.forceRefresh();
      await settle();
      expect(fetchCount, 2);
    });

    test('invalidate força refetch mesmo dentro do TTL', () async {
      final notifier = buildNotifier();
      notifier.ensureFresh();
      await settle();
      notifier.invalidate(); // zera fetchedAt e recarrega
      await settle();
      expect(fetchCount, 2);
      expect(notifier.state.fetchedAt, isNotNull);
    });

    test('invalidate com load em voo enfileira um único reload extra',
        () async {
      final notifier = buildNotifier();
      notifier.ensureFresh();
      notifier.invalidate(); // ainda em voo → só enfileira
      notifier.invalidate(); // dedup
      await settle();
      await settle();
      expect(fetchCount, 2); // 1 inicial + 1 enfileirado
    });

    test('grupo não pronto (groupId nulo) não dispara fetch', () async {
      final notifier = buildNotifier(groupId: null);
      notifier.ensureFresh();
      await settle();
      expect(fetchCount, 0);
      expect(notifier.state.fetchedAt, isNull);
    });

    test('erro no fetch preserva estado de erro e sai do loading', () async {
      fetcher = (_) async => throw Exception('falha de rede');
      final notifier = buildNotifier();
      notifier.ensureFresh();
      await settle();
      expect(fetchCount, 1);
      expect(notifier.state.loading, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.hasData, isFalse);
    });
  });
}
