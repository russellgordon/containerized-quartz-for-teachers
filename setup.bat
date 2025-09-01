@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Resolve script directory and companion PowerShell script
set "_SCRIPT_DIR=%~dp0"
set "_PS1=%_SCRIPT_DIR%setup.ps1"

if not exist "%_PS1%" (
  echo Unable to find setup.ps1 next to this file. Ensure both files are together.
  exit /b 1
)

REM Prefer PowerShell 7+ (pwsh), fall back to Windows PowerShell
where pwsh >nul 2>nul
if %ERRORLEVEL%==0 (
  pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%_PS1%" %*
) else (
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%_PS1%" %*
)
set "ERR=%ERRORLEVEL%"
exit /b %ERR%
