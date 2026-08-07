import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/title_system.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_time_x.dart';
import '../../providers/group_session_provider.dart';
import '../../providers/identity_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/medal_badge.dart';

/// AppBar com glassmorphism mostrando nome do grupo, dias restantes e ações.
class GroupAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String code;
  const GroupAppBar({super.key, required this.code});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(groupSessionProvider(code));

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(AppRoutes.home),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.groupShare(code)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(session.group?.coverEmoji ?? '🍻',
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            session.group?.name ?? 'Grupo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (session.group != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: session.group!.isActive
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : context.cs.errorContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              session.group!.isActive
                                  ? DateTimeX.hoursLeftLabel(
                                      session.group!.endDate)
                                  : 'Encerrado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: session.group!.isActive
                                    ? Colors.green
                                    : context.cs.onErrorContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    context.push(AppRoutes.groupShare(code));
                    break;
                  case 'theme':
                    ref.read(themeModeProvider.notifier).toggle();
                    break;
                  case 'home':
                    context.go(AppRoutes.home);
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Compartilhar')),
                PopupMenuItem(value: 'theme', child: Text('Alternar tema')),
                PopupMenuItem(value: 'home', child: Text('Sair do grupo')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
