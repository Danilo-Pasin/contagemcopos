import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/drink_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/participant_entity.dart';
import 'core_providers.dart';
import 'identity_provider.dart';

/// Estado completo da sessão de um grupo.
class GroupSessionState {
  final GroupEntity? group;
  final ParticipantEntity? me;
  final List<ParticipantEntity> ranking;
  final List<ActivityItem> feed;
  final bool loading;
  final String? error;

  const GroupSessionState({
    this.group,
    this.me,
    this.ranking = const [],
    this.feed = const [],
    this.loading = true,
    this.error,
  });

  bool get hasGroup => group != null;
  bool get isMember => me != null;
  bool get iAmCreator => me?.isCreator ?? false;

  int get totalGroupDrinks =>
      ranking.fold(0, (sum, p) => sum + p.totalDrinks);

  ParticipantEntity? get leader =>
      ranking.isEmpty ? null : ranking.first;

  GroupSessionState copyWith({
    GroupEntity? group,
    ParticipantEntity? me,
    List<ParticipantEntity>? ranking,
    List<ActivityItem>? feed,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      GroupSessionState(
        group: group ?? this.group,
        me: me ?? this.me,
        ranking: ranking ?? this.ranking,
        feed: feed ?? this.feed,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class GroupSessionNotifier extends StateNotifier<GroupSessionState> {
  GroupSessionNotifier(this._ref, this._code)
      : super(const GroupSessionState()) {
    _init();
  }

  final Ref _ref;
  final String _code;

  GroupRepository get _groupRepo => _ref.read(groupRepositoryProvider);
  DrinkRepository get _drinkRepo => _ref.read(drinkRepositoryProvider);
  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  IdentityNotifier get _identity => _ref.read(identityProvider.notifier);

  Timer? _refreshTimer;
  RealtimeChannel? _rankingChannel;
  RealtimeChannel? _feedChannel;

  Future<void> _init() async {
    try {
      debugPrint('[GroupSession] init para código $_code');
      // Garante identidade pronta antes de buscar membro
      try {
        await _identity.ensureReady();
      } catch (e) {
        debugPrint('[GroupSession] aviso: identity não pronta: $e');
      }

      await _groupRepo.endExpiredGroups();
      final group = await _groupRepo.getGroupByCode(_code);
      if (group == null) {
        debugPrint('[GroupSession] grupo não encontrado');
        state = GroupSessionState(
          loading: false,
          error: 'Grupo não encontrado. Verifique o código.',
        );
        return;
      }
      debugPrint('[GroupSession] grupo encontrado: ${group.name}');

      // Tenta localizar o participante atual (conta nome+senha ou anon_id)
      final identityState = _ref.read(identityProvider);
      ParticipantEntity? me;
      if (identityState.accountId != null) {
        me = await _groupRepo.findMemberByAccount(
            group.id, identityState.accountId!);
        debugPrint('[GroupSession] membro (conta): ${me?.name ?? "nenhum"}');
      } else if (identityState.anonId != null) {
        me = await _groupRepo.findMember(group.id, identityState.anonId!);
        debugPrint('[GroupSession] membro (anon): ${me?.name ?? "nenhum"}');
      }

      state = GroupSessionState(
        group: group,
        me: me,
        loading: false,
      );

      await _refreshAll();
      _subscribeRealtime(group.id);
      // Polling de segurança a cada 20s (garante atualização)
      _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (state.hasGroup) _refreshAll();
      });
    } catch (e) {
      debugPrint('[GroupSession] ERRO init: $e');
      state = GroupSessionState(loading: false, error: e.toString());
    }
  }

  Future<void> _refreshAll() async {
    if (state.group == null) return;
    try {
      final ranking = await _groupRepo.listRanking(state.group!.id);
      final feed = await _drinkRepo.listFeed(state.group!.id);
      // atualiza "me" com dados frescos do ranking
      ParticipantEntity? me = state.me;
      if (me != null) {
        final fresh = ranking.where((p) => p.id == me!.id);
        if (fresh.isNotEmpty) me = fresh.first;
      }
      state = state.copyWith(ranking: ranking, feed: feed, me: me, clearError: true);
    } catch (e, s) {
      // Falha transitória de refresh: preserva os dados atuais para não
      // derrubar a UI do grupo. O próximo polling/realtime tenta novamente.
      debugPrint('[GroupSession] falha no refresh: $e\n$s');
    }
  }

  void _subscribeRealtime(String groupId) {
    const schema = 'public';
    _rankingChannel = _client
        .channel('ranking-$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: schema,
          table: 'ctg_drinks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => _refreshAll(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: schema,
          table: 'ctg_photos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => _refreshAll(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: schema,
          table: 'ctg_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => _refreshAll(),
        )
        .subscribe();

    _feedChannel = _client
        .channel('feed-$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: schema,
          table: 'ctg_activity_log',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => _refreshAll(),
        )
        .subscribe();
  }

  /// Entra no grupo como participante.
  Future<void> joinAsMember({
    required String name,
    String? photoUrl,
    required String anonId,
    bool isCreator = false,
  }) async {
    final group = state.group;
    if (group == null) return;
    final me = await _groupRepo.joinGroup(
      group: group,
      anonId: anonId,
      name: name,
      photoUrl: photoUrl,
      isCreator: isCreator,
    );
    await _identity.rememberMember(_code, me.id);
    state = state.copyWith(me: me);
    await _refreshAll();
  }

  /// Registra +1 bebida com a foto obrigatória vinculada.
  ///
  /// Insere a bebida, obtém o id criado e então registra a foto apontando para
  /// ela (`ctg_photos.drink_id`), mantendo o registro atômico do ponto de
  /// vista do usuário. Sem foto a bebida não é registrada.
  Future<void> addDrinkWithPhoto({
    String? drinkType,
    String? note,
    required String photoUrl,
  }) async {
    final me = state.me;
    final group = state.group;
    if (me == null || group == null) return;
    final drinkId = await _drinkRepo.addDrink(
      groupId: group.id,
      participantId: me.id,
      drinkType: drinkType,
      note: note,
    );
    await _drinkRepo.addPhoto(
      groupId: group.id,
      participantId: me.id,
      url: photoUrl,
      drinkId: drinkId,
    );
    await _refreshAll();
  }

  /// Adiciona uma foto ao álbum.
  Future<void> addPhoto(String url) async {
    final me = state.me;
    final group = state.group;
    if (me == null || group == null) return;
    await _drinkRepo.addPhoto(
      groupId: group.id,
      participantId: me.id,
      url: url,
    );
    await _refreshAll();
  }

  /// Atualiza a foto de perfil do participante atual.
  Future<void> updateProfilePhoto(String url) async {
    final me = state.me;
    if (me == null) return;
    await _groupRepo.updateParticipantPhoto(me.id, url);
    await _refreshAll();
  }

  Future<void> refresh() => _refreshAll();

  @override
  void dispose() {
    _rankingChannel?.unsubscribe();
    _feedChannel?.unsubscribe();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider factory: cria a sessão para um código de grupo.
final groupSessionProvider = StateNotifierProvider.autoDispose
    .family<GroupSessionNotifier, GroupSessionState, String>((ref, code) {
  return GroupSessionNotifier(ref, code);
});
