@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Ensure we're in the same directory as this script
cd /d "%~dp0"

set "CONTAINER_NAME=teaching-quartz"

REM ---------------------------
REM Usage helper
REM ---------------------------
if "%~1"=="" goto :usageAndExit
if "%~2"=="" goto :usageAndExit

REM Arguments
set "COURSE_CODE=%~1"
set "SECTION_NUM=%~2"
shift
shift

REM Collect any extra args to forward to deploy.py (e.g., --owner, --repo, --no-create-remote, --private)
set "EXTRA_ARGS=%*"

REM Host-side paths (bind-mounted into the container at /teaching/courses)
set "COURSE_DIR_HOST=%CD%\courses\%COURSE_CODE%"
set "MERGED_DIR_HOST=%COURSE_DIR_HOST%\.merged_output"
set "SECTION_DIR_HOST=%MERGED_DIR_HOST%\section%SECTION_NUM%"

REM Detect host timezone offset in ±HHMM format (e.g., -0400, +0130)
for /f "usebackq delims=" %%Z in (`powershell -NoProfile -Command "(Get-Date).ToString('zzz').Replace(':','')"`) do set "HOST_TZ_OFFSET=%%Z"
echo 🕒 Host timezone offset: %HOST_TZ_OFFSET%

REM Extra friendly preflight: ensure the course folder exists
if not exist "%COURSE_DIR_HOST%" (
  echo ❌ Course folder not found on host:
  echo    %COURSE_DIR_HOST%
  echo.
  echo 👉 Make sure you've run the course setup and/or preview steps.
  echo    Try: preview.bat %COURSE_CODE% %SECTION_NUM%
  if exist "%CD%\courses" (
    echo.
    echo 📚 Available course folders:
    for /f "usebackq delims=" %%C in (`dir /b "%CD%\courses" 2^>nul`) do echo    - %%C
  )
  exit /b 1
)

REM Friendly preflight: ensure the merged output for this section exists
if not exist "%SECTION_DIR_HOST%" (
  echo ❌ Section directory not found on host:
  echo    %SECTION_DIR_HOST%
  echo.
  echo 👉 You likely need to build the merged output first:
  echo    preview.bat %COURSE_CODE% %SECTION_NUM%
  if exist "%MERGED_DIR_HOST%" (
    for /f "usebackq delims=" %%S in (`dir /ad /b "%MERGED_DIR_HOST%\section*" 2^>nul`) do (
      if not defined PRINTED_SECTIONS (
        echo.
        echo 📂 Existing merged sections for %COURSE_CODE%:
        set "PRINTED_SECTIONS=1"
      )
      echo    - %%S
    )
  )
  exit /b 1
)

REM Ensure the container exists
set "EXISTS="
for /f "usebackq delims=" %%A in (`docker ps -a --format "{{.Names}}" ^| findstr /r /c:"^%CONTAINER_NAME%$"`) do set "EXISTS=1"
if not defined EXISTS (
  echo ❌ Docker container "%CONTAINER_NAME%" not found.
  echo    Please run setup.bat first to create and start the container.
  exit /b 1
)

REM Start container if it exists but isn't running
set "RUNNING="
for /f "usebackq delims=" %%A in (`docker ps --format "{{.Names}}" ^| findstr /r /c:"^%CONTAINER_NAME%$"`) do set "RUNNING=1"
if not defined RUNNING (
  echo 🐳 Starting container %CONTAINER_NAME%...
  docker start "%CONTAINER_NAME%" >nul
  if errorlevel 1 (
    echo ❌ Failed to start Docker container "%CONTAINER_NAME%".
    exit /b 1
  )
)

set "SECTION_DIR_IN_CONTAINER=/teaching/courses/%COURSE_CODE%/.merged_output/section%SECTION_NUM%"
echo 🚀 Deploying %COURSE_CODE% S%SECTION_NUM% from: %SECTION_DIR_IN_CONTAINER%

docker exec -it ^
  -e HOST_TZ_OFFSET="%HOST_TZ_OFFSET%" ^
  "%CONTAINER_NAME%" ^
  python /opt/scripts/deploy.py ^
    --course "%COURSE_CODE%" ^
    --section "%SECTION_NUM%" ^
    %EXTRA_ARGS%

exit /b %errorlevel%

:usageAndExit
echo 🧰 Usage:
echo   deploy.bat ^<COURSE_CODE^> ^<SECTION_NUMBER^> [--owner ^<github-user-or-org^>] [--repo ^<repo-name^>] [--no-create-remote] [--private]
echo.
echo Examples:
echo   deploy.bat ICS3U 1
echo   deploy.bat ICS3U 1 --owner my-org --private
echo   deploy.bat ICS3U 2 --repo ICS3U-S2-2025 --no-create-remote
echo.
echo Notes:
echo - Deploys from /teaching/courses/^<COURSE_CODE^>/.merged_output/section^<SECTION_NUMBER^> inside the container.
echo - You will be prompted for a GitHub Personal Access Token (PAT) when needed.
echo - Host timezone offset is detected and passed to the container for accurate timestamps.
exit /b 1
