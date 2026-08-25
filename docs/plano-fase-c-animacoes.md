# PLANO — Fase C: Percepção de velocidade (animações)

> As animações de entrada (`flutter_animate`) com delays encadeados somam
> centenas de ms à percepção de lentidão ao abrir páginas — e hoje **repetem a
> cada remontagem**. Este plano padroniza durações e garante que animações de
> entrada rodem uma única vez. É a fase de menor risco; aplicar por último.
>
> Status: ✅ Implementado · Prioridade: BAIXA · Impacto: perceção/UX · Risco: muito baixo
> Nota: com a Fase A (indexedStack), as abas param de remontar e estas animações
> naturalmente passam a rodar 1× por sessão — reavaliar o inventário APÓS A.

---

## 1. Diagnóstico — inventário atual

Delays/durações encontrados (grep `\.animate\(`):

| Arquivo | Animações | Pior caso |
|---|---|---|
| `home_page.dart:66-136` | logo `.scale(600ms, elasticOut)` + `.shimmer(delay: 800ms)`; CTAs `fadeIn` delay 200/300/500ms | **~800-1100ms** até último elemento |
| `join_group_page.dart:228-305` | scale 500ms; fadeIn delays 200/300/380/400ms | ~900ms |
| `share_page.dart:68-149` | fadeIn delays 0/150/300/350ms | ~350ms+ |
| `feed_page.dart:60` | animação por tile da lista | repete a cada rebuild da lista |
| `ranking_page.dart:106` | animação por item do pódio/lista | idem |
| `album_page.dart:93` | animação por tile da grade | idem |
| `hall_of_fame_page.dart:115` | animação de entrada | — |
| `create_group_page.dart:207` | slideX 300ms | ok |
| `group_home_page.dart:460` | animação de seção | ok |
| `enter_group_page.dart:94` | animação de entrada | ok |

Problemas concretos:

1. **Staggers longos** (home/join): conteúdo importante (CTAs) aparece até
   ~500ms depois do paint — soma ao "carregando".
2. **Animações de lista repetem** em cada rebuild de feed/ranking/álbum (com
   realtime coalescido + polling, há rebuilds regulares → itens "piscam"/reanimam).
3. Sem padrão central: cada página define seus próprios delays.

---

## 2. Mudanças propostas

### 2.1 Tokens de animação centralizados

**Arquivo:** `lib/core/theme/app_tokens.dart` (já concentra `AppSpacing`,
`AppRadius` — mesmo padrão)

```dart
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const entrance = Duration(milliseconds: 300); // teto p/ entradas
  static const stagger = Duration(milliseconds: 60);   // entre itens
}
```

Regra de projeto: **nenhuma entrada de página passa de ~300ms** do primeiro
paint até o último elemento; CTAs nunca esperam mais que 150ms.

### 2.2 Páginas de fluxo (home / join / share / hall-of-fame)

**Arquivos:** `home_page.dart`, `join_group_page.dart`, `share_page.dart`,
`hall_of_fame_page.dart`, `enter_group_page.dart`

- Reduzir delays encadeados para escala `AppMotion.stagger`
  (ex.: home 200/300/500ms → 40/80/120ms; durações 600ms→300ms).
- `home_page.dart:66`: manter o scale elástico do logo (assinatura visual),
  mas reduzir para ~400ms e garantir que os CTAs não dependam dele.
- `.shimmer(delay: 800.ms)` do logo: avaliar tornar `repeat:` limitado ou
  remover — shimmer infinito custa paint contínuo na home.

### 2.3 Listas (feed / ranking / álbum) — animar só na inserção

**Arquivos:** `feed_page.dart:60`, `ranking_page.dart:106`, `album_page.dart:93`

- Hoje o `.animate()` em cada tile re-executa quando o widget é recriado
  (refresh coalescido cria listas novas).
- Estratégia recomendada:
  - Animar apenas os itens novos após o primeiro load: guardar o tamanho
    anterior da lista no State e aplicar `.animate()` somente aos índices
    >= tamanho anterior (padrão simples e sem deps novas);
  - Alternativa mínima: animar apenas os primeiros N tiles (ex.: 8) com
    stagger curto e deixar o resto estático;
  - Em hipótese nenhuma animar em cima de `RepaintBoundary` recém criado em
    burst de realtime (evitar jank duplo).

