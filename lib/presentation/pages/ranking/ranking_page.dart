import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/title_system.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/group_session_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/medal_badge.dart';
import '../../widgets/responsive_content.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));
    final ranking = session.ranking;
    final maxGoal = session.group?.maxGoal ?? 100;

    return ResponsiveContent(
      child: CustomScrollView(
        slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 8)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('Ranking',
                  style: context.tt.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        if (ranking.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              emoji: '🏆',
              title: 'Ranking vazio',
              subtitle: 'Adicione bebidas para ver o ranking.',
            ),
          )
        else ...[
          // Pódio dos top 3
          if (ranking.length >= 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _Podium(ranking: ranking.take(3).toList(), maxGoal: maxGoal),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          // Restante
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actualIndex = index + (ranking.length >= 3 ? 3 : 0);
                  if (actualIndex >= ranking.length) return null;
                  final p = ranking[actualIndex];
                  final tier = TitleSystem.currentTier(p.totalDrinks, maxGoal);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                      child: Row(
                        children: [
                          MedalBadge(position: actualIndex + 1, size: 30),
                          const SizedBox(width: AppSpacing.md),
                          AppAvatar(
                              photoUrl: p.photoUrl,
                              name: p.name,
                              radius: 20,
                              isCreator: p.isCreator),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.tt.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                Text('${tier.emoji} ${tier.name}',
                                    style: context.tt.bodySmall),
                              ],
                            ),
                          ),
                          Text('${p.totalDrinks}',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (actualIndex * 30).ms);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
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

class _Podium extends StatelessWidget {
  final List ranking;
  final int maxGoal;
  const _Podium({required this.ranking, required this.maxGoal});

  @override
  Widget build(BuildContext context) {
    // Ordem visual do pódio: 2º, 1º, 3º
    final first = ranking.isNotEmpty ? ranking[0] : null;
    final second = ranking.length > 1 ? ranking[1] : null;
    final third = ranking.length > 2 ? ranking[2] : null;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            _PodiumColumn(participant: second, place: 2, height: 90, maxGoal: maxGoal)
          else
            const SizedBox(width: 70),
          const SizedBox(width: AppSpacing.sm),
          if (first != null)
            _PodiumColumn(participant: first, place: 1, height: 120, maxGoal: maxGoal),
          const SizedBox(width: AppSpacing.sm),
          if (third != null)
            _PodiumColumn(participant: third, place: 3, height: 70, maxGoal: maxGoal)
          else
            const SizedBox(width: 70),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final dynamic participant;
  final int place;
  final double height;
  final int maxGoal;

  const _PodiumColumn({
    required this.participant,
    required this.place,
    required this.height,
    required this.maxGoal,
  });

  @override
  Widget build(BuildContext context) {
    final tier = TitleSystem.currentTier(participant.totalDrinks as int, maxGoal);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppAvatar(
          photoUrl: participant.photoUrl as String?,
          name: participant.name as String,
          radius: place == 1 ? 32 : 24,
          isCreator: participant.isCreator,
          hasGradientRing: place == 1,
        ),
        const SizedBox(height: 4),
        Text(participant.name.split(' ').first,
            style: context.tt.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
        Text('${participant.totalDrinks}',
            style: TextStyle(
                fontSize: place == 1 ? 22 : 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Container(
          width: 64,
          height: height,
          decoration: BoxDecoration(
            gradient: _gradient(place),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 6),
          child: Text(_emoji(place), style: const TextStyle(fontSize: 22)),
        ),
      ],
    );
  }

  LinearGradient _gradient(int place) {
    switch (place) {
      case 1:
        return AppGradients.gold;
      case 2:
        return AppGradients.silver;
      default:
        return AppGradients.bronze;
    }
  }

  String _emoji(int place) {
    switch (place) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      default:
        return '🥉';
    }
  }
}
