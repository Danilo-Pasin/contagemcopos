# 2026-08-25 — Fases A/B/C de performance, prompt PWA e correção de rotas

# FASE A — Navegação sem reload entre abas `[Front-end]`

**Diagnóstico:** cada aba era uma rota filha que remontava o `GroupShell` inteiro; `groupSessionProvider.autoDispose` morria na transição e refazia toda a cadeia (identity → RPC → 4 queries → resubscribe realtime).

**Implementação:**
- `StatefulShellRoute.indexedStack` com 5 branches (Início, Feed, Ranking, Stats, Álbum); `share`/`hall-of-fame` como subrotas da branch Início.
- `GroupShell` recebe `StatefulNavigationShell`; `_onTap` = `goBranch(i, initialLocation: i == currentIndex)`; guard para code vazio.
- Removido `.autoDispose` do provider — sessão sobrevive às transições.
- Critério de aceite: troca de aba sem novas requisições/spinner.

# FASE B — Cache de estatísticas `[Front-end]`

**Diagnóstico:** stats fazia SELECT completo de `ctg_drinks` a cada visita à aba.

**Implementação:**
- Novo `stats_provider.dart`: `StatsState` tipado; agregação pura testável (`aggregateDrinkRows`); TTL 60s com stale-while-revalidate (`ensureFresh`), `forceRefresh()` (pull-to-refresh) e `invalidate()` por evento.
- Invalidação: chamada direta do `GroupSessionNotifier` em `addDrinkWithPhoto()`/`addPhoto()`, com guarda `ref.exists()`. Desvio justificado do plano: com IndexedStack, voltar à aba não dispara rebuild — então `invalidate()` recarrega em background (SWR) com dedup (`_reloadQueued`).
- `DrinkRepository.fetchStatsRaw(groupId)`; página virou `ConsumerWidget` recebendo `code` via construtor.
- 13 testes novos em `test/stats_provider_test.dart`.

# FASE C — Percepção de velocidade (animações) `[Front-end]`

**Implementação:**
- `AppMotion` em `app_tokens.dart`: fast 150ms · normal 250ms · entrance 300ms (teto) · staggerMs 40.
- Staggers reduzidos (home: pior caso ~800–1100ms → ≤300ms; logo mantém elasticOut + shimmer 1×).
- Listas (feed/ranking/álbum): conjunto de IDs já exibidos (`_seenIds`) + `_bootstrapped`; primeira carga anima com teto 8×40ms; refresh realtime só anima itens inéditos.

Suíte após fases A+B+C: **137 testes ✅**.

---

# Prompt "Adicionar à Tela de Início" (PWA install) `[Front-end]`

Recriado a partir de referência de outro projeto (arquivo de exemplo já apagado), adaptado ao design system local:

- **Novos arquivos:** `lib/core/utils/platform_detector.dart` (+`_web.dart`/`_stub.dart`) e `lib/presentation/widgets/add_to_homescreen_prompt.dart`.
- Detecção via `package:web` + `dart:js_interop` (**compatível com build WASM** — o original usava `dart:html`, que não compila para wasm): web mobile, iOS (incl. iPadOS 13+ via maxTouchPoints), Safari, modo standalone e captura de `beforeinstallprompt`.
- Bottom sheet com `AppLogo`, `PrimaryButton`/`SecondaryButton`, tokens e fonte Inter. Com prompt nativo: botão "Instalar app" + tutorial manual como fallback. iOS Safari: Compartilhar → "Adicionar à Tela de Início"; Android: menu ⋮.
- **Comportamento:** apenas web mobile · fora do standalone · **1× até dispensar** (`adhs_dismissed_v1`). Disparo na home ~1.2s pós-frame. Desktop não exibe.
- `pubspec.yaml`: `web: ^1.1.0` direta. Teste novo: `add_to_homescreen_sheet_test.dart` (4 casos).

---

# Correção das rotas do grupo (go_router 14.8.1) `[Front-end]`

## Problema
```
Assertion failed: configuration.dart:146
"The default location of a StatefulShellBranch cannot be a parameterized route"
```
A validação exige rota **sem parâmetro** como default de **TODAS** as branches (checagem **somente debug** — `flutter build web --release` não executa asserts, mascarando o problema).

## Tentativas intermediárias (histórico)
1. Base `/g` só na branch Início → parcial: Feed/Ranking/Stats/Álbum continuavam parametrizadas.
2. Todas as branches com base `/g` + filhos `:code/<segment>` → passava na assertion, mas **quebrava a navegação**: `goBranch(i)` de branch não visitada ia para `/g` (default) → redirect para home. Re-tap na aba Início também caía em spinner infinito.

## Solução definitiva
O `StatefulShellRoute` ficou **aninhado sob `/g/:code`** com abas RELATIVAS:

