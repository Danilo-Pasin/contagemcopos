# Contagem — Copa das Bebidas 🍻

Aplicativo social onde grupos de amigos registram a quantidade de bebidas consumidas durante uma competição e disputam o ranking. **Flutter Web PWA** instalável na tela inicial, com identidade local por nome (senha opcional por grupo) e foto opcional.

## Stack

- **Frontend:** Flutter 3.x · Material 3 · FlexColorScheme · Riverpod · GoRouter · Clean Architecture
- **Backend:** Supabase (PostgreSQL · Realtime · Storage · RLS · Auth Anônimo)

## Pré-requisitos de configuração (Supabase)

> ⚠️ **Etapa obrigatória única** — habilitar sign-in anônimo.

1. Acesse o **Dashboard do Supabase** → **Authentication** → **Sign In / Providers**
2. Ative o provedor **Anonymous** (Enable Anonymous sign-ins)
3. Pronto. O app cria usuários anônimos automaticamente (a sessão fica salva no navegador).

As credenciais já estão em `lib/core/config/app_config.dart`.

## Como rodar localmente

```bash
flutter pub get
flutter run -d chrome
```

## Build de produção (PWA)

```bash
flutter build web --release --base-href "/"
```

Os arquivos saem em `build/web/`. Faça deploy em qualquer host estático
(Vercel, Netlify, Firebase Hosting, etc.).

## Estrutura (Clean Architecture)

```
lib/
├── core/           # config, tema, router, constants, utils, extensions
├── data/           # models (DTOs), repositories, services
├── domain/         # entities (Group, Participant, Drink, Photo, ...)
├── presentation/   # providers (Riverpod), pages, widgets (design system)
├── app.dart
└── main.dart
```

## Funcionalidades

- ✅ Criação de grupo com código + link compartilhável (`/g/AB72XC`) e período de competição
- ✅ Meta opcional por pessoa (bebidas) ou modo livre (sem meta definida)
- ✅ Home com CTAs "Criar Grupo", "Entrar em um grupo" (por código) e "Já estou em um grupo" (nome + senha)
- ✅ Entrada sem baixa fricção: nome + foto opcional · identidade salva localmente
- ✅ Autenticação leve com senha por grupo apenas como **hash** no servidor (RPCs do Postgres)
- ✅ Cards de participantes com botão **+1 BEBIDA** (sem confirmação) e **Adicionar Foto**
- ✅ Feed estilo Instagram (histórico em tempo real)
- ✅ Ranking com pódio 🥇🥈🥉 em tempo real
- ✅ Sistema de títulos (7 faixas, meta proporcional ao período) e distribuição na página de stats
- ✅ Estatísticas (total, média, mais ativo, gráfico "Bebidas por dia", tipos por pessoa)
- ✅ Countdown no mini-dashboard; competição bloqueia +1 bebida/foto após o término
- ✅ Álbum de fotos com visualizador ampliado
- ✅ Conquistas (18 achievements)
- ✅ Compartilhamento (Copômetro, QR Code, código, link)
- ✅ Hall da Fama (campeões de competições encerradas)
- ✅ Tema light/dark persistido · glassmorphism · animações · responsivo
- ✅ Confete ao assumir a liderança

## Comandos úteis

```bash
flutter build web --release     # build (também serve como typecheck/compile check)
flutter test                    # roda toda a suíte (test/)
flutter pub get                 # instalar dependências
```
