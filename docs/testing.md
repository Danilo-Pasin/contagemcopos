# Testes automáticos

Suíte de testes unitários e de widgets do app **Contagem**. Rodam sem
backend (sem acesso ao Supabase), cobrindo regras de regressão e comportamento
da UI de forma isolada e determinística.

## Como rodar

```bash
flutter test            # roda toda a suíte (test/)
flutter test test/app_routes_test.dart   # apenas um arquivo
flutter test test/theme_provider_test.dart --plain-name "toggle" # filtra por nome
```

> O `flutter analyze` (LSP) quebra por causa do acento em "Programação" no
> caminho. **Use `flutter test` como validação de testes e `flutter build web --release`
> como validação de compilação** — ver `AGENTS.md`.

## Cobertura

| Arquivo                | O que cobre                                                                 |
| ---------------------- | --------------------------------------------------------------------------- |
| `test/app_routes_test.dart`   | Regressão do bug P0: `join()` e `group()` já tiveram o mesmo path (`/g/:code`), causando loop infinito. Garante paths distintos e o formato compartilhável `/entrar/:code` e `/g/:code`. |
| `test/app_theme_test.dart`    | `AppTheme.light()` e `AppTheme.dark()` produzem `ThemeData` válidos (brightness, primaryColor, useMaterial3, colorScheme). |
| `test/theme_provider_test.dart` | Logic do `ThemeModeNotifier`: padrão = system, carregamento de 'light'/'dark' salvos, `toggle()` alterna dark↔light sem cair em system, e persiste no `SharedPreferences`. |
| `test/app_logo_test.dart`    | `AppLogo` renderiza um container do tamanho pedido (padrão 120 e custom), e `ResponsiveContent` limita a largura a `maxWidth` (regressão de botões/campos esticados por toda a tela). |

## Adicionar um teste

1. Crie `test/<nome>_test.dart` seguindo o padrão dos existentes (grupo `group('...')` + `test[Widgets]`).
2. Teste de widget: `testWidgets('descrição', (tester) async { ... })` + `tester.pumpWidget`.
3. **Não** dependa de: Google Fonts (use `GoogleFonts.config.allowRuntimeFetching = false` ou `runZonedGuarded`), rede/Supabase ou shared_preferences real (use `SharedPreferences.setMockInitialValues`).
4. Não haja asserts dependentes de timing de animação sem `pumpAndSettle`.