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

# 14. CHANGELOG — 2026-08-10 (rodada 7 — re-vínculo de sessão no login por conta)

## ✅ 14.1 Bug — `403` ao registrar bebida/foto após login por conta (nome+senha)

- **Sintoma:** `POST /ctg_drinks` → 403 `PostgrestException(42501)` (violação de RLS)
  ao tocar em `+1 BEBIDA`, mesmo sendo membro do grupo e a competição ativa.
- **Causa raiz:** a **sessão anônima** é a identidade do RLS (`auth.uid()`). As
  policies de insert de `ctg_drinks`/`ctg_photos` exigem `p.anon_id = auth.uid()`.
  Porém quem volta por **conta** (nome+senha) pode estar em uma sessão anônima
  nova (outro navegador/dispositivo); o participante mantinha o `anon_id` antigo
  → `auth.uid() != anon_id` → insert bloqueado.
- **Correção (backend, sem mudança no Flutter):** `ctg_login_account` passou a,
  após validar a senha, re-vincular `ctg_participants.anon_id = auth.uid()` para
  todas as participações da conta (guarda `NOT EXISTS` evita conflito com a
  unique `(group_id, anon_id)`). O re-vínculo só ocorre com senha correta
  (imune a spoofing — `ctg_participants` tem leitura pública).
- **Backfill imediato:** `ctg_participants` do `dandan` (grupo Fazenda `LTQPKQ`)
  atualizado para a sessão anônima ativa `a0a8708d-…` (volta a escrever ainda sem
  novo login). Corrige **bebidas e fotos**.
- **Migration:** `bind_anon_on_account_login`.
- **Trade-off (documentado):** o último dispositivo que logar com a conta detém o
  vínculo de escrita (anon = sessão do dispositivo).

## Verificação
- Migration `bind_anon_on_account_login` aplicada; `pg_get_functiondef`
  confirma o bloco de re-vínculo.
- Backfill confirmado por `RETURNING` (`anon_id` = sessão atual).
- Teste manual recomendado: `flutter run -d chrome` → entrar em Fazenda com a
  conta `dandan` → `+1 BEBIDA` deve registrar (sem 403).

---

# 15. CHANGELOG — 2026-08-10 (rodada 8 — foto obrigatória ao registrar bebida)

## ✅ 15.1 Fluxo "+1 BEBIDA" agora exige foto
- **Problema/objetivo:** bebida podia ser registrada sem nenhuma comprovação
  visual.
- **Mudança de fluxo (`group_home_page.dart`):** ao tocar em `+1 BEBIDA`,
  depois de escolher o tipo (opcional), o app pergunta a **origem da foto**
  (📷 tirar agora / 🖼️ galeria) e **cancela tudo** se a foto for cancelada.
  Só então insere a bebida **e** a foto, vinculadas por `ctg_photos.drink_id`.
- **`drink_repository.dart`:** `addDrink` agora devolve o `id` criado
  (`.select('id').single()`), permitindo o vínculo da foto.
- **`group_session_provider.dart`:** `addDrink` foi substituído por
  `addDrinkWithPhoto({drinkType, note, required photoUrl})` — insere a bebida,
  obtém o id e insere a foto com `drink_id`; sem foto não há bebida (regra
  centralizada no provider, não apenas na tela).
- **Mensagens de erro mais precisas:** RLS `42501` → "A competição já
  encerrou."; demais falhas → mensagem genérica (antes qualquer erro virava
  "competição encerrou", o que confundia com falha de upload/rede).
- O botão **"Adicionar Foto"** (foto solta, sem bebida) continua funcionando.

## Verificação
- `flutter test` → ✅ 119/119 passam.
- `flutter build web --release` → ✅ compila.
- Teste manual sugerido: `flutter run -d chrome` → `+1 BEBIDA` → cancelar a
  foto deve **não** registrar bebida; completar com foto deve registrar bebida
  + foto no álbum/feed.

---

# 16. CHANGELOG — 2026-08-10 (rodada 9 — sistema de títulos com patamares fixos)

## ✅ 16.1 Títulos — híbrido: iniciais proporcionais + fixos a partir da Lenda
- **Pedido:** manter `Aprendiz`, `Cachaceiro` e `Rei do Boteco` como estão
  (proporcionais à meta do grupo) e, **a partir da Lenda**, subir a dificuldade
  com patamares **fixos em copos**.
