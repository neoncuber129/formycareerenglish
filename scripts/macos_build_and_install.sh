#!/usr/bin/env bash

set -euo pipefail

# Build macOS app and install into /Applications.
#
# Usage:
#   scripts/macos_build_and_install.sh [debug|release] [app_name]
#
# Example:
#   scripts/macos_build_and_install.sh release Formycareer.app

BUILD_MODE="${1:-release}"
TARGET_APP_NAME="${2:-desktop.app}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/desktop"
APPLICATIONS_DIR="/Applications"
INSTALLED_APP_PATH="$APPLICATIONS_DIR/$TARGET_APP_NAME"

if [[ "$BUILD_MODE" != "debug" && "$BUILD_MODE" != "release" ]]; then
  echo "Invalid build mode: $BUILD_MODE"
  echo "Use: debug or release"
  exit 1
fi

if [[ "$BUILD_MODE" == "debug" ]]; then
  BUILD_OUTPUT_DIR="Debug"
else
  BUILD_OUTPUT_DIR="Release"
fi

BUILD_APP_PATH="$APP_DIR/build/macos/Build/Products/$BUILD_OUTPUT_DIR/desktop.app"

echo "==> Building macOS app ($BUILD_MODE)..."
(cd "$APP_DIR" && flutter build macos --"$BUILD_MODE")

if [[ ! -d "$BUILD_APP_PATH" ]]; then
  echo "Build completed but app not found at: $BUILD_APP_PATH"
  exit 1
fi

echo "==> Installing app to: $INSTALLED_APP_PATH"
if [[ -d "$INSTALLED_APP_PATH" ]]; then
  echo "Removing old app..."
  sudo rm -rf "$INSTALLED_APP_PATH"
fi

sudo cp -R "$BUILD_APP_PATH" "$INSTALLED_APP_PATH"

echo ""
echo "Done."
echo "Installed: $INSTALLED_APP_PATH"
echo "Opening app..."
open "$INSTALLED_APP_PATH"
