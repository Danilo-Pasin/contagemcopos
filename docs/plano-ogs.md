# Plano — App "OGS" (festa 29→30/08/2026)

> Plano de implementação para transformar o app genérico "Contagem — Copa das
> Bebidas" no app específico **OGS** para a festa de amanhã. Baseado na análise
> do código (rotas, páginas, providers, repositórios e schema Supabase).
> Executado na branch `festa-2026`.

## Dados da festa

| Item | Valor |
|---|---|
| Nome do app | **OGS** (título único) |
| Início | 29/08/2026 22:00 |
| Fim | 30/08/2026 06:00 (8h) |
| Database | Reutilizar a mesma (limpa antes da festa); remoções só no front |
| Logo | `docs/logo.png` (644×634, RGBA, **fundo preto opaco**) |

---

## 1. Logo — adaptação às densidades e uso

**Imagem-fonte:** `docs/logo.png` (644×634). Problema: **fundo preto opaco** no
entorno (não transparente) — sobre o gradiente da home viraria um bloco preto.
Origem quase quadrada (não exata).

Uso do **Pillow** (disponível, PIL 11.3.0) — implementado em
`tool/gen_icons.py`:

1. **Remover fundo preto → transparente** usando o sinal de dominância do verde
   (`G - max(R,B)`, com `alpha = (score/60)**2`), que preserva o desenho verde e
   as bordas anti-aliasadas (mais robusto que limiar por cor de canto).
2. Gerar saídas:
   - `assets/logo.png` (644×634 transparente, home/AppBar)
   - `web/icons/Icon-192.png` (192×192, logo ~82%)
   - `web/icons/Icon-512.png` (512×512, logo ~82%)
   - `web/icons/Icon-maskable-192.png` / `Icon-maskable-512.png` (safe zone ~20%,
     logo ~60%)
   - `web/favicon.png` — logo composta sobre o fundo do app `#0B0E14`
     (favicon não suporta transparência preta)
3. `docs/logo.md` atualizado (fonte + pipeline).
4. Validação: `docs/logo-preview.png` (logo sobre fundo escuro e claro).

> ⚠️ **Validação visual:** o modelo não enxerga imagens — a conferência visual
> do resultado (remoção de fundo) fica **com o usuário** em `docs/logo-preview.png`.

---

## 2. Nome — trocar para "OGS"

- Centralizar num `const` único (ex.: `AppBrand.name` em `app_config.dart` ou
  `app_tokens.dart`).
- Substituir textos:
  - Home: `Contagem` → `OGS`, `Copa das Bebidas`/subtítulo → texto da festa.
  - `web/manifest.json` (name / short_name).
  - `web/index.html` (title + meta og).
  - Títulos de página onde couber.

---

## 3. Criar grupo — remover meta e período

Arquivos: `lib/presentation/pages/create_group/create_group_page.dart`,
`lib/core/constants/competition_periods.dart` (uso),
`lib/core/constants/title_system.dart` (parcial).

- Remover do form: seletor de **meta** (🆓 Sem meta / 🎯 Por meta + valor) e
  seletor de **período** (presets + "Personalizado").
- Fixar internamente: `start = 29/08 22:00`, `end = 30/08 06:00`,
  `maxGoal = kNoGoalMaxGoal` (sem meta). Assinatura do RPC `ctg_create_group`
  permanece (recebe valores fixos) — **sem migração**.
- Manter: nome do grupo, ícone (emoji), perfil (nome + foto), senha (login).
- Simplificar o resumo exibido (duração fixa "8 horas").
- Countdown / `acceptsEntries` seguem funcionando com `end_date` fixo.

---

## 4. Estatísticas — "bebidas por dia" → "bebidas por hora"

Arquivos: `lib/presentation/providers/stats_provider.dart`,
`lib/presentation/pages/stats/stats_page.dart`,
`lib/core/utils/date_time_x.dart`.

- `aggregateDrinkRows`: nova agregação `byHour` (agrupar por hora local `HH:00`).
  Novo `HourlyStat(label: '22h', value)`.
- `_DailyChart` → `_HourlyChart` (barras por hora 0–23h; eixo X com hora;
  título do card "Bebidas por hora").
- Manter demais cards (total, média, mais ativo, fotos) e "tipos por pessoa" e
  "distribuição de títulos" (fora do escopo de remoção).

---

## 5. Ranking de grupos (novo)

Arquivos: `lib/presentation/pages/ranking/ranking_page.dart`,
`lib/data/repositories/{drink,group}_repository.dart`, novo provider.

- **Métrica:** soma total de `ctg_drinks` por `group_id` (todos os grupos).
- **Dados:** agregação por `group_id` + `name`/`cover_emoji` via repository
  (sem migração).
- **Visibilidade:** global — visível para qualquer participante de qualquer grupo.
- **UI (aba Ranking):**
  - **Mobile:** empilhado — topo = ranking de usuários (com pódio), abaixo =
    ranking de grupos.
  - **Desktop:** lado a lado (2 colunas: usuários | grupos).
- **Realtime:** mesmo padrão dos demais.

---

## Ordem de execução

1. Nome → "OGS" (constante + textos + manifest/PWA)
2. Criar grupo: remover meta/período, fixar janela 22h→06h
3. Estatísticas: agregar por hora
4. Ranking de grupos (repo + provider + UI responsiva)
5. Logo: remover fundo + gerar assets/ícones PWA (**com validação do resultado**)
   + atualizar `docs/logo.md`
6. `flutter build web --release` (compilação) + `flutter test` (suíte)

---

## Notas

- Base de dados reutilizada; antes da festa o usuário limpará os dados.
- O que for remoção de funcionalidade é só no front, sem migração.
- Reportar erros/validações no `docs/QAS-testes.md` após a festa.
