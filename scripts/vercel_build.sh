#!/usr/bin/env bash
#
# Script de build da Vercel para o Flutter Web.
# A Vercel não traz o Flutter no ambiente de build, então o SDK é clonado aqui.
#
# Versão PINADA (determinística): usar o branch `stable` deixa a produção
# derivar silenciosamente (ex.: 3.47.x trouxe regressão de fotos pretas no web,
# #191800). Fixamos numa versão específica para produção == local.
set -euo pipefail

# Ambiente de build da Vercel fixa a raiz do projeto em $VERCEL_PROJECT_ROOT.
ROOT="${VERCEL_PROJECT_ROOT:-$(pwd)}"
FLUTTER_DIR="$ROOT/flutter"

# Versão fixada. Troque aqui (e no seu Flutter local) ao mudar o SDK.
FLUTTER_VERSION="3.44.9"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "==> Clonando Flutter $FLUTTER_VERSION..."
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "==> Flutter SDK encontrado (cache)."
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "==> Versão do Flutter:"
flutter --version

# Garante que a versão é a esperada (falha o build em caso de drift).
ACTUAL="$(flutter --version 2>/dev/null | head -1)"
echo "==> Esperado: $FLUTTER_VERSION | Atual: $ACTUAL"
if ! echo "$ACTUAL" | grep -qE "$FLUTTER_VERSION(\\b|-)"; then
  echo "ERRO: versão do Flutter inesperada (esperado $FLUTTER_VERSION)." >&2
  exit 1
fi

flutter config --no-analytics --enable-web 2>/dev/null || true

cd "$ROOT"

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build web --release --wasm"
flutter build web --release --wasm --base-href /

echo "==> Build concluído."