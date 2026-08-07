enum ActivityType {
  drinkAdded,
  photoAdded,
  memberJoined,
  groupCreated,
  titleChanged,
  achievementUnlocked,
  groupEnded;

  static ActivityType fromString(String s) {
    switch (s) {
      case 'drink_added':
        return ActivityType.drinkAdded;
      case 'photo_added':
        return ActivityType.photoAdded;
      case 'member_joined':
        return ActivityType.memberJoined;
      case 'group_created':
        return ActivityType.groupCreated;
      case 'title_changed':
        return ActivityType.titleChanged;
      case 'achievement_unlocked':
        return ActivityType.achievementUnlocked;
      case 'group_ended':
        return ActivityType.groupEnded;
      default:
        return ActivityType.drinkAdded;
    }
  }
}

/// Item do feed de atividades.
class ActivityItem {
  final String id;
  final String groupId;
  final String? participantId;
  final String? participantName;
  final String? participantPhoto;
  final ActivityType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  /// URL da foto (quando activity_type = photo_added).
  final String? photoUrl;

  const ActivityItem({
    required this.id,
    required this.groupId,
    this.participantId,
    this.participantName,
    this.participantPhoto,
    required this.type,
    this.payload = const {},
    required this.createdAt,
    this.photoUrl,
  });

  factory ActivityItem.empty() => ActivityItem(
        id: '',
        groupId: '',
        type: ActivityType.drinkAdded,
        createdAt: DateTime.now(),
      );
}
