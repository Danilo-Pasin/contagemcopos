# QA — Plano de Testes Manuais (app Web/PWA "Contagem — Copa das Bebidas")

> Plano de testes **manuais** para validar o app de ponta a ponta (E2E) usando a
> automação de navegador (Chrome DevTools) e a emulação de dispositivo móvel.
> Nenhum código do app é alterado — apenas navegação, interação e anotações.

## Contexto / Visão geral

- **App:** Flutter Web PWA "Contagem — Copa das Bebidas" (estático).
- **Backend:** Supabase dedicado `qzfqkldzvoqvxytvaoaa` (anon auth, RLS, realtime).
- **Rotas principais** (`app_routes.dart`):
  - `/` home
  - `/criar` criar grupo
  - `/entrar-grupo` informar código antes de entrar
  - `/entrar/:code` entrar num grupo pelo link/código
  - `/entrar-login` login por conta (nome + senha)
  - `/g/:code/inicio` · `/g/:code/feed` · `/g/:code/ranking` · `/g/:code/stats` · `/g/:code/album`
  - `/g/:code/inicio/share` · `/g/:code/inicio/hall-of-fame`
- **Ambiente de teste:** build local servido (ex.: `python3 -m http.server 8080 --directory build/web`) **ou** o deploy público `https://contagemcopos.online`.

### Dados de teste sugeridos

| Papel | Nome | Senha | Observação |
|---|---|---|---|
| Criador do Grupo 1 | QA Danilo | `qa12345` | cria grupo e reentra via login |
| Membro do Grupo 1 | QA Membro | `qa54321` | entrou por código |
| Conta de teste (outra) | QA Outro | `qa00000` | login global (nome+senha) |
| Grupo de teste | `QA Copa Teste` | código anotado | período personalizado curto |

> ⚠️ Usar **nomes/senhas de teste únicos** para não colidir com dados reais
> (contas nome+senha são globais: se o nome já existe com outra senha, o RPC
> recusa). A cada rodada, usar sufixo de data, ex.: `QA Danilo 2808`.

---

## Preparação

1. **Garantir sessão anônima limpa:** abrir o app em contexto isolado
   (sem cookies/`localStorage` de sessões anteriores) — usar aba anônima ou
   `clear site data` para cada conta de teste.
2. **Desktop:** `resize` do navegador para ~1440x900.
3. **Mobile:** emular viewport de celular (ex.: `390x844x3,mobile,touch`) para os
   casos sinalizados com **[MOBILE]**.
4. Sempre anotar código do grupo e senhas.
5. Registrar em cada caso: **PASS ✅ / FAIL ❌ / BUG 🐛** + evidência (screenshot).

---

## 1. Home

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 1.1 | Render home | Abrir `/` | Logo, título "Copa das Bebidas", 3 CTAs (Criar, Entrar, Já estou), pills de features |
| 1.2 | Tema dark/light | Clicar no ícone no topo à direita | Alterna entre claro/escuro; **persiste** após reload |
| 1.3 | Animação responsiva **[MOBILE]** | Carregar em viewport mobile | Sem overflow horizontal; conteúdo centralizado pelo `ResponsiveContent`; botões não esticados |
| 1.4 | PWA install prompt **[MOBILE]** | Carregar em mobile após ~1.2s | Bottom sheet "Adicionar à Tela de Início" aparece (1× até dispensar); dispensar some por visita |
| 1.5 | Prompt install não aparece **[DESKTOP]** | Carregar em desktop | **Não** exibe prompt de instalação |
| 1.6 | "Voltar para: X" | Tendo grupo conhecido localmente | Botão aparece ao pé da home e navega de volta ao último grupo |

---

## 2. Criar Grupo (`/criar`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 2.1 | Validação de campos | Tentar criar com campos vazios | Botão "Criar e entrar" desabilitado |
| 2.2 | Criar com preset | Nome + ícone + período preset (ex.: 3 dias) + meta | Cria grupo e entra (redirect `/g/CODE/inicio`) |
| 2.3 | Período personalizado | Ativar "📅 Personalizado", quantidade + unidade | Cards de resumo atualizam (duração e beb/dia); consegue criar |
| 2.4 | Meta por pessoa | Ativar "🎯 Por meta", definir valor | Mostra "Meta por pessoa: X bebidas"; títulos calculados pela meta |
| 2.5 | Sem meta | Manter "🆓 Sem meta" | Resumo "Sem meta definida" |
| 2.6 | Senha mín. 5 | Digitar senha < 5 | Não habilita criar |
| 2.7 | Senha visível/oculta | Toggle do olho | Alterna obscure/visible |
| 2.8 | Foto de perfil | Tocar avatar/câmera e escolher imagem da galeria | Avatar mostra a foto carregada |
| 2.9 | Criar grupo (fluxo completo) | Preencher tudo e criar | Entra no grupo como **criador** (escudo 🛡️), identidade salva localmente |
| 2.10 | Criar grupo com conta nome existente errada | Nome já usado com outra senha | Mostra erro claro (**não** quebra/crash) |

