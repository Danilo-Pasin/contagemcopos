/// Centralização das rotas do app.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String homeName = 'home';

  static const String create = '/criar';
  static const String createName = 'create';

  /// Página que pergunta o código antes de entrar num grupo.
  static const String enterGroup = '/entrar-grupo';
  static const String enterGroupName = 'enterGroup';

  // Path distinto do `group` evita conflito de rota no GoRouter.
  // O link compartilhável permanece /g/CODE (rota `group`).
  static String join(String code) => '/entrar/$code';
  static const String joinName = 'join';

  /// Login de usuário já cadastrado (nome + senha), acessível pela home.
  static const String login = '/entrar-login';
  static const String loginName = 'login';

  /// Rota fixa usada apenas no redirect de "/g" (sem código) para a home.
  static const String groupBase = '/g';
  static const String groupBaseName = 'groupBase';

  static String group(String code) => '/g/$code';
  static const String groupName = 'group';

  /// Rotas internas do grupo (relativas a /g/:code).
  static const homeSegment = 'inicio';
  static const feedSegment = 'feed';
  static const rankingSegment = 'ranking';
  static const statsSegment = 'stats';
  static const albumSegment = 'album';
  static const shareSegment = 'share';
  static const hallOfFameSegment = 'hall-of-fame';

  static String groupHome(String code) => '/g/$code/$homeSegment';
  static String groupFeed(String code) => '/g/$code/feed';
  static String groupRanking(String code) => '/g/$code/ranking';
  static String groupStats(String code) => '/g/$code/stats';
  static String groupAlbum(String code) => '/g/$code/album';
  // share/hall-of-fame são subrotas da branch Início (/g/:code/inicio/*).
  static String groupShare(String code) =>
      '/g/$code/$homeSegment/$shareSegment';
  static String groupHallOfFame(String code) =>
      '/g/$code/$homeSegment/$hallOfFameSegment';
}
