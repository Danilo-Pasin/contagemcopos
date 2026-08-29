# Relatórios — Contagem

Histórico consolidado de intervenções do projeto, organizado em **ordem
cronológica por data** (um arquivo por dia de trabalho). Dentro de cada
arquivo, cada entrada indica o escopo dominante da mudança:

| Tag | Escopo |
|---|---|
| `[Front-end]` | Flutter/UI/rotas/UX |
| `[Back-end]` | Supabase (SQL, RLS, RPCs, storage) |
| `[Infra]` | Build/deploy/configuração |
| `[Testes]` | Suíte automática |

> Regra de manutenção: mudanças novas ganham um arquivo `AAAA-MM-DD-<tema>.md`
> neste diretório; nada de relatórios soltos na raiz ou em `docs/`.

## Índice

| Data | Arquivo | Resumo |
|---|---|---|
| 2026-08-06 | [2026-08-06-auditoria-p0-robustez.md](2026-08-06-auditoria-p0-robustez.md) | Auditoria técnica · bug P0 (loading infinito) corrigido · QR/link adaptativo |
| 2026-08-07 | [2026-08-07-stats-fim-competicao-endurecimento.md](2026-08-07-stats-fim-competicao-endurecimento.md) | Gráfico de stats · trava RLS pós-prazo · status unknown · countdown |
| 2026-08-10 | [2026-08-10-login-titulos-performance-migracao-supabase.md](2026-08-10-login-titulos-performance-migracao-supabase.md) | Re-vínculo de sessão no login · títulos fixos · foto de perfil · performance P1–P4 · migração para projeto Supabase dedicado · PWA iOS |
| 2026-08-25 | [2026-08-25-fases-abc-performance-pwa-rotas.md](2026-08-25-fases-abc-performance-pwa-rotas.md) | Fases A/B/C (navegação, cache de stats, animações) · prompt de instalação PWA · correções das rotas do grupo (go_router) |
| 2026-08-29 | [2026-08-29-app-ogs-festa-ranking-grupos.md](2026-08-29-app-ogs-festa-ranking-grupos.md) | App OGS da festa · ranking de grupos (mobile/desktop) · correção do layout responsivo do ranking · novos testes (agregação de grupos, janela fixa) · suíte 160 ✅ |

Documentação viva (não-histórica) permanece em `docs/` e `AGENTS.md`.
