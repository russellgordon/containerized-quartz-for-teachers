@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

REM Wrapper to run PowerShell script with the same name (setup.ps1)
set "_SCRIPT_DIR=%~dp0"
set "_PS1=%_SCRIPT_DIR%setup.ps1"

if not exist "%_PS1%" (
  echo ❌ Unable to find setup.ps1 next to this file. Ensure both files are together.
  exit /b 1
)

REM Allow PowerShell to execute the script without prompting
powershell -NoProfile -ExecutionPolicy Bypass -File "%_PS1%" %*
set "ERR=%ERRORLEVEL%"
exit /b %ERR%
