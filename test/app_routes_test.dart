import 'package:contagem/core/router/app_routes.dart';
import 'package:contagem/core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes — regressão do bug P0 (rotas join × group)', () {
    test('join e group devem ter paths distintos (evita loop infinito)', () {
      const code = 'AB72XC';
      expect(AppRoutes.join(code), isNot(AppRoutes.group(code)));
    });

    test('group mantém o link compartilhável em /g/:code', () {
      const code = 'AB72XC';
      expect(AppRoutes.group(code), '/g/AB72XC');
    });

    test('join usa path próprio /entrar/:code', () {
      const code = 'AB72XC';
      expect(AppRoutes.join(code), '/entrar/AB72XC');
    });

    test('strings de name de rota continuam distintas', () {
      expect(AppRoutes.joinName, isNot(AppRoutes.groupName));
    });

    test('rotas internas do grupo são complementares à rota group', () {
      const code = 'AB72XC';
      expect(AppRoutes.groupFeed(code), '/g/AB72XC/feed');
      expect(AppRoutes.groupRanking(code), '/g/AB72XC/ranking');
      expect(AppRoutes.groupStats(code), '/g/AB72XC/stats');
      expect(AppRoutes.groupAlbum(code), '/g/AB72XC/album');
      expect(AppRoutes.groupShare(code), '/g/AB72XC/inicio/share');
      expect(AppRoutes.groupHallOfFame(code), '/g/AB72XC/inicio/hall-of-fame');
    });
  });

  group('AppRoutes — rotas top-level', () {
    test('paths/nomes de home, create, enterGroup e login', () {
      expect(AppRoutes.home, '/');
      expect(AppRoutes.create, '/criar');
      expect(AppRoutes.enterGroup, '/entrar-grupo');
      expect(AppRoutes.login, '/entrar-login');
      for (final name in [
        AppRoutes.homeName,
        AppRoutes.createName,
        AppRoutes.enterGroupName,
        AppRoutes.loginName,
      ]) {
        expect(name, isNotEmpty);
      }
    });

    test('loginWithCode preenche o código via query param', () {
      expect(AppRoutes.loginWithCode('AB72XC'), '/entrar-login?code=AB72XC');
    });

    test('nomes de rota são únicos entre si', () {
      final names = {
        AppRoutes.homeName,
        AppRoutes.createName,
        AppRoutes.enterGroupName,
        AppRoutes.loginName,
        AppRoutes.joinName,
        AppRoutes.groupName,
      };
      expect(names.length, 6);
    });
  });

  group('AppRoutes — segmentos internos do grupo', () {
    test('path interno montado usa a constante de segmento de cada rota', () {
      expect(AppRoutes.group(AppRoutes.feedSegment),
          '/g/${AppRoutes.feedSegment}');
      expect(AppRoutes.group(AppRoutes.rankingSegment),
          '/g/${AppRoutes.rankingSegment}');
      expect(AppRoutes.group(AppRoutes.statsSegment),
          '/g/${AppRoutes.statsSegment}');
      expect(AppRoutes.group(AppRoutes.albumSegment),
          '/g/${AppRoutes.albumSegment}');
      expect(AppRoutes.group(AppRoutes.shareSegment),
          '/g/${AppRoutes.shareSegment}');
      expect(AppRoutes.group(AppRoutes.hallOfFameSegment),
          '/g/${AppRoutes.hallOfFameSegment}');
    });

    test('segmentos têm valores esperados (evita typo hardcoded)', () {
      expect(AppRoutes.feedSegment, 'feed');
      expect(AppRoutes.rankingSegment, 'ranking');
      expect(AppRoutes.statsSegment, 'stats');
      expect(AppRoutes.albumSegment, 'album');
      expect(AppRoutes.shareSegment, 'share');
      expect(AppRoutes.hallOfFameSegment, 'hall-of-fame');
    });
  });

  group('AppRoutes — branches do StatefulShellRoute (Fase A)', () {
    test('branch defaults relativos e SEM parâmetro (assertion do go_router)',
        () {
      // Cada branch é filha de /g/:code; os defaults precisam ser rotas
      // relativas sem parâmetro, senão a assertion do go_router 14.8.1
      // derruba o app em debug.
      for (final segment in [
        AppRoutes.homeSegment,
        AppRoutes.feedSegment,
        AppRoutes.rankingSegment,
        AppRoutes.statsSegment,
        AppRoutes.albumSegment,
      ]) {
        expect(segment, isNot(contains(':')));
        expect(segment, isNotEmpty);
        expect(segment, isNot(startsWith('/')));
      }
      expect(AppRoutes.homeSegment, 'inicio');
    });

    test('5 abas na ordem da NavigationBar (/g/:code/segment)', () {
      // Ordem dos destinos: Início, Feed, Ranking, Estatísticas, Álbum.
      final paths = [
        '${AppRoutes.groupBase}/:code/${AppRoutes.homeSegment}',
        '${AppRoutes.groupBase}/:code/${AppRoutes.feedSegment}',
        '${AppRoutes.groupBase}/:code/${AppRoutes.rankingSegment}',
        '${AppRoutes.groupBase}/:code/${AppRoutes.statsSegment}',
        '${AppRoutes.groupBase}/:code/${AppRoutes.albumSegment}',
      ];
      expect(paths[0], '/g/:code/inicio');
      expect(paths[1], endsWith('/feed'));
      expect(paths[2], endsWith('/ranking'));
      expect(paths[3], endsWith('/stats'));
      expect(paths[4], endsWith('/album'));
    });

    test('share e hall-of-fame são subrotas da branch Início', () {
      expect(AppRoutes.groupShare(':code'), '/g/:code/inicio/share');
      expect(AppRoutes.groupHallOfFame(':code'),
          '/g/:code/inicio/hall-of-fame');
    });

    test('REGRESSÃO: GoRouter instancia sem "branch cannot be parameterized"',
        () {
      // Construir o GoRouter em modo debug dispara
      // _debugCheckStatefulShellBranchDefaultLocations se QUALQUER branch
      // tiver rota com parâmetro como default. Era exatamente o crash visto
      // no flutter run -d chrome.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(() => container.read(appRouterProvider), returnsNormally);
    });

    group('appRedirect (redirects de nível superior)', () {
      test('/g sem código → home', () {
        expect(appRedirect(Uri.parse('/g')), '/');
      });
      test('/g/CODE → /g/CODE/inicio (link compartilhável)', () {
        expect(appRedirect(Uri.parse('/g/AB72XC')), '/g/AB72XC/inicio');
      });
      test('paths legados de share/hall-of-fame são redirecionados', () {
        expect(appRedirect(Uri.parse('/g/AB72XC/share')),
            '/g/AB72XC/inicio/share');
        expect(appRedirect(Uri.parse('/g/AB72XC/hall-of-fame')),
            '/g/AB72XC/inicio/hall-of-fame');
      });
      test('abas internas NÃO são redirecionadas', () {
        expect(appRedirect(Uri.parse('/g/AB72XC/feed')), isNull);
        expect(appRedirect(Uri.parse('/g/AB72XC/stats')), isNull);
        expect(appRedirect(Uri.parse('/g/AB72XC/inicio/share')), isNull);
        expect(appRedirect(Uri.parse('/g/AB72XC/inicio/hall-of-fame')),
            isNull);
      });
      test('outras rotas não são afetadas', () {
        expect(appRedirect(Uri.parse('/')), isNull);
        expect(appRedirect(Uri.parse('/criar')), isNull);
        expect(appRedirect(Uri.parse('/entrar/AB72XC')), isNull);
        expect(appRedirect(Uri.parse('/g/AB72XC/outro')), isNull);
      });
    });
  });
}