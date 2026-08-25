/// Detecção de plataforma/ambiente do navegador.
///
/// Implementação real apenas no web (compatível com build WASM via
/// `package:web` + `dart:js_interop`); fora do web usa o stub com valores
/// padrão, mantendo o app compilável para mobile/desktop/testes.
export 'platform_detector_stub.dart'
    if (dart.library.js_interop) 'platform_detector_web.dart';
