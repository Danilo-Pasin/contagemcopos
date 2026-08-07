import '../../domain/entities/participant_entity.dart';

class ParticipantModel {
  final Map<String, dynamic> json;
  ParticipantModel(this.json);

  ParticipantEntity toEntity() => ParticipantEntity(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        anonId: json['anon_id'] as String,
        name: json['name'] as String,
        photoUrl: json['photo_url'] as String?,
        role: json['role'] == 'creator' ? MemberRole.creator : MemberRole.member,
        joinedAt: DateTime.parse(json['joined_at'] as String),
        totalDrinks: (json['total_drinks'] as num?)?.toInt() ?? 0,
        position: (json['position'] as num?)?.toInt(),
      );
}
