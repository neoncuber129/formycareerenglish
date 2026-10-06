#!/usr/bin/env bash

set -euo pipefail

# One-command workflow:
# 1) Build macOS debug app
# 2) Run TCC reset + open permission panes + open app
#
# Usage:
#   scripts/macos_build_and_permissions.sh [bundle_id]

BUNDLE_ID="${1:-vn.edu.vmmu.formycareer.desktop}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/desktop"
PERM_SCRIPT="$ROOT_DIR/scripts/macos_post_build_permissions.sh"

if [[ ! -f "$PERM_SCRIPT" ]]; then
  echo "Missing script: $PERM_SCRIPT"
  exit 1
fi

echo "Building macOS debug app..."
(cd "$APP_DIR" && flutter build macos --debug)

APP_PATH="$APP_DIR/build/macos/Build/Products/Debug/desktop.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build completed but app not found at: $APP_PATH"
  exit 1
fi

echo "Running permission helper..."
"$PERM_SCRIPT" "$BUNDLE_ID" "$APP_PATH"

