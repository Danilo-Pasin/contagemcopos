import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/album/album_page.dart';
import '../../presentation/pages/create_group/create_group_page.dart';
import '../../presentation/pages/enter_group/enter_group_page.dart';
import '../../presentation/pages/feed/feed_page.dart';
import '../../presentation/pages/group/group_home_page.dart';
import '../../presentation/pages/group/group_shell.dart';
import '../../presentation/pages/hall_of_fame/hall_of_fame_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/join_group/join_group_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/ranking/ranking_page.dart';
import '../../presentation/pages/share/share_page.dart';
import '../../presentation/pages/stats/stats_page.dart';
import 'app_routes.dart';

/// Redirects de nível superior do app (extraído para ser testável).
///
/// - `/g` (sem código) → home.
/// - `/g/CODE` exato (link compartilhável/deep link) → `/g/CODE/inicio`.
String? appRedirect(Uri uri) {
  final path = uri.path;
  if (path == AppRoutes.groupBase) return AppRoutes.home;
  if (RegExp(r'^/g/[A-Za-z0-9]+$').hasMatch(path)) {
    return '$path/${AppRoutes.homeSegment}';
  }
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (_, state) => appRedirect(state.uri),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.create,
        name: AppRoutes.createName,
        builder: (_, __) => const CreateGroupPage(),
      ),
      GoRoute(
        path: AppRoutes.enterGroup,
        name: AppRoutes.enterGroupName,
        builder: (_, __) => const EnterGroupPage(),
      ),
      GoRoute(
        path: AppRoutes.join(':code'),
        name: AppRoutes.joinName,
        builder: (_, state) =>
            JoinGroupPage(code: state.pathParameters['code']!),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (_, state) => const LoginGroupPage(),
      ),
      // Grupo com bottom navigation persistente (estado vivo entre abas).
      // A ordem dos branches deve casar com os destinos da NavigationBar
      // (GroupShell): Início, Feed, Ranking, Estatísticas, Álbum.
      //
      // ESTRUTURA: o StatefulShellRoute fica ANINHADO sob /g/:code e as abas
      // são caminhos RELATIVOS ('inicio', 'feed', …). Assim cada branch tem
      // rota default SEM parâmetro (exigência da assertion do go_router
      // 14.8.1 em debug) e o goBranch resolve o :code do pai automaticamente
      // ao visitar a branch pela primeira vez. O link compartilhável /g/CODE
      // é redirecionado para /g/CODE/inicio pelo redirect acima.
      GoRoute(
        path: AppRoutes.group(':code'),
        name: AppRoutes.groupName,
        // Nunca renderiza: o redirect manda /g/CODE para /g/CODE/inicio,
        // que cai no shell aninhado abaixo.
        builder: (_, __) => const SizedBox.shrink(),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, navigationShell) =>
                GroupShell(navigationShell: navigationShell),
            branches: [
              // Branch 0 — Início (/g/:code/inicio) + subrotas share/hall.
              StatefulShellBranch(routes: [
                GoRoute(
                  path: AppRoutes.homeSegment,
                  builder: (_, __) => const GroupHomePage(),
                  routes: [
                    GoRoute(
                      path: AppRoutes.shareSegment,
                      builder: (_, __) => const SharePage(),
                    ),
                    GoRoute(
                      path: AppRoutes.hallOfFameSegment,
                      builder: (_, state) => HallOfFamePage(
                        code: state.pathParameters['code']!,
                      ),
                    ),
                  ],
                ),
              ]),
              // Branch 1 — Feed (/g/:code/feed).
              StatefulShellBranch(routes: [
                GoRoute(
                  path: AppRoutes.feedSegment,
                  builder: (_, __) => const FeedPage(),
                ),
              ]),
              // Branch 2 — Ranking (/g/:code/ranking).
              StatefulShellBranch(routes: [
                GoRoute(
                  path: AppRoutes.rankingSegment,
                  builder: (_, __) => const RankingPage(),
                ),
              ]),
              // Branch 3 — Estatísticas (/g/:code/stats).
              StatefulShellBranch(routes: [
                GoRoute(
                  path: AppRoutes.statsSegment,
                  builder: (_, state) =>
                      StatsPage(code: state.pathParameters['code']!),
                ),
              ]),
              // Branch 4 — Álbum (/g/:code/album).
              StatefulShellBranch(routes: [
                GoRoute(
                  path: AppRoutes.albumSegment,
                  builder: (_, __) => const AlbumPage(),
                ),
              ]),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Página não encontrada\n${state.error}')),
    ),
  );
});
