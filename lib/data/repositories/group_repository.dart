import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/participant_entity.dart';
import '../models/group_model.dart';
import '../models/participant_model.dart';

/// Repositório de grupos e participantes (tabelas ctg_ no schema public).
class GroupRepository {
  GroupRepository(this._client);
  final SupabaseClient _client;

  /// Cria um grupo via RPC (gera código único).
  Future<GroupEntity> createGroup({
    required String anonId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
    required int maxGoal,
    String coverEmoji = '🍻',
  }) async {
    final res = await _client.rpc(
      'ctg_create_group',
      params: {
        'p_name': name,
        'p_creator_anon_id': anonId,
        'p_start_date': startDate.toUtc().toIso8601String(),
        'p_end_date': endDate.toUtc().toIso8601String(),
        'p_duration_days': durationDays,
        'p_max_goal': maxGoal,
        'p_cover_emoji': coverEmoji,
      },
    );

    final row = (res as List).first as Map<String, dynamic>;
    final groupId = (row['out_id'] ?? row['id']) as String;

    final data = await _client
        .from('ctg_groups')
        .select()
        .eq('id', groupId)
        .single();
    return GroupModel(data as Map<String, dynamic>).toEntity();
  }

  /// Busca um grupo pelo código.
  Future<GroupEntity?> getGroupByCode(String code) async {
    final data = await _client
        .from('ctg_groups')
        .select()
        .eq('code', code.toUpperCase())
        .maybeSingle();
    if (data == null) return null;
    return GroupModel(data as Map<String, dynamic>).toEntity();
  }

  Future<GroupEntity?> getGroupById(String id) async {
    final data = await _client
        .from('ctg_groups')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return GroupModel(data as Map<String, dynamic>).toEntity();
  }

  /// Adiciona o usuário atual como participante do grupo.
  Future<ParticipantEntity> joinGroup({
    required GroupEntity group,
    required String anonId,
    required String name,
    String? accountId,
    String? photoUrl,
    bool isCreator = false,
  }) async {
    final data = await _client.from('ctg_participants').insert({
      'group_id': group.id,
      'anon_id': anonId,
      'name': name,
      'account_id': accountId,
      'photo_url': photoUrl,
      'role': isCreator ? 'creator' : 'member',
    }).select().single();
    return ParticipantModel(data as Map<String, dynamic>).toEntity();
  }

  /// Busca participante pelo anon_id dentro de um grupo.
  Future<ParticipantEntity?> findMember(String groupId, String anonId) async {
    final data = await _client
        .from('ctg_participants')
        .select()
        .eq('group_id', groupId)
        .eq('anon_id', anonId)
        .maybeSingle();
    if (data == null) return null;
    return ParticipantModel(data as Map<String, dynamic>).toEntity();
  }

  /// Busca participante de um grupo pelo id de conta (nome + senha).
  Future<ParticipantEntity?> findMemberByAccount(
      String groupId, String accountId) async {
    final data = await _client
        .from('ctg_participants')
        .select()
        .eq('group_id', groupId)
        .eq('account_id', accountId)
        .maybeSingle();
    if (data == null) return null;
    return ParticipantModel(data as Map<String, dynamic>).toEntity();
  }

  /// Garante que existe uma conta (name + password).
  ///
  /// - Se a conta com esse nome já existe e a senha bate, devolve o id.
  /// - Se a conta não existe, cria e devolve o id.
  /// - Se a conta existe mas a senha difere, lança erro.
  Future<String> ensureAccount({
    required String name,
    required String password,
  }) async {
    final trimmed = name.trim();
    final existing = await _client
        .from('ctg_accounts')
        .select('id,password')
        .eq('name', trimmed)
        .maybeSingle();
    if (existing != null) {
      if (existing['password'].toString() != password) {
        throw Exception('Senha incorreta para "$trimmed". Se é novo, use outro nome.');
      }
      return existing['id'] as String;
    }
    final ins = await _client
        .from('ctg_accounts')
        .insert({'name': trimmed, 'password': password})
        .select('id')
        .single();
    return ins['id'] as String;
  }

  /// Lista participantes com total de bebidas (via ctg_ranking_view).
  Future<List<ParticipantEntity>> listRanking(String groupId) async {
    final data = await _client
        .from('ctg_ranking_view')
        .select()
        .eq('group_id', groupId)
        .order('position', ascending: true);
    return (data as List)
        .map((e) => ParticipantModel(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Atualiza foto de perfil do participante.
  Future<void> updateParticipantPhoto(
      String participantId, String photoUrl) async {
    await _client.from('ctg_participants').update({
      'photo_url': photoUrl,
    }).eq('id', participantId);
  }

  /// Arquiva o grupo (somente criador).
  Future<void> archiveGroup(String groupId) async {
    await _client
        .from('ctg_groups')
        .update({'status': 'archived'}).eq('id', groupId);
  }

  /// Encerra grupos expirados.
  Future<void> endExpiredGroups() async {
    await _client.rpc('ctg_end_expired_groups');
  }
}
