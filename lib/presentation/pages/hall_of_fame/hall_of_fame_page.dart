import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_time_x.dart';
import '../../providers/core_providers.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive_content.dart';

class HallOfFamePage extends ConsumerStatefulWidget {
  final String code;
  const HallOfFamePage({super.key, required this.code});

  @override
  ConsumerState<HallOfFamePage> createState() => _HallOfFamePageState();
}

class _HallOfFamePageState extends ConsumerState<HallOfFamePage> {
  List<Map<String, dynamic>> _champions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(achievementRepositoryProvider);
      final data = await repo.hallOfFame();
      setState(() {
        _champions = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hall da Fama')),
      body: SafeArea(
        child: ResponsiveContent(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _champions.isEmpty
                ? const EmptyState(
                    emoji: '🏛️',
                    title: 'Nenhum campeão ainda',
                    subtitle: 'Quando as competições terminarem, '
                        'os campeões aparecem aqui para a eternidade.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _champions.length,
                    itemBuilder: (context, index) {
                      final c = _champions[index];
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: AppSpacing.md),
                            AppAvatar(
                              photoUrl: c['champion_photo'],
                              name: c['champion_name'] ?? '?',
                              radius: 24,
                              hasGradientRing: true,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['champion_name'] ?? '',
                                      style: context.tt.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  Text(c['group_name'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.tt.bodySmall),
                                  Text(
                                    DateTimeX.format(
                                        DateTime.parse(c['end_date']),
                                        pattern: 'MMM/yyyy'),
                                    style: context.tt.bodySmall?.copyWith(
                                        color: context.cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${c['total_drinks']}',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900)),
                                Text('bebidas',
                                    style: context.tt.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(
                                  milliseconds:
                                  index * AppMotion.staggerMs))
                          .slideX(begin: 0.05, duration: AppMotion.entrance);
                    },
                  ),
        ),
      ),
    );
  }
}
