#!/usr/bin/env bash
set -euo pipefail

SKIP_INTEGRATION="${1:-}"

echo "== Mobile: pub get =="
flutter pub get --project-dir "d:/formycareer/apps/mobile"

echo "== Desktop: pub get =="
flutter pub get --project-dir "d:/formycareer/apps/desktop"

echo "== Shared models: tests =="
flutter test "d:/formycareer/packages/shared_models"

echo "== Mobile: analyze + test =="
flutter analyze "d:/formycareer/apps/mobile"
flutter test "d:/formycareer/apps/mobile"

echo "== Desktop: analyze + test =="
flutter analyze "d:/formycareer/apps/desktop"
flutter test "d:/formycareer/apps/desktop"

if [[ "${SKIP_INTEGRATION}" != "--skip-integration" ]]; then
  echo "== Mobile integration test (Windows) =="
  flutter test integration_test -d windows --project-dir "d:/formycareer/apps/mobile"
fi

echo "Quality gate passed."
