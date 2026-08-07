import '../../domain/entities/photo_entity.dart';

class PhotoModel {
  final Map<String, dynamic> json;
  PhotoModel(this.json);

  PhotoEntity toEntity() => PhotoEntity(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        participantId: json['participant_id'] as String,
        participantName: json['participant_name'] as String?,
        participantPhoto: json['participant_photo'] as String?,
        drinkId: json['drink_id'] as String?,
        url: json['url'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
