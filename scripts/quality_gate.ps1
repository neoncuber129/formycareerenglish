Param(
  [switch]$SkipIntegration
)

$ErrorActionPreference = "Stop"

Write-Host "== Mobile: pub get =="
flutter pub get --project-dir "d:/formycareer/apps/mobile"

Write-Host "== Desktop: pub get =="
flutter pub get --project-dir "d:/formycareer/apps/desktop"

Write-Host "== Shared models: tests =="
flutter test "d:/formycareer/packages/shared_models"

Write-Host "== Mobile: analyze + test =="
flutter analyze "d:/formycareer/apps/mobile"
flutter test "d:/formycareer/apps/mobile"

Write-Host "== Desktop: analyze + test =="
flutter analyze "d:/formycareer/apps/desktop"
flutter test "d:/formycareer/apps/desktop"

if (-not $SkipIntegration) {
  Write-Host "== Mobile integration test (Windows) =="
  flutter test integration_test -d windows --project-dir "d:/formycareer/apps/mobile"
}

Write-Host "Quality gate passed."
