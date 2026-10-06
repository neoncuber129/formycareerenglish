#!/bin/sh
set -e

DEST="$1"
if [ -z "$DEST" ]; then
  echo "[Argos] missing destination path; skipping."
  exit 0
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
RUNTIME_ROOT="$SCRIPT_DIR/runtime"

if [ ! -d "$RUNTIME_ROOT" ]; then
  echo "[Argos] runtime directory not found at $RUNTIME_ROOT; skipping."
  exit 0
fi

mkdir -p "$DEST/argos_runtime"
cp -R "$RUNTIME_ROOT"/. "$DEST/argos_runtime/"
echo "[Argos] copied runtime to $DEST/argos_runtime"
