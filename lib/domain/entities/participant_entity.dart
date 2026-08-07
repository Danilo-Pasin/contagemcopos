enum MemberRole { member, creator }

/// Entidade de domínio: Participante de um grupo.
class ParticipantEntity {
  final String id;
  final String groupId;
  final String anonId;
  final String name;
  final String? photoUrl;
  final MemberRole role;
  final DateTime joinedAt;

  /// Total de bebidas (preenchido via join/contagem).
  final int totalDrinks;

  /// Posição no ranking (1-based, preenchido via ranking view).
  final int? position;

  const ParticipantEntity({
    required this.id,
    required this.groupId,
    required this.anonId,
    required this.name,
    this.photoUrl,
    this.role = MemberRole.member,
    required this.joinedAt,
    this.totalDrinks = 0,
    this.position,
  });

  bool get isCreator => role == MemberRole.creator;

  ParticipantEntity copyWith({
    int? totalDrinks,
    int? position,
    String? photoUrl,
  }) =>
      ParticipantEntity(
        id: id,
        groupId: groupId,
        anonId: anonId,
        name: name,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role,
        joinedAt: joinedAt,
        totalDrinks: totalDrinks ?? this.totalDrinks,
        position: position ?? this.position,
      );
}