---

## 3. Início do Grupo (`/g/CODE/inicio`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 3.1 | Mini-dashboard | Ver resumo | Bebidas totais, nº membros, countdown (dias→horas→min→seg) |
| 3.2 | Card do usuário | Ver | Nome, título (ex.: Aprendiz 🍺), nº bebidas, barra de progresso p/ próximo título |
| 3.3 | Avatar do líder/criador | Ver no card e na lista de participantes | 👑 no líder (1º) e 🛡️ no criador |
| 3.4 | Botão +1 BEBIDA desabilitado pós-prazo | Grupo encerrado | Botão desabilitado (countdown "encerrado") |
| 3.5 | Lista de participantes | Ver | Medalhas 🥇🥈🥉, nome, título, total por pessoa |

### 3.A — +1 BEBIDA (registrar bebida)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 3.A.1 | Registrar sem tipo | +1 BEBIDA → "Só contar" → escolher galeria → imagem | Snack "Bebida registrada! 🍻", total sobe, feed ganha entrada |
| 3.A.2 | Registrar com tipo | +1 BEBIDA → escolher tipo (ex.: 🍺) → imagem | Bebida vinculada ao tipo; stats de tipos atualizam |
| 3.A.3 | Cancelar a foto | +1 BEBIDA → escolher origem → **cancelar** seleção | **Nada é registrado** (contador não muda) |
| 3.A.4 | Bloqueio pós-prazo | Tentar registrar em grupo encerrado | Snack "A competição já encerrou." / botão inativo |
| 3.A.5 | Foto obrigatória **[MOBILE]** | Fluxo em viewport mobile | Sheets ocupam largura correta, sem overflow |
| 3.A.6 | Confete do líder | Registrar até ultrapassar o líder | Confete dispara ao assumir a liderança |

### 3.B — Adicionar Foto (solta) e Foto de perfil

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 3.B.1 | Adicionar Foto (solta) | "Adicionar Foto" → galeria → imagem | Snack "Foto adicionada ao álbum!", foto aparece no Álbum |
| 3.B.2 | Trocar foto de perfil | Tocar no avatar → origem → imagem | Foto atualiza no app e persiste |
| 3.B.3 | Race/estado pós-adição | Adicionar bebida/foto e trocar de aba rapidamente | Stats/albu recebem invalidação (SWR) sem spinner infinito |

---

## 4. Navegação entre abas (Shell persistente)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 4.1 | Trocar de aba | Clicar Início/Feed/Ranking/Estatísticas/Álbum | Troca **sem reload** e **sem spinner** (estado vivo via IndexedStack) |
| 4.2 | Voltar ao topo re-tap | Clicar 2× na aba atual | Volta à raiz da aba dentro do grupo |
| 4.3 | Re-tap volta ao shell | Re-tap na aba atual | Permanece no grupo (não cai em loop/spinner infinito) |
| 4.4 | Deep link `/g/CODE` | Navegar direto para `/g/CODE` | Redireciona para `/g/CODE/inicio` |
| 4.5 | Deep link antigo `/g/CODE/share` | Navegar para caminho antigo | Redireciona para `/g/CODE/inicio/share` |
| 4.6 | `/g` sem código | Ir para `/g` | Redireciona para home |
| 4.7 | Rota inexistente | Ir para URL aleatória dentro grupo | Tela "Página não encontrada" (sem crash) |

---

## 5. Feed (`/g/CODE/feed`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 5.1 | Feed com atividades | Registrar bebida/foto | Itens aparecem com nome, avatar e a ação |
| 5.2 | Tempo real (multi-contas) | Com duas contas/abas abertas, registrar na conta A | Feed da conta B atualiza **sozinho** (realtime) |
| 5.3 | Itens inéditos animados | Com feed já carregado, nova atividade | Só o item novo anima (não a lista toda) |
| 5.4 | Pull-to-refresh | Arrastar para baixo | Recarrega dados (RefreshIndicator) [] |
| 5.5 | Feed responsivo **[MOBILE]** | Viewport mobile | Cartões não estouram; imagens com width 640 |

---

## 6. Ranking (`/g/CODE/ranking`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 6.1 | Ranking ordenado | Ver | Ordenado por total (maior primeiro), pódio 🥇🥈🥉 |
| 6.2 | Tempo real | Registrar bebida na conta A | Posição/ordem na conta B atualiza em tempo real |
| 6.3 | Avatar/título por posição | Ver | 👑 no líder; título de cada um |
| 6.4 | Responsivo **[MOBILE]** | Viewport mobile | Sem overflow no grid do pódio |

