# 2026-08-29 — Fix PWA: travamento iOS standalone + fotos pretas no web

> Correções de estabilidade e desempenho do PWA (deploy Vercel), após bugs de
> congelamento no modo **standalone iOS** e **fotos de perfil pretas** no web.
> Executadas na branch `festa-2026` e sincronizadas em `main` via `git merge`.

# Bug: fotos pretas no web (regressão do Flutter) `[Front-end]`

**Sintoma:** imagens de perfil/bebidas carregadas como **preto** no build web.

**Causa raiz:** regressão do Flutter **#191800** (Flutter `3.47+`), no caminho
padrão `HtmlImage` do `CachedNetworkImage` via `ui_web.createImageCodecFromUrl`.
Produção entrou nessa versão porque o build da Vercel clonava o branch
`stable` (3.47.2), enquanto o ambiente local usava 3.44.2 — **produto ≠ local**.

**Correção em duas camadas:**

1. **HttpGet no web (defesa principal)** — novo wrapper
   `lib/presentation/widgets/app_network_image.dart`
   (`AppNetworkImage`) com
   `imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet` nos **4 call sites**
   que usavam `CachedNetworkImage`:
   - `widgets/app_avatar.dart` (avatar de usuário);
   - `pages/album/album_page.dart` (tile do álbum + viewer da foto);
   - `pages/feed/feed_page.dart` (foto no feed).
   - Adicionada dependência direta `cached_network_image_platform_interface
     ^4.1.1` ao `pubspec.yaml` (o enum `ImageRenderMethodForWeb` não é exportado
     pelo pacote principal). O wrapper repassa `imageUrl`, `fit`,
     `memCacheWidth`, `width`, `height`, `placeholder` e `errorWidget`.
   - O `HttpGet` desvia do bug #191800, restaura cache em disco/memória via
     `flutter_cache_manager` e força a evicção do `ImageCache` a funcionar sem
     placeholder preto.

# Bug: travamento no iOS standalone (PWA) `[Front-end]` `[Infra]`

**Sintoma:** app congela/fica inutilizável ao usar inputs no modo **standalone**
do iOS PWA (Flutter `flutter/flutter#111896` / `#115829` — "teclado fantasma"
após focar um `TextField`).

**Correção em `web/index.html` (só ativa em iOS standalone):**

- Listeners `touchstart` **passivos** para mitigar o scroll fantasma pós-foco.
- Reset de scroll em `focusout`, `resize`, `pageshow`, `visibilitychange` e
  `visualViewport.resize` (rebate o "teclado fantasma" que desloca o layout).
- **Timeout de segurança do splash:** o overlay de splash passou a ser removido
  à força após 12s (antes ficava preso bloqueando os toques se o app não
  acordasse a tempo).
- `window.scrollTo(0,0)` no first-frame do app.

# Desempenho no skwasm (single-thread) `[Front-end]`

- `pages/group/group_home_page.dart`: o **timer de 1s** (countdown/redraw) agora
  **pausa quando o app/aba não está visível** (via `WidgetsBindingObserver`,
  cross-platform — sem `package:web` direto, para não quebrar mobile/testes).
  Reduz gasto de CPU desnecessário e o "travamento" ao voltar.
- `widgets/glass_card.dart`: blur padrão dos `GlassCard` reduzido de **14 → 8**
  (menos carga no raster do skwasm).

# Determinismo do deploy (Infra) `[Infra]`

`scripts/vercel_build.sh`:
- Versão do Flutter **fixada em 3.44.9** (antes clonava `stable` → 3.47.2 com o
  bug #191800). Produção agora usa a mesma versão do ambiente local.
- **Checagem de versão** que **falha o build** se houver drift, evitando
  regressões silenciosas em futuros deploys.

# Resultado

- `flutter build web --release` ✅ (compila; valida erros de LSP/caminho).
- **168 testes ✅** (suíte completa).
- Commit `57ed85d` na `festa-2026`; merge `461b960` em `main` (via `git merge`),
  ambos com push → deploy Vercel disparado (Flutter 3.44.9, determinístico).
