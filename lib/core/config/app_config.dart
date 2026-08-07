/// Configuração central do app — credenciais Supabase.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl =
      'https://cxuurozyyfcqxywhsiyt.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4dXVyb3p5eWZjcXh5d2hzaXl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4MDYwOTYsImV4cCI6MjA5NzM4MjA5Nn0.hdZuvQDsVb3Pet-FE7T3RKXjsd8NOx8lrAfoXCg2UWE';

  /// Schema do banco usado pelo app (tabelas no public com prefixo ctg_).
  static const String schema = 'public';

  /// URL base pública para links de grupo (fallback em plataformas não-web).
  static const String publicBaseUrl = 'https://contagemcopos.online';
}
