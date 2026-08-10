import 'package:cached_network_image/cached_network_image.dart';
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
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive_content.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));

    final feed = session.feed;

    return ResponsiveContent(
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
                  (context, index) => RepaintBoundary(
                    child: _FeedTile(item: feed[index])
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideY(begin: 0.08, duration: 350.ms),
                  ),
                  childCount: feed.length,
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
                  child: CachedNetworkImage(
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
