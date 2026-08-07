import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/achievement_entity.dart';
import '../models/achievement_model.dart';

/// Repositório de conquistas.
class AchievementRepository {
  AchievementRepository(this._client);
  final SupabaseClient _client;

  /// Lista todas as conquistas, marcando as desbloqueadas pelo participante.
  Future<List<AchievementEntity>> listForParticipant(String participantId) async {
    final data = await _client.from('ctg_achievements').select('''
      id, code, emoji, title, description,
      unlocked:ctg_participant_achievements!left(unlocked_at)
    ''').order('code');

    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;
      final unlockedList = map['unlocked'] as List?;
      final unlockedRow =
          (unlockedList != null && unlockedList.isNotEmpty) ? unlockedList.first : null;
      return AchievementModel({
        'id': map['id'],
        'code': map['code'],
        'emoji': map['emoji'],
        'title': map['title'],
        'description': map['description'],
        'unlocked': unlockedRow != null,
        'unlocked_at': unlockedRow?['unlocked_at'],
      }).toEntity();
    }).toList();
  }

  /// Desbloqueia uma conquista para o participante (ignora se já existir).
  Future<void> unlock(String achievementCode, {
    required String participantId,
    required String groupId,
  }) async {
    final ach = await _client
        .from('ctg_achievements')
        .select('id')
        .eq('code', achievementCode)
        .maybeSingle();
    if (ach == null) return;
    await _client.from('ctg_participant_achievements').upsert({
      'participant_id': participantId,
      'group_id': groupId,
      'achievement_id': ach['id'],
    }, onConflict: 'participant_id,achievement_id');
  }

  /// Busca campeões de competições anteriores (Hall da Fama).
  Future<List<Map<String, dynamic>>> hallOfFame() async {
    final data = await _client
        .from('ctg_hall_of_fame')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
