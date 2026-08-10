import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:postgrest/postgrest.dart';
import '../../../core/constants/drink_types.dart';
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
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _mounted = true;
    // A cada 30s recalcula o countdown; só redesenha se o rótulo mudou.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _ticker?.cancel();
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
    final res = await showModalBottomSheet<_DrinkPickResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DrinkTypeSheet(),
    );
    if (!mounted || res == null) return;

    // A foto é obrigatória para registrar a bebida.
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (!mounted || source == null) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source == _PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      // Cancelou a foto -> não registra a bebida.
      if (file == null) return;

      final identity = ref.read(identityProvider);
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadDrinkPhoto(identity.anonId!, file);
      await ref
          .read(groupSessionProvider(code).notifier)
          .addDrinkWithPhoto(drinkType: res.type?.id, photoUrl: url);
      if (_mounted) context.showSnack('Bebida registrada! 🍻');
    } on PostgrestException catch (e) {
      if (_mounted) {
        context.showSnack(
          e.code == '42501'
              ? 'A competição já encerrou.'
              : 'Não foi possível registrar a bebida.',
          isError: true,
        );
      }
      debugPrint('[GroupHome] falha ao adicionar bebida: $e');
    } catch (e) {
      if (_mounted) {
        context.showSnack(
          'Não foi possível registrar a bebida. Tente novamente.',
          isError: true,
        );
      }
      debugPrint('[GroupHome] falha ao adicionar bebida: $e');
    }
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
      if (_mounted) {
        context.showSnack(
          'Não foi possível adicionar foto: a competição já encerrou.',
          isError: true,
        );
      }
      debugPrint('[GroupHome] falha ao adicionar foto: $e');
    }
  }

  /// Troca a foto de perfil tocando no avatar do mini-dashboard.
  Future<void> _changeProfilePhoto(String code) async {
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (!mounted || source == null) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source == _PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file == null) return;

      final identity = ref.read(identityProvider);
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadAvatar(identity.anonId!, file);
      await ref
          .read(groupSessionProvider(code).notifier)
          .updateProfilePhoto(url);
      // Persiste a foto também no perfil local (nome/account preservados).
      final me = ref.read(groupSessionProvider(code)).me;
      await ref.read(identityProvider.notifier).saveProfile(
            name: me?.name ?? identity.savedName,
            photoUrl: url,
          );
      if (_mounted) context.showSnack('Foto de perfil atualizada! 📸');
    } catch (e) {
      if (_mounted) {
        context.showSnack(
          'Não foi possível atualizar a foto de perfil.',
          isError: true,
        );
      }
      debugPrint('[GroupHome] falha ao trocar foto de perfil: $e');
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
    // Desafio encerrado quando o status é 'ended' OU o prazo já passou:
    // a partir daí só leitura (sem +1 bebida / foto).
    final running = session.group!.acceptsEntries();

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
                            GestureDetector(
                              onTap: () => _changeProfilePhoto(code),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AppAvatar(
                                    photoUrl: me.photoUrl,
                                    name: me.name,
                                    radius: 30,
                                    isCreator: me.isCreator,
                                    isLeader: me.id == session.leader?.id,
                                    hasGradientRing: me.id == session.leader?.id,
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: context.cs.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                            onPressed: running
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
                            onPressed: running
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
                                isCreator: p.isCreator,
                                isLeader: p.id == session.leader?.id),
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
    final stat = session.group!.isActive
        ? DateTimeX.timeLeftStat(session.group!.endDate)
        : (value: 0, label: 'encerrado');
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
                  value: '${stat.value}', label: stat.label)),
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
/// Resultado do popup de tipo de bebida.
class _DrinkPickResult {
  final DrinkTypeDef? type;
  const _DrinkPickResult(this.type);
}

/// Origem da foto obrigatória da bebida.
enum _PhotoSource { camera, gallery }

/// Popup de origem da foto obrigatória da bebida.
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: context.cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('📸 Foto da bebida',
                      style: context.tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Obrigatória para registrar a bebida.',
                style: context.tt.bodySmall
                    ?.copyWith(color: context.cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _PhotoSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tirar foto agora'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, _PhotoSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Escolher da galeria'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popup opcional exibido ao tocar em "+1 BEBIDA".
///
/// Permite marcar o tipo da bebida (opcional). Se o usuário tocar em
/// "Só contar", o resultado é um tipo nulo — a bebida ainda é registrada,
/// mas sem tipo. Fechar o sheet (arrastar/fora) cancela a adição.
class _DrinkTypeSheet extends StatelessWidget {
  const _DrinkTypeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: context.cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🍺 O que você vai beber?',
                      style: context.tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Opcional — ajuda a enriquecer suas estatísticas.',
                style: context.tt.bodySmall
                    ?.copyWith(color: context.cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: kDrinkTypes.map((t) {
                  return ChoiceChip(
                    selected: false,
                    avatar: Text(t.emoji),
                    label: Text(t.label),
                    onSelected: (_) =>
                        Navigator.pop(context, _DrinkPickResult(t)),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, const _DrinkPickResult(null)),
                  icon: const Icon(Icons.remove),
                  label: const Text('Só contar (sem tipo)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
