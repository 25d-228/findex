#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SOURCE="$("$ROOT/scripts/build-local.sh")"
DEST_DIR="${1:-$HOME/Applications}"
APP_DEST="$DEST_DIR/Findex.app"
EXTENSION_ID="com.findex.app.FinderExtension"

mkdir -p "$DEST_DIR"
pkill -x Findex 2>/dev/null || true
if [ -d "$APP_DEST/Contents/PlugIns/FindexFinderExtension.appex" ]; then
  pluginkit -r "$APP_DEST/Contents/PlugIns/FindexFinderExtension.appex" || true
fi
rm -rf "$APP_DEST"
cp -R "$APP_SOURCE" "$APP_DEST"

open -Ra "$APP_DEST"
pluginkit -e use -p com.apple.FinderSync -i "$EXTENSION_ID" || true
open "$APP_DEST"

echo "Installed $APP_DEST"
if pluginkit -m -p com.apple.FinderSync -i "$EXTENSION_ID" | grep -q "$EXTENSION_ID"; then
  echo "Findex Finder Extension is enabled."
else
  echo "macOS registered the extension, but did not report it as enabled."
  echo "Enable Findex Finder Extension in System Settings > General > Login Items & Extensions > Finder Extensions."
  open "x-apple.systempreferences:com.apple.ExtensionsPreferences" || true
fi
