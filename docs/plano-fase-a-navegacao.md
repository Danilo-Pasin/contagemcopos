# PLANO — Fase A: Navegação sem reload de estado entre abas

> Contexto: o atraso percebido ao trocar de abas dentro do grupo (`/g/CODE`) não é
> download de código (o bundle é único). É o **ciclo de vida do estado**: o provider
> da sessão é descartado e recriado a cada troca de rota, refazendo toda a cadeia
> de rede e reconectando realtime. Este plano elimina isso.
>
> Status: ✅ Implementado · Prioridade: ALTA · Impacto: alto · Risco: médio-baixo

---

## 1. Diagnóstico (causa raiz)

### 1.1 Cada aba é uma rota que recria o shell

`lib/core/router/app_router.dart:50-105` — todas as abas são rotas filhas de
`/g/:code`, e cada uma constrói um **novo** `GroupShell`:

```dart
GoRoute(
  path: AppRoutes.feedSegment,
  builder: (_, state) => GroupShell(
    code: state.pathParameters['code']!,
    child: const FeedPage(),
  ),
),
```

Resultado: ao navegar `/g/X` → `/g/X/feed`, a árvore inteira (Scaffold, AppBar,
NavigationBar, página) é desmontada e remontada.

### 1.2 O provider morre na transição

`lib/presentation/providers/group_session_provider.dart:355`:

```dart
final groupSessionProvider = StateNotifierProvider.autoDispose
    .family<GroupSessionNotifier, GroupSessionState, String>((ref, code) {
```

Na transição entre rotas existe um frame em que **nenhuma widget observa** o
provider → `autoDispose` o destrói → a próxima aba cria um notifier novo e
`_init()` (linha 81) executa de novo, **em série**:

1. `_identity.ensureReady()` — pode ir à rede
2. `_groupRepo.endExpiredGroups()` — RPC Supabase
3. `_groupRepo.getGroupByCode(_code)` — query
4. `findMember/findMemberByAccount` — query
5. `_refreshAll()` — 2 queries (ranking + feed)
6. `_subscribeRealtime(group.id)` — **desinscreve e reinscreve 2 channels**

Isso é exatamente o "loading" sentido entre abas.

---

## 2. Mudanças propostas

### 2.1 Migrar para `StatefulShellRoute.indexedStack` (GoRouter 14)

**Arquivo:** `lib/core/router/app_router.dart`

Estrutura alvo:

```dart
StatefulShellRoute.indexedStack(
  builder: (_, __, navigationShell) =>
      GroupShell(code: ???, navigationShell: navigationShell),
  branches: [
    // Branch 0 — Início
    StatefulShellBranch(routes: [
      GoRoute(
        path: AppRoutes.group(':code'),
        name: AppRoutes.groupName,
        builder: (_, state) => GroupHomePage(/* ou extrair code */),
        routes: [
          // share e hall-of-fame empilham DENTRO da branch inicial,
          // mantendo a bottom nav visível
          GoRoute(path: AppRoutes.shareSegment, ...),
          GoRoute(path: AppRoutes.hallOfFameSegment, ...),
        ],
      ),
    ]),
    // Branch 1 — Feed
    StatefulShellBranch(routes: [
      GoRoute(path: AppRoutes.group(':code') + '/' + AppRoutes.feedSegment, ...),
    ]),
    // Branch 2 — Ranking ...
    // Branch 3 — Estatísticas ...
    // Branch 4 — Álbum ...
  ],
)
```

Pontos importantes:

- **5 branches = 5 destinos da NavigationBar** (`group_shell.dart:61-87`):
  Início, Feed, Ranking, Estatísticas, Álbum.
- `share` e `hall-of-fame` viram subrotas da branch 0 (`/g/:code/share`,
  `/g/:code/hall-of-fame`) → continuam funcionando por deep link e empilham por
  cima da aba Início, com a bottom nav preservada. Hoje o share envolve
  `GroupShell` (app_router.dart:90-95); após a migração isso deixa de ser
  necessário pois o shell já está acima das branches.
- Branches não visitadas **não constroem conteúdo** até a primeira visita
  (comportamento do indexedStack do GoRouter) → primeira visita constrói,
  visitas seguintes são instantâneas (estado vivo em memória).
- O `code` precisa chegar ao `GroupShell` no builder do
  `StatefulShellRoute`. Opção recomendada: extrair do
  `GoRouterState.of(context)` dentro do `GroupShell` (mesma regex já usada em
  `stats_page.dart:254`) **ou** usar um builder que leia
  `state.uri.pathSegments`. Definir na implementação e manter consistente.

### 2.2 Adaptar o `GroupShell`

**Arquivo:** `lib/presentation/pages/group/group_shell.dart`

- Receber `StatefulNavigationShell navigationShell` em vez de `child`.
- `currentIndex` passa a ser `navigationShell.currentIndex`
  (substitui o parse de string em `_currentIndex`, linhas 92-99).
- `_onTap` passa a chamar `navigationShell.goBranch(i,
  initialLocation: i == navigationShell.currentIndex)` — tocar na aba atual
  volta ao "root" dela (comportamento padrão de apps).
- Manter intacto: watch do `groupSessionProvider(code)`, redirect de
  não-membro (linhas 24-34), gate de loading/erro (linhas 46-57).

### 2.3 Remover o `autoDispose` do provider

**Arquivo:** `lib/presentation/providers/group_session_provider.dart:355`

