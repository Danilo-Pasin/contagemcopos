/// Entidade de domínio: Foto do álbum (bebida/memória).
class PhotoEntity {
  final String id;
  final String groupId;
  final String participantId;
  final String? participantName;
  final String? participantPhoto;
  final String? drinkId;
  final String url;
  final DateTime createdAt;

  const PhotoEntity({
    required this.id,
    required this.groupId,
    required this.participantId,
    this.participantName,
    this.participantPhoto,
    this.drinkId,
    required this.url,
    required this.createdAt,
  });

  factory PhotoEntity.empty() => PhotoEntity(
        id: '',
        groupId: '',
        participantId: '',
        url: '',
        createdAt: DateTime.now(),
      );
}
