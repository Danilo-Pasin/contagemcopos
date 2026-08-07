import '../../domain/entities/activity_item.dart';

class ActivityModel {
  final Map<String, dynamic> json;
  ActivityModel(this.json);

  ActivityItem toEntity() {
    final payload =
        Map<String, dynamic>.from(json['payload'] as Map? ?? const {});
    return ActivityItem(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      participantId: json['participant_id'] as String?,
      participantName: json['participant_name'] as String?,
      participantPhoto: json['participant_photo'] as String?,
      type: ActivityType.fromString(json['type'] as String),
      payload: payload,
      createdAt: DateTime.parse(json['created_at'] as String),
      photoUrl: (json['photo_url'] as String?) ?? payload['url'] as String?,
    );
  }
}