### 2.4 O que NÃO mudar

- Transições de navegação padrão do GoRouter/Material (já leves).
- Confete de liderança (`confetti`) — é feedback funcional, não entrada.
- Animações de botões/feedback de toque.

---

## 3. Riscos e cuidados

| Risco | Mitigação |
|---|---|
| Perda de identidade visual (elastic/shimmer) | Manter logo animado; reduzir, não remover |
| Regressão em testes de widget que esperam widgets animados | Rodar suíte completa; animações não devem bloquear hit-test (`animate` não impede) |
| Stagger muito curto parece "bug visual" | Validar em device real (PWA iOS é o público-alvo principal) |

---

## 4. Validação

1. `flutter build web --release --wasm` ✅ · `flutter test` ✅ (122+).
2. **Teste funcional (`flutter run -d chrome`):**
   - Home: todos os CTAs interativos < 200ms após o paint (clicável cedo,
     mesmo com fade em andamento).
   - Feed/Ranking/Álbum: registrar bebida em outro navegador → lista atualiza
     **sem** reanimar itens antigos (sem flash/piscada).
   - Performance overlay ligado durante 30s na aba Feed com realtime ativo:
     sem barras vermelhas (jank) nas atualizações.
3. Critério de aceite: nenhuma tela tem elemento essencial (texto/CTA) que
   demore > 300ms para aparecer após o primeiro frame; listas não reanimam em
   refresh de dados.

---

## 5. Registro de implementação (2026-08-25)

Implementado conforme o plano:

### 5.1 `lib/core/theme/app_tokens.dart` — tokens centralizados
- Novo `AppMotion`: `fast` (150ms), `normal` (250ms), `entrance` (300ms,
  teto de entradas) e `staggerMs` (40ms entre itens).
- Regra documentada no código: última entrada essencial ≤ ~300ms do primeiro
  paint; CTAs esperam no máx. ~150ms.

### 5.2 Páginas de fluxo — staggers reduzidos
| Página | Antes (pior caso) | Depois |
|---|---|---|
| `home_page.dart` | logo 600ms + shimmer 800ms; CTAs até 700ms | logo scale 400ms + shimmer 150ms; delays 150/80/120/140/170/200ms, durações ≤ 300ms |
| `join_group_page.dart` | scale 500ms; delays até 400ms | scale `entrance`; delays 150/80/120/160ms |
| `share_page.dart` | delays até 350ms | delays 0/150/80/120ms |
| `enter_group_page.dart` | delay 100ms, slide 300ms | delay `fast`, slide `entrance` |
| `hall_of_fame_page.dart` | stagger 60ms/item | stagger `AppMotion.staggerMs` (40ms), slide `entrance` |

Logo da home mantém o elasticOut (assinatura visual) e o shimmer roda uma
única vez (comportamento padrão do flutter_animate) com delay curto.

### 5.3 Listas — animar apenas itens novos
- **Estratégia escolhida** (das duas sugeridas): conjunto de IDs já exibidos
  (`_seenIds`) + flag `_bootstrapped`. Na primeira carga, todos os itens
  animam com stagger curto (teto de 8 × 40ms); nos builds seguintes, só
  itens com ID inédito animam (delay zero) — refresh de realtime/polling não
  reanima nada.
- `feed_page.dart`: `ConsumerWidget` → `ConsumerStatefulWidget` (`ActivityItem.id`).
- `ranking_page.dart`: idem (`ParticipantEntity.id`).
- `album_page.dart`: lógica adicionada ao State existente (`PhotoEntity.id`).
- Nota: itens abaixo da dobra são marcados como "vistos" quando construídos
  (builder lazy do Sliver) — podem animar sem delay ao entrar na viewport,
  igual ao comportamento anterior.

### 5.4 O que NÃO mudou (conforme plano)
- Transições de navegação, confete de liderança, feedbacks de toque,
  `create_group_page.dart:207` e `group_home_page.dart:460` (já leves).

### 5.5 Validação executada
- `flutter build web --release` ✅ · `flutter test` ✅ (137 testes).
- ⏳ Pendente (manual, `flutter run -d chrome`): CTAs clicáveis < 200ms;
  listas sem flash em realtime; performance overlay sem jank por 30s no Feed.
