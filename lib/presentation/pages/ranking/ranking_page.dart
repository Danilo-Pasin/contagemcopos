import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/title_system.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/group_entity.dart';
import '../../providers/core_providers.dart';
import '../../providers/group_session_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/medal_badge.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  /// Participantes já exibidos: anima apenas na primeira carga e em
  /// participantes realmente novos — nunca a cada rebuild de realtime.
  final Set<String> _seenIds = {};
  bool _bootstrapped = false;

  @override
  Widget build(BuildContext context) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));
    final ranking = session.ranking;
    final maxGoal = session.group?.maxGoal ?? 100;
    final isFirstLoad = !_bootstrapped;
    _bootstrapped = true;
    // Re-avalia a cada visita; garante que os grupos se refrescam ocasionalmente.
    final groupRanking = ref.watch(groupRankingProvider);

    final userRanking = _UserRankingSection(
      ranking: ranking,
      maxGoal: maxGoal,
      isFirstLoad: isFirstLoad,
      seenIds: _seenIds,
    );

    final groupRankingSection = _GroupRankingSection(
      groupRanking: groupRanking,
      isFirstLoad: isFirstLoad,
    );

    // Breakpoint real do dispositivo (não da largura de conteúdo, que é capada).
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    if (desktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: userRanking)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(child: groupRankingSection),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(groupSessionProvider(code).notifier).refresh();
            ref.invalidate(groupRankingProvider);
            await ref.read(groupRankingProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              const SizedBox(height: kToolbarHeight + 8),
              userRanking,
              const SizedBox(height: AppSpacing.lg),
              groupRankingSection,
            ],
          ),
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
          isLeader: place == 1,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(title,
          textAlign: TextAlign.center,
          style: context.tt.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _UserRankingSection extends StatelessWidget {
  final List ranking;
  final int maxGoal;
  final bool isFirstLoad;
  final Set<String> seenIds;

  const _UserRankingSection({
    required this.ranking,
    required this.maxGoal,
    required this.isFirstLoad,
    required this.seenIds,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _SectionHeader('Ranking'),
      if (ranking.isEmpty)
        const EmptyState(
          emoji: '🏆',
          title: 'Ranking vazio',
          subtitle: 'Adicione bebidas para ver o ranking.',
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _Podium(
              ranking: ranking.take(3).toList(), maxGoal: maxGoal),
        ),
    ];

    final offset = ranking.length >= 3 ? 3 : 0;
    for (var index = 0; index + offset < ranking.length; index++) {
      final actualIndex = index + offset;
      final p = ranking[actualIndex];
      final tier = TitleSystem.currentTier(p.totalDrinks as int, maxGoal);
      Widget row = Padding(
        padding: const EdgeInsets.only(
            top: AppSpacing.xs, left: AppSpacing.md, right: AppSpacing.md),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              MedalBadge(position: actualIndex + 1, size: 30),
              const SizedBox(width: AppSpacing.md),
              AppAvatar(
                  photoUrl: p.photoUrl as String?,
                  name: p.name as String,
                  radius: 20,
                  isCreator: p.isCreator,
                  isLeader: p.id == ranking.first.id),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name as String,
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
      );
      if (seenIds.add(p.id)) {
        row = row.animate().fadeIn(
              delay: isFirstLoad
                  ? Duration(
                      milliseconds:
                          actualIndex.clamp(0, 8) * AppMotion.staggerMs)
                  : Duration.zero,
            );
      }
      rows.add(row);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _GroupRankingSection extends StatelessWidget {
  final AsyncValue<List<GroupRank>> groupRanking;
  final bool isFirstLoad;

  const _GroupRankingSection({
    required this.groupRanking,
    required this.isFirstLoad,
  });

  @override
  Widget build(BuildContext context) {
    final header = const _SectionHeader('Ranking de grupos');
    return groupRanking.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        )],
      ),
      error: (e, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          EmptyState(
            emoji: '📡',
            title: 'Não foi possível carregar os grupos',
            subtitle: 'Puxe para atualizar ou tente novamente.',
          ),
        ],
      ),
      data: (ranks) {
        if (ranks.isNotEmpty && ranks.first.totalDrinks == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const EmptyState(
                emoji: '🥂',
                title: 'Nenhuma bebida ainda',
                subtitle: 'Os grupos aparecem aqui conforme registram bebidas.',
              ),
            ],
          );
        }
        final items = <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text('🥇', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(ranks.first.name,
                        overflow: TextOverflow.ellipsis,
                        style: context.tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Text('${ranks.first.totalDrinks}',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ];
        for (var i = 0; i < ranks.length; i++) {
          final rank = ranks[i];
          final medal = _groupMedal(i);
          Widget row = Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xs, left: AppSpacing.md, right: AppSpacing.md),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              child: Row(
                children: [
                  Text(medal, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.md),
                  Text(rank.coverEmoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(rank.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text('${rank.totalDrinks}',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
          if (isFirstLoad) {
            row = row.animate().fadeIn(
                delay: Duration(milliseconds: i.clamp(0, 8) * AppMotion.staggerMs));
          }
          items.add(row);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, ...items],
        );
      },
    );
  }

  String _groupMedal(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      default:
        return '🥉';
    }
  }
}

