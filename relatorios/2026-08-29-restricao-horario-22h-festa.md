# 2026-08-29 — Restrição de horário (bloqueio de bebidas/fotos antes das 22h)

> Implementação da restrição de horário para a festa OGS de 29→30/08: **ninguém
> pode registrar bebidas nem fotos antes das 22h**, com contagem regressiva em
> tempo real na tela. Aplicada em **camadas duplas** (front-end **e** backend
> via RLS), na branch `festa-2026`.

## Decisões confirmadas

- Bloqueia **somente** o registro de **bebidas** e **fotos** antes das 22h.
  Criar/entrar em grupo, navegar e ver o ranking continuam liberados.
- Novos membros podem **entrar** antes das 22h, mas **não** registrar bebidas.
- Janela fixa (sem seletor): `festaStart = 29/08/2026 22:00`,
  `festaEnd = 30/08/2026 06:00` (8 horas) — `AppConfig.festaStart`/`festaEnd`
  em `lib/core/config/app_config.dart`.
- Contagem regressiva no formato `HH:MM:SS` até o início.

## O que mudou

### Domain — `lib/domain/entities/group_entity.dart`

- Novo método `canLogDrinks({now})`:
  `isActive && !now.isBefore(startDate) && now.isBefore(endDate)`.
- `acceptsEntries` foi **preservado** (continua sendo usado por
  `join_group_page.dart` na entrada de membros) — entrada continua livre antes
  das 22h.

### Front — `lib/presentation/pages/group/group_home_page.dart`

- `running` agora usa `session.group!.canLogDrinks()` (antes era
  `acceptsEntries()`).
- `_ticker` passou para intervalo fixo de **1s** (para a contagem regressiva).
- Aviso **"🎉 A festa começa em HH:MM:SS"** exibido acima do botão +1 quando o
  grupo **não** pode registrar ainda (antes do início).

### Utils — `lib/core/utils/date_time_x.dart`

- Novo `DateTimeX.timeUntilStart(start, {now})`: formata o tempo até o início
  como `dd:HH:MM:SS` (ou `HH:MM:SS` quando < 24h), retornando `"00:00:00"` se
  o início já tiver passado.

### Backend (Supabase — RLS) — migration `block_drinks_photos_before_party_start`

- Policies **`ctg_drinks_insert`** e **`ctg_photos_insert`** agora incluem a
  condição `AND g.start_date <= now()` (antes só checavam
  `status = 'active' AND end_date > now()`). Ou seja: o **backend também**
  rejeita inserts de bebida/foto enquanto a festa não começou — proteção real,
  mesmo que o front seja burlado.
- Foto de **perfil** usa Storage (`uploadAvatar`), **não** `ctg_photos`, então
  não é afetada.

## Testes

- `test/group_session_state_test.dart` — novo bloco `GroupEntity.canLogDrinks`
  (6 casos): dentro da janela = true; antes do início = false; exatamente no
  início = true; após o fim = false; encerrado = false; e independência de
  `acceptsEntries` (entrada liberada + registro bloqueado antes do início).
- `test/data_model_test.dart` — `canLogDrinks` respeita a janela da festa a
  partir do mapeamento `GroupModel.toEntity` (dentro/antes/após/início + entrada
  liberada).

## Validação

- `flutter test` → **167 testes passando**.
- `flutter build web --release` → compila sem erros (`flutter analyze` segue
  quebrado pelo acento no caminho "Programação", conforme convenção do projeto).
- Advisors de segurança do Supabase: apenas avisos **pré-existentes**
  (views/functions `SECURITY DEFINER`, extensão `pg_net`) — nenhum relacionado
  a esta mudança.

## Arquivos alterados/novos (neste commit)

- `lib/domain/entities/group_entity.dart`
- `lib/presentation/pages/group/group_home_page.dart`
- `lib/core/utils/date_time_x.dart`
- `lib/core/constants/title_system.dart` (já cometido em `3bfd476`)
- `lib/presentation/widgets/add_to_homescreen_prompt.dart` (cometido em `190a7be`)
- `lib/presentation/widgets/app_buttons.dart` (cometido em `190a7be`)
- `lib/presentation/pages/create_group/create_group_page.dart` (cometido em `3bfd476`)
- `test/group_session_state_test.dart`
- `test/data_model_test.dart`
- `test/title_system_test.dart` (cometido em `3bfd476`)
- `docs/plano-restricao-horario-22h.md` (novo — plano completo)

## Nota

`docs/.Rhistory` permanece **não rastreado** (fora do commit).
