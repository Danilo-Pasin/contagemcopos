# Plano — Restrição de horário (só registrar bebidas/fotos a partir das 22h)

> Documento de contexto para retomar o trabalho caso o estado da sessão seja
> perdido. Criado em 29/08/2026.

## Contexto

Festa OGS: começa **29/08/2026 22:00** e termina **30/08/2026 06:00**
(`AppConfig.festaStart` / `AppConfig.festaEnd` em `lib/core/config/app_config.dart`).

Hoje o app permite registrar bebida a qualquer hora **antes do fim** (`endDate`),
inclusive antes das 22h. A política RLS de inserção também só valida
`status='active' AND end_date > now()` — sem checar o início.

Queremos bloquear **+1 bebida** e **Adicionar Foto** antes das 22h, mantendo o
resto do app utilizável (criar/entrar/navegar).

## Decisões confirmadas com o usuário

1. **Só** bloquear adicionar bebidas/fotos — criar, entrar e navegar continuam
   livres (para os convidados se prepararem antes das 22h).
2. Aplicar no **front + backend (RLS)** — não burlável via API.
3. A tela do grupo mostra **contagem regressiva até o início** (HH:MM:SS).
4. **Entrada de novos membros antes das 22h: liberada.** Por isso NÃO mexer em
   `acceptsEntries` (usado pelo `join_group_page` para liberar entrada); criar um
   método separado `canLogDrinks`.

## Mudanças planejadas

### 1. Domain — `lib/domain/entities/group_entity.dart`
Adicionar (NÃO alterar `acceptsEntries`):

```dart
bool canLogDrinks({DateTime? now}) {
  final n = now ?? DateTime.now();
  return isActive && !n.isBefore(startDate) && n.isBefore(endDate);
}
```

- `startDate` do grupo = `festaStart` (22h), persistido na criação
  (`create_group_page._create`).
- Resultado: false antes das 22h e depois das 6h; true no meio da festa.

### 2. Front — `lib/presentation/pages/group/group_home_page.dart`
- Linha ~216: trocar `running = session.group!.acceptsEntries()` por
  `running = session.group!.canLogDrinks()`.
  - Botão **+1 BEBIDA** (~linha 350) e **Adicionar Foto** (~linha 378) já usam
    `running` → ficam desabilitados antes das 22h automaticamente.
- Adicionar aviso de contagem regressiva até o início, acima do botão +1,
  quando `now < startDate` (ex.: "🎉 A festa começa em 10:58:31").
- Ajustar `_ticker` (linha ~41): usar 1s enquanto `now < startDate` (mostrar
  segundos), voltar a 30s após começar (comportamento atual). OU usar 1s
  constante (barato).
- `_GroupSummary` (countdown até o fim, linha ~486) permanece como está.

### 3. Utilitário — `lib/core/utils/date_time_x.dart`
Adicionar `timeUntilStart(DateTime start, {DateTime? now})` retornando string
`dd:HH:MM:SS` (ou `HH:MM:SS`) até o início, para a contagem regressiva.

### 4. Backend — políticas RLS (migração Supabase)
Adicionar `AND g.start_date <= now()` na regra EXISTS de `ctg_groups` em:
- **`ctg_drinks_insert`** (bloqueia bebida antes das 22h).
- **`ctg_photos_insert`** (bloqueia "Adicionar Foto" e foto da bebida antes das
  22h). A foto de perfil usa **Storage** (`uploadAvatar`), NÃO `ctg_photos`, então
  não é afetada.

Políticas hoje (inspeção via `pg_policy`):
- `ctg_drinks_insert` with_check:
  `EXISTS(participant do grupo) AND EXISTS(grupo active AND end_date > now())`
- `ctg_photos_insert` with_check: idem.

### 5. Testes
- `test/group_session_state_test.dart` e `test/data_model_test.dart`:
  - Adicionar casos de `canLogDrinks`: antes do início → false; entre início e
    fim → true; após fim → false.
  - Manter cobertura existente de `acceptsEntries` (entrada) intacta.

## Validação
- `flutter test` (toda a suíte).
- `flutter build web --release` (valida erros de compilação/LSP — caminho com
  acento quebra o `flutter analyze`).

Hoje é 29/08/2026 ~10:51 (antes das 22h) → a restrição de início é
**imediatamente testável** neste momento.

## Status
- [x] Plano definido e confirmado
- [ ] docs (este arquivo)
- [ ] Domain `canLogDrinks`
- [ ] Front group_home (running + contagem + ticker)
- [ ] DateTimeX `timeUntilStart`
- [ ] RLS `ctg_drinks_insert` + `ctg_photos_insert`
- [ ] Testes
- [ ] flutter test + build release
