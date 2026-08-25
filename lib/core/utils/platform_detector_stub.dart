/// Stub não-web da [PlatformDetector] — todos os recursos de navegador
/// retornam falso/nil, pois só fazem sentido no Flutter Web.
library;

/// Captura do evento nativo de instalação PWA (sem efeito fora do web).
void initInstallPromptListener() {}

/// Indica se existe um prompt nativo de instalação pendente.
bool get hasDeferredInstall => false;

/// Invoca o prompt nativo de instalação. Retorna o outcome
/// ('accepted'/'dismissed') ou null se não havia prompt.
Future<String?> nativeInstall() async => null;

class PlatformDetector {
  const PlatformDetector._();

  static bool get isWeb => false;
  static bool get isIOS => false;
  static bool get isAndroid => false;
  static bool get isSafari => false;

  /// Web em dispositivo móvel (fora do web sempre falso).
  static bool get isWebMobile => false;

  /// O app já está rodando como PWA instalado (display-mode standalone).
  static bool get isPWA => false;
}
