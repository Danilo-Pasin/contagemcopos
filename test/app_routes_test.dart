import 'package:contagem/core/router/app_routes.dart';
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
      expect(AppRoutes.groupShare(code), '/g/AB72XC/share');
      expect(AppRoutes.groupHallOfFame(code), '/g/AB72XC/hall-of-fame');
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
}