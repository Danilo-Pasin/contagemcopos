/// Configuração central do app — credenciais Supabase.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl =
      'https://qzfqkldzvoqvxytvaoaa.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6ZnFrbGR6dm9xdnh5dHZhb2FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MDA2NTcsImV4cCI6MjEwMTk3NjY1N30.rmllcXSONo5KXPRrL-jphYdM2xd1Y6MnRnoWoFPf0zs';

  /// Schema do banco usado pelo app (tabelas no public com prefixo ctg_).
  static const String schema = 'public';

  /// URL base pública para links de grupo (fallback em plataformas não-web).
  static const String publicBaseUrl = 'https://contagemcopos.online';
}
