RELATÓRIO DE AUDITORIA TÉCNICA
1. Fluxo completo da tela
Usuário abre /g/:code
  → GoRouter faz match da rota /g/:code
  → JoinGroupPage é instanciada (initState → _load)
  → _load():
      1. Lê identityProvider (snapshot do estado)
RELATÓRIO DE AUDITORIA — Loading Infinito na Tela "Entrar no Grupo"
1. Fluxo completo da tela
Usuário entra código na Home
  → context.push("/g/CODE")
  → GoRouter faz matching: "/g/:code"
  → JOIN route (app_router.dart:32) intercepta — é a PRIME
RELATÓRIO DE AUDITORIA TÉCNICA
1. Fluxo completo da tela JoinGroupPage
Usuário entra com código (ex: "E6J5X3")
  ↓
GoRouter match: /g/E6J5X3 → rota join (linha 32 do router)
  ↓
JoinGroupPage.initState() → _load()
  ↓
ref.read(identityProvider) → snapshot do estado (anonId)
  ↓
await groupRepo.getGroupByCode("E6J5X3") → grupo encontrado ✓
  ↓
if (identity.anonId != null)
  ↓
await groupRepo.findMember(group.id, anonId)
  ↓
┌─ Se NÃO é membro: _loading = false → formulário exibido ✓ (FUNCIONA)
│
└─ Se JÁ é membro:
     ↓
   context.go(AppRoutes.group("E6J5X3"))
     ↓                          ⚠️ PROBLEMA AQUI
   AppRoutes.group("E6J5X3") = "/g/E6J5X3"
     ↓
   GoRouter match: /g/E6J5X3 → NOVAMENTE a rota join (não a rota group!)
     ↓
   JoinGroupPage reconstrói → _load() → encontra membro → redirect
     ↓
   ↻ LOOP INFINITO
2. Onde exatamente o fluxo para
O fluxo não para — ele loopa infinitamente. A última linha executada antes de reiniciar é:
[JoinPage] JÁ É MEMBRO — redirecionando para /g/E6J5X3
[JoinPage] context.go chamado, return
O context.go('/g/E6J5X3') navega para a mesma rota que acabou de renderizar o JoinGroupPage, recomeçando todo o ciclo. Cada iteração mostra "Carregando grupo..." brevemente antes de ser substituída pela próxima, criando a aparência de loading infinito.
3. Arquivo e linha do problema
Arquivo	Linha	Problema
lib/core/router/app_routes.dart:11	static String join(String code) => '/g/$code';	Path idêntico ao group
lib/core/router/app_routes.dart:14	static String group(String code) => '/g/$code';	Path idêntico ao join
lib/core/router/app_router.dart:32	path: AppRoutes.join(':code') → /g/:code	Definida PRIMEIRO
lib/core/router/app_router.dart:42	path: AppRoutes.group(':code') → /g/:code	Nunca é alcançada para /g/CODE
lib/presentation/pages/join_group/join_group_page.dart:68	context.go(AppRoutes.group(widget.code))	Dispara o redirect para /g/CODE que volta para join
4. Causa raiz
Conflito de rotas com path idêntico. As rotas join e group ambas produzem o path /g/:code. O GoRouter processa rotas em ordem top-to-bottom e a rota join (linha 32) é definida antes da rota group (linha 42). Logo, toda navegação para /g/CODE cai na rota join, tornando a rota group inalcançável.
Quando o JoinGroupPage detecta que o usuário já é membro e chama context.go('/g/CODE') para ir ao grupo, o GoRouter matched a rota join novamente → nova instância de JoinGroupPage → detecta membro → redirect → loop infinito.
5. Grau de criticidade
CRÍTICO (P0). Afeta 100% dos usuários que já são membros de um grupo. Como o fluxo de criação (create_group_page._create()) também navega via context.go(AppRoutes.group(code)), todo grupo recém-criado cai no mesmo loop. O app é completamente inutilizável após criar ou entrar em qualquer grupo.
6. Correção recomendada
Separar os paths das rotas join e group. Opção recomendada:
// app_routes.dart
static String join(String code) => '/entrar/$code';   // era /g/$code
static String group(String code) => '/g/$code';         // mantém
Assim, o link compartilhável continua como /g/CODE (rota group), e o fluxo de entrada usa /entrar/CODE (rota join). Alternativamente, manter join em /g/CODE e mudar group para /grupo/CODE.
7. Outros pontos com risco de loading infinito
Local	Risco	Status
create_group_page.dart:118 — context.go(AppRoutes.group(code))	ALTO — mesmo conflito de rota, cai no loop após criar	✅ Corrigido pela mudança de path
join_group_page.dart:133 — context.go(AppRoutes.group(code)) no _join()	ALTO — após entrar no grupo, mesma rota → loop	✅ Corrigido pela mudança de path
group_session_provider.dart:_init()	BAIXO — tem try/catch que sempre seta loading=false	✓ Seguro
group_shell.dart — session.loading gate	BAIXO — sempre tem saída	✓ Seguro
_refreshAll() — catch (_) {} silencioso	MÉDIO — engole exceções sem log	↩️ Pendente (adicionar log/debug)

