import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/group_session_provider.dart';
import '../../widgets/glass_card.dart';
import 'group_app_bar.dart';

/// Shell persistente das telas internas do grupo com bottom navigation.
/// Recebe um [StatefulNavigationShell] para que as abas mantenham estado
/// vivo (IndexedStack) e o provider da sessão sobreviva às transições.
class GroupShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const GroupShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = _extractCode(context);

    // Fallback: /g sem código (o redirect do router já manda para a home;
    // aqui garantimos que nunca fique em spinner infinito).
    if (code.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.home);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              : navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
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

  String _extractCode(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final match = RegExp(r'/g/([A-Z0-9]+)').firstMatch(uri);
    return match?.group(1) ?? '';
  }
}
