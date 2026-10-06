@echo off
setlocal EnableExtensions
set "SRC=%~1"
set "DST=%~2"
if not exist "%SRC%\run_playwright_translate.mjs" exit /b 0
if not exist "%DST%" mkdir "%DST%" 2>nul
robocopy "%SRC%" "%DST%" /E /XO /R:3 /W:5 /NFL /NDL /NJH /NC /NS /NP
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 exit /b 1
exit /b 0