- **Novas faixas (`title_system.dart`):**
  - Aprendiz 🍺 · Cachaceiro 🍻 · Rei do Boteco 👑 — **inalterados** (% do goal)
  - Lenda 💀 **20+** · Imperador do Copo 🏆 **30+** · Mito do Bar 🔥 **40+** ·
    Deus da Geladeira 👑👑 **50+** · Farmador de aura ✨ **67+** ·
    Alcoólatra Supremo 🍾 **76+** · O Sigma Verdadeiro 🐺 **88+** ·
    Papo de Reabilitação 🙏 **99+**
- **Implementação:** `TitleTier` ganhou `absoluteMin` (piso em copos); o patamar
  efetivo é `max(percentual da meta, piso fixo)`. Novo `thresholdsFor(maxGoal)`
  aplica **carry-forward** para garantir patamares monotônicos — uma meta alta
  nunca faz um título exigir menos que o anterior (conflito inerente ao misturar
  `%` com valores fixos, resolvido para qualquer meta).
- Sem mudanças de API pública (`currentTier`/`nextTier`/`progressToNext`/`tiers`
  continuam os mesmos) → demandas em home, ranking e stats mantidas.

## Verificação
- `flutter test` → ✅ 120/120 (title_system_test reescrito p/ o híbrido).
- `flutter build web --release` → ✅ compila.

---

# 17. CHANGELOG — 2026-08-10 (rodada 10 — títulos fixos em copos, foto de perfil, coroa p/ líder)

## ✅ 17.1 Títulos 100% por quantidade de copos (não %)
- **Pedido:** confirmado que os títulos são por **quantidade absoluta de copos**
  (notação `+`), não percentual da meta.
- **`title_system.dart`:** removida a lógica de `%`; todos os patamares são fixos:
  Aprendiz 🍺 **5** · Cachaceiro 🍻 **10** · Rei do Boteco 👑 **15** · Lenda 💀 **20** ·
  Imperador do Copo 🏆 **30** · Mito do Bar 🔥 **40** · Deus da Geladeira 👑👑 **50** ·
  Farmador de aura ✨ **67** · Alcoólatra Supremo 🍾 **76** · O Sigma Verdadeiro 🐺 **88** ·
  Papo de Reabilitação 🙏 **99**.
  - Os 3 primeiros (Aprendiz/Cachaceiro/Rei) tinham valores indefinidos pelo usuário;
    adotados 5/10/15 para encaixar com a Lenda 20 (ajuste fácil se desejar).
  - `requiredDrinks` não depende mais da meta; `maxGoal` continua usado no
    restante do app (objetivo/competição).
- `test/title_system_test.dart` reescrito (todos os casos por copos fixos).

## ✅ 17.2 Foto de perfil editável pelo mini-dashboard
- Tocando no **seu avatar** (mini-dashboard do grupo) abre a escolha de origem da
  foto (📷 agora / 🖼️ galeria), faz upload como **avatar** e atualiza
  `ctg_participants.photo_url` (via `updateProfilePhoto` no
  `group_session_provider`) + perfil local (`identityProvider.saveProfile`).
- Pequeno selo de 📷 câmera no canto do avatar indica que é tocável.
- RLS: `ctg_part_update` exige `anon_id = auth.uid()` — ok para o participante
  logado (mesma regra do re-vínculo da rodada 7).

## ✅ 17.3 Coroa para o 1º lugar; criador marcado com escudo
- **Problema:** a coroa 👑 aparecia no avatar do **criador** do grupo.
- **`app_avatar.dart`:** novo `isLeader` → **👑** no avatar de quem está em 1º;
  `isCreator` agora mostra **🛡️** (escudo) no canto oposto.
- Aplicado em `group_home_page` (card do usuário + lista) e `ranking_page`
  (lista + pódio: `isLeader: place == 1`).

## Verificação
- `flutter test` → ✅ 120/120.
- `flutter build web --release` → ✅ compila.

---

# 18. CHANGELOG — 2026-08-10 (rodada 11 — otimização de performance P1–P4)

## ✅ 18.1 Startup: ICU de datas + fonte sem fetch em runtime
- **`main.dart`:** `initializeDateFormatting('pt_BR')` saiu do caminho do
  primeiro frame e roda num `addPostFrameCallback` — antes bloqueava o paint
  inicial carregando o pacote de ICU da `intl`.
