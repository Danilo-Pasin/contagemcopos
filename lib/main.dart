import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'presentation/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Usa URLs sem hash (ex.: /g/NXGUZN) para que links e QR code de grupos
  // naveguem direto para o grupo. Sem isso, o deep link abre a home pedindo
  // o código. (No-op em mobile.)
  usePathUrlStrategy();

  // Captura erros não tratados (útil para debug no web)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[ZoneError] $error\n$stack');
    return true;
  };

  await initSupabase();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ContagemApp(),
    ),
  );

  // Carrega os símbolos de data/hora em pt_BR (ex.: "05/01", "d MMM").
  // Sem isso, DateFormat(..., 'pt_BR') lança LocaleDataException em runtime.
  // Roda após o primeiro frame para não bloquear o paint inicial com o
  // pacote de ICU; as primeiras formatações acontecem depois que a rede
  // responde, quando o carregamento já terminou.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initializeDateFormatting('pt_BR', null);
  });
}
