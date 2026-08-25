import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_time_x.dart';
import '../../domain/entities/participant_entity.dart';
import '../../data/repositories/drink_repository.dart';
import 'core_providers.dart';
import 'group_session_provider.dart';

/// Uma barra do gráfico "Bebidas por dia".
class DailyStat {
  final String label; // dd/MM
  final int value;
  const DailyStat({required this.label, required this.value});
}

/// Contagem de um tipo de bebida de uma pessoa.
class PersonTypeCount {
  final String typeId;
  final int value;
  const PersonTypeCount({required this.typeId, required this.value});
}

/// Agregado de tipos por pessoa (card "Tipos de bebidas por pessoa").
class PerPersonTypes {
  final String name;
  final int total;
  final List<PersonTypeCount> types; // ordenados por contagem desc
  const PerPersonTypes({
    required this.name,
    required this.total,
    required this.types,
  });
}

/// Estado das estatísticas do grupo, com base de TTL ([fetchedAt]).
class StatsState {
  final List<DailyStat> daily;
  final List<PerPersonTypes> perPerson;
  final bool loading;
  final DateTime? fetchedAt; // base do TTL; null = defasado
  final Object? error;

  const StatsState({
    this.daily = const [],
    this.perPerson = const [],
    this.loading = true,
    this.fetchedAt,
    this.error,
  });

  bool get hasData => daily.isNotEmpty || perPerson.isNotEmpty;

  /// Cópia com [fetchedAt] zerado (invalidação).
  StatsState markedStale() => StatsState(
        daily: daily,
        perPerson: perPerson,
        loading: loading,
        fetchedAt: null,
        error: error,
      );

