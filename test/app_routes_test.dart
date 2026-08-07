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
    });
  });
}