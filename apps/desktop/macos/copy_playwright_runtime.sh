#!/bin/sh
set -e

SRC_DIR="${PROJECT_DIR}/../third_party/playwright_translate"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Resources/playwright_translate"

if [ ! -f "${SRC_DIR}/run_playwright_translate.mjs" ]; then
  echo "[Playwright] source bundle missing, skipping copy."
  exit 0
fi

mkdir -p "$DEST_DIR"
rsync -a --delete --exclude ".git" "$SRC_DIR"/ "$DEST_DIR"/
echo "[Playwright] runtime copied to app bundle."