---

## 7. Estatísticas (`/g/CODE/stats`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 7.1 | Cards de métricas | Abrir stats | Total, média, mais ativo etc. **sem overflow** (padding fixo) |
| 7.2 | Gráfico "Bebidas por dia" | Ver | Gráfico renderiza (não vazio) |
| 7.3 | Tipos por pessoa | Registrar com tipos diferentes | Divisão de tipos correta |
| 7.4 | Títulos/faixas | Ver | Faixas (Aprendiz…Papo de Reabilitação) conforme copos |
| 7.5 | Stats após nova bebida | Registrar bebida e voltar a stats | Invalida (cache 60s SWR) e recarrega em background |
| 7.6 | Abrir stats direto (deep link) | Ir para `/g/CODE/stats` | Carrega sem crash ("modify provider during build" **não** ocorre) |

---

## 8. Álbum (`/g/CODE/album`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 8.1 | Lista de fotos | Registrar fotos | Fotos aparecem no álbum (widths 400) |
| 8.2 | Visualizador ampliado | Tocar numa foto | Abre visor ampliado; fecha corretamente |
| 8.3 | Foto vinculada a bebida | Ver foto vinda de bebida | Associada corretamente |
| 8.4 | Responsivo **[MOBILE]** | Viewport mobile | Grade sem overflow |

---

## 9. Compartilhar (`/g/CODE/inicio/share`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 9.1 | Link compartilhável | Ver | `/g/CODE` gerado com a origem atual do host |
| 9.2 | Código do grupo | Ver | Código exibido (copiar funciona) |
| 9.3 | QR Code | Ver | QR renderiza e aponta para o link |
| 9.4 | Copômetro | Ver | Componente presente e funcional |
| 9.5 | Navegar share | Usar botão "Compartilhar" no início | Abre `/g/CODE/inicio/share` (rota correta, não "não encontrada") |

---

## 10. Hall da Fama (`/g/CODE/inicio/hall-of-fame`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 10.1 | Acesso | Abrir pela branch Início | Rota `/g/CODE/inicio/hall-of-fame` abre (não "não encontrada") |
| 10.2 | Campeões | Ver | Exibe campeões (se houver competições encerradas) |
| 10.3 | Vazio | Sem competição encerrada | Estado vazio amigável (sem crash) |

---

## 11. Entrar em um grupo (`/entrar-grupo` e `/entrar/:code`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 11.1 | Código upper/sem espaço | Digitar `abc 12` | Normaliza para maiúsculas sem espaços |
| 11.2 | Código válido (membro novo) | Código de grupo ativo → nome + senha | Consegue entrar (assinatura nova); conta criada no grupo |
| 11.3 | Código inválido | Código inexistente | Mensagem de erro (sem crash/loop) |
| 11.4 | Já membro + senha igual | Reentrar com nome+senha deste grupo | Volta ao grupo (mesma conta reutilizada) |
| 11.5 | Já membro + senha errada | Nome deste grupo com senha errada | Mensagem clara ("Já existe alguém como X neste grupo com outra senha") |
| 11.6 | Voltar | Seta do AppBar | Volta para a home |
| 11.7 | Grupo encerrado (novo membro) | Entrar em grupo com prazo vencido | Aviso de encerrado; não entra como novo membro |
| 11.8 | **Deep link `/entrar/:code`** | Navegar direto | Abre cadastro/entrada para o código (sem conflito de rota P0) |

---

## 12. Login por conta (`/entrar-login`)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 12.1 | Login correto | Nome + senha da conta criada | Re-vincula sessão (407/403 resolvido) e volta ao grupo |
| 12.2 | Login em novo dispositivo/aba | Logar com a mesma conta nome+senha | Acessa o grupo mesmo em sessão anônima nova (backfill do anon_id) |
| 12.3 | Senha incorreta | Senha errada | Erro claro |
| 12.4 | Grupo preferido na re-vinculação | Conta em múltiplos grupos | Prefere a participação no grupo informado |
| 12.5 | Registrar bebida após login | Logar e registrar | **Sem 403** (RLS/anónimo re-vinculados) |

---

## 13. Sair do grupo e mudar de conta (fluxo do enunciado)

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 13.1 | Sair do grupo | Usar fluxo de saída (limpar identidade local / não-membro) | Volta para home; grupo não aparece mais como "conhecido" |
| 13.2 | Reentrar com outra conta | Navegar home → "Ainda estou num grupo" → nome+senha da segunda conta | Entra como a **segunda** conta (não confunde identidades) |
| 13.3 | Dois usuários no mesmo grupo | Conta A e B abertas em abas/conttextos isolados | Ambos veem o mesmo grupo em tempo real |
| 13.4 | Persistência de identidade | Fechar e reabrir o app limpo | Identidade/anexos locais preservados |

