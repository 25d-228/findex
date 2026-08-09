#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="9876.5.4"
INVALID_VERSION="9876.5.4.0"
ARCHIVE="$ROOT/build/dist/Findex-$VERSION-macos-unsigned.zip"
INVALID_ARCHIVE="$ROOT/build/dist/Findex-$INVALID_VERSION-macos-unsigned.zip"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/FindexPackageReleaseTests.XXXXXX")"
BUILD_MARKER="$ROOT/build/Findex.app/invalid-version-build-marker"

cleanup() {
  rm -f "$ARCHIVE" "$INVALID_ARCHIVE" "$BUILD_MARKER"
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

assert_versions() {
  local plist="$1"
  local expected_short_version="$2"
  local expected_bundle_version="$3"
  local description="$4"
  local short_version
  local bundle_version

  short_version="$(plutil -extract CFBundleShortVersionString raw -o - "$plist")"
  bundle_version="$(plutil -extract CFBundleVersion raw -o - "$plist")"
  if [ "$short_version" != "$expected_short_version" ] || [ "$bundle_version" != "$expected_bundle_version" ]; then
    echo "error: $description bundle metadata is incorrect" >&2
    exit 1
  fi
}

cp "$ROOT/Resources/App/Info.plist" "$TEST_DIR/AppInfo.plist"
cp "$ROOT/Resources/FinderExtension/Info.plist" "$TEST_DIR/ExtensionInfo.plist"

archive_path="$("$ROOT/scripts/package-release.sh" "$VERSION")"
if [ "$archive_path" != "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
  echo "error: release archive was not created at the expected path" >&2
  exit 1
fi

EXTRACTED="$TEST_DIR/extracted"
mkdir -p "$EXTRACTED"
ditto -x -k "$ARCHIVE" "$EXTRACTED"

APP_PLIST="$EXTRACTED/Findex.app/Contents/Info.plist"
EXTENSION_PLIST="$EXTRACTED/Findex.app/Contents/PlugIns/FindexFinderExtension.appex/Contents/Info.plist"
assert_versions "$APP_PLIST" "$VERSION" "$VERSION" "archived app"
assert_versions "$EXTENSION_PLIST" "$VERSION" "$VERSION" "archived extension"

local_app_path="$("$ROOT/scripts/build-local.sh")"
source_app_short_version="$(plutil -extract CFBundleShortVersionString raw -o - "$ROOT/Resources/App/Info.plist")"
source_app_bundle_version="$(plutil -extract CFBundleVersion raw -o - "$ROOT/Resources/App/Info.plist")"
source_extension_short_version="$(plutil -extract CFBundleShortVersionString raw -o - "$ROOT/Resources/FinderExtension/Info.plist")"
source_extension_bundle_version="$(plutil -extract CFBundleVersion raw -o - "$ROOT/Resources/FinderExtension/Info.plist")"
assert_versions "$local_app_path/Contents/Info.plist" "$source_app_short_version" "$source_app_bundle_version" "local app"
assert_versions \
  "$local_app_path/Contents/PlugIns/FindexFinderExtension.appex/Contents/Info.plist" \
  "$source_extension_short_version" \
  "$source_extension_bundle_version" \
  "local extension"

touch "$BUILD_MARKER"
if "$ROOT/scripts/package-release.sh" "$INVALID_VERSION" >"$TEST_DIR/invalid.stdout" 2>"$TEST_DIR/invalid.stderr"; then
  echo "error: invalid release version was accepted" >&2
  exit 1
fi
if [ ! -f "$BUILD_MARKER" ] || [ -e "$INVALID_ARCHIVE" ]; then
  echo "error: invalid release version produced build or archive output" >&2
  exit 1
fi
if ! grep -Fxq "error: version must contain one to three dot-separated non-negative integers" "$TEST_DIR/invalid.stderr"; then
  echo "error: invalid release version did not produce the expected concise error" >&2
  exit 1
fi

cmp "$TEST_DIR/AppInfo.plist" "$ROOT/Resources/App/Info.plist"
cmp "$TEST_DIR/ExtensionInfo.plist" "$ROOT/Resources/FinderExtension/Info.plist"

echo "PackageReleaseTests passed"
