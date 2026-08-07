import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/photo_entity.dart';
import '../models/activity_model.dart';
import '../models/photo_model.dart';

/// Repositório de bebidas, fotos e feed de atividades.
class DrinkRepository {
  DrinkRepository(this._client);
  final SupabaseClient _client;

  /// Registra uma bebida (aciona trigger de activity_log).
  Future<void> addDrink({
    required String groupId,
    required String participantId,
    String? drinkType,
    String? note,
  }) async {
    await _client.from('ctg_drinks').insert({
      'group_id': groupId,
      'participant_id': participantId,
      if (drinkType != null) 'drink_type': drinkType,
      if (note != null) 'note': note,
    });
  }

  /// Adiciona uma foto ao álbum (e ao feed).
  Future<void> addPhoto({
    required String groupId,
    required String participantId,
    required String url,
    String? drinkId,
  }) async {
    await _client.from('ctg_photos').insert({
      'group_id': groupId,
      'participant_id': participantId,
      'url': url,
      'drink_id': drinkId,
    });
  }

  /// Lista o feed de atividades com dados de participante (join).
  Future<List<ActivityItem>> listFeed(String groupId, {int limit = 100}) async {
    final data = await _client
        .from('ctg_activity_log')
        .select('*, participant:ctg_participants(name, photo_url)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;
      final participant = map['participant'] as Map<String, dynamic>?;
      return ActivityModel({
        ...map,
        'participant_name': participant?['name'],
        'participant_photo': participant?['photo_url'],
      }).toEntity();
    }).toList();
  }

  /// Lista todas as fotos do álbum do grupo (com dados do autor).
  Future<List<PhotoEntity>> listPhotos(String groupId) async {
    final data = await _client
        .from('ctg_photos')
        .select('*, participant:ctg_participants(name, photo_url)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;
      final participant = map['participant'] as Map<String, dynamic>?;
      return PhotoModel({
        ...map,
        'participant_name': participant?['name'],
        'participant_photo': participant?['photo_url'],
      }).toEntity();
    }).toList();
  }

  /// Conta drinks diários (para gráficos).
  Future<List<Map<String, dynamic>>> dailyCounts(String groupId) async {
    final data = await _client
        .from('ctg_drinks')
        .select('created_at')
        .eq('group_id', groupId);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