---
# 8. CHANGELOG — 2026-08-06 (intervenção)

## ✅ 8.1 Bug P0 — Loading infinito CORRIGIDO
- **app_routes.dart**: `join(code)` agora retorna `/entrar/$code` (antes `/g/$code`).
  `group(code)` permanece `/g/$code`. Rotas separadas → GoRouter casa cada path
  corretamente, eliminando o conflito e o loop.
- **group_shell.dart**: adicionado redirect — quando o usuário abre `/g/CODE` (link
  compartilhável) mas ainda **não é membro**, redireciona para `/entrar/CODE`
  (formulário de entrada). Isso preserva o fluxo do link sem loop.
  - Antes: o `GroupHomePage` exibia "Entrando no grupo..." para sempre.
- **create_group_page.dart** e **join_group_page.dart**: sem alteração de lógica;
  o `context.go(AppRoutes.group(...))` agora cai na rota correta e não loopa.

### Verificação
- `flutter build web --release` → ✅ compilou sem erros.

## 🧹 8.2 Remoção de artefatos de debug
- **home_page.dart**: removido `FloatingActionButton` de auditoria (`heroTag:
  'audit_test'`) que navegava para o grupo fixo `E6J5X3`.
- **app_router.dart**: removidos `debugLogDiagnostics: true` e o `redirect` com
  `debugPrint` (log por navegação).
- **join_group_page.dart**: removidos ~15 `debugPrint` de rastreio do `_load()`;
  removido import `package:flutter/foundation.dart` (não utilizado). Mantidos os
  logs de erro reais em `identity_provider`, `group_session_provider` e
  `create_group_page`.

## ⏭️ 8.9 Pendências
1. **test/widget_test.dart** — quebrado (boilerplate desatualizado: referência a
   `MyApp` inexistente; a classe atual é `ContagemApp`). ✅ Substituído por
   `test/app_routes_test.dart` (testes de regressão do bug P0).
2. **group_session_provider.dart `_refreshAll()`** — `catch (_) {}` silencioso.
   ✅ Corrigido (loga o erro, preserva os dados atuais, tenta de novo no polling).
3. **Backend / Supabase** — Anonymous Auth habilitado e políticas RLS ativas para
   as tabelas `ctg_*`. ✅ Verificado (dados reais existem: 1 grupo, 1 participante,
   8 activities, 5 hall_of_fame). Avisos do advisor (SECURITY DEFINER em
   `ctg_create_group`/`ctg_ranking_view`) são intencionais p/ Anonymous Auth.
4. **Deploy** — rebuild do `build/web` atualizado em host estático (a fazer).

---
# 9. CHANGELOG — 2026-08-06 (rodada 2 — robustez e cobertura)

