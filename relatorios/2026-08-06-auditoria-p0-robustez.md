# 2026-08-06 — Auditoria técnica, bug P0 e rodadas de robustez

## Auditoria técnica (contexto)

Fluxo da tela "Entrar no Grupo": usuário digita código na home → `context.push("/g/CODE")` → rota join interceptava (era a PRIMEIRA definida) → `JoinGroupPage._load()` → se já é membro, `context.go(AppRoutes.group(code))` — que produzia o **mesmo path** `/g/CODE` → GoRouter casava novamente na rota join → loop infinito.

| Arquivo | Linha | Problema |
|---|---|---|
| `app_routes.dart` | 11/14 | `join()` e `group()` com path idêntico `/g/$code` |
| `app_router.dart` | 32/42 | rota join definida antes; rota group inalcançável |
| `join_group_page.dart` | 68 | redirect para o mesmo path → loop |

Criticidade: **P0** — app inutilizável após criar/entrar em qualquer grupo.

---

# CHANGELOG rodada 1 (2026-08-06)

## ✅ Bug P0 — Loading infinito CORRIGIDO `[Front-end]`
- `app_routes.dart`: `join(code)` agora retorna `/entrar/$code`; `group(code)` permanece `/g/$code`. Rotas separadas eliminam o conflito.
- `group_shell.dart`: redirect — ao abrir `/g/CODE` sem ser membro, vai para `/entrar/CODE`.
- Removidos artefatos de debug: FAB de auditoria na home, `debugLogDiagnostics`, ~15 `debugPrint` do `_load()`.

## ⏭️ Pendências da rodada
1. `widget_test.dart` quebrado → substituído por `test/app_routes_test.dart` (regressão do P0). ✅
2. `_refreshAll()` com `catch (_) {}` silencioso. ✅ (rodada 2)
3. Supabase: Anonymous Auth + RLS verificados (dados reais: 1 grupo, 8 activities).
4. Deploy do `build/web` em host estático.

---

# CHANGELOG rodada 2 (2026-08-06)

## ✅ Backend verificado `[Back-end]`
- Tabelas `ctg_*` com RLS; RPCs `ctg_create_group`, `ctg_end_expired_groups` + triggers OK; Anonymous Auth ativo (incl. `storage.objects` para avatares/fotos).

## ✅ `_refreshAll()` robusto `[Front-end]`
- `catch (_) {}` → `catch (e, s)` com log. Erro transitório NÃO seta `state.error` (evitaria substituir a tela por erro); polling (20s) e realtime reintentam.

## ✅ `test/app_routes_test.dart` (novo) `[Testes]`
- 5 testes de regressão do P0 (`join()` ≠ `group()`, paths internos complementares). Suíte: 5/5.

## ✅ Home — botão de seta do campo de código `[Front-end]`
- `IconButton` tinha `onPressed` vazio (só Enter navegava). Extraído `_CodeEntryCard` compartilhando navegação via `_submit()`.

---

# CHANGELOG rodada 3 (2026-08-06)

## ✅ QR code / link adaptativo ao host `[Front-end]`
- Problema: link fixo `AppConfig.publicBaseUrl` (`https://contagem.app`) mesmo em localhost.
- Solução: `publicBaseUrlProvider` em `core_providers.dart` — no Web deriva a origem via `Uri.base`; não-web mantém fallback config.
