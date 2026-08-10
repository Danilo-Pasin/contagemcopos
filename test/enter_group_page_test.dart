import 'package:contagem/core/router/app_routes.dart';
import 'package:contagem/presentation/pages/enter_group/enter_group_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('EnterGroupPage — botão voltar', () {
    Widget buildApp(String initial, Widget home) {
      final router = GoRouter(
        initialLocation: initial,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: AppRoutes.enterGroup,
            builder: (_, __) => const EnterGroupPage(),
          ),
        ],
      );
      return ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('exibe botão voltar e retorna para a home', (tester) async {
      await tester.pumpWidget(buildApp(AppRoutes.enterGroup, const Text('')));
      await tester.pumpAndSettle();

      expect(find.byType(EnterGroupPage), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });
  });
}