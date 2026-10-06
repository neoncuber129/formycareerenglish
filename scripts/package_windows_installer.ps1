<#
.SYNOPSIS
  Build Flutter Windows release and compile the Inno Setup installer (upgrade-safe paths).

.DESCRIPTION
  Reads version from apps/desktop/pubspec.yaml, runs flutter build windows, then ISCC.
  Inno script appdeskwin inoo.iss uses a fixed AppId and paths relative to repo root.

.PARAMETER SkipFlutterBuild
  Only compile the installer (Release build must already exist).

.PARAMETER IsccPath
  Full path to ISCC.exe if not under default "Inno Setup 6" locations.

.EXAMPLE
  .\scripts\package_windows_installer.ps1
.EXAMPLE
  .\scripts\package_windows_installer.ps1 -SkipFlutterBuild
#>
[CmdletBinding()]
param(
  [switch] $SkipFlutterBuild,
  [string] $IsccPath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$pubspecPath = Join-Path $repoRoot "apps\desktop\pubspec.yaml"
$issPath = Join-Path $repoRoot "appdeskwin inoo.iss"
$releaseDir = Join-Path $repoRoot "apps\desktop\build\windows\x64\runner\Release"

if (-not (Test-Path -LiteralPath $pubspecPath)) {
  throw "Missing pubspec: $pubspecPath"
}
if (-not (Test-Path -LiteralPath $issPath)) {
  throw "Missing Inno script: $issPath"
}

$pubspecText = Get-Content -LiteralPath $pubspecPath -Raw
if ($pubspecText -notmatch '(?m)^version:\s*([\d.]+)\+(\d+)\s*$') {
  throw "Could not parse version: line 'version: x.y.z+build' in $pubspecPath"
}
$versionName = $Matches[1]
$buildNumber = [int]$Matches[2]
if ($buildNumber -lt 0 -or $buildNumber -gt 65535) {
  throw "Build number must be 0..65535 for Windows VERSIONINFO (got $buildNumber)"
}
$versionInfo = "$versionName.$buildNumber"

function Find-Iscc {
  param([string] $Explicit)
  if ($Explicit -and (Test-Path -LiteralPath $Explicit)) {
    return (Resolve-Path -LiteralPath $Explicit).Path
  }
  $candidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
  )
  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

$iscc = Find-Iscc -Explicit $IsccPath
if (-not $iscc) {
  throw "ISCC.exe not found. Install Inno Setup 6 or pass -IsccPath 'C:\...\ISCC.exe'"
}

if (-not $SkipFlutterBuild) {
  Push-Location (Join-Path $repoRoot "apps\desktop")
  try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed ($LASTEXITCODE)" }
    & flutter build windows --release --build-name=$versionName --build-number=$buildNumber
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed ($LASTEXITCODE)" }
  }
  finally {
    Pop-Location
  }
}

if (-not (Test-Path -LiteralPath $releaseDir)) {
  throw "Release output not found: $releaseDir (build first or omit -SkipFlutterBuild)"
}
$desktopExe = Join-Path $releaseDir "desktop.exe"
if (-not (Test-Path -LiteralPath $desktopExe)) {
  throw "Missing $desktopExe"
}

$installerOut = Join-Path $repoRoot "apps\desktop\installer"
if (-not (Test-Path -LiteralPath $installerOut)) {
  New-Item -ItemType Directory -Path $installerOut | Out-Null
}

Write-Host "Compiling installer: AppVersion=$versionName VERSIONINFO=$versionInfo"
Push-Location $repoRoot
try {
  & $iscc "/DMyAppVersion=$versionName" "/DMyAppVersionInfo=$versionInfo" $issPath
}
finally {
  Pop-Location
}
if ($LASTEXITCODE -ne 0) {
  throw "ISCC failed ($LASTEXITCODE)"
}

$setupName = "FormyCareer_Setup_$versionName.exe"
$setupPath = Join-Path $installerOut $setupName
if (Test-Path -LiteralPath $setupPath) {
  Write-Host "OK: $setupPath"
} else {
  Write-Warning "Expected output not found: $setupPath (check Inno OutputBaseFilename)"
}