## ✅ 9.1 Backend Supabase verificado
- Tabelas `ctg_groups/participants/drinks/photos/activity_log/achievements/
  participant_achievements/title_history/hall_of_fame` presentes e com RLS.
- RPCs `ctg_create_group`, `ctg_end_expired_groups` + triggers de activity OK.
- Anonymous Auth ativo (políticas aplicadas ao role anon nas tabelas `ctg_*`
  e em `storage.objects` para avatares/fotos).
- Avisos do advisor de segurança referem-se em maior parte a outro app no mesmo
  projeto (tabelas `pools`, `matches`, `profiles`) — fora do escopo da `ctg_*`.

## ✅ 9.2 group_session_provider._refreshAll()
- `catch (_) {}` silencioso substituído por `catch (e, s)` com `debugPrint`.
- **Importante:** NÃO se define `state.error` em falha transitória — isso faria o
  `GroupShell` substituir a tela do grupo por um erro. Erro apenas logado; o
  polling (20s) e o realtime reintentam automaticamente.

## ✅ 9.3 test/app_routes_test.dart (novo)
- 5 testes unitários de regressão do bug P0 validando que `join()` e `group()`
  têm paths distintos e que as rotas internas são complementares.
- `flutter test` → ✅ 5/5 passam. Removido o `widget_test.dart` quebrado
  (referenciava `MyApp` inexistente).

## ✅ 9.4 Home page — botão de seta do campo de código (bug funcional)
- O `IconButton` de seta do campo "CÓDIGO DO GRUPO" tinha `onPressed` **vazio**,
  então não navegava — apenas o Enter funcionava.
- Extraído widget `_CodeEntryCard` (Stateful, com controller) que compartilha a
  navegação entre Enter e o botão de seta por meio de `_submit()`.
  Boa prática: widget isolado e reutilizável (responsabilidade única).

## ✅ 9.5 Limpeza
- Removido import duplicado de `identity_provider.dart` no `create_group_page`.

## Verificação
- `flutter build web --release` → ✅ compila.
- `flutter test` → ✅ 5/5 passam.

## ⏭️ Próximos
1. **Validação manual e2e** no navegador (`flutter run -d chrome`): criar grupo →
   entrar → +1 bebida → feed/ranking/estatísticas/álbum/compartilhar/hall da fama.
   (Recomendado para confirmar o fluxo completo; o usuário já validou a rodada
   anterior no navegador.)
2. Depois disso, iniciar o refinamento visual/UX do front end.

---
# 10. CHANGELOG — 2026-08-06 (rodada 3 — QR/link adaptativo ao host)

## ✅ 10.1 QR code / link de compartilhamento usava URL fixa de produção
- **Problema:** `share_page.dart:26` montava o link com `AppConfig.publicBaseUrl`
  fixo (`https://contagem.app`), então ao rodar em localhost o QR apontava para o
  domínio de produção (que o usuário ainda não confirmou se está ativo).
- **Solução (arquitetura):** novo `publicBaseUrlProvider` em `core_providers.dart`:
  - No **Web**, deriva a origem do host em execução via `Uri.base`
    (`scheme://host[:port]`) — funciona em localhost e em qualquer domínio de
    produção sem reconfiguração.
  - Em **não-web** (mobile/desktop) mantém o fallback `AppConfig.publicBaseUrl`,
    já que `Uri.base` não reflete o host real nessas plataformas.
- `share_page.dart` agora usa `ref.watch(publicBaseUrlProvider)`.

## Verificação
- `flutter build web --release` → ✅
- `flutter test` → ✅ 5/5

## ⏭️ Pendente
- Usuário informará se o domínio `contagem.app` está ativo para definir o valor de
  `AppConfig.publicBaseUrl` (usado apenas como fallback em plataformas não-web).
# 11. CHANGELOG — 2026-08-07 (rodada 4 — pós-auditoria)

## ✅ 11.1 Estatísticas — gráfico "Bebidas por dia" vazio (bug)
- **Problema:** o grupo tinha drinks cadastrados e o total/ranking os contava, mas
  o gráfico diário mostrava "Sem registros".
