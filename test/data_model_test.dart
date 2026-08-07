import 'package:contagem/data/models/achievement_model.dart';
import 'package:contagem/data/models/activity_model.dart';
import 'package:contagem/data/models/group_model.dart';
import 'package:contagem/data/models/participant_model.dart';
import 'package:contagem/data/models/photo_model.dart';
import 'package:contagem/domain/entities/activity_item.dart';
import 'package:contagem/domain/entities/group_entity.dart';
import 'package:contagem/domain/entities/participant_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _groupJson({
  String status = 'active',
  String? coverEmoji,
  String? endedAt,
}) =>
    {
      'id': 'g1',
      'code': 'ABC123',
      'name': 'Boteco',
      'creator_anon_id': 'anon1',
      'start_date': '2026-08-01T00:00:00.000',
      'end_date': '2026-08-31T00:00:00.000',
      'duration_days': 30,
      'max_goal': 100,
      'status': status,
      'cover_emoji': coverEmoji,
      'created_at': '2026-08-01T00:00:00.000',
      'ended_at': endedAt,
    };

Map<String, dynamic> _ach({bool? unlocked, String? unlockedAt}) => {
      'id': 'ac1',
      'code': 'FIRST',
      'emoji': '🏅',
      'title': 'Primeiro',
      'description': 'desc',
      'unlocked': unlocked,
      'unlocked_at': unlockedAt,
    };

