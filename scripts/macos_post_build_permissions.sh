#!/usr/bin/env bash

set -euo pipefail

# Usage:
#   scripts/macos_post_build_permissions.sh [bundle_id] [app_path]
#
# Example:
#   scripts/macos_post_build_permissions.sh vn.edu.vmmu.formycareer.desktop "/path/to/desktop.app"
#
# If app_path is omitted, script tries common build output locations.

BUNDLE_ID="${1:-vn.edu.vmmu.formycareer.desktop}"
APP_PATH="${2:-}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_DEBUG_APP="$ROOT_DIR/apps/desktop/build/macos/Build/Products/Debug/desktop.app"
DEFAULT_RELEASE_APP="$ROOT_DIR/apps/desktop/build/macos/Build/Products/Release/desktop.app"

if [[ -z "$APP_PATH" ]]; then
  if [[ -d "$DEFAULT_DEBUG_APP" ]]; then
    APP_PATH="$DEFAULT_DEBUG_APP"
  elif [[ -d "$DEFAULT_RELEASE_APP" ]]; then
    APP_PATH="$DEFAULT_RELEASE_APP"
  else
    echo "Could not find desktop.app in common Flutter build outputs."
    echo "Pass app path explicitly as second argument."
    exit 1
  fi
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App path does not exist: $APP_PATH"
  exit 1
fi

echo "Bundle ID: $BUNDLE_ID"
echo "App path : $APP_PATH"

echo ""
echo "Resetting TCC entries so macOS can prompt again..."
tccutil reset Accessibility "$BUNDLE_ID" || true
tccutil reset ScreenCapture "$BUNDLE_ID" || true
tccutil reset ListenEvent "$BUNDLE_ID" || true

echo ""
echo "Opening app..."
open "$APP_PATH"

echo ""
echo "Opening Privacy panes..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture" || true
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" || true

cat <<EOF

Done. Next steps:
1) Enable the app in Accessibility, Screen Recording, and Input Monitoring.
2) Quit and reopen the app once after enabling permissions.

EOF
