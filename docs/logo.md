# Logo "C" — onde colocar a imagem

A marca usa uma logo "C". Hoje há um placeholder (`assets/logo.png`, copiado de
`web/favicon.png`) para o app não quebrar. Troque pelos arquivos finais.

## 1. Logo principal do app (a "C" em gradiente da home)

`lib/presentation/widgets/app_logo.dart` renderiza **`assets/logo.png`**.
- **Formato:** PNG com fundo transparente, quadrado.
- **Tamanho recomendado:** 512×512 (cabe em 120px na home sem perder nitidez).
- Se o arquivo sumir/der erro de leitura, o widget cai no emoji 🍺 (fallback).
- Para trocar: sobrescreva `assets/logo.png` e rode `flutter pub get` (re-gera o
  manifest de assets) ou apenas rebuild (`flutter build web`).

Esse é o único lugar da marca que o app usa por enquanto — ele aparece na tela
inicial (hero) substituindo o antigo emoji de cerveja.

## 2. Favicon do navegador

`web/favicon.png` — ícone da aba. 64×64 (ou maior, o navegador redimensiona).

## 3. Ícones de instalação (PWA / splash / atalho)

`web/manifest.json` referencia os ícones usados ao "instalar" o app no celular/
desktop e na splash screen. Substitua os quatro arquivos em `web/icons/`:

| Arquivo                      | Uso                            |
| ---------------------------- | ------------------------------ |
| `web/icons/Icon-192.png`     | Ícone padrão 192×192           |
| `web/icons/Icon-512.png`     | Ícone padrão 512×512           |
| `web/icons/Icon-maskable-192.png` | Ícone com margem segura (maskable) 192×192 |
| `web/icons/Icon-maskable-512.png` | Ícone com margem segura (maskable) 512×512 |

Dica: gere os maskables com uma margem (safe zone) de ~20% ao redor da logo.
Depois de substituir, `flutter build web --release` re-emite tudo.

## 4. Capa de compartilhamento / meta

Quando a URL for compartilhada em redes sociais, o `index.html` usa os mesmos
`icons/Icon-512.png` via meta tags. Se quiser um og:image dedicado, adicione
`assets/og-cover.png` (1200×630) e aponte a meta `og:image` em `web/index.html`
para `/icons/Icon-512.png` (ou o novo arquivo).
