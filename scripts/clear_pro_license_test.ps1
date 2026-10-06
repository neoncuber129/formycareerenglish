<#
.SYNOPSIS
  Xoa nhanh trang thai Pro / license trong SharedPreferences (ban test desktop).

.DESCRIPTION
  Giu dong bo voi apps/desktop/lib/core/monetization/app_state.dart (AppStateController),
  gom quota SRS/ngay va capture-popup banner prefs neu can reset ve mac dinh sau fetch config.
  shared_preferences luu key co tien to mac dinh "flutter.".

  Mac dinh Windows: %APPDATA%\com.example\desktop\shared_preferences.json
  (CompanyName/ProductName trong Runner.rc).

.PARAMETER PrefsPath
  Duong day day du toi shared_preferences.json.

.PARAMETER CompanyName
  Thu muc con trong Roaming (mac dinh: com.example).

.PARAMETER ProductName
  Ten thu muc app (mac dinh: desktop).

.EXAMPLE
  .\scripts\clear_pro_license_test.ps1
.EXAMPLE
  .\scripts\clear_pro_license_test.ps1 -PrefsPath "D:\temp\shared_preferences.json"
#>
[CmdletBinding()]
param(
  [string] $PrefsPath = "",
  [string] $CompanyName = "com.example",
  [string] $ProductName = "desktop"
)

$ErrorActionPreference = "Stop"

$keysToRemove = @(
  "flutter.isPro",
  "flutter.lemonLastLicenseKey",
  "flutter.lemonLicenseInstanceId",
  "flutter.lemonSqueezyInstanceFingerprint",
  "flutter.dailyReviewDate",
  "flutter.dailyReviewCount",
  "flutter.dailyVocabSaveDate",
  "flutter.dailyVocabSaveCount",
  "flutter.freeDailyVocabSaveLimit",
  "flutter.dailyTranslateCallDate",
  "flutter.dailyTranslateCallCount",
  "flutter.freeDailyTranslateCallLimit",
  "flutter.capturePopupBannerLastShownMs",
  "flutter.freeDailyReviewLimit",
  "flutter.capturePopupBannerEnabled",
  "flutter.capturePopupBannerCooldownMinutes"
)

if ([string]::IsNullOrWhiteSpace($PrefsPath)) {
  $roaming = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
  $appDir = Join-Path (Join-Path $roaming $CompanyName) $ProductName
  $PrefsPath = Join-Path $appDir "shared_preferences.json"
}

if (-not (Test-Path -LiteralPath $PrefsPath)) {
  Write-Host "Khong tim thay file prefs: $PrefsPath" -ForegroundColor Yellow
  Write-Host "Dong app truoc khi chay neu can; hoac truyen -PrefsPath dung vi tri build cua ban." -ForegroundColor Yellow
  exit 1
}

$raw = Get-Content -LiteralPath $PrefsPath -Raw -Encoding UTF8
$json = $raw | ConvertFrom-Json
if ($null -eq $json) {
  Write-Host "File JSON khong hop le hoac rong: $PrefsPath" -ForegroundColor Red
  exit 1
}

$removed = @()
foreach ($k in $keysToRemove) {
  if ($json.PSObject.Properties.Name -contains $k) {
    $json.PSObject.Properties.Remove($k)
    $removed += $k
  }
}

if ($removed.Count -eq 0) {
  Write-Host "Khong co key Pro/license nao can xoa (da sach hoac chua tung kich hoat)." -ForegroundColor Cyan
  exit 0
}

$out = $json | ConvertTo-Json -Depth 100 -Compress:$false
[System.IO.File]::WriteAllText($PrefsPath, $out, [System.Text.UTF8Encoding]::new($false))
Write-Host "Da xoa $($removed.Count) key khoi:" -ForegroundColor Green
Write-Host "  $PrefsPath"
$removed | ForEach-Object { Write-Host "  - $_" }
