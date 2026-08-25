import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/responsive_content.dart';
import '../../providers/identity_provider.dart';
import '../../providers/theme_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0E2A1A);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.hero : AppGradients.heroLight,
        ),
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
                          Text(
                            'Contagem',
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -.5,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                ref.read(themeModeProvider.notifier).toggle(),
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: fg.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                      // Logo
                      const AppLogo()
                          .animate()
                          .scale(
                              duration: Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                              begin: const Offset(0.5, 0.5))
                          .shimmer(delay: AppMotion.fast),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Copa das Bebidas',
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: AppMotion.fast),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Crie grupos, registre\nsuas bebidas e domine\no ranking 🏆',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: fg,
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: const Duration(milliseconds: 80)).slideY(
                            begin: 0.2,
                            duration: AppMotion.normal,
                            curve: Curves.easeOut,
                          ),
                      const Spacer(flex: 2),
                      // Stats pills
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _FeaturePill(emoji: '🍻', label: 'Grupos ilimitados'),
                          _FeaturePill(emoji: '⚡', label: 'Tempo real'),
                          _FeaturePill(emoji: '🏆', label: 'Ranking ao vivo'),
                        ],
                      ).animate().fadeIn(delay: const Duration(milliseconds: 120)),
                      const SizedBox(height: AppSpacing.xl),
                      // CTA buttons
                      PrimaryButton(
                        label: 'Criar Grupo',
                        icon: Icons.add_rounded,
                        onPressed: () => context.push(AppRoutes.create),
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 140),
                              duration: AppMotion.fast)
                          .slideY(begin: 0.3, duration: AppMotion.normal),
                      const SizedBox(height: AppSpacing.md),
                      // Definir código do grupo a entrar (Entrar em um grupo)
                      SecondaryButton(
                        label: 'Entrar em um grupo',
                        icon: Icons.group_add_rounded,
                        onPressed: () => context.push(AppRoutes.enterGroup),
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 170),
                              duration: AppMotion.fast)
                          .slideY(begin: 0.3, duration: AppMotion.normal),
                      const SizedBox(height: AppSpacing.md),
                      // Já estou num grupo (código + nome + senha)
                      SecondaryButton(
                        label: 'Já estou em um grupo',
                        icon: Icons.key_rounded,
                        onPressed: () => context.push(AppRoutes.login),
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 200),
                              duration: AppMotion.fast)
                          .slideY(begin: 0.3, duration: AppMotion.normal),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0E2A1A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          ],
        ),
    );
  }
}
