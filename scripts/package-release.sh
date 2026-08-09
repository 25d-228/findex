#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$#" -ne 1 ] || [[ ! "$1" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
  echo "error: version must contain one to three dot-separated non-negative integers" >&2
  exit 1
fi

VERSION="$1"
DIST_DIR="$ROOT/build/dist"
APP_PATH="$(FINDEX_RELEASE_VERSION="$VERSION" "$ROOT/scripts/build-local.sh")"
ZIP_PATH="$DIST_DIR/Findex-$VERSION-macos-unsigned.zip"

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"

(
  cd "$(dirname "$APP_PATH")"
  COPYFILE_DISABLE=1 zip -qry "$ZIP_PATH" "$(basename "$APP_PATH")" -x '*.DS_Store' -x '__MACOSX/*'
)

echo "$ZIP_PATH"
