# AGENTS.md

## Build / Typecheck

Este projeto tem um caractere especial no caminho ("Programação") que quebra o
`flutter analyze` (LSP). Use o build web como verificação de compilação:

```bash
flutter build web --release        # compila e valida todos os erros
```

## Testes

```bash
flutter test                        # roda toda a suíte (test/)
```

Detalhes e cobertura em [`docs/testing.md`](docs/testing.md).

## Logo

A marca fica em `assets/logo.png` (usada na home) e nos ícones de
`web/icons/` (PWA/splash), favicon em `web/favicon.png`. Guia completo em
[`docs/logo.md`](docs/logo.md).

## Dependências

```bash
flutter pub get
```

## Rodar localmente

```bash
flutter run -d chrome              # dev com hot reload
# ou servir o build estático:
python3 -m http.server 8080 --directory build/web
```

## Arquitetura

- `lib/core/` — config, tema, router, constants, utils
- `lib/data/` — models, repositories, services (Supabase)
- `lib/domain/` — entities
- `lib/presentation/` — providers (Riverpod), pages, widgets

## Backend (Supabase)

Tabelas com prefixo `ctg_` no schema `public`. RPCs: `ctg_create_group`,
`ctg_end_expired_groups`. View: `ctg_ranking_view`.
Requer **Anonymous Auth habilitado** (Authentication > Providers > Anonymous).
