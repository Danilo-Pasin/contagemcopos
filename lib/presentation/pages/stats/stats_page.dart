import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/drink_types.dart';
import '../../../core/constants/title_system.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../domain/entities/participant_entity.dart';
import '../../providers/core_providers.dart';
import '../../providers/group_session_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive_content.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  List<Map<String, dynamic>> _daily = [];
  List<Map<String, dynamic>> _perPerson = [];
  bool _loading = true;
  String? _loadedKey;

  Future<void> _loadStats(
    String groupId,
    List<ParticipantEntity> ranking,
  ) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final data = await client
          .from('ctg_drinks')
          .select('created_at, drink_type, participant_id')
          .eq('group_id', groupId);
      final byDay = <String, int>{};
      // participante -> tipo -> quantidade
      final personMap = <String, Map<String, int>>{};
      for (final row in data as List) {
        final raw = row['created_at'];
        final dt = raw is String ? DateTime.tryParse(raw) : null;
        if (dt == null) {
          debugPrint('StatsPage: created_at inválido em $row');
          continue;
        }
        final local = dt.toLocal();
        final key = DateTimeX.shortDate(local);
        byDay[key] = (byDay[key] ?? 0) + 1;
        final type = (row['drink_type'] as String?) ?? 'sem_tipo';
        final pid = (row['participant_id'] as String?) ?? 'sem_participante';
        final inner = personMap.putIfAbsent(pid, () => {});
        inner[type] = (inner[type] ?? 0) + 1;
      }
      final entries = byDay.entries.toList();
      entries.sort((a, b) {
        final aP = a.key.split('/');
        final bP = b.key.split('/');
        final aM = int.parse(aP[1]);
        final bM = int.parse(bP[1]);
        final byMonth = aM.compareTo(bM);
        if (byMonth != 0) return byMonth;
        return int.parse(aP[0]).compareTo(int.parse(bP[0]));
      });

      final persons = personMap.entries.map((e) {
        final participant = ranking.where((p) => p.id == e.key).firstOrNull;
        final name = participant?.name ?? 'Participante';
        final types = e.value.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total =
            types.fold<int>(0, (s, t) => s + t.value);
        return {
          'name': name,
          'total': total,
          'types': types
              .map((t) => {'id': t.key, 'value': t.value})
              .toList(),
        };
      }).toList()
        ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

      setState(() {
        _daily = entries
            .map((e) => {'label': e.key, 'value': e.value})
            .toList();
        _perPerson = persons;
        _loading = false;
      });
    } catch (e) {
      debugPrint('StatsPage: falha ao carregar estatísticas: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Recarrega as estatísticas (pull-to-refresh).
  Future<void> _reload(
    String groupId,
    List<ParticipantEntity> ranking,
  ) async {
    _loadedKey = null;
    await _loadStats(groupId, ranking);
  }

  @override
  Widget build(BuildContext context) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));
    final ranking = session.ranking;
    final maxGoal = session.group?.maxGoal ?? 100;

    // Carrega as estatísticas assim que o grupo estiver disponível
    // (evita ficar preso em loading se a sessão ainda não carregou).
    // Recarrega apenas uma vez por grupo (ou com pull-to-refresh), em vez
    // de refazer o SELECT completo a cada nova bebida.
    final groupId = session.group?.id;
    if (groupId != null && groupId != _loadedKey) {
      _loadedKey = groupId;
      _loadStats(groupId, ranking);
    }

    if (ranking.isEmpty) {
      return const ResponsiveContent(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 8)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                emoji: '📊',
                title: 'Sem dados ainda',
                subtitle: 'As estatísticas aparecem conforme o grupo evolui.',
              ),
            ),
          ],
        ),
      );
    }

    final total = ranking.fold<int>(0, (s, p) => s + p.totalDrinks);
    final media = ranking.isNotEmpty ? (total / ranking.length) : 0.0;
    final mostActive = ranking.reduce((a, b) =>
        a.totalDrinks >= b.totalDrinks ? a : b);
    final photoCount = session.feed
        .where((a) => a.type.toString().contains('photo')).length;

    return ResponsiveContent(
      child: RefreshIndicator(
        onRefresh: () => _reload(groupId!, ranking),
        child: CustomScrollView(
          slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 8)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('Estatísticas',
                  style: context.tt.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        // Métricas
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisExtent: 108,
            ),
            delegate: SliverChildListDelegate([
              _MetricCard('🍺', 'Total', '$total', const Color(0xFF1FB45C)),
              _MetricCard('📊', 'Média/pessoa', media.toStringAsFixed(1), const Color(0xFF48E37F)),
              _MetricCard('👑', 'Mais ativo', mostActive.name.split(' ').first, const Color(0xFFFFB300)),
              _MetricCard('📸', 'Fotos', '$photoCount', const Color(0xFF4CAF50)),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        // Gráfico diário
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bebidas por dia',
                      style: context.tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 180,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _daily.isEmpty
                            ? const Center(child: Text('Sem registros'))
                            : _DailyChart(data: _daily),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        // Tipos de bebidas por pessoa
        if (_perPerson.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: _PerPersonTypesCard(persons: _perPerson),
            ),
          ),
        if (_perPerson.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        // Distribuição de títulos
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distribuição de títulos',
                      style: context.tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final tier in TitleSystem.tiers)
                    _TitleDistribution(
                      tier: tier,
                      maxGoal: maxGoal,
                      ranking: ranking,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    ),
    ),
    );
  }

  String _extractCode(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final match = RegExp(r'/g/([A-Z0-9]+)').firstMatch(uri);
    return match?.group(1) ?? '';
  }
}

class _MetricCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _MetricCard(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const Spacer(),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.tt.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.tt.bodySmall
                  ?.copyWith(color: context.cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _DailyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(
        0, (m, e) => (e['value'] as int) > m ? (e['value'] as int).toDouble() : m);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal + 1,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(data[i]['label'] as String,
                      style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['value'] as int).toDouble(),
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: AppGradients.primary,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TitleDistribution extends StatelessWidget {
  final TitleTier tier;
  final int maxGoal;
  final List ranking;
  const _TitleDistribution({
    required this.tier,
    required this.maxGoal,
    required this.ranking,
  });

  @override
  Widget build(BuildContext context) {
    final required = tier.requiredDrinks(maxGoal);
    final count = ranking.where((p) =>
        TitleSystem.currentTier(p.totalDrinks as int, maxGoal).id == tier.id).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(tier.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${tier.name} ($required+)',
                style: context.tt.bodySmall),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('$count',
                  style: context.tt.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _PerPersonTypesCard extends StatelessWidget {
  final List<Map<String, dynamic>> persons;
  const _PerPersonTypesCard({required this.persons});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tipos de bebidas por pessoa',
              style: context.tt.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          for (final person in persons) _PersonTypesRow(person: person),
        ],
      ),
    );
  }
}

class _PersonTypesRow extends StatelessWidget {
  final Map<String, dynamic> person;
  const _PersonTypesRow({required this.person});

  @override
  Widget build(BuildContext context) {
    final types = (person['types'] as List).cast<Map<String, dynamic>>();
    final total = person['total'] as int;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(person['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('$total',
                  style: context.tt.bodySmall
                      ?.copyWith(color: context.cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: types.map((t) {
              final def = drinkTypeById(t['id'] as String);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${def?.emoji ?? '🍻'} ${def?.label ?? 'Sem tipo'} ×${t['value']}',
                  style: context.tt.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
