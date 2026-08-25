import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/drink_types.dart';
import '../../../core/constants/title_system.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/group_session_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive_content.dart';

class StatsPage extends ConsumerWidget {
  final String code;
  const StatsPage({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(groupSessionProvider(code));
    final stats = ref.watch(statsProvider(code));

    // TTL/stale-while-revalidate: recarrega em background se expirou.
    // Idempotente e barato (guarda interna de TTL e request em voo).
    ref.read(statsProvider(code).notifier).ensureFresh();

    final ranking = session.ranking;
    final maxGoal = session.group?.maxGoal ?? 100;

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
    final mostActive =
        ranking.reduce((a, b) => a.totalDrinks >= b.totalDrinks ? a : b);
    final photoCount = session.feed
        .where((a) => a.type.toString().contains('photo')).length;

    return ResponsiveContent(
      child: RefreshIndicator(
        onRefresh:
            () => ref.read(statsProvider(code).notifier).forceRefresh(),
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
              mainAxisExtent: 122,
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
        // Gráfico diário (stale-while-revalidate: dados antigos ficam visíveis
        // durante o recarregamento)
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
                    child: stats.loading && !stats.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : stats.daily.isEmpty
                            ? const Center(child: Text('Sem registros'))
                            : _DailyChart(data: stats.daily),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        // Tipos de bebidas por pessoa
        if (stats.perPerson.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: _PerPersonTypesCard(persons: stats.perPerson),
            ),
          ),
        if (stats.perPerson.isNotEmpty)
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
          const SizedBox(height: AppSpacing.sm),
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
  final List<DailyStat> data;
  const _DailyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(
        0, (m, e) => e.value > m ? e.value.toDouble() : m);
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
                  child: Text(data[i].label,
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
                toY: e.value.value.toDouble(),
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
  final List<PerPersonTypes> persons;
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
  final PerPersonTypes person;
  const _PersonTypesRow({required this.person});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${person.total}',
                  style: context.tt.bodySmall
                      ?.copyWith(color: context.cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: person.types.map((t) {
              final def = drinkTypeById(t.typeId);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${def?.emoji ?? '🍻'} ${def?.label ?? 'Sem tipo'} ×${t.value}',
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