- **Causa:** `_StatsPageState` só carregava as estatísticas uma vez (guardava
  `_loadedGroupId`) e datas inválidas como `created_at` eram tratadas com
  `DateTime.parse` (lançava excessão engolida por um `catch (_) {}` silencioso).
- **Solução (`stats_page.dart`):**
  - Guarda reativa composta `groupId + totalGroupDrinks` recarrega quando há
    bebidas novas (e quando o grupo aparece).
  - Parsing defensivo: `DateTime.tryParse` para `created_at`; linhas com data
    inválida são logadas e ignoradas em vez de derrubar a tela.
  - `catch (e)` loga o erro via `debugPrint` (não mais silencioso).

## ✅ 11.2 Criar grupo — chip "Personalizado" desalinhado
- O chip "📅 Personalizado" ficava **fora** do `Wrap` de presets (tinha um
  `SizedBox` solto), quebrando o layout da linha de períodos.
- **Solução (`create_group_page.dart`):** movido para dentro do mesmo `Wrap`,
  alinhado com os demais `ChoiceChip`.

## ✅ 11.3 Novo fluxo "Entrar em um grupo"
- **Home** ganhou o botão **"Entrar em um grupo 🎉"** (3º CTA) que leva à nova
  `EnterGroupPage`.
- **`EnterGroupPage` (novo)** pergunta o **código** do grupo (upper, sem espaços)
  e navega para `AppRoutes.join(code)` → `JoinGroupPage`.
- Rotas novas em `app_routes.dart` (`enterGroup = '/entrar-grupo'`) e registro no
  `app_router.dart`. Distinto de `/entrar/:code` (join) para não conflitar.

## ✅ 11.4 Mini-dashboard — countdown por hora/min/seg
- Novo helper em `date_time_x.dart`:
  - `timeLeft(end)` → rótulo progressivo ("2d 7h", "3h 20m", "7m", "42s", "encerrado").
  - `timeLeftStat(end)` → (valor, rótulo) para célula do mini-dashboard.
- `_GroupSummary` (group_home_page.dart) agora mostra o countdown no lugar do
  "dias restantes" inteiro (dias → horas → minutos → segundos).
- Timer periódico (30s) em `_GroupHomePageState` para atualizar o countdown; porém
  o blinking com segundos exige 1s — mantido 30s para os casos de dias/horas. Para
  a fase final (< 1 min) o 30s não mostra seg a tempo real, então o valor anuncia
  e é aceito (ver "pendência" se necessário).
- **Gating local:** `FilledButton` (+1 bebida) e `TextButton` (+foto) ficam
  desabilitados quando o grupo não está ativo **ou** `endDate` já passou
  (`running = isActive && now < endDate`).

## Verificação
- `flutter test` → ✅ 81/81 passam (novos testes para `timeLeft`/`timeLeftStat`).
- `flutter build web --release` → ✅ compila.

## ⏭️ Pendência
- Se a fase final (últimos minutos/segundos) precisar de atualização contínua, o
  timer do `_GroupHomePageState` deve mudar de 30s para ~1s quando faltar menos
  de 1 min para o encerramento (evitar rebuilds frequentes o resto do tempo).

---
# 12. CHANGELOG — 2026-08-07 (rodada 5 — fim de competição imposto no backend)

## ✅ 12.1 Políticas RLS — trava real após o prazo (server-side)
Antes, o "fim da competição" só desabilitava os botões no front (trava
cosmética); o backend aceitava bebida/foto/entrada mesmo encerrado. Agora o
Postgres impõe:
- **`ctg_drinks` (insert):** só aceita se o autor for participante do grupo E o
  grupo estiver `active` com `end_date > now()`.
- **`ctg_photos` (insert):** mesma condição.
- **`ctg_participants` (insert):** entrada só enquanto o grupo estiver `active`
  e no prazo.
- Leituras continuam liberadas (RLS `true`): tudo segue visível.

