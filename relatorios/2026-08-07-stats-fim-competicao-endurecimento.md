# 2026-08-07 — Estatísticas, fim de competição (RLS) e endurecimento

# CHANGELOG rodada 4 (2026-08-07)

## ✅ Stats — gráfico "Bebidas por dia" vazio (bug) `[Front-end]`
- Causa: carregava 1× por grupo (`_loadedGroupId`) e `DateTime.parse` lançava em datas inválidas engolidas por `catch (_) {}`.
- Solução: guarda reativa `groupId + totalGroupDrinks`; `DateTime.tryParse` (linhas inválidas logadas/ignoradas); erro logado.

## ✅ Criar grupo — chip "Personalizado" desalinhado `[Front-end]`
- Chip movido para dentro do `Wrap` dos presets.

## ✅ Novo fluxo "Entrar em um grupo" `[Front-end]`
- Home ganhou CTA → nova `EnterGroupPage` (pergunta código, upper, sem espaços) → `/entrar/:code`.
- Rotas novas: `enterGroup = '/entrar-grupo'` (distinto de `/entrar/:code`).

## ✅ Mini-dashboard — countdown `[Front-end]`
- Helpers `timeLeft(end)` / `timeLeftStat(end)` em `date_time_x.dart`; countdown progressivo (dias→horas→min→seg).
- Gating local: +1 bebida/+foto desabilitados fora do prazo (`running = isActive && now < endDate`).

Verificação: 81/81 testes · build ✅.

---

# CHANGELOG rodada 5 (2026-08-07)

## ✅ Fim de competição imposto no backend `[Back-end]`
Migração `enforce_active_competition_insert`:
- `ctg_drinks` (insert): só com participante do grupo E grupo `active` com `end_date > now()`.
- `ctg_photos` (insert): idem.
- `ctg_participants` (insert): entrada só no prazo. Leituras liberadas.

## ✅ Frontend — mensagens amigáveis `[Front-end]`
- Falha em +1 bebida/foto mostra snack "a competição já encerrou".
- `join_group_page`: pessoa nova vê aviso de encerrado; membro existente continua entrando (leitura).
- `group_entity.dart`: getter central `acceptsEntries({now})` espelhando a regra RLS.

Testes: 86/86 (+5 para `acceptsEntries`).

---

# CHANGELOG rodada 6 (2026-08-07)

## ✅ Status/activity desconhecidos `[Back-end] [Front-end]`
- `GroupStatus.unknown`: status desconhecido nunca mais vira `active`; mapeado/logado em `group_model.toEntity()` (defensivo; banco usa enum).
- `ActivityType.unknown`: `fromString` retorna `unknown` (antes `drinkAdded`); feed ganhou `default` ("fez uma atividade").

## ✅ Crash/consistência `[Front-end]`
- `activity_model.dart`: cast seguro de `payload['url']` (evita crash no feed).
- `identity_provider.dart`: `saveProfile` espelha o nome persistido (trim).

## ✅ Rotas com constantes `[Front-end]`
- `app_router.dart` usa `AppRoutes.*Segment` (anti-typo).

## ✅ Testes novos (+33) `[Testes]`
- `data_model_test.dart`, `identity_notifier_test.dart`, `date_time_x_test.dart` ampliado, `app_routes_test.dart` ampliado. Suíte: **119/119**.
