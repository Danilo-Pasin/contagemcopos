import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/album/album_page.dart';
import '../../presentation/pages/create_group/create_group_page.dart';
import '../../presentation/pages/feed/feed_page.dart';
import '../../presentation/pages/group/group_home_page.dart';
import '../../presentation/pages/group/group_shell.dart';
import '../../presentation/pages/hall_of_fame/hall_of_fame_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/join_group/join_group_page.dart';
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
        path: AppRoutes.join(':code'),
        name: AppRoutes.joinName,
        builder: (_, state) =>
            JoinGroupPage(code: state.pathParameters['code']!),
      ),
      // Grupo com bottom navigation (shell)
      ShellRoute(
        builder: (_, __, child) => child,
        routes: [
          GoRoute(
            path: AppRoutes.group(':code'),
            name: AppRoutes.groupName,
            builder: (_, state) => GroupShell(
              code: state.pathParameters['code']!,
              child: const GroupHomePage(),
            ),
            routes: [
              GoRoute(
                path: 'feed',
                builder: (_, state) => GroupShell(
                  code: state.pathParameters['code']!,
                  child: const FeedPage(),
                ),
              ),
              GoRoute(
                path: 'ranking',
                builder: (_, state) => GroupShell(
                  code: state.pathParameters['code']!,
                  child: const RankingPage(),
                ),
              ),
              GoRoute(
                path: 'stats',
                builder: (_, state) => GroupShell(
                  code: state.pathParameters['code']!,
                  child: const StatsPage(),
                ),
              ),
              GoRoute(
                path: 'album',
                builder: (_, state) => GroupShell(
                  code: state.pathParameters['code']!,
                  child: const AlbumPage(),
                ),
              ),
              GoRoute(
                path: 'share',
                builder: (_, state) => GroupShell(
                  code: state.pathParameters['code']!,
                  child: const SharePage(),
                ),
              ),
              GoRoute(
                path: 'hall-of-fame',
                builder: (_, state) => HallOfFamePage(
                  code: state.pathParameters['code']!,
                ),
              ),
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
