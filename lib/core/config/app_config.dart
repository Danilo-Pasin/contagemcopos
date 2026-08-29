/// Identidade de marca do app (centralizada para fácil renomeação).
class AppBrand {
  const AppBrand._();

  /// Nome principal exibido na home e no título do app.
  static const String name = 'OGS';

  /// Subtítulo/lema exibido na home.
  static const String tagline = 'Copa da Ressaca';

  /// Descrição curta da festa (splash/SEO).
  static const String description =
      'OGS — registre suas bebidas e suba no ranking da festa.';
}

/// Configuração central do app — credenciais Supabase.
class AppConfig {
  const AppConfig._();

  /// Janela fixa da festa (início/fim). Usada na criação de grupo, pois nesta
  /// versão não há seletor de período — a competição dura toda a festa.
  static DateTime get festaStart =>
      DateTime(2026, 8, 29, 22, 0); // 29/08/2026 22:00

  static DateTime get festaEnd => DateTime(2026, 8, 30, 6, 0); // 30/08/2026 06:00

  static const String supabaseUrl =
      'https://qzfqkldzvoqvxytvaoaa.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6ZnFrbGR6dm9xdnh5dHZhb2FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MDA2NTcsImV4cCI6MjEwMTk3NjY1N30.rmllcXSONo5KXPRrL-jphYdM2xd1Y6MnRnoWoFPf0zs';

  /// Schema do banco usado pelo app (tabelas no public com prefixo ctg_).
  static const String schema = 'public';

  /// URL base pública para links de grupo (fallback em plataformas não-web).
  static const String publicBaseUrl = 'https://contagemcopos.online';
}
