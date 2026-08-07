import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/title_system.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_time_x.dart';
import '../../providers/core_providers.dart';
import '../../providers/group_session_provider.dart';
import '../../providers/identity_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/medal_badge.dart';
import '../../widgets/responsive_content.dart';

class GroupHomePage extends ConsumerStatefulWidget {
  const GroupHomePage({super.key});

  @override
  ConsumerState<GroupHomePage> createState() => _GroupHomePageState();
}

class _GroupHomePageState extends ConsumerState<GroupHomePage> {
  late ConfettiController _confetti;
  String? _previousLeaderId;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _mounted = true;
  }

  @override
  void dispose() {
    _mounted = false;
    _confetti.dispose();
    super.dispose();
  }

  void _watchLeaderChange(WidgetRef ref, String code) {
    final session = ref.read(groupSessionProvider(code));
    final leader = session.leader;
    if (leader != null) {
      if (_previousLeaderId != null &&
          _previousLeaderId != leader.id &&
          leader.id == session.me?.id &&
          leader.totalDrinks > 0) {
        _confetti.play();
      }
      _previousLeaderId = leader.id;
    }
  }

  Future<void> _addDrink(String code) async {
    await ref.read(groupSessionProvider(code).notifier).addDrink();
  }

  Future<void> _addPhoto(String code) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file == null) return;
      final identity = ref.read(identityProvider);
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadDrinkPhoto(identity.anonId!, file);
      await ref.read(groupSessionProvider(code).notifier).addPhoto(url);
      if (_mounted) context.showSnack('Foto adicionada ao álbum! 📸');
    } catch (e) {
      if (_mounted) context.showSnack('Erro: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));
    _watchLeaderChange(ref, code);

    if (!session.isMember) {
      return const Center(child: Text('Entrando no grupo...'));
    }

    final me = session.me!;
    final maxGoal = session.group!.maxGoal;
    final tier = TitleSystem.currentTier(me.totalDrinks, maxGoal);
    final nextTier = TitleSystem.nextTier(me.totalDrinks, maxGoal);
    final progress = TitleSystem.progressToNext(me.totalDrinks, maxGoal);

    return Stack(
      children: [
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.1,
          numberOfParticles: 25,
          gravity: 0.2,
          shouldLoop: false,
          colors: const [
            Color(0xFF1FB45C),
            Color(0xFF48E37F),
            Color(0xFFFFB300),
            Color(0xFF4CAF50),
          ],
        ),
        ResponsiveContent(
          child: RefreshIndicator(
          onRefresh: () =>
              ref.read(groupSessionProvider(code).notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 8)),
              // Resumo do grupo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: _GroupSummary(session: session),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              // Card do usuário atual (destaque)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AppAvatar(
                              photoUrl: me.photoUrl,
                              name: me.name,
                              radius: 30,
                              isCreator: me.isCreator,
                              hasGradientRing: me.id == session.leader?.id,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(me.name,
                                      style: context.tt.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  TitleBadge(
                                      emoji: tier.emoji, name: tier.name),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${me.totalDrinks}',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text('bebidas',
                                    style: context.tt.bodySmall),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Barra de progresso para próximo título
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                context.cs.surfaceContainerHighest,
                          ),
                        ),
                        if (nextTier != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Faltam ${nextTier.requiredDrinks(maxGoal) - me.totalDrinks} '
                              'para ${nextTier.emoji} ${nextTier.name}',
                              style: context.tt.bodySmall?.copyWith(
                                  color: context.cs.onSurfaceVariant),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        // Botão +1 BEBIDA gigante
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: session.group!.isActive
                                ? () => _addDrink(code)
                                : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md + 2),
                              backgroundColor: const Color(0xFF1FB45C),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            icon: const Icon(Icons.local_bar_rounded,
                                size: 26),
                            label: const Text(
                              '+1 BEBIDA',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: session.group!.isActive
                                ? () => _addPhoto(code)
                                : null,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Adicionar Foto'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              // Lista de participantes
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text('Participantes (${session.ranking.length})',
                          style: context.tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (session.leader != null)
                        Text(
                          '👑 ${session.leader!.name.split(' ').first}',
                          style: context.tt.bodySmall
                              ?.copyWith(color: context.cs.primary),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = session.ranking[index];
                    final isMe = p.id == me.id;
                    if (isMe) return const SizedBox.shrink(); // já no topo
                    final pTier =
                        TitleSystem.currentTier(p.totalDrinks, maxGoal);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 6),
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            MedalBadge(position: p.position ?? index + 1),
                            const SizedBox(width: AppSpacing.md),
                            AppAvatar(
                                photoUrl: p.photoUrl,
                                name: p.name,
                                radius: 22,
                                isCreator: p.isCreator),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700)),
                                  TitleBadge(
                                      emoji: pTier.emoji,
                                      name: pTier.name,
                                      compact: true),
                                ],
                              ),
                            ),
                            Text(
                              '${p.totalDrinks}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (index * 40).ms)
                        .slideY(begin: 0.05, duration: 300.ms);
                  },
                  childCount: session.ranking.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
          ),
      ],
    );
  }

  String _extractCode(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final match = RegExp(r'/g/([A-Z0-9]+)').firstMatch(uri);
    return match?.group(1) ?? '';
  }
}

class _GroupSummary extends StatelessWidget {
  final GroupSessionState session;
  const _GroupSummary({required this.session});

  @override
  Widget build(BuildContext context) {
    final days = DateTimeX.daysLeft(session.group!.endDate);
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
              child: _StatCell(
                  value: '${session.totalGroupDrinks}', label: 'bebidas')),
          Container(
              width: 1,
              height: 32,
              color: context.cs.outlineVariant.withValues(alpha: 0.5)),
          Expanded(
              child: _StatCell(
                  value: '${session.ranking.length}', label: 'membros')),
          Container(
              width: 1,
              height: 32,
              color: context.cs.outlineVariant.withValues(alpha: 0.5)),
          Expanded(
              child: _StatCell(
                  value: session.group!.isActive ? '$days' : '0',
                  label: 'dias restantes')),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: context.tt.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        Text(label,
            style:
                context.tt.bodySmall?.copyWith(color: context.cs.onSurfaceVariant)),
      ],
    );
  }
}

// import necessário para GoRouterState

