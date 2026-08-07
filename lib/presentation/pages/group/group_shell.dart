import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/group_session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass_card.dart';
import 'group_app_bar.dart';

/// Shell que envolve as telas internas do grupo com bottom navigation.
class GroupShell extends ConsumerWidget {
  final String code;
  final Widget child;
  const GroupShell({super.key, required this.code, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(groupSessionProvider(code));

    // Se não é membro (mas tem grupo), redireciona para o formulário de
    // entrada. Evita mostrar tela interna para quem ainda não entrou.
    if (session.hasGroup &&
        !session.isMember &&
        !session.loading &&
        session.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.join(code));
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentIndex = _currentIndex(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: session.hasGroup
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: GroupAppBar(code: code),
            )
          : null,
      body: session.loading
          ? const Center(child: CircularProgressIndicator())
          : session.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(session.error!,
                        textAlign: TextAlign.center,
                        style: context.tt.titleMedium),
                  ),
                )
              : child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed_rounded),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Estatísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: 'Álbum',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.contains(AppRoutes.feedSegment)) return 1;
    if (location.contains(AppRoutes.rankingSegment)) return 2;
    if (location.contains(AppRoutes.statsSegment)) return 3;
    if (location.contains(AppRoutes.albumSegment)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go(AppRoutes.group(code));
        break;
      case 1:
        context.go(AppRoutes.groupFeed(code));
        break;
      case 2:
        context.go(AppRoutes.groupRanking(code));
        break;
      case 3:
        context.go(AppRoutes.groupStats(code));
        break;
      case 4:
        context.go(AppRoutes.groupAlbum(code));
        break;
    }
  }
}
