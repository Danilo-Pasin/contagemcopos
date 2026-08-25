# 2026-08-10 — Login, títulos, performance e migração Supabase

# CHANGELOG rodada 7 — re-vínculo de sessão no login por conta `[Back-end]`

## ✅ Bug — `403` ao registrar bebida/foto após login (nome+senha)
- Sintoma: `POST /ctg_drinks` → 403 `42501` (RLS) mesmo sendo membro ativo.
- Causa: quem volta por conta pode estar em sessão anônima nova; o participante mantinha o `anon_id` antigo → `auth.uid() != anon_id` → insert bloqueado.
- Correção: RPC `ctg_login_account` re-vincula `ctg_participants.anon_id = auth.uid()` das participações da conta após validar senha (guarda `NOT EXISTS` evita conflito com unique `(group_id, anon_id)`). Imune a spoofing (só roda com senha correta).
- Backfill imediato do participante `dandan` (grupo Fazenda `LTQPKQ`). Migração: `bind_anon_on_account_login`.
- Trade-off documentado: o último dispositivo que logar detém o vínculo de escrita.

---

# CHANGELOG rodada 8 — foto obrigatória ao registrar bebida `[Front-end]`

## ✅ Fluxo "+1 BEBIDA" exige foto
- Escolhe tipo (opcional) → origem da foto (câmera/galeria) → cancelar foto cancela tudo.
- `drink_repository.addDrink` devolve o `id`; `group_session_provider`: novo `addDrinkWithPhoto({drinkType, note, required photoUrl})` vincula `ctg_photos.drink_id`.
- Erros mais precisos: RLS `42501` → "A competição já encerrou."; demais → mensagem genérica.
- Botão "Adicionar Foto" (foto solta) segue funcionando.

---

# CHANGELOG rodada 9 — sistema de títulos (híbrido) `[Front-end]`
- Novas faixas fixas a partir da Lenda (Lenda 💀 20+ … Papo de Reabilitação 🙏 99+); 3 primeiras proporcionais à meta.
- `TitleTier.absoluteMin` + `thresholdsFor(maxGoal)` com carry-forward monotônico.

# CHANGELOG rodada 10 — títulos 100% por copos + perfil `[Front-end]`

## ✅ Títulos fixos em copos
- Aprendiz 🍺 5 · Cachaceiro 🍻 10 · Rei do Boteco 👑 15 · Lenda 💀 20 · Imperador 🏆 30 · Mito 🔥 40 · Deus da Geladeira 👑👑 50 · Farmador de aura ✨ 67 · Alcoólatra Supremo 🍾 76 · O Sigma Verdadeiro 🐺 88 · Papo de Reabilitação 🙏 99. Sem lógica de %.

## ✅ Foto de perfil editável no mini-dashboard
- Toque no avatar → upload como avatar → atualiza `ctg_participants.photo_url` (`updateProfilePhoto`) + perfil local. Selo 📷 indica tocável. RLS `ctg_part_update` ok.

## ✅ Coroa para líder; escudo para criador
- `app_avatar.dart`: `isLeader` → 👑 para o 1º lugar; `isCreator` → 🛡️.

---

# CHANGELOG rodada 11 — otimização de performance P1–P4 `[Front-end] [Infra]`
- **Startup:** ICU `initializeDateFormatting('pt_BR')` pós-frame; removido `google_fonts` — Inter variable bundled (`assets/fonts/Inter-Variable.ttf`, `fontFamily: 'Inter'`).
- **Realtime coalescido:** debounce `_scheduleRefresh()` de 400ms (burst de ~3 canais + polling → 1 refresh), flag in-flight + re-queue, diff antes de setar state.
- **Imagens:** `memCacheWidth/Height` — avatar 256px, feed 640px, álbum 400px.
- **Stats:** SELECT por visita (não por bebida).
- **Wasm:** `scripts/vercel_build.sh` com `--wasm`; feed em `RepaintBoundary`.

---

# CHANGELOG rodada 12 — migração para projeto Supabase dedicado `[Back-end] [Infra]`
- Novo projeto `qzfqkldzvoqvxytvaoaa` (SA/São Paulo) substitui o compartilhado.
- Migrações: schema completo, storage (buckets `drinks`/`avatars`), dump de dados, 14 contas (hash preservado). URLs de mídia reescritas.
- Realtime publicado nas 8 tabelas `ctg_*` (`ctg_accounts` fora — login via RPC).
- Smoke test e2e REST anon OK (signup → grupo → participante → drink → ranking → triggers).
- ⚠️ Cutover: anônimos antigos viram "novos" (limpeza manual de órfãos); rollback disponível (projeto antigo intacto).

---

# CHANGELOG rodada 13 — voltar no "Entrar em um grupo" + toque PWA iOS `[Front-end]`

## ✅ Botão voltar na EnterGroupPage
- AppBar com seta → home. Teste novo (`enter_group_page_test.dart`).

## ✅ Toque "dessincronizado" no PWA iOS
- Bug conhecido do Flutter web em PWA iOS (flutter/flutter#115829): double-tap dispara smart-zoom do Safari dessincronizando o hit-test.
- `web/index.html`: CSS `touch-action: manipulation` (trava eficaz; iOS ignora `user-scalable=no`) + viewport `maximum-scale=1.0, user-scalable=no`.

## 🔒 Privacidade
- Repo é público: `.gitignore` exclui dumps com PII (`contagem_data.sql`, `contagem_accounts.sql`).

Verificação: 122/122 testes · build wasm ✅.
