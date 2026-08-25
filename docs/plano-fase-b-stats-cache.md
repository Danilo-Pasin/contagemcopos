# PLANO — Fase B: Cache de estatísticas (fim do SELECT por visita)

> A página de Estatísticas executa um `SELECT` completo de `ctg_drinks` a cada
> visita à aba. Este plano move o carregamento/agregação para um provider com
> TTL, tornando a aba instantânea após a primeira visita e eliminando queries
> repetidas — complementando a Fase A (estado vivo entre abas).
>
> Status: ✅ Implementado · Prioridade: MÉDIA · Impacto: médio · Risco: baixo
> Dependência: idealmente aplicada DEPOIS da Fase A.

---

## 1. Diagnóstico

**Arquivo:** `lib/presentation/pages/stats/stats_page.dart`

- `_loadStats()` (linhas 30-97) faz `client.from('ctg_drinks').select(...).eq('group_id', groupId)`
  — **tabela inteira de bebidas do grupo** — e agrega em memória (por dia e por
  pessoa/tipo).
- Guarda atual `_loadedKey` (linha 120): recarrega **uma vez por grupo**, mas:
  - Com o comportamento atual (provider morre a cada troca de aba), a página é
    remontada ao voltar para a aba... porém `_StatsPageState` também é recriado,
    então `_loadedKey == null` → **o SELECT roda em toda visita à aba**
    (a guarda só sobrevive enquanto o State vive).
  - Após a Fase A (indexedStack), o State passa a viver e a guarda passa a
    funcionar — mas os dados ficam **congelados para sempre** até pull-to-refresh.
- Conclusão: precisamos de cache com **invalidação inteligente**, não apenas da
  guarda atual.

---

## 2. Mudanças propostas

### 2.1 Novo provider de estatísticas

**Arquivo novo:** `lib/presentation/providers/stats_provider.dart`

```dart
class StatsState {
  final List<({String label, int value})> daily;
  final List<PerPersonTypes> perPerson;
  final bool loading;
  final DateTime? fetchedAt;      // base do TTL
  final Object? error;
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier(this._ref, this._groupId) : super(...) { _load(); }

  static const _ttl = Duration(seconds: 60);

  Future<void> _load() async { ... }        // query + agregação (hoje na page)
  Future<void> forceRefresh() => _load();   // pull-to-refresh
}

final statsProvider = StateNotifierProvider.autoDispose
    .family<StatsNotifier, StatsState, String>((ref, groupId) ...);
```

Comportamento:

- **Load inicial:** ao criar (primeira visita à aba no grupo).
- **TTL de 60s:** se a página volta a ser exibida após o TTL, recarrega em
  background (stale-while-revalidate: mostra dados antigos, atualiza por baixo).
  Implementação: a página chama `notifier.ensureFresh()` no build/init; o
  notifier compara `DateTime.now() - fetchedAt > _ttl`.
- **Invalidação por evento:** expor `statsProvider.notifier(groupId).invalidate()`
  (zera `fetchedAt`) e chamá-lo de `group_session_provider.dart` em
  `addDrinkWithPhoto()` e `addPhoto()` (linhas 295-332) — sem refetch imediato;
  a próxima visita à aba busca fresco. Alternativa mais simples: ouvir
  `groupSessionProvider` dentro do statsProvider e invalidar quando
  `totalGroupDrinks` mudar. Escolher UMA das duas na implementação.
- **autoDispose.family por groupId**: com a Fase A, o cache vive enquanto o app
  está no grupo; sai do grupo → memória liberada.

### 2.2 Mover a agregação para fora da UI

**Arquivos:** `lib/presentation/providers/stats_provider.dart` (+ opcionalmente
`lib/data/repositories/drink_repository.dart`)

- Transferir o corpo de `_loadStats` (query + agregações `byDay`, `personMap`,
  ordenações) para um método de repositório, ex.:
  `DrinkRepository.fetchStatsRaw(groupId)` retornando as linhas brutas, e a
  agregação pura num helper testável (`lib/core/utils/` ou dentro do provider):
  `(List rows, List<ParticipantEntity> ranking) → StatsState`.
- Benefício extra: a lógica de parsing defensivo (`DateTime.tryParse`,
  linhas 44-49) ganha testes unitários.

### 2.3 Simplificar a página

**Arquivo:** `lib/presentation/pages/stats/stats_page.dart`

- Remover `_daily/_perPerson/_loading/_loadedKey`, `_loadStats`, `_reload`
  (linhas 24-106).
- A página vira `ConsumerWidget`: `final stats = ref.watch(statsProvider(groupId));`
  + `RefreshIndicator(onRefresh: () => ref.read(statsProvider(groupId).notifier).forceRefresh())`.
- Manter intactos: empty state de ranking (linhas 125-141), cards métricas,
  `_DailyChart`, `_TitleDistribution`, `_PerPersonTypesCard`.
- Aproveitar para receber `code` via construtor (após Fase A) e eliminar o
  `_extractCode` com regex (linhas 254-258).

---

