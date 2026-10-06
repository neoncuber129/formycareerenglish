#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Running macOS build + permissions helper..."
echo "Project root: $ROOT_DIR"
echo ""

bash "$SCRIPT_DIR/macos_build_and_permissions.sh"

echo ""
echo "Done. Press Enter to close this window."
read -r

