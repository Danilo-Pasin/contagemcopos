enum GroupStatus { active, ended, archived, unknown }

/// Entrada do ranking global de grupos (soma de bebidas por grupo).
class GroupRank {
  final String groupId;
  final String name;
  final String coverEmoji;
  final int totalDrinks;
  const GroupRank({
    required this.groupId,
    required this.name,
    required this.coverEmoji,
    required this.totalDrinks,
  });
}

/// Entidade de domínio: Grupo de competição.
class GroupEntity {
  final String id;
  final String code;
  final String name;
  final String creatorAnonId;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int maxGoal;
  final GroupStatus status;
  final String coverEmoji;
  final DateTime createdAt;
  final DateTime? endedAt;

  const GroupEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.creatorAnonId,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.maxGoal,
    required this.status,
    required this.coverEmoji,
    required this.createdAt,
    this.endedAt,
  });

  bool get isActive => status == GroupStatus.active;
  bool get isEnded => status == GroupStatus.ended;
  bool get isArchived => status == GroupStatus.archived;
  bool get isUnknown => status == GroupStatus.unknown;

  /// Competição aceitando novos registros/entradas: precisa estar `active` e
  /// ainda dentro do prazo. Espelha a regra das políticas RLS do backend
  /// (`status = 'active' AND end_date > now()`).
  bool acceptsEntries({DateTime? now}) =>
      isActive && (now ?? DateTime.now()).isBefore(endDate);

  /// Link público de entrada no grupo.
  String get shareLink => '/g/$code';

  factory GroupEntity.empty() => GroupEntity(
        id: '',
        code: '',
        name: '',
        creatorAnonId: '',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        durationDays: 7,
        maxGoal: 40,
        status: GroupStatus.active,
        coverEmoji: '🍻',
        createdAt: DateTime.now(),
      );
}