## 3. Riscos e cuidados

| Risco | Mitigação |
|---|---|
| Dados defasados após nova bebida (janela do TTL) | Invalidação no ato de registrar bebida/foto + stale-while-revalidate |
| Grupo grande → query pesada | Sem mudança de query nesta fase (fase futura pode agregar via view/RPC SQL, ex. `ctg_stats_view`); TTL já elimina repetição |
| Dois mecanismos de invalidação conflitantes | Escolher UM (callback direto do session provider OU listener); documentar no código |
| autoDispose sem ouvinte durante pull-to-refresh | Usar `ref.keepAlive()` enquanto refresh em voo, ou watch contínuo da página |

---

## 4. Validação

1. `flutter build web --release --wasm` ✅ · `flutter test` ✅.
2. **Novos testes unitários:** agregação (dias fora de ordem, `created_at`
   inválido, participante sem nome no ranking, tipos múltiplos) e TTL
   (`ensureFresh` respeita `fetchedAt`; `forceRefresh` ignora).
3. **Teste funcional (`flutter run -d chrome`):**
   - Abrir Estatísticas → 1 request de `ctg_drinks` na Network tab.
   - Sair e voltar à aba em < 60s → **zero requests novos**, render instantâneo.
   - Registrar +1 bebida → voltar à aba Estatísticas → gráfico atualizado
     (1 request novo, via invalidação).
   - Pull-to-refresh força 1 request mesmo dentro do TTL.
   - Gráfico "Bebidas por dia" e "Tipos por pessoa" idênticos aos de antes da
     refactor (regressão visual com grupo real).
4. Critério de aceite: no máx. 1 query de stats por minuto de uso ativo,
   exceto invalidação/pull-to-refresh.

---

## 5. Registro de implementação (2026-08-25)

Implementado conforme o plano. Decisões tomadas na implementação:

### 5.1 Mecanismo de invalidação (escolha única, conforme plano)
Escolhida a **chamada direta** do `GroupSessionNotifier`: `_invalidateStats()`
em `addDrinkWithPhoto()` e `addPhoto()`, com guarda `ref.exists()` para não
criar o provider se a aba nunca foi visitada (evita SELECT fantasma).
Descartado o listener de `totalGroupDrinks`.

**Desvio do plano (justificado):** o plano previa "sem refetch imediato — a
próxima visita busca fresco". Com o IndexedStack da Fase A, porém, voltar à
aba **não dispara rebuild**, então o refetch nunca aconteceria até o
pull-to-refresh. Solução: `invalidate()` zera `fetchedAt` E recarrega em
background com stale-while-revalidate (dados antigos visíveis durante o
refetch), com dedup via fila (`_reloadQueued`) para bebidas em rajada.

### 5.2 `lib/presentation/providers/stats_provider.dart` (novo)
- `StatsState` tipado: `daily` (`List<DailyStat>`), `perPerson`
  (`List<PerPersonTypes>`), `loading`, `fetchedAt` (base do TTL), `error`.
- `aggregateDrinkRows(rows, ranking)`: agregação pura e testável
  (parsing defensivo de `created_at`, fallback "Participante", ordenações).
- `StatsNotifier` com dependências injetadas (`fetchRows`,
  `currentGroupId`, `currentRanking`, `ttl`, `now`) → testável sem Supabase.
  API: `ensureFresh()` (TTL 60s, SWR), `forceRefresh()` (pull-to-refresh),
  `invalidate()` (evento de bebida/foto; coalescido se load em voo).
- `statsProvider`: `autoDispose.family` por código de grupo.

### 5.3 `lib/data/repositories/drink_repository.dart`
- Novo `fetchStatsRaw(groupId)` — query movida da página para o repositório.

### 5.4 `lib/presentation/pages/stats/stats_page.dart`
- De `ConsumerStatefulWidget` (com `_daily/_perPerson/_loading/_loadedKey/`
  `_loadStats/_reload`) para `ConsumerWidget` enxuto.
- Recebe `code` via construtor (elimina `_extractCode` regex).
- Widgets internos migrados para tipos (`_DailyChart`, `_PerPersonTypesCard`,
  `_PersonTypesRow`). Empty state, métricas e distribuição de títulos intactos.

### 5.5 `lib/core/router/app_router.dart`
- Branch de stats passa `state.pathParameters['code']!` ao construir a página.

### 5.6 Testes
- `test/stats_provider_test.dart` (novo): 13 testes — agregação pura (dias
  fora de ordem, `created_at` inválido, participante desconhecido, tipos
  múltiplos ordenados, pessoas por total desc, `drink_type` nulo) e notifier
  (primeira carga, TTL respeitado, expiração com SWR, forceRefresh ignora
  TTL, invalidate força refetch, dedup de invalidate em voo, grupo não pronto,
  erro preservado). Requer `initializeDateFormatting('pt_BR')`.
- Suíte completa: **137 testes ✅** · build web ✅.
- ⏳ Pendente: teste funcional manual (`flutter run -d chrome`) conforme seção 4.
