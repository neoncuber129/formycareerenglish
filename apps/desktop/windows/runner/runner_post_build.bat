@echo off
setlocal EnableExtensions
rem Args: 1=dotnet 2=csproj 3=publishOutDir 4=runnerExeDir 5=cmake
rem       6=playwrightTranslateSrcDir 7=playwrightSyncBat (optional; empty skips)
set "DOTNET=%~1"
set "CSPROJ=%~2"
set "PUBOUT=%~3"
set "RUNNERDIR=%~4"
set "CMAKE=%~5"

echo [PostBuild] dotnet publish SelectionHost...
"%DOTNET%" publish "%CSPROJ%" -c Release -r win-x64 --self-contained false -o "%PUBOUT%" || exit /b 1

echo [PostBuild] copy SelectionHost next to desktop.exe...
"%CMAKE%" -E copy_if_different "%PUBOUT%\Formycareer.SelectionHost.exe" "%RUNNERDIR%\Formycareer.SelectionHost.exe" || exit /b 1
"%CMAKE%" -E copy_if_different "%PUBOUT%\Formycareer.SelectionHost.dll" "%RUNNERDIR%\Formycareer.SelectionHost.dll" || exit /b 1
"%CMAKE%" -E copy_if_different "%PUBOUT%\Formycareer.UiaSelection.dll" "%RUNNERDIR%\Formycareer.UiaSelection.dll" || exit /b 1
"%CMAKE%" -E copy_if_different "%PUBOUT%\Formycareer.SelectionHost.runtimeconfig.json" "%RUNNERDIR%\Formycareer.SelectionHost.runtimeconfig.json" || exit /b 1
"%CMAKE%" -E copy_if_different "%PUBOUT%\Formycareer.SelectionHost.deps.json" "%RUNNERDIR%\Formycareer.SelectionHost.deps.json" || exit /b 1

set "PWSRC=%~6"
set "PWSYNC=%~7"
if "%PWSRC%"=="" goto :after_pw
if not exist "%PWSRC%\run_playwright_translate.mjs" goto :after_pw
if "%PWSYNC%"=="" goto :after_pw
if /i "%FMC_FORCE_PLAYWRIGHT_SYNC%"=="1" goto :do_pw_sync
if not exist "%RUNNERDIR%\playwright_translate\node_modules\playwright\package.json" goto :do_pw_sync
if not exist "%RUNNERDIR%\playwright_translate\run_playwright_translate.mjs" goto :do_pw_sync
fc /b "%PWSRC%\run_playwright_translate.mjs" "%RUNNERDIR%\playwright_translate\run_playwright_translate.mjs" >nul 2>&1
if errorlevel 1 goto :do_pw_sync
echo [Playwright] skip robocopy: playwright_translate present and script unchanged.
echo [Playwright] To resync after npm install: set FMC_FORCE_PLAYWRIGHT_SYNC=1 then build.
goto :after_pw
:do_pw_sync
echo [Playwright] syncing third_party\playwright_translate to output ^(optional; can be large^)...
call "%PWSYNC%" "%PWSRC%" "%RUNNERDIR%\playwright_translate"
if errorlevel 8 exit /b 1
:after_pw

exit /b 0
