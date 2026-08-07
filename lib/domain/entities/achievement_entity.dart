/// Entidade de domínio: Conquista (definição + status de desbloqueio).
class AchievementEntity {
  final String id;
  final String code;
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementEntity({
    required this.id,
    required this.code,
    required this.emoji,
    required this.title,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory AchievementEntity.empty() => const AchievementEntity(
        id: '',
        code: '',
        emoji: '🏅',
        title: '',
        description: '',
      );
}
