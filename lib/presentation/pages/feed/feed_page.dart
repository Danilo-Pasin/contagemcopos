import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../domain/entities/activity_item.dart';
import '../../providers/group_session_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive_content.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  /// Itens já exibidos: garante que a animação de entrada rode apenas
  /// na primeira carga (com stagger curto) e em itens realmente novos —
  /// nunca a cada rebuild de realtime/polling.
  final Set<String> _seenIds = {};
  bool _bootstrapped = false;

  @override
  Widget build(BuildContext context) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));

    final feed = session.feed;
    final isFirstLoad = !_bootstrapped;

    final result = ResponsiveContent(
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(groupSessionProvider(code).notifier).refresh(),
        child: CustomScrollView(
          slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 8)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text('Feed',
                    style: context.tt.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          if (feed.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                emoji: '📭',
                title: 'Nada por aqui ainda',
                subtitle: 'As atividades do grupo aparecem aqui em tempo real.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = feed[index];
                    final isNew = _seenIds.add(item.id);
                    Widget tile = _FeedTile(item: item);
                    if (isNew) {
                      tile = tile
                          .animate()
                          .fadeIn(
                            delay: isFirstLoad
                                ? Duration(
                                    milliseconds: index.clamp(0, 8) *
                                        AppMotion.staggerMs)
                                : Duration.zero,
                          )
                          .slideY(begin: 0.08, duration: AppMotion.entrance);
                    }
                    return RepaintBoundary(child: tile);
                  },
                  childCount: feed.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
      ),
    );

    // A partir do próximo build, só itens novos são animados.
    _bootstrapped = true;
    return result;
  }

  String _extractCode(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final match = RegExp(r'/g/([A-Z0-9]+)').firstMatch(uri);
    return match?.group(1) ?? '';
  }
}

class _FeedTile extends StatelessWidget {
  final ActivityItem item;
  const _FeedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isPhoto = item.type == ActivityType.photoAdded && item.photoUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  photoUrl: item.participantPhoto,
                  name: item.participantName ?? '?',
                  radius: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: context.tt.bodyMedium,
                      children: [
                        TextSpan(
                          text: item.participantName ?? 'Alguém',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' ${_actionLabel(item)}',
                          style: TextStyle(
                              color: context.cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                if (item.type == ActivityType.drinkAdded)
                  const Text('🍺', style: TextStyle(fontSize: 20)),
              ],
            ),
            if (isPhoto) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: AppNetworkImage(
                    imageUrl: item.photoUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 640,
                    placeholder: (_, __) => Container(
                      color: context.cs.surfaceContainerHighest,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateTimeX.timeAgo(item.createdAt),
              style: context.tt.bodySmall
                  ?.copyWith(color: context.cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _actionLabel(ActivityItem item) {
    switch (item.type) {
      case ActivityType.drinkAdded:
        return 'adicionou uma bebida';
      case ActivityType.photoAdded:
        return 'adicionou uma foto';
      case ActivityType.memberJoined:
        return 'entrou no grupo';
      case ActivityType.groupCreated:
        return 'criou o grupo';
      case ActivityType.groupEnded:
        return 'competição encerrada';
      case ActivityType.titleChanged:
        return 'mudou de título';
      case ActivityType.achievementUnlocked:
        return 'desbloqueou uma conquista';
      case ActivityType.unknown:
        return 'fez uma atividade';
    }
  }
}
