#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/Findex.app"
APP_CONTENTS="$APP_DIR/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_PLUGINS="$APP_CONTENTS/PlugIns"
EXT_DIR="$APP_PLUGINS/FindexFinderExtension.appex"
EXT_CONTENTS="$EXT_DIR/Contents"
EXT_MACOS="$EXT_CONTENTS/MacOS"
EXT_RESOURCES="$EXT_CONTENTS/Resources"
DERIVED="$BUILD_DIR/DerivedData"

SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="$ARCH-apple-macosx13.0"
SIGN_IDENTITY="${FINDEX_SIGN_IDENTITY:--}"

export CLANG_MODULE_CACHE_PATH="$DERIVED/ModuleCache"
export MODULE_CACHE_DIR="$DERIVED/ModuleCache"

rm -rf "$APP_DIR"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$APP_PLUGINS" "$EXT_MACOS" "$EXT_RESOURCES" "$DERIVED"

cp "$ROOT/Resources/App/Info.plist" "$APP_CONTENTS/Info.plist"
cp "$ROOT/Resources/FinderExtension/Info.plist" "$EXT_CONTENTS/Info.plist"
cp "$ROOT/Resources/App/FindexIcon.icns" "$APP_RESOURCES/FindexIcon.icns"
cp "$ROOT/Resources/App/FindexIcon.icns" "$EXT_RESOURCES/FindexIcon.icns"

# Bundle the web preferences UI when it has been built (web/dist).
if [ -d "$ROOT/web/dist" ]; then
  cp -R "$ROOT/web/dist" "$APP_RESOURCES/WebPreferences"
else
  echo "note: web/dist not found; Preferences falls back to the native window (run 'npm run build' in web/)" >&2
fi

clang \
  -target "$TARGET" \
  -isysroot "$SDK" \
  -fobjc-arc \
  -c "$ROOT/Sources/FindexFinderExtension/main.m" \
  -o "$DERIVED/FinderExtensionMain.o"

swiftc \
  -swift-version 5 \
  -target "$TARGET" \
  -sdk "$SDK" \
  -module-name Findex \
  -framework AppKit \
  -framework Carbon \
  -framework WebKit \
  "$ROOT/Sources/FindexShared/FindexCommand.swift" \
  "$ROOT/Sources/FindexShared/FindexGlyphs.swift" \
  "$ROOT/Sources/FindexApp/main.swift" \
  "$ROOT/Sources/FindexApp/FindexApp.swift" \
  "$ROOT/Sources/FindexApp/FinderContextReader.swift" \
  "$ROOT/Sources/FindexApp/FindexServicesProvider.swift" \
  "$ROOT/Sources/FindexApp/CommandRunner.swift" \
  "$ROOT/Sources/FindexApp/FindexPreferences.swift" \
  "$ROOT/Sources/FindexApp/FinderViewPresetScript.swift" \
  "$ROOT/Sources/FindexApp/PreferencesWindowController.swift" \
  "$ROOT/Sources/FindexApp/WebPreferencesWindowController.swift" \
  -o "$APP_MACOS/Findex"

swiftc \
  -emit-executable \
  -swift-version 5 \
  -target "$TARGET" \
  -sdk "$SDK" \
  -module-name FindexFinderExtension \
  -framework AppKit \
  -framework FinderSync \
  "$DERIVED/FinderExtensionMain.o" \
  "$ROOT/Sources/FindexShared/FindexCommand.swift" \
  "$ROOT/Sources/FindexShared/FindexGlyphs.swift" \
  "$ROOT/Sources/FindexFinderExtension/FinderSyncExtension.swift" \
  -o "$EXT_MACOS/FindexFinderExtension"

codesign --force --timestamp=none --sign "$SIGN_IDENTITY" --entitlements "$ROOT/Resources/FinderExtension/FindexFinderExtension.entitlements" "$EXT_DIR"
codesign --force --timestamp=none --sign "$SIGN_IDENTITY" --entitlements "$ROOT/Resources/App/Findex.entitlements" "$APP_DIR"

echo "$APP_DIR"
