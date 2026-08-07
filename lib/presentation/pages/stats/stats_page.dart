import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/title_system.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_time_x.dart';
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
  bool _loading = true;
  String? _loadedGroupId;

  Future<void> _loadStats(String groupId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final data = await client
          .from('ctg_drinks')
          .select('created_at')
          .eq('group_id', groupId);
      final byDay = <String, int>{};
      for (final row in data as List) {
        final dt = DateTime.parse(row['created_at']).toLocal();
        final key = DateTimeX.shortDate(dt);
        byDay[key] = (byDay[key] ?? 0) + 1;
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
      setState(() {
        _daily = entries
            .map((e) => {'label': e.key, 'value': e.value})
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));
    final ranking = session.ranking;
    final maxGoal = session.group?.maxGoal ?? 100;

    // Carrega as estatísticas assim que o grupo estiver disponível
    // (evita ficar preso em loading se a sessão ainda não carregou).
    final groupId = session.group?.id;
    if (groupId != null && groupId != _loadedGroupId) {
      _loadedGroupId = groupId;
      _loadStats(groupId);
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
              _MetricCard('🍺', 'Total', '$total', const Color(0xFF7C4DFF)),
              _MetricCard('📊', 'Média/pessoa', media.toStringAsFixed(1), const Color(0xFFE040FB)),
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
    if (count == 0 && required > (ranking.fold<int>(0, (m, p) => p.totalDrinks > m ? p.totalDrinks : m))) {
      return const SizedBox.shrink();
    }
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
