#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$ROOT"

if [ -z "${THEOS:-}" ] || [ ! -f "$THEOS/makefiles/common.mk" ]; then
  echo "Erro: THEOS não aponta para uma instalação válida do Theos." >&2
  echo "Configure o Theos, o SDK iOS e o toolchain antes de compilar." >&2
  exit 1
fi

make clean
make

mkdir -p dist
BUILT="$(find .theos -type f -name 'QuickNotesPanel.dylib' -print -quit 2>/dev/null || true)"
if [ -z "$BUILT" ]; then
  BUILT="$(find . -type f -name 'QuickNotesPanel.dylib' -not -path './dist/*' -print -quit)"
fi
if [ -z "$BUILT" ] || [ ! -f "$BUILT" ]; then
  echo "Erro: o Theos terminou sem produzir QuickNotesPanel.dylib." >&2
  exit 1
fi
cp "$BUILT" dist/QuickNotesPanel.dylib
echo "Dylib criada em: $ROOT/dist/QuickNotesPanel.dylib"
