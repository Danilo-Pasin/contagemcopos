---
description: Contexto e regras do projeto Contagem (Flutter Web PWA + Supabase). Use em QUALQUER tarefa neste projeto — build, testes, arquitetura, convenções, backend ou changelog. Carregar sempre antes de editar código.
---

# Contagem — Workflow do Projeto

App social de contagem de bebidas ("Copa das Bebidas"). Flutter Web PWA +
Supabase (Postgres/Realtime/Storage/RLS/Anonymous Auth).

## Build e validação

- **Typecheck/compile check = `flutter build web --release`** (ou `--wasm`, que
  é o build de produção usado pela Vercel).
  - NUNCA sugira/confie em `flutter analyze` como verificação principal: o
    caminho do projeto contém "Programação" (caractere especial) e quebra o LSP.
- **Testes: `flutter test`** — suíte completa em `test/` (122+ testes).
  Rodar antes de encerrar qualquer mudança de código.
- Rodar local: `flutter run -d chrome`.

## Regras invioláveis

1. **Sem commit sem pedido explícito do usuário.**
2. **O repo é PÚBLICO** — nenhum dado de usuário no git (nomes, hashes,
   URLs de foto). Dumps com PII já estão no `.gitignore`
   (`20260810000002_contagem_data.sql`, `..._contagem_accounts.sql`).
3. Rotas sempre via constantes `AppRoutes.*` (`lib/core/router/app_routes.dart`)
   — nunca paths hardcoded (lição da rodada 6; bug P0 das rotas duplicadas).
4. Erros RLS `42501` em insert → mensagem amigável "A competição já encerrou."
   (padrão centralizado nos providers/pages, rodada 8).

## Arquitetura (Clean Architecture)

```
lib/
├── core/           config (app_config), tema (app_theme/app_tokens),
│                   router (app_router/app_routes), constants, utils, extensions
├── data/           models (DTOs *_model.dart), repositories, services
├── domain/         entities (*_entity.dart)
└── presentation/   providers (Riverpod), pages, widgets (design system)
```

Padrões vigentes:
- Estado: Riverpod `StateNotifierProvider` (sem hooks_riverpod em uso).
- Sessão de grupo: `groupSessionProvider` (`presentation/providers/group_session_provider.dart`)
  — refresh coalescido (debounce 400ms) para realtime + polling 20s.
- Identidade anônima: `identityProvider` (sign-in anônimo Supabase).
- Fonte Inter bundled (sem google_fonts); ICU de datas pós-primeiro-frame.

## Backend Supabase

- Projeto dedicado: `qzfqkldzvoqvxytvaoaa` (São Paulo). Antigo (compartilhado):
  `cxuurozyyfcqxywhsiyt`.
- Tabelas com prefixo `ctg_*`; RPCs `ctg_create_group`, `ctg_end_expired_groups`,
  `ctg_login_account`; view `ctg_ranking_view`.
- Requer **Anonymous Auth habilitado**.
- Migrations em `supabase/migrations/`. Realtime publicado nas 8 tabelas `ctg_*`.
- MCP Supabase disponível na config global do opencode.

## Histórico / contexto

- Relatórios por data em `relatorios/` (índice no `relatorios/README.md`;
  arquivos `AAAA-MM-DD-<tema>.md`, cronológicos). Mudanças novas ganham
  arquivo novo nesse diretório — nada de relatórios na raiz ou em `docs/`.
  Inclui auditoria técnica, bug P0 de loading infinito, migração de projeto
  Supabase, otimizações P1–P4 e Fases A/B/C (já implementadas).
- Testes: `docs/testing.md`. Logo/assets: `docs/logo.md`.
