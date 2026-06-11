#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-0.1.0}"
DIST_DIR="$ROOT/build/dist"
APP_PATH="$("$ROOT/scripts/build-local.sh")"
ZIP_PATH="$DIST_DIR/Findex-$VERSION-macos-unsigned.zip"

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"

(
  cd "$(dirname "$APP_PATH")"
  COPYFILE_DISABLE=1 zip -qry "$ZIP_PATH" "$(basename "$APP_PATH")" -x '*.DS_Store' -x '__MACOSX/*'
)

echo "$ZIP_PATH"