```dart
// antes
final groupSessionProvider = StateNotifierProvider.autoDispose
    .family<GroupSessionNotifier, GroupSessionState, String>(...);
// depois
final groupSessionProvider =
    StateNotifierProvider.family<GroupSessionNotifier, GroupSessionState, String>(...);
```

- Justificativa: a sessão é singleton por grupo e viva durante todo o uso;
  destruí-la em qualquer transição é sempre errado aqui.
- Memória: 1 instância por código acessado na sessão do navegador — custo
  desprezível. Se quiser higiene, adicionar `ref.onDispose` explícito não é
  necessário (o `dispose()` do notifier já cancela timers e desinscreve
  channels, linhas 344-351).

### 2.4 Limpeza decorrente

- `feed_page.dart`, `ranking_page.dart`, `album_page.dart`, `stats_page.dart`:
  nenhum wrapper muda — continuam páginas simples. Verificar apenas que
  nenhuma depende de ser remontada para recarregar dados (a stats tem guarda
  `_loadedKey` própria, que a Fase B substitui).
- Remover o `ShellRoute` externo sem função (`builder: (_, __, child) => child`,
  linha 50-51) — ele desaparece naturalmente na migração.

---

## 3. Riscos e cuidados

| Risco | Mitigação |
|---|---|
| Deep link `/g/X/feed` direto (QR/link compartilhado aponta só para `/g/X`; abas não costumam ser linkadas) | Testar abertura direta de cada URL de aba em aba anônima |
| Botão voltar do navegador com indexedStack (histórico por branch) | Testar back/forward nas 5 abas |
| Redirect de não-membro (`group_shell.dart:24-34`) dispara dentro do shell persistente | Garantir que roda uma única vez (guard com flag se necessário) |
| `share`/`hall-of-fame` deixando de ter `GroupShell` próprio | Conferir AppBar/bottom nav nessas telas após migração |
| Testes de rota existentes (`test/app_routes_test.dart`) | Segmentos/paths não mudam; adicionar teste novo: 5 branches, ordem dos destinos |

---

## 4. Validação

1. `flutter build web --release --wasm` ✅ compila.
2. `flutter test` ✅ suíte completa (121+) + novos testes de rota.
3. **Teste funcional (`flutter run -d chrome`):**
   - Entrar num grupo → alternar as 5 abas → **Network tab deve mostrar ZERO
     novas requisições** após o primeiro load (critério de aceite principal).
   - Console não deve repetir `[GroupSession] init para código …` a cada troca.
   - Realtime: registrar bebida em outro dispositivo/navegador → aba aberta
     atualiza sem reconexão (sem novos logs de subscribe).
   - Scroll do feed → trocar aba → voltar → posição de scroll preservada.
   - Não-membro abrindo `/g/X` → redireciona para `/entrar/X` uma única vez.
   - `/g/X/share` e `/g/X/hall-of-fame` direto por URL funcionam.
4. Critério de aceite: tempo percebido de troca de aba < 1 frame (sem spinner).

---

## 5. Registro de implementação (2026-08-25)

Implementado conforme o plano, com as seguintes alterações:

### 5.1 `lib/core/router/app_router.dart`
- `ShellRoute` externo substituído por `StatefulShellRoute.indexedStack`.
- 5 branches na ordem da `NavigationBar`: Início (`/g/:code`), Feed,
  Ranking, Stats e Álbum (`/g/:code/<segment>`).
- `share` e `hall-of-fame` viraram **subrotas da branch Início**
  (`/g/:code/share`, `/g/:code/hall-of-fame`) → empilham por cima da aba
  Início com bottom nav preservada.
- Wrappers `GroupShell` duplicados por rota removidos — o shell agora existe
  uma única vez no builder do `StatefulShellRoute`.

### 5.2 `lib/presentation/pages/group/group_shell.dart`
- Recebe `StatefulNavigationShell navigationShell` em vez de `code` + `child`.
- O `code` é extraído internamente via regex no URI
  (`RegExp(r'/g/([A-Z0-9]+)')`, mesmo padrão de `stats_page.dart`), pois o
  state do shell não expõe os pathParameters das branches.
- `currentIndex` = `navigationShell.currentIndex`; `_onTap` =
  `goBranch(i, initialLocation: i == currentIndex)` (tocar na aba atual
  volta ao root dela).
- Guard para `code` vazio (spinner até a rota resolver).
- Mantidos intactos: watch do provider, redirect de não-membro e gate
  loading/erro.

### 5.3 `lib/presentation/providers/group_session_provider.dart`
- Removido `.autoDispose`: `StateNotifierProvider.family` puro. A sessão
  sobrevive às transições entre abas (sem re-init de rede/realtime).

### 5.4 Mudança de comportamento (intencional)
- `hall-of-fame` agora exibe AppBar + bottom nav (antes era tela cheia sem
  shell), conforme previsto no plano.

### 5.5 Testes
- `test/app_routes_test.dart`: novo grupo "branches do StatefulShellRoute"
  validando as 5 abas na ordem da NavigationBar e share/hall-of-fame como
  subrotas da branch Início. Suíte completa: **124 testes ✅**.

### 5.6 Validação executada
- `flutter build web --release` ✅ (typecheck).
- `flutter test` ✅ (124 testes).
- ⏳ Pendente: teste funcional manual (`flutter run -d chrome`) — zero
  requisições ao trocar abas, realtime sem reconexão, scroll preservado,
  deep links diretos.
