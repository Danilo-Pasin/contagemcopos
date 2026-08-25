/// Implementação web da [PlatformDetector] — usa `package:web` +
/// `dart:js_interop` (compatível com build WASM; não usar `dart:html`).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Evento `beforeinstallprompt` do navegador (não-padronizado no TS do
/// package:web) — expõe `prompt()` e `userChoice`.
extension type _BeforeInstallPromptEvent._(JSObject _) implements JSObject {
  external void prompt();
  external JSPromise<JSObject> get userChoice;
}

web.EventHandler? _listener;
_BeforeInstallPromptEvent? _deferredPrompt;

void initInstallPromptListener() {
  if (_listener != null) return;
  _listener = ((web.Event event) {
    try {
      event.preventDefault();
      _deferredPrompt = event as _BeforeInstallPromptEvent;
    } catch (_) {}
  }).toJS;
  try {
    web.window.addEventListener('beforeinstallprompt', _listener!);
  } catch (_) {
    _deferredPrompt = null;
  }
}

bool get hasDeferredInstall => _deferredPrompt != null;

Future<String?> nativeInstall() async {
  final prompt = _deferredPrompt;
  if (prompt == null) return null;
  try {
    prompt.prompt();
    final choice = await prompt.userChoice.toDart;
    final outcome = choice.getProperty('outcome'.toJS);    return outcome.isUndefinedOrNull ? null : outcome.toString();
  } catch (_) {
    return null;
  } finally {
    _deferredPrompt = null;
  }
}

class PlatformDetector {
  const PlatformDetector._();

  static bool get isWeb => true;

  static String get _ua =>
      web.window.navigator.userAgent.toLowerCase();

  static bool get isIOS {
    if (_ua.contains('iphone') || _ua.contains('ipod') || _ua.contains('ipad')) {
      return true;
    }
    // iPadOS 13+ se identifica como Macintosh, mas reporta pontos de toque.
    return _ua.contains('macintosh') && web.window.navigator.maxTouchPoints > 1;
  }

  static bool get isAndroid => _ua.contains('android');

  static bool get isSafari =>
      _ua.contains('safari') &&
      !_ua.contains('chrome') &&
      !_ua.contains('chromium') &&
      !_ua.contains('crios') &&
      !_ua.contains('firefox');

  /// Web em dispositivo móvel (UA de celular/tablet ou tela pequena + touch).
  static bool get isWebMobile {
    if (!isWeb) return false;
    if (isAndroid || isIOS) return true;
    if (RegExp(r'mobile').hasMatch(_ua)) return true;
    try {
      final touch = web.window.navigator.maxTouchPoints > 0 &&
          web.window.matchMedia('(pointer: coarse)').matches;
      final small = web.window.innerWidth < 600;
      return touch && small;
    } catch (_) {
      return false;
    }
  }

  /// O app já está rodando como PWA instalado (display-mode standalone ou,
  /// no iOS Safari, `navigator.standalone`).
  static bool get isPWA {
    try {
      if (web.window.matchMedia('(display-mode: standalone)').matches ||
          web.window.matchMedia('(display-mode: minimal-ui)').matches) {
        return true;
      }
      final standalone =
          (web.window.navigator as JSObject).getProperty('standalone'.toJS);
      return !standalone.isUndefinedOrNull && standalone.dartify() == true;
    } catch (_) {
      return false;
    }
  }
}
