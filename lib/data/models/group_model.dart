import 'package:flutter/foundation.dart';
import '../../domain/entities/group_entity.dart';

class GroupModel {
  final Map<String, dynamic> json;
  GroupModel(this.json);

  factory GroupModel.fromEntity(GroupEntity e) => GroupModel({
        'id': e.id,
        'code': e.code,
        'name': e.name,
        'creator_anon_id': e.creatorAnonId,
        'start_date': e.startDate.toIso8601String(),
        'end_date': e.endDate.toIso8601String(),
        'duration_days': e.durationDays,
        'max_goal': e.maxGoal,
        'status': e.status.name,
        'cover_emoji': e.coverEmoji,
        'created_at': e.createdAt.toIso8601String(),
        'ended_at': e.endedAt?.toIso8601String(),
      });

  GroupEntity toEntity() {
    GroupStatus status;
    switch (json['status']) {
      case 'ended':
        status = GroupStatus.ended;
        break;
      case 'archived':
        status = GroupStatus.archived;
        break;
      case 'active':
        status = GroupStatus.active;
        break;
      default:
        // Por segurança, nunca mapear um status desconhecido como 'active'
        // (que liberaria entradas no front). Vira 'unknown' → não aceita nada.
        debugPrint('GroupModel: status desconhecido "${json['status']}"');
        status = GroupStatus.unknown;
    }
    return GroupEntity(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      creatorAnonId: json['creator_anon_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      durationDays: json['duration_days'] as int,
      maxGoal: json['max_goal'] as int,
      status: status,
      coverEmoji: (json['cover_emoji'] as String?) ?? '🍻',
      createdAt: DateTime.parse(json['created_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }
}