---

## 14. Competição encerrada / prazo

| # | Caso | Passos | Resultado esperado |
|---|---|---|---|
| 14.1 | Countdown | Grupo ativo dentro do prazo | Countdown conta regressivamente |
| 14.2 | Bloqueio local após prazo | Grupo sem `acceptsEntries` | +1 bebida / foto desabilitados |
| 14.3 | Bloqueio no backend | Tentar registrar via UI mesmo assim (defensivo) | Snack "a competição já encerrou" (erro 42501 mapeado) |
| 14.4 | Entrada bloqueada pós-prazo | Novo participante | Aviso de encerrado; leitura mantida p/ membros |

---

## 15. Responsividade / Mobile (viewport celular)

| # | Caso | Resultado esperado |
|---|---|---|
| 15.1 | Home **[MOBILE]** | Sem overflow; CTAs empilhados corretamente |
| 15.2 | Criar grupo **[MOBILE]** | Chips/emojis em `Wrap` sem estouro; campos não esticam |
| 15.3 | Grupo Início **[MOBILE]** | Cards, barras e botão +1 dentro da tela |
| 15.4 | Sheets (tipo/origem foto) **[MOBILE]** | Ocupam a largura certa, sem overflow |
| 15.5 | Feed/Ranking/Stats/Álbum **[MOBILE]** | Sem RenderFlex overflow (principalmente nos cards de métrica de stats) |
| 15.6 | Bottom nav **[MOBILE]** | 5 abas com rótulos legíveis; sem cortar texto |
| 15.7 | Scroll/touch **[MOBILE]** | Rolar suave; `touch-action: manipulation` sem zoom acidental |
| 15.8 | Landscape **[MOBILE]** | Layout não quebra ao girar |

---

## 16. Robustez / Regressões conhecidas (foco)

| # | Caso | Resultado esperado |
|---|---|---|
| 16.1 | **P0 rota enter vs group** | `/entrar/:code` e `/g/:code` nunca conflitam (sem loop infinito de loading) |
| 16.2 | **Stats sem crash** | Abrir stats não lança "modify provider during widget tree building" |
| 16.3 | **Overflow stats** | Cards de métrica sem overflow em telas largas (extent 130) |
| 16.4 | **Share/Hall rotas** | `/g/CODE/inicio/share|hall-of-fame` abrem (não "Página não encontrada") |
| 16.5 | Estado `unknown` | Status desconhecido não vira "active" (defensivo) |
| 16.6 | Cast seguro do feed | Atividade com payload sem `url` não crasha |
| 16.7 | Erro transitório | Falha de rede transitória não substitui a tela por erro (polling 20s reintenta) |
| 16.8 | Banner de erro | Se sessão der erro, mostra erro (não spinner infinito) |

---

## 17. Roteiro E2E principal (ordem sugerida de execução)

> Roteiro completo do enunciado — rodar de ponta a ponta.

1. **Limpar** dados do contexto de teste (sessão anônima zerada).
2. Abrir home desktop ✔ (seção 1).
3. Criar grupo `QA Copa Teste` com período personalizado curto (ex.: 7 dias),
   meta ativa e foto de perfil ✔ (seção 2).
4. Registrar bebidas com e sem tipo; registrar foto ✔ (seções 3.A/3.B).
5. Navegar entre as 5 abas e conferir persistência/tempo real ✔ (seções 4–8).
6. Testar Compartilhar (link/código/QR/Copômetro) e Hall da Fama ✔ (9–10).
7. **Sair do grupo** (limpar identidade / fluxo de saída) ✔ (13.1).
8. **Criar/entrar com outra conta** (nome+senha) e voltar ao grupo ✔ (13.2).
9. Testar **login por conta** de novo dispositivo/aba e registrar bebida (sem 403) ✔ (12).
10. Testar cenário de prazo encerrado (grupo curto) ✔ (14).
11. Repetir passos críticos em **modo celular** ✔ (15).
12. Fechar com verificação de **robustez** (regressões) ✔ (16).

## 18. Checklist final / Critérios de aceite

- [ ] Todos os casos da seção 16 (regressões conhecidas) PASS.
- [ ] Nenhum crash / erro de console inesperado (verificar `list_console_messages`).
- [ ] Nenhum spinner infinito / loop de rota.
- [ ] Nenhum overflow (RenderFlex) em desktop **e** mobile.
- [ ] Realtime funcionando entre contas.
- [ ] Roteiro E2E (seção 17) concluído de ponta a ponta.
- [ ] Bugs encontrados registrados com nº do caso + screenshot + repro passo a passo.

---

**Registro de execução** (preencher durante o teste):

| Caso | Status | Evidência / Obs |
|---|---|---|
| | | |