- **Fonte:** removido o `google_fonts` (que baixa a Inter da rede em runtime
  no web, causando atraso e layout shift). A **Inter variable**
  (`assets/fonts/Inter-Variable.ttf`, OFL) agora é bundled via `pubspec.yaml`;
  `app_theme.dart` usa `fontFamily: 'Inter'` nos dois temas.
- `test/app_theme_test.dart` sem o `google_fonts`; novo teste confere que a
  Inter vem do bundle.

## ✅ 18.2 Realtime/refresh coalescidos (menos rebuilds)
- **`group_session_provider.dart`:**
  - callbacks de realtime (ctg_drinks, ctg_photos, ctg_participants,
    ctg_activity_log) e o polling de 20s agora passam por `_scheduleRefresh()`
    — um **debounce de 400ms** que transforma o burst de eventos de uma
    bebida (até ~3 canais + polling) em **um único refresh**;
  - `_runRefresh()` tem flag in-flight + re-queue (não concorre com refresh
    em andamento);
  - `_refreshAll()` faz **diff** de ranking/feed/`me` antes de setar o state —
    sem mudança real, não notifica listeners (evita rebuild de todas as telas);
  - `addDrinkWithPhoto`, `addPhoto` e `updateProfilePhoto` não fazem mais
    `_refreshAll()` explícito (realtime + schedule cobrem);
  - `refresh()` (pull-to-refresh) segue executando direto, esperando conclusão.

## ✅ 18.3 Imagens: decodificação no tamanho do elemento
- `memCacheWidth`/`memCacheHeight` nos `CachedNetworkImage`:
  - `app_avatar.dart` → 256px (avatares);
  - `feed_page.dart` → 640px (foto 4:3 do tile);
  - `album_page.dart` → 400px (grade); viewer mantém a original.
- Menos CPU/memória para decodificar 1024px+ em elementos pequenos.

## ✅ 18.4 Estatísticas: 1 SELECT por visita (antes: 1 por bebida)
- **`stats_page.dart`:** a chave de recarga deixou de incluir
  `totalGroupDrinks` (que disparava o SELECT completo de `ctg_drinks` a cada
  nova bebida) e passou a ser **por grupo**. A página recarrega ao entrar e
  por **pull-to-refresh**.

## ✅ 18.5 Build Wasm + isolamento de paint
- **`scripts/vercel_build.sh`:** `flutter build web --release --wasm`
  (3MB wasm + bootstrap `main.dart.mjs`) — melhor performance de runtime no
  web moderno; validado localmente.
- `feed_page.dart`: itens em `RepaintBoundary` (paint isolado por tile).

## Verificação
- `flutter test` → ✅ **121/121** (1 novo: fonte Inter bundled).
- `flutter build web --release --wasm --base-href /` → ✅ compila e gera
  `main.dart.wasm`/`main.dart.mjs`.
- **Sem commit** (conforme pedido); mudanças pendentes em working tree.

---

# 19. CHANGELOG — 2026-08-10 (rodada 12 — migração para projeto Supabase dedicado)

## ✅ 19.1 Novo projeto dedicado `contagem`
- Criado o projeto **`qzfqkldzvoqvxytvaoaa`** (contagem, South America/São
  Paulo, 2026-08-10) para substituir o compartilhado
  `cxuurozyyfcqxywhsiyt` (que segue servindo o outro app: matches/pools/
  countries/profiles).
- `lib/core/config/app_config.dart` → `supabaseUrl` + `anonKey` novos.
- Anonymous Auth habilitado no projeto novo.

## ✅ 19.2 Schema/storage/dados copiados e verificados
- `supabase/migrations/20260810000000_contagem_schema.sql` (tabelas, enums,
  indices, `ctg_ranking_view`, functions, triggers, RLS + pgcrypto),
  `..._contagem_storage.sql` (buckets `drinks`/`avatars` + políticas),
  `..._contagem_data.sql` (dump via `migration_to_new_project/dump_data.py`),
  `..._contagem_accounts.sql` (14 contas).
- Dados conferidos no novo: **13 participantes, 78 drinks, 18 fotos, 112
  activities, 18 achievements, 1 hall_of_fame, 14 contas**, 26 objetos de
  storage (~3.8MB).
