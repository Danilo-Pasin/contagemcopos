#!/usr/bin/env bash
#
# Script de build da Vercel para o Flutter Web.
# A Vercel não traz o Flutter no ambiente de build, então o SDK é clonado aqui.
set -euo pipefail

# Ambiente de build da Vercel fixa a raiz do projeto em $VERCEL_PROJECT_ROOT.
ROOT="${VERCEL_PROJECT_ROOT:-$(pwd)}"
FLUTTER_DIR="$ROOT/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "==> Clonando Flutter (branch stable)..."
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "==> Flutter SDK encontrado (cache)."
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "==> Versão do Flutter:"
flutter --version

flutter config --no-analytics --enable-web 2>/dev/null || true

cd "$ROOT"

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build web --release"
flutter build web --release --base-href /

echo "==> Build concluído."