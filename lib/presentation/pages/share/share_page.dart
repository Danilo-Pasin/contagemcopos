import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../providers/group_session_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/medal_badge.dart';
import '../../widgets/responsive_content.dart';

class SharePage extends ConsumerWidget {
  const SharePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = _extractCode(context);
    final session = ref.watch(groupSessionProvider(code));
    final group = session.group;
    if (group == null) return const SizedBox();

    final ranking = session.ranking.take(5).toList();
    final baseUrl = ref.watch(publicBaseUrlProvider);
    final link = '$baseUrl/g/${group.code}';

    return Scaffold(
      appBar: AppBar(title: const Text('Compartilhar')),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card final do ranking (Copômetro)
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 40)),
                    Text('COPÔMETRO',
                        style: context.tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900, letterSpacing: 2)),
                    Text(group.name,
                        style: context.tt.titleMedium
                            ?.copyWith(color: context.cs.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.lg),
                    if (ranking.isNotEmpty) ...[
                      for (int i = 0; i < ranking.length; i++)
                        _WinnerRow(
                          position: i + 1,
                          name: ranking[i].name,
                          drinks: ranking[i].totalDrinks,
                          photoUrl: ranking[i].photoUrl,
                          isChampion: i == 0,
                        ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('Ainda sem vencedores'),
                      ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: AppSpacing.lg),
              // QR Code
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text('Escaneie para entrar',
                        style: context.tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: AppMotion.fast).slideY(
                  begin: 0.1, duration: AppMotion.normal),
              const SizedBox(height: AppSpacing.lg),
              // Código do grupo
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Text('🔑', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Código do grupo',
                              style: context.tt.bodySmall),
                          Text(group.code,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: group.code));
                        context.showSnack('Código copiado!');
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(
                  delay: const Duration(milliseconds: 80)),
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Text('🔗', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(link,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.tt.bodyMedium),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        context.showSnack('Link copiado!');
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(
                  delay: const Duration(milliseconds: 120)),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
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

class _WinnerRow extends StatelessWidget {
  final int position;
  final String name;
  final int drinks;
  final String? photoUrl;
  final bool isChampion;
  const _WinnerRow({
    required this.position,
    required this.name,
    required this.drinks,
    this.photoUrl,
    this.isChampion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          MedalBadge(position: position, size: 32),
          const SizedBox(width: AppSpacing.md),
          AppAvatar(photoUrl: photoUrl, name: name, radius: 18),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: isChampion ? 18 : 15,
                fontWeight: isChampion ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text('$drinks',
              style: TextStyle(
                  fontSize: isChampion ? 22 : 18,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