- URLs de mídia reescritas para o domínio novo; storage copiado via
  `upload_storage.py` (service_role, `x-upsert: true`).

## ✅ 19.3 Relatime/configuração
- Publicação `supabase_realtime` no novo: 8 tabelas `ctg_*` (drinks, photos,
  participants, activity_log, groups, hall_of_fame, participant_achievements,
  title_history). `ctg_accounts` fica de fora (login via RPC, sem realtime).

## ✅ 19.4 Smoke test end-to-end (REST anon)
- signup anônimo → lista grupos (`LTQPKQ`, `WECMKA`) → INSERT participante
  (RLS) → INSERT drink (RLS `ctg_drinks_insert`) → ranking view inclui o
  participante com total = 1 → triggers `member_joined`/`drink_added` OK.
- Um 403 observado era artefato do próprio teste (participante de execução
  anterior com outro `anon_id`); dados de teste removidos do banco novo
  (bancos revalidados em 13/78/112/18).

## ⚠️ 19.5 Cutover & consequências
- **Usuários anônimos existentes serão tratados como "novos"** no novo projeto
  (novo `anon_id`); participantes órfãos duplicados exigem limpeza manual após
  o cutover real.
- Contas com nome+senha (`ctg_accounts`) migram íntegras (hash preservado);
  após login a conta re-vincula `anon_id` às participações via
  `ctg_login_account`.
- Projeto antigo segue intacto (rollback disponível).

## Verificação
- `flutter test` → ✅ **121/121**.
- `flutter build web --release --wasm --base-href /` → ✅ com `app_config`
  novo.
- **Sem commit** (conforme pedido); mudanças pendentes em working tree.

---

# 20. CHANGELOG — 2026-08-10 (rodada 13 — botão voltar no "Entrar em um grupo" + correção de toque no PWA iOS)

## ✅ 20.1 Botão voltar na tela "Entrar em um grupo"
- `enter_group_page.dart`: a tela de digitar o código (aberta pela home via
  "Entrar em um grupo") **não tinha como voltar**. Adicionado `AppBar` com
  seta que retorna à home (`context.go(AppRoutes.home)`), no mesmo padrão das
  telas de login e de entrar no grupo.
- Novo teste `test/enter_group_page_test.dart` (1 teste: app bar + voltar → home).

## ✅ 20.2 Toque "dessincronizado" no PWA iOS (botão registra no de baixo)
- Sintoma: no PWA instalado (não no navegador), depois de focar um `TextField`
  e dar um **double-tap**, os botões pareciam deslocados (ex.: tocar
  "+1 BEBIDA" acionava "Adicionar Foto", logo abaixo).
- Causa: bug conhecido do **Flutter web em PWA iOS**
  ([flutter/flutter#115829](https://github.com/flutter/flutter/issues/115829),
  aberto) — o double-tap dispara o *smart-zoom* do Safari, que dessincroniza o
  hit-test do canvas enquanto o layout fica "menor" (como se o teclado ainda
  estivesse aberto). Acontece só no PWA, não na aba do navegador.
- Correção em `web/index.html`:
  - CSS `html, body { touch-action: manipulation; }` — bloqueia o double-tap
    zoom (o iOS **ignora** `user-scalable=no`, então esta é a trava eficaz);
  - viewport `maximum-scale=1.0, user-scalable=no` (Android/outros navegadores).
- Validar no iPhone: focar campo de texto → fechar teclado → usar os botões.

## 🔒 20.3 Privacidade: repo é PÚBLICO — dados de usuários ficam fora do git
- `.gitignore` agora exclui `supabase/migrations/20260810000002_
  contagem_data.sql` e `20260810000003_contagem_accounts.sql` (nomes, hashes
  de senha, URLs de foto). Já aplicados no projeto novo; recuperáveis do
  antigo se preciso. Schema/storage (DDL, sem PII) seguem versionados.

## Verificação
- `flutter test` → ✅ **122/122** (1 novo: `enter_group_page_test.dart`).
- `flutter build web --release --wasm --base-href /` → ✅
  (viewport/touch-action presentes no `build/web/index.html`).
- Deploy: commit em `DEV` → merge em `main` → push (Vercel auto-build).

---