```
/g/:code                      (pai — carrega :code)
└── StatefulShellRoute.indexedStack
    ├── Branch 0: inicio      (+ share, hall-of-fame)
    ├── Branch 1: feed
    ├── Branch 2: ranking
    ├── Branch 3: stats
    └── Branch 4: album
```

- Cada branch tem default sem parâmetro → assertion satisfeita.
- Ao visitar uma branch pela primeira vez, o go_router substitui o `:code` do pai no caminho (`_effectiveInitialBranchLocation` → `patternToPath`) → `/g/CODE/feed`. Paths finais idênticos aos anteriores; navegações/deep links intactos.
- Redirects centralizados em `appRedirect(Uri)` (testável): `/g` → home; `/g/CODE` exato → `/g/CODE/inicio` (link compartilhável segue funcionando).
- Re-tap na aba atual volta ao root **dentro do grupo** (`/g/CODE/inicio`).
- Nota: `GoRoute(path: '')` é proibido por assert do próprio go_router — daí o segmento explícito `inicio`.
- Limpezas: parâmetro morto `code` do `GroupHomePage` removido; fallback no `GroupShell` redireciona para home se código vazio.

## Regressão permanente
`test/app_routes_test.dart`: teste que instancia o `appRouterProvider` real (a assertion dispararia na suíte se qualquer branch voltar a ser parametrizada) + testes do `appRedirect`.

**Verificação final: `flutter test` 147/147 ✅ · `flutter build web --release` ✅.**

---

# CHANGELOG 2026-08-25 — correções pós-teste local `[Front-end]`

## ✅ "Tried to modify a provider while the widget tree was building" ao abrir Estatísticas
- **Problema:** `StatsPage.build` chama `ensureFresh()` → `_load()` setava
  `state.loading = true` sincronamente antes do primeiro `await`, mutando o
  provider dentro do ciclo de build (crash em debug).
- **Arquivo:** `lib/presentation/providers/stats_provider.dart` — `ensureFresh()`
  adia a mutação com `Future.microtask(...)`.

## ✅ RenderFlex overflowed by 8px nos cards de métrica das estatísticas
- **Problema:** conteúdo (~82px) não cabia nos 74px internos do extent 108 do grid.
- **Arquivo:** `lib/presentation/pages/stats/stats_page.dart` — `mainAxisExtent`
  108 → 122; `Spacer()` trocado por espaçamento fixo (`AppSpacing.sm`).

## 📝 Esclarecimento — "Senha incorreta para X" ao criar grupo
Não é bug: contas nome+senha são **globais** (`ctg_accounts`, única por nome,
case-insensitive). Se o nome já existe com outra senha, o RPC `ctg_create_account`
recusa e o app mostra o erro. Melhoria futura: mensagem mais explicativa na tela
de criação.

## Verificação
- `flutter test` → ✅ 147/147 passam.
- `flutter build web --release` → ✅ compila.
- Teste manual: abas com estado vivo OK · stats sem crash/overflow · login OK.

---

# CHANGELOG 2026-08-25 — contas nome+senha passam a ser por grupo `[Back-end] [Front-end]`

## ✅ Nomes duplicados entre grupos diferentes agora são permitidos
Antes: `ctg_accounts` tinha índice único global em `lower(name)` — uma pessoa
"Danilo" com senha X impedia qualquer outra "danilo" de criar/entrar em
qualquer grupo. Agora a unicidade vale **apenas dentro de cada grupo**.

**Migração `accounts_scoped_by_group`:**
- Removido `ctg_accounts_name_key` (unique em `lower(name)`).
- Novo RPC `ctg_ensure_account(p_name, p_password, p_group_id)`:
  - nome já participante DESTE grupo → valida senha (hash) e devolve o id;
    senha errada → erro "Já existe alguém como X neste grupo com outra senha."
  - mesmo nome+senha já existente (outra conta) → reaproveita a conta
    (mesma pessoa em vários grupos compartilha credenciais);
  - caso contrário → cria conta nova.
- `ctg_login_account(p_name, p_password, p_group_id default null)`: se houver
  mais de uma conta com mesmo nome+senha, prefere a que participa do grupo
  informado. Re-vinculação de anon_id mantida.

**Frontend:**
- `group_repository.ensureAccount({name, password, groupId})` — chamada única
  ao novo RPC (removida a dupla login+create); import postgrest removido.
- Call sites atualizados com `groupId`: `create_group_page`, `join_group_page`
  e `login_page`.

## Verificação
- Smoke test SQL (com rollback): criação · recusa no mesmo grupo · duplicata
  permitida entre grupos · reaproveitamento de credenciais · login por grupo —
  todos OK, sem vazamento de dados de teste.
- `flutter test` → ✅ 147/147 · `flutter build web --release` → ✅.
