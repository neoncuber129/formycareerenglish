#!/usr/bin/env bash

set -euo pipefail

# Build and package macOS release app as DMG.
#
# Usage:
#   scripts/macos_build_release_dmg.sh [version]
#
# Example:
#   scripts/macos_build_release_dmg.sh 1.0.0

VERSION="${1:-$(date +%Y.%m.%d-%H%M)}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/desktop"
BUILD_APP_PATH="$APP_DIR/build/macos/Build/Products/Release/desktop.app"

DIST_DIR="$ROOT_DIR/dist/macos"
STAGE_DIR="$DIST_DIR/stage"
DMG_NAME="Formycareer-macOS-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

echo "==> Building macOS release app..."
(cd "$APP_DIR" && flutter build macos --release)

if [[ ! -d "$BUILD_APP_PATH" ]]; then
  echo "Build finished but app not found at: $BUILD_APP_PATH"
  exit 1
fi

echo "==> Preparing DMG staging folder..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
mkdir -p "$DIST_DIR"

cp -R "$BUILD_APP_PATH" "$STAGE_DIR/Formycareer.app"
ln -s /Applications "$STAGE_DIR/Applications"

echo "==> Creating DMG at:"
echo "    $DMG_PATH"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "Formycareer" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo ""
echo "Done."
echo "DMG: $DMG_PATH"

