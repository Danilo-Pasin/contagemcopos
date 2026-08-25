---
description: Contexto das Fases de Performance do projeto Contagem (A/B/C — todas implementadas). Use para consultar decisões tomadas, validar regressões ou planejar novas fases de performance.
---

# Contagem — Fases de Performance

**Status: ✅ A, B e C implementadas em 2026-08-25.** Registro completo das
decisões (incl. desvios justificados dos planos) em
[`relatorios/2026-08-25-fases-abc-performance-pwa-rotas.md`](../../relatorios/2026-08-25-fases-abc-performance-pwa-rotas.md).

## Resumo do que ficou implementado

| Fase | Tema | Resultado |
|---|---|---|
| **A** | `StatefulShellRoute.indexedStack` + provider sem autoDispose | Estado vivo entre abas; zero reload |
| **B** | `statsProvider` com TTL 60s + SWR + invalidação por evento | Fim do SELECT por visita à aba |
| **C** | Tokens `AppMotion` + listas animam só itens inéditos (`_seenIds`) | Entradas ≤300ms; sem flash no realtime |

## Regressões a vigiar

- Qualquer nova rota de aba NÃO pode ter parâmetro como default da branch
  (assertion do go_router em debug). Teste de regressão:
  `test/app_routes_test.dart` instancia o router real.
- Listas novas (grid/lista com realtime) devem seguir o padrão `_seenIds`
  para não re-animar em refresh.
- Novos providers de dados caros: seguir o padrão do `statsProvider`
  (TTL + SWR + invalidação por evento, dependências injetadas p/ teste).
