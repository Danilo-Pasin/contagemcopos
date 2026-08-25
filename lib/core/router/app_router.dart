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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
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
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            GroupShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.group(':code'),
              name: AppRoutes.groupName,
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
          StatefulShellBranch(routes: [
            GoRoute(
              path: '${AppRoutes.group(':code')}/${AppRoutes.feedSegment}',
              builder: (_, __) => const FeedPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '${AppRoutes.group(':code')}/${AppRoutes.rankingSegment}',
              builder: (_, __) => const RankingPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '${AppRoutes.group(':code')}/${AppRoutes.statsSegment}',
              builder: (_, __) => const StatsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '${AppRoutes.group(':code')}/${AppRoutes.albumSegment}',
              builder: (_, __) => const AlbumPage(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Página não encontrada\n${state.error}')),
    ),
  );
});
