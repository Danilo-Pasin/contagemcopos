import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/participant_entity.dart';
import '../models/group_model.dart';
import '../models/participant_model.dart';

/// Agregação pura (testável) do ranking global de grupos.
///
/// Recebe as linhas brutas de `ctg_groups` (com `id`, `name`, `cover_emoji`) e
/// de `ctg_drinks` (com `group_id`) e devolve a soma de bebidas por grupo,
/// ordenada do maior para o menor. Sem acesso à rede.
List<GroupRank> aggregateGroupRanking(
    List<dynamic> groupsData, List<dynamic> drinksData) {
  final counts = <String, int>{};
  for (final d in drinksData) {
    final gid = (d as Map<String, dynamic>)['group_id'] as String?;
    if (gid == null) continue;
    counts[gid] = (counts[gid] ?? 0) + 1;
  }

  final ranks = groupsData.map((g) {
    final map = g as Map<String, dynamic>;
    final gid = map['id'] as String;
    return GroupRank(
      groupId: gid,
      name: (map['name'] as String?) ?? 'Grupo',
      coverEmoji: (map['cover_emoji'] as String?) ?? '🍻',
      totalDrinks: counts[gid] ?? 0,
    );
  }).toList()
    ..sort((a, b) => b.totalDrinks.compareTo(a.totalDrinks));
  return ranks;
}

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

  /// Garante a conta nome+senha no escopo de um grupo.
  ///
  /// O mesmo nome pode existir em grupos diferentes com senhas diferentes:
  /// - Se já há participante com esse nome DESTE grupo: valida a senha
  ///   (hash comparado no banco) e devolve o id; senha errada lança erro.
  /// - Mesmo nome+senha já existente em outra conta: reaproveita
  ///   (mesma pessoa em vários grupos compartilha credenciais).
  /// - Caso contrário: cria conta nova.
  Future<String> ensureAccount({
    required String name,
    required String password,
    required String groupId,
  }) async {
    final accountId = await _client.rpc('ctg_ensure_account', params: {
      'p_name': name.trim(),
      'p_password': password,
      'p_group_id': groupId,
    });
    return accountId as String;
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

  /// Ranking global de grupos: soma de bebidas por grupo (todos os grupos).
  ///
  /// Agrega no front (sem objeto no banco): busca os grupos e as linhas de
  /// bebida (só o group_id) e soma em memória. Como a festa tem poucos grupos
  /// e dura algumas horas, o volume é baixo e a abordagem dispensa migração.
  Future<List<GroupRank>> listGroupRanking() async {
    final groupsData = await _client
        .from('ctg_groups')
        .select('id, name, cover_emoji');
    final drinksData = await _client
        .from('ctg_drinks')
        .select('group_id');
    return aggregateGroupRanking(groupsData as List, drinksData as List);
  }

  /// Atualiza foto de perfil do participante.
  ///
  /// Lança [PostgrestException] (PGRST116) se o RLS bloquear a atualização
  /// (0 linhas), em vez de falhar silenciosamente.
  Future<void> updateParticipantPhoto(
      String participantId, String photoUrl) async {
    await _client.from('ctg_participants').update({
      'photo_url': photoUrl,
    }).eq('id', participantId).select().single();
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
