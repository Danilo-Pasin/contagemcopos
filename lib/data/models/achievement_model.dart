import '../../domain/entities/achievement_entity.dart';

class AchievementModel {
  final Map<String, dynamic> json;
  AchievementModel(this.json);

  AchievementEntity toEntity() => AchievementEntity(
        id: json['id'] as String,
        code: json['code'] as String,
        emoji: json['emoji'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        unlocked: json['unlocked'] == true,
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.parse(json['unlocked_at'] as String)
            : null,
      );
}