void main() {
  group('GroupModel.toEntity', () {
    test('mapeia active', () {
      final e = GroupModel(_groupJson()).toEntity();
      expect(e.status, GroupStatus.active);
      expect(e.isActive, isTrue);
      expect(e.acceptsEntries(), isTrue);
    });

    test('mapeia ended e ended_at', () {
      final e = GroupModel(
        _groupJson(status: 'ended', endedAt: '2026-08-31T10:00:00.000'),
      ).toEntity();
      expect(e.status, GroupStatus.ended);
      expect(e.isEnded, isTrue);
      expect(e.endedAt, isNotNull);
    });

    test('mapeia archived', () {
      final e = GroupModel(_groupJson(status: 'archived')).toEntity();
      expect(e.status, GroupStatus.archived);
      expect(e.isArchived, isTrue);
    });

    test('status desconhecido NÃO vira active (segurança)', () {
      final e = GroupModel(_groupJson(status: 'paused')).toEntity();
      expect(e.status, GroupStatus.unknown);
      expect(e.isUnknown, isTrue);
      expect(e.isActive, isFalse);
      expect(e.acceptsEntries(), isFalse, reason: 'desconhecido não aceita');
    });

    test('cover_emoji ausente usa padrão 🍻', () {
      final e = GroupModel(_groupJson(coverEmoji: null)).toEntity();
      expect(e.coverEmoji, '🍻');
      final withEmoji = GroupModel(_groupJson(coverEmoji: '🔥')).toEntity();
      expect(withEmoji.coverEmoji, '🔥');
    });

    test('round-trip fromEntity -> toEntity preserva dados', () {
      final src = GroupEntity(
        id: 'g1',
        code: 'ABC123',
        name: 'Boteco',
        creatorAnonId: 'anon1',
        startDate: DateTime.utc(2026, 8, 1),
        endDate: DateTime.utc(2026, 8, 31),
        durationDays: 30,
        maxGoal: 100,
        status: GroupStatus.active,
        coverEmoji: '🔥',
        createdAt: DateTime.utc(2026, 8, 1),
      );
      final e = GroupModel.fromEntity(src).toEntity();
      expect(e.id, 'g1');
      expect(e.code, 'ABC123');
      expect(e.maxGoal, 100);
      expect(e.status, GroupStatus.active);
      expect(e.coverEmoji, '🔥');
      expect(e.startDate, src.startDate);
      expect(e.endDate, src.endDate);
    });
  });

  group('ParticipantModel.toEntity', () {
    Map<String, dynamic> json({String role = 'member', num total = 0}) => {
          'id': 'p1',
          'group_id': 'g1',
          'anon_id': 'anon1',
          'name': 'Zé',
          'photo_url': null,
          'role': role,
          'joined_at': '2026-08-01T00:00:00.000',
          'total_drinks': total,
          'position': null,
        };

    test('role creator', () {
      final e = ParticipantModel(json(role: 'creator')).toEntity();
      expect(e.role, MemberRole.creator);
      expect(e.isCreator, isTrue);
    });

    test('date envolver double -> int com truncamento', () {
      final e = ParticipantModel(json(total: 7.0)).toEntity();
      expect(e.totalDrinks, 7);
      final d = ParticipantModel(json(total: 12.9)).toEntity();
      expect(d.totalDrinks, 12);
    });

    test('total_drinks/position ausentes -> 0/null', () {
      final e = ParticipantModel(json()).toEntity();
      expect(e.totalDrinks, 0);
      expect(e.position, isNull);
    });
  });

  group('ActivityModel.toEntity', () {
    Map<String, dynamic> json({
      String type = 'drink_added',
      Map? payload,
      String? photoUrl,
    }) =>
        {
          'id': 'a1',
          'group_id': 'g1',
          'participant_id': 'p1',
          'type': type,
          'payload': payload,
          'created_at': '2026-08-01T00:00:00.000',
          'photo_url': photoUrl,
        };

    test('payload ausente vira {}', () {
      final a = ActivityModel(json(type: 'group_created')).toEntity();
      expect(a.payload, isEmpty);
      expect(a.type, ActivityType.groupCreated);
    });

    test('photoUrl vem do json photo_url', () {
      final a = ActivityModel(json(photoUrl: 'https://x/img.png')).toEntity();
      expect(a.photoUrl, 'https://x/img.png');
    });

    test('photoUrl cai no payload["url"] quando json ausente', () {
      final a = ActivityModel(
        json(type: 'photo_added', payload: {'url': 'https://x/p.png'}),
      ).toEntity();
      expect(a.photoUrl, 'https://x/p.png');
    });

    test('payload.url não-String não derruba (cast seguro)', () {
      final a = ActivityModel(json(payload: {'url': 42})).toEntity();
      expect(a.photoUrl, isNull);
    });
  });

  group('PhotoModel.toEntity', () {
    test('campos anuláveis preservados', () {
      final p = PhotoModel({
        'id': 'f1',
        'group_id': 'g1',
        'participant_id': 'p1',
        'participant_name': null,
        'participant_photo': null,
        'drink_id': null,
        'url': 'https://x/f.png',
        'created_at': '2026-08-01T00:00:00.000',
      }).toEntity();
      expect(p.url, 'https://x/f.png');
      expect(p.drinkId, isNull);
      expect(p.participantName, isNull);
    });

    test('drink_id presente', () {
      final p = PhotoModel({
        'id': 'f1',
        'group_id': 'g1',
        'participant_id': 'p1',
        'url': 'https://x/f.png',
        'drink_id': 'd9',
        'created_at': '2026-08-01T00:00:00.000',
      }).toEntity();
      expect(p.drinkId, 'd9');
    });
  });

  group('AchievementModel.toEntity', () {
    test('unlocked só quando exatamente true', () {
      expect(AchievementModel(_ach(unlocked: true)).toEntity().unlocked, isTrue);
      expect(AchievementModel(_ach(unlocked: false)).toEntity().unlocked, isFalse);
      expect(AchievementModel(_ach(unlocked: null)).toEntity().unlocked, isFalse);
    });

    test('unlocked_at anulável', () {
      expect(AchievementModel(_ach()).toEntity().unlockedAt, isNull);
      final e =
          AchievementModel(_ach(unlockedAt: '2026-08-02T00:00:00.000')).toEntity();
      expect(e.unlockedAt, isNotNull);
    });
  });

  test('ActivityType.fromString cobre todos os valores', () {
    expect(ActivityType.fromString('drink_added'), ActivityType.drinkAdded);
    expect(ActivityType.fromString('photo_added'), ActivityType.photoAdded);
    expect(ActivityType.fromString('member_joined'), ActivityType.memberJoined);
    expect(ActivityType.fromString('group_created'), ActivityType.groupCreated);
    expect(ActivityType.fromString('title_changed'), ActivityType.titleChanged);
    expect(ActivityType.fromString('achievement_unlocked'),
        ActivityType.achievementUnlocked);
    expect(ActivityType.fromString('group_ended'), ActivityType.groupEnded);
    expect(ActivityType.fromString('whatever_future'), ActivityType.unknown);
  });

  test('ActivityType.fromString nunca vira drinkAdded por engano', () {
    expect(ActivityType.fromString('bogus'), isNot(ActivityType.drinkAdded));
  });
}