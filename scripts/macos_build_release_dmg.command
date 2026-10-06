#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Building Formycareer release DMG..."
echo "Project root: $ROOT_DIR"
echo ""

bash "$SCRIPT_DIR/macos_build_release_dmg.sh"

echo ""
echo "Done. Press Enter to close this window."
read -r

