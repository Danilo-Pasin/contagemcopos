# Logo — onde colocar a imagem

A marca do **OGS** é o logo verde (centro verde sobre fundo que era preto na
fonte), gerado a partir de `docs/logo.png` por `tool/gen_icons.py`.

## 1. Logo principal do app (a marca da home)

`lib/presentation/widgets/app_logo.dart` renderiza **`assets/logo.png`**.
- **Formato:** PNG com fundo transparente (o preto da fonte foi removido).
- **Tamanho:** 644×634 (cabe em 120px na home sem perder nitidez).
- Se o arquivo sumir/der erro de leitura, o widget cai no emoji 🍺 (fallback).
- Para trocar: sobrescreva `assets/logo.png` e rode `flutter pub get` ou apenas
  rebuild (`flutter build web`).

Esse é o único lugar da marca que o app usa por enquanto — aparece na tela
inicial (hero).

## 2. Favicon do navegador

`web/favicon.png` — ícone da aba. O logo foi composto sobre o fundo do app
(`#0B0E14`), pois favicon não suporta transparência preta. 644×634 (o navegador
redimensiona).

## 3. Ícones de instalação (PWA / splash / atalho)

`web/manifest.json` referencia os ícones usados ao "instalar" o app. Os quatro
arquivos em `web/icons/` são gerados por `tool/gen_icons.py`:

| Arquivo                      | Uso                            |
| ---------------------------- | ------------------------------ |
| `web/icons/Icon-192.png`     | Ícone padrão 192×192 (logo ~82%) |
| `web/icons/Icon-512.png`     | Ícone padrão 512×512 (logo ~82%) |
| `web/icons/Icon-maskable-192.png` | Icone maskable 192×192 (safe zone 20%, logo ~60%) |
| `web/icons/Icon-maskable-512.png` | Icone maskable 512×512 (safe zone 20%, logo ~60%) |

Depois de substituir, `flutter build web --release` re-emite tudo. Para
regenerar: `python3 tool/gen_icons.py`.

## 4. Geração (remover fundo preto)

`docs/logo.png` (fonte) tem canto preto opaco e centro verde. O script
`tool/gen_icons.py` remove o fundo usando o sinal de dominância do verde
(`G - max(R,B)`, com `alpha = (score/60)**2`), preservando bordas
anti-aliasadas, e gera `assets/logo.png`, o favicon e os ícones PWA. A validação
visual é via `docs/logo-preview.png` (logo sobre fundo escuro e claro).

## 5. Capa de compartilhamento / meta

Quando a URL é compartilhada, o `index.html` usa `icons/Icon-512.png` via meta
tags. Para um og:image dedicado, adicione `assets/og-cover.png` (1200×630) e
aponte a meta `og:image` em `web/index.html`.
