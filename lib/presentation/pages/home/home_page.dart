import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive_content.dart';
import '../../providers/identity_provider.dart';
import '../../providers/theme_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: ResponsiveContent(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40),
                          const Text(
                            'Contagem',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -.5,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                ref.read(themeModeProvider.notifier).toggle(),
                            icon: Icon(
                              Theme.of(context).brightness == Brightness.dark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C4DFF)
                                  .withValues(alpha: 0.5),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🍺', style: TextStyle(fontSize: 60)),
                        ),
                      )
                          .animate()
                          .scale(
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                              begin: const Offset(0.5, 0.5))
                          .shimmer(delay: 800.ms),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Copa das Bebidas',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Crie grupos, registre\nsuas bebidas e domine\no ranking 🏆',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(
                            begin: 0.2,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          ),
                      const Spacer(flex: 2),
                      // Stats pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FeaturePill(emoji: '🍻', label: 'Grupos ilimitados'),
                          const SizedBox(width: AppSpacing.md),
                          _FeaturePill(emoji: '⚡', label: 'Tempo real'),
                          const SizedBox(width: AppSpacing.md),
                          _FeaturePill(emoji: '🏆', label: 'Ranking ao vivo'),
                        ],
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: AppSpacing.xl),
                      // CTA buttons
                      PrimaryButton(
                        label: 'Criar Grupo',
                        icon: Icons.add_rounded,
                        onPressed: () => context.push(AppRoutes.create),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideY(begin: 0.3, duration: 500.ms),
                      const SizedBox(height: AppSpacing.md),
                      _CodeEntryCard()
                          .animate()
                          .fadeIn(delay: 700.ms)
                          .slideY(begin: 0.3, duration: 500.ms),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Digite um código para entrar em um grupo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (identity.knownGroups.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: TextButton.icon(
                            onPressed: () => context.push(
                                AppRoutes.join(identity.knownGroups.last)),
                            icon: const Icon(Icons.history, size: 18),
                            label: Text(
                              'Voltar para: ${identity.knownGroups.last}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String emoji;
  final String label;
  const _FeaturePill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          ],
        ),
    );
  }
}

class _CodeEntryCard extends StatefulWidget {
  const _CodeEntryCard();

  @override
  State<_CodeEntryCard> createState() => _CodeEntryCardState();
}

class _CodeEntryCardState extends State<_CodeEntryCard> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    context.push(AppRoutes.join(code));
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      color: Colors.white.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: TextField(
        controller: _codeCtrl,
        textCapitalization: TextCapitalization.characters,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 4,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'CÓDIGO DO GRUPO',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            onPressed: _submit,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
