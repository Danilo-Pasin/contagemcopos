import 'package:contagem/domain/entities/group_entity.dart';
import 'package:contagem/domain/entities/participant_entity.dart';
import 'package:contagem/presentation/providers/group_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

GroupEntity _group({GroupStatus status = GroupStatus.active}) => GroupEntity(
      id: 'g1',
      code: 'ABCDEF',
      name: 'Boteco',
      creatorAnonId: 'anon1',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      durationDays: 30,
      maxGoal: 100,
      status: status,
      coverEmoji: '🍻',
      createdAt: DateTime(2026, 8, 1),
    );

ParticipantEntity _p(String id, int drinks, {MemberRole role = MemberRole.member}) =>
    ParticipantEntity(
      id: id,
      groupId: 'g1',
      anonId: id,
      name: 'Jogador $id',
      role: role,
      joinedAt: DateTime(2026, 8, 1),
      totalDrinks: drinks,
      position: 1,
    );

void main() {
  group('GroupEntity', () {
    test('status helpers', () {
      expect(_group().isActive, isTrue);
      expect(_group().isEnded, isFalse);
      expect(_group(status: GroupStatus.ended).isEnded, isTrue);
      expect(_group(status: GroupStatus.archived).isArchived, isTrue);
    });

    test('shareLink é /g/<code>', () {
      expect(_group().shareLink, '/g/ABCDEF');
    });

    test('empty cria um grupo ativo', () {
      final e = GroupEntity.empty();
      expect(e.isActive, isTrue);
      expect(e.maxGoal, 40);
      expect(e.shareLink, '/g/');
    });
  });

  group('GroupEntity.acceptsEntries', () {
    final now = DateTime(2026, 8, 10, 12);

    // grupo ativo que termina em 31/08
    GroupEntity activeGroup({DateTime? end}) => GroupEntity(
          id: 'g1',
          code: 'ABCDEF',
          name: 'Boteco',
          creatorAnonId: 'anon1',
          startDate: DateTime(2026, 8, 1),
          endDate: end ?? DateTime(2026, 8, 31),
          durationDays: 30,
          maxGoal: 100,
          status: GroupStatus.active,
          coverEmoji: '🍻',
          createdAt: DateTime(2026, 8, 1),
        );

    test('ageito quando ativo e dentro do prazo', () {
      expect(activeGroup().acceptsEntries(now: now), isTrue);
    });

    test('exatamente no prazo (igual a now) NÃO aceita mais', () {
      expect(activeGroup(end: now).acceptsEntries(now: now), isFalse);
    });

    test('após o prazo NÃO aceita', () {
      expect(activeGroup(end: now.subtract(const Duration(hours: 1)))
          .acceptsEntries(now: now), isFalse);
    });

    test('encerrado nunca aceita, mesmo com end no futuro', () {
      final g = _group(status: GroupStatus.ended);
      expect(g.acceptsEntries(now: now), isFalse);
    });

    test('archived nunca aceita', () {
      expect(_group(status: GroupStatus.archived)
          .acceptsEntries(now: now), isFalse);
    });
  });

  group('ParticipantEntity', () {
    test('isCreator reflete o role', () {
      expect(_p('a', 0, role: MemberRole.creator).isCreator, isTrue);
      expect(_p('a', 0).isCreator, isFalse);
    });

    test('copyWith atualiza total e posição sem perder o resto', () {
      final p = _p('a', 0);
      final updated = p.copyWith(totalDrinks: 12, position: 3);
      expect(updated.totalDrinks, 12);
      expect(updated.position, 3);
      expect(updated.id, 'a');
      expect(updated.role, MemberRole.member);
    });
  });

  group('GroupSessionState', () {
    test('estado inicial não tem grupo nem membro e está carregando', () {
      const s = GroupSessionState();
      expect(s.hasGroup, isFalse);
      expect(s.isMember, isFalse);
      expect(s.loading, isTrue);
      expect(s.totalGroupDrinks, 0);
      expect(s.leader, isNull);
    });

    test('isMember/iAmCreator dependem de me', () {
      final s = GroupSessionState(
        group: _group(),
        me: _p('me', 5, role: MemberRole.creator),
      );
      expect(s.hasGroup, isTrue);
      expect(s.isMember, isTrue);
      expect(s.iAmCreator, isTrue);
    });

    test('totalGroupDrinks soma todos os membros', () {
      final s = GroupSessionState(
        group: _group(),
        ranking: [_p('a', 10), _p('b', 5), _p('c', 2)],
      );
      expect(s.totalGroupDrinks, 17);
    });

    test('leader é o primeiro do ranking ordenado', () {
      final s = GroupSessionState(
        group: _group(),
        ranking: [_p('top', 42), _p('low', 1)],
      );
      expect(s.leader?.id, 'top');
    });

    test('copyWith(clearError: true) limpa o erro', () {
      const s = GroupSessionState(error: 'boom');
      final cleared = s.copyWith(clearError: true);
      expect(cleared.error, isNull);
      final kept = s.copyWith();
      expect(kept.error, 'boom');
    });
  });
}