  StatsState copyWith({
    List<DailyStat>? daily,
    List<PerPersonTypes>? perPerson,
    bool? loading,
    DateTime? fetchedAt,
    Object? error,
    bool clearError = false,
  }) =>
      StatsState(
        daily: daily ?? this.daily,
        perPerson: perPerson ?? this.perPerson,
        loading: loading ?? this.loading,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Agregação pura das linhas brutas de `ctg_drinks` em estatísticas.
///
/// Linhas com `created_at` inválido são ignoradas (parsing defensivo).
/// Participantes ausentes no ranking caem para o nome genérico.
({List<DailyStat> daily, List<PerPersonTypes> perPerson}) aggregateDrinkRows(
  List<Map<String, dynamic>> rows,
  List<ParticipantEntity> ranking,
) {
  final byDay = <String, int>{};
  // participante -> tipo -> quantidade
  final personMap = <String, Map<String, int>>{};
  for (final row in rows) {
    final raw = row['created_at'];
    final dt = raw is String ? DateTime.tryParse(raw) : null;
    if (dt == null) continue;
    final local = dt.toLocal();
    final key = DateTimeX.shortDate(local);
    byDay[key] = (byDay[key] ?? 0) + 1;
    final type = (row['drink_type'] as String?) ?? 'sem_tipo';
    final pid = (row['participant_id'] as String?) ?? 'sem_participante';
    final inner = personMap.putIfAbsent(pid, () => {});
    inner[type] = (inner[type] ?? 0) + 1;
  }

  final dailyEntries = byDay.entries.toList()
    ..sort((a, b) {
      final aP = a.key.split('/');
      final bP = b.key.split('/');
      final byMonth = int.parse(aP[1]).compareTo(int.parse(bP[1]));
      if (byMonth != 0) return byMonth;
      return int.parse(aP[0]).compareTo(int.parse(bP[0]));
    });

  final perPerson = personMap.entries.map((e) {
    final participant = ranking.where((p) => p.id == e.key).firstOrNull;
    final types = e.value.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return PerPersonTypes(
      name: participant?.name ?? 'Participante',
      total: types.fold<int>(0, (s, t) => s + t.value),
      types: types
          .map((t) => PersonTypeCount(typeId: t.key, value: t.value))
          .toList(),
    );
  }).toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  return (
    daily: [
      for (final e in dailyEntries) DailyStat(label: e.key, value: e.value)
    ],
    perPerson: perPerson,
  );
}

/// Notifier com cache TTL (stale-while-revalidate).
///
/// Estratégias de atualização:
/// - [ensureFresh]: chamado pela página; recarrega se `fetchedAt` expirou
///   (> [ttl]) ou nunca carregou. Mostra dados antigos enquanto recarrega.
/// - [forceRefresh]: pull-to-refresh; ignora o TTL.
/// - [invalidate]: chamado ao registrar bebida/foto; zera o `fetchedAt` e
///   recarrega em background (o IndexedStack da Fase A mantém a aba viva, mas
///   sem rebuild ao voltar — então o refetch acontece no próprio evento).
class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier({
    required Future<List<Map<String, dynamic>>> Function(String groupId)
        fetchRows,
    required String? Function() currentGroupId,
    required List<ParticipantEntity> Function() currentRanking,
    this.ttl = defaultTtl,
    DateTime Function()? now,
  })  : _fetchRows = fetchRows,
        _currentGroupId = currentGroupId,
        _currentRanking = currentRanking,
        _now = now ?? DateTime.now,
        super(const StatsState());

  static const defaultTtl = Duration(seconds: 60);
  final Duration ttl;

  final Future<List<Map<String, dynamic>>> Function(String groupId) _fetchRows;
  final String? Function() _currentGroupId;
  final List<ParticipantEntity> Function() _currentRanking;
  final DateTime Function() _now;

  bool _inFlight = false;
  bool _reloadQueued = false;

  Future<void> _load({bool staleOk = false}) async {
    final groupId = _currentGroupId();
    if (groupId == null) return; // sessão ainda não pronta
    if (_inFlight) {
      _reloadQueued = true;
      return;
    }
    _inFlight = true;
    // Stale-while-revalidate: só entra em loading visível se não há dados.
    if (!staleOk || !state.hasData) {
      state = state.copyWith(loading: true, clearError: true);
    }
    try {
      final rows = await _fetchRows(groupId);
      final agg = aggregateDrinkRows(rows, _currentRanking());
      state = StatsState(
        daily: agg.daily,
        perPerson: agg.perPerson,
        loading: false,
        fetchedAt: _now(),
      );
    } catch (e) {
      debugPrint('StatsNotifier: falha ao carregar estatísticas: $e');
      state = state.copyWith(loading: false, error: e);
    } finally {
      _inFlight = false;
      if (_reloadQueued) {
        _reloadQueued = false;
        await _load();
      }
    }
  }

  /// Recarrega se os dados expiraram (TTL) ou nunca foram carregados.
  void ensureFresh() {
    if (_inFlight || _currentGroupId() == null) return;
    final fetched = state.fetchedAt;
    final expired =
        fetched == null || _now().difference(fetched) > ttl;
    if (!expired) return;
    // Pode ser invocado durante o build da página (ConsumerWidget.build);
    // adia a mutação de state para fora do ciclo de build.
    Future.microtask(() => _load(staleOk: fetched != null));
  }

  /// Pull-to-refresh: ignora o TTL.
  Future<void> forceRefresh() {
    _reloadQueued = false;
    return _load(staleOk: state.hasData);
  }

  /// Invalida o cache (bebida/foto registrada) e recarrega em background.
  void invalidate() {
    if (_inFlight) {
      _reloadQueued = true;
      return;
    }
    state = state.markedStale();
    _load(staleOk: state.hasData);
  }
}

/// Cache de estatísticas por código de grupo.
/// autoDispose: liberado quando ninguém mais observa (saída do grupo).
final statsProvider = StateNotifierProvider.autoDispose
    .family<StatsNotifier, StatsState, String>((ref, code) {
  final repo = ref.watch(drinkRepositoryProvider);
  return StatsNotifier(
    fetchRows: repo.fetchStatsRaw,
    currentGroupId: () => ref.read(groupSessionProvider(code)).group?.id,
    currentRanking: () => ref.read(groupSessionProvider(code)).ranking,
  );
});
