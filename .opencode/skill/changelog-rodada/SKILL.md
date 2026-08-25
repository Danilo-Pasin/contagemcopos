---
description: Registra a rodada de mudanças na pasta relatorios/ do projeto Contagem. Use quando o usuário pedir para "fechar/registrar a rodada", "atualizar o changelog" ou ao concluir um bloco de trabalho com verificações.
---

# Contagem — Fechar Rodada (changelog)

Relatórios vivem em `relatorios/`, **um arquivo por data** de trabalho:
`relatorios/YYYY-MM-DD-<tema>.md` (índice no `relatorios/README.md`).
NÃO criar relatórios na raiz ou em `docs/`.

## Protocolo

1. **Mesmo dia:** se já existe arquivo `AAAA-MM-DD-*.md` de hoje, anexar a
   rodada nele (seção nova). Dia novo: criar arquivo seguindo o padrão dos
   existentes e adicioná-lo ao índice do `README.md`.
2. **Antes de escrever, verificar de verdade** — os resultados vão na seção
   `## Verificação` com números reais:
   - `flutter test` (anotar total, ex.: "✅ 147/147")
   - `flutter build web --release --wasm` ✅/❌ (é o typecheck do projeto;
     NÃO usar flutter analyze)
3. **Formato por rodada** (dentro do arquivo do dia):

   ```markdown
   # CHANGELOG AAAA-MM-DD — <título curto> `[Front-end|Back-end|Infra|Testes]`

   ## ✅ <mudança 1>
   - **Problema/objetivo:** ...
   - **Arquivo(s):** `caminho/arquivo.dart:linha` — o que mudou e por quê.

   ## Verificação
   - `flutter test` → ✅ X/X passam.
   - `flutter build web --release --wasm` → ✅ compila.
   - Teste manual: <o que validar no navegador>.

   ## ⏭️ Pendentes / Próximos
   1. ...
   ```

4. Referenciar arquivos com `file:line` quando útil.
5. Atualizar também o índice (`relatorios/README.md`) ao criar arquivo novo.

## Privacidade (repo PÚBLICO)

Nunca incluir no changelog: nomes reais de usuários, hashes de senha,
URLs de foto/storage com paths sensíveis, anon_ids completos. Códigos de grupo
de teste genéricos são aceitáveis.