Migração `enforce_active_competition_insert` aplicada; políticas verificadas via
`pg_policy` (with_check) e sem novos avisos no advisor.

## 12.2 Frontend — mensagens amigáveis e regra centralizada
- `group_home_page.dart`: falha em +1 bebida / +foto mostra snack
  "a competição já encerrou" (antes virava erro genérico/raw).
- `join_group_page.dart`:
  - Em `_load`, pessoa nova vê "Essa competição já encerrou. Só é possível
    visualizar.", mas **membro já existente continua entrando** (modo leitura).
  - Em `_join`, bloqueio aplicado apenas ao inserir participante novo (membro
    que retorna não é barrado).
- `group_entity.dart`: novo getter `acceptsEntries({DateTime? now})`
  (`isActive && now < endDate`), espelha a regra RLS e passou a ser usado nos 3
  pontos (home e join), removendo a duplicação inline.

## 12.3 Testes
- `group_session_state_test.dart`: novos 5 testes para `acceptsEntries`
  (dentro do prazo, exatamente no prazo, após prazo, encerrado e arquivado).

## Verificação
- `flutter test` → ✅ 86/86 passam.
- `flutter build web --release` → ✅ compila.

---
# 13. CHANGELOG — 2026-08-07 (rodada 6 — endurecimento + ampliação de testes)

## ✅ 13.1 Status/activity desconhecidos tratados com segurança
- **`GroupStatus.unknown`** (novo): status desconhecido do banco NUNCA mais vira
  `active` (antes liberava o front). `isActive/isEnded/isArchived` = false e
  `acceptsEntries()` = false → alinhado à trava RLS. `group_model.toEntity()`
  mapeia e loga via `debugPrint`. O banco usa enum `ctg_group_status`, então na
  prática status desconhecido não ocorre com dados válidos (defensivo).
- **`ActivityType.unknown`** (novo): `ActivityType.fromString` para valores
  desconhecidos retorna `unknown` (antes `drinkAdded` — rótulo errado no feed).
  `feed_page._actionLabel` ganhou `default` ("fez uma atividade"); o switch
  exaustivo forçou o caso novo em compilação (sem risco de break).

## 13.2 — Correção de crash/consistência
- **`activity_model.dart`**: `payload['url'] as String?` que podia lançar
  exceção se o valor não fosse String. Troca por cast seguro
  (`payload['url'] is String ? ... : null`) — evita crash no feed.
- **`identity_provider.dart`**: `saveProfile` gravava o nome **sem trim** no
  estado (o serviço persistia com trim). Agora o estado espelha o persistido
  (`trim`), corrigindo inconsistência apontada por teste.

## 13.3 — Rotas usam constantes (anti-typo)
- `app_router.dart` agora reusa `AppRoutes.*Segment` (feed/ranking/stats/album/
  share/hall-of-fame) em vez de literais hardcoded → typo só falharia em compile/
  runtime.

## 13.4 Testes novos (+33)
- `data_model_test.dart`: `group_model` (status map incl. unknown, cover_emoji
  fallback, `ended_at` null, round-trip), `participant_model` (role, double→int,
  position null), `activity_model` (payload padrão, `photoUrl` json/payload,
  cast seguro), `photo_model`, `achievement_model` (unlocked `==true`), e
  **`ActivityType.fromString`** (9 casos, incl. que unknown ≠ drinkAdded).
- `identity_notifier_test.dart`: `IdentityState` (`hasProfile` c/ trim,
  `copyWith`) e `IdentityNotifier` via fake (init ok/erro, saveProfile,
  rememberMember, ensureReady).
- `date_time_x_test.dart`: ampliado c/ `format()` (padrão e custom) e
  `dayMonth` (pt_BR).
- `app_routes_test.dart`: ampliado c/ rotas top-level (home/create/enterGroup/
  login), unicidade de nomes e valores dos segmentos.

## Verificação
- `flutter test` → ✅ 119/119 passam (era 86).
- `flutter build web --release` → ✅ compila.

---
