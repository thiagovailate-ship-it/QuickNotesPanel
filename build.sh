#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$ROOT"

echo "Diretório do projeto: $ROOT"
echo "Arquivos disponíveis:"
ls -la

if [ ! -f "$ROOT/Makefile" ]; then
  echo "ERRO: Makefile não encontrado na raiz do projeto."
  echo "Envie o arquivo Makefile para a raiz do repositório."
  exit 1
fi

if [ -z "${THEOS:-}" ] || [ ! -f "$THEOS/makefiles/common.mk" ]; then
  echo "ERRO: instalação do Theos não encontrada."
  exit 1
fi

make -f "$ROOT/Makefile" clean || true
make -f "$ROOT/Makefile"

mkdir -p "$ROOT/dist"

BUILT="$(find "$ROOT/.theos" -type f \
  -name 'QuickNotesPanel.dylib' -print -quit 2>/dev/null || true)"

if [ -z "$BUILT" ]; then
  BUILT="$(find "$ROOT" -type f \
    -name 'QuickNotesPanel.dylib' \
    -not -path "$ROOT/dist/*" \
    -print -quit)"
fi

if [ -z "$BUILT" ] || [ ! -f "$BUILT" ]; then
  echo "ERRO: a compilação não produziu a dylib."
  exit 1
fi

cp "$BUILT" "$ROOT/dist/QuickNotesPanel.dylib"
file "$ROOT/dist/QuickNotesPanel.dylib"

echo "Compilação concluída."
