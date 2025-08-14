@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

REM ==================== Defaults ====================
set "HUB_USER=rwhgrwhg"
set "DEFAULT_TAG=latest"
set "IMAGE_NAME=teaching-quartz"
set "CONTAINER_NAME=teaching-quartz"
set "HOST_PORT=8081"
set "CONTAINER_PORT=8081"

REM ==================== Config (from flags) ====================
set "TAG=%DEFAULT_TAG%"
set "FORCE_UPDATE_IMAGE=false"
set "PASSTHRU_ARGS="
set "PULL_STATUS="

REM ==================== Help text ====================
if /I "%~1"=="--help"  goto :print_help
if /I "%~1"=="-h"      goto :print_help

REM ==================== Arg parsing ====================
:parse_args
if "%~1"=="" goto :after_parse

if /I "%~1"=="--help" (
  goto :print_help
) else if /I "%~1"=="-h" (
  goto :print_help
) else if /I "%~1"=="--tag" (
  if "%~2"=="" (
    echo ❌ --tag requires a value 1>&2
    exit /b 1
  )
  set "TAG=%~2"
  shift
  shift
  goto :parse_args
) else if /I "%~1"=="--update-image" (
  set "FORCE_UPDATE_IMAGE=true"
  shift
  goto :parse_args
) else if "%~1"=="--" (
  shift
  REM Everything after -- is passed through to setup_course.py verbatim
  set "PASSTHRU_ARGS=%*"
  goto :after_parse
) else (
  REM Unknown/other options: pass-through to setup_course.py
  if defined PASSTHRU_ARGS (
    set "PASSTHRU_ARGS=%PASSTHRU_ARGS% %~1"
  ) else (
    set "PASSTHRU_ARGS=%~1"
  )
  shift
  goto :parse_args
)

:after_parse
set "IMAGE=%HUB_USER%/%IMAGE_NAME%:%TAG%"

REM ==================== Pre-flight checks ====================
cd /d "%~dp0"

where docker >nul 2>&1
if errorlevel 1 (
  echo ❌ Docker is not installed or not on PATH. Please install Docker Desktop first.
  exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
  echo ❌ Docker daemon not reachable. Please open Docker Desktop and try again.
  exit /b 1
)

for /f "usebackq delims=" %%A in (`docker info --format "{{.Architecture}}" 2^>nul`) do set "HOST_ARCH=%%A"
if not defined HOST_ARCH set "HOST_ARCH=unknown"
for /f "usebackq delims=" %%A in (`docker info --format "{{.OSType}}" 2^>nul`) do set "HOST_OS=%%A"
if not defined HOST_OS set "HOST_OS=unknown"
echo 🧭 Host detected by Docker: %HOST_OS%/%HOST_ARCH%
echo 🖼️  Using image: %IMAGE%

REM ==================== Folders (permissions N/A on Windows) ====================
if not exist "courses" (
  echo 📁 Creating 'courses' directory on host...
  mkdir "courses"
)
if not exist "courses\_backups" (
  echo 📦 Creating 'courses\_backups' directory on host...
  mkdir "courses\_backups"
)
REM chmod not applicable on Windows/Docker Desktop; skipping.

REM ==================== Pull image if needed ====================
set "IMAGE_PRESENT=false"
docker image inspect "%IMAGE%" >nul 2>&1 && set "IMAGE_PRESENT=true"

if /I "%FORCE_UPDATE_IMAGE%"=="true" (
  echo 🔄 --update-image passed: pulling latest for %IMAGE%…
  docker pull "%IMAGE%"
  if errorlevel 1 exit /b 1
  set "PULL_STATUS=(just pulled)"
) else if /I "%IMAGE_PRESENT%"=="false" (
  echo ⬇️  Image not found locally. Pulling %IMAGE% …
  docker pull "%IMAGE%"
  if errorlevel 1 exit /b 1
  set "PULL_STATUS=(just pulled)"
) else (
  echo ✅ Image already present: %IMAGE%
  set "PULL_STATUS=(already on this machine)"
)

REM ==================== Show image version/build info ====================
call :show_image_info "%IMAGE%"
if errorlevel 1 exit /b 1

REM ==================== Create/start container ====================
set "CONTAINER_EXISTS="
for /f "usebackq delims=" %%N in (`docker ps -a --format "{{.Names}}" ^| findstr /r /c:"^%CONTAINER_NAME%$"`) do set "CONTAINER_EXISTS=1"

if defined CONTAINER_EXISTS (
  for /f "usebackq delims=" %%I in (`docker inspect -f "{{.Config.Image}}" "%CONTAINER_NAME%" 2^>nul`) do set "CURRENT_IMAGE=%%I"
  if /I "%FORCE_UPDATE_IMAGE%"=="true" (
    set "NEED_RECREATE=1"
  ) else (
    set "NEED_RECREATE="
    if /I not "%CURRENT_IMAGE%"=="%IMAGE%" set "NEED_RECREATE=1"
  )

  if defined NEED_RECREATE (
    echo ♻️  Recreating container %CONTAINER_NAME% to use image: %IMAGE%
    for /f "usebackq delims=" %%R in (`docker ps --format "{{.Names}}" ^| findstr /r /c:"^%CONTAINER_NAME%$"`) do set "RUNNING=1"
    if defined RUNNING (
      docker stop "%CONTAINER_NAME%" >nul
    )
    docker rm "%CONTAINER_NAME%" >nul 2>&1
    docker run -dit ^
      --name "%CONTAINER_NAME%" ^
      -v "%CD%\courses:/teaching/courses" ^
      -p %HOST_PORT%:%CONTAINER_PORT% ^
      "%IMAGE%" ^
      tail -f /dev/null
    if errorlevel 1 exit /b 1
  ) else (
    for /f "usebackq delims=" %%R in (`docker ps --format "{{.Names}}" ^| findstr /r /c:"^%CONTAINER_NAME%$"`) do set "RUNNING=1"
    if defined RUNNING (
      echo 🛑 Stopping running container %CONTAINER_NAME% to refresh volume mount...
      docker stop "%CONTAINER_NAME%" >nul
    )
    echo 🚀 Starting existing container %CONTAINER_NAME%...
    docker start "%CONTAINER_NAME%" >nul
  )
) else (
  echo 🚀 Creating a new container named %CONTAINER_NAME% ^(image: %IMAGE%^)
  docker run -dit ^
    --name "%CONTAINER_NAME%" ^
    -v "%CD%\courses:/teaching/courses" ^
    -p %HOST_PORT%:%CONTAINER_PORT% ^
    "%IMAGE%" ^
    tail -f /dev/null
  if errorlevel 1 exit /b 1
)

REM ==================== Backup confirmation (pass-through option) ====================
for /f "usebackq delims=" %%Z in (`powershell -NoProfile -Command "(Get-Date).ToString('zzz').Replace(':','')"`) do set "HOST_TZ_OFFSET=%%Z"
echo 🕒 Detected host timezone offset: %HOST_TZ_OFFSET%
echo 🛟 Backups will be written to: %CD%\courses\_backups

echo %PASSTHRU_ARGS% | findstr /I /C:"--no-backup" >nul
if not errorlevel 1 (
  echo ⚠️  You are running with --no-backup.
  echo     This will skip creating a safety ZIP before modifying course folders.
  set /p CONFIRM=❓ Are you sure you want to proceed without a backup? ^(yes/no^) 
  if /I not "%CONFIRM%"=="yes" if /I not "%CONFIRM%"=="y" (
    echo ❌ Cancelled.
    exit /b 1
  )
  echo Proceeding without backup...
)

REM ==================== Run setup inside container ====================
echo 📚 Running setup_course.py inside the Docker container...
docker exec -e HOST_TZ_OFFSET="%HOST_TZ_OFFSET%" -it "%CONTAINER_NAME%" ^
  python3 /opt/scripts/setup_course.py %PASSTHRU_ARGS%
exit /b %errorlevel%

REM ==================== Functions ====================
:print_help
echo Usage: setup.bat [options] [-- ^<args passed to setup_course.py^>]
echo.
echo Options:
echo   --tag TAG            Use a specific tag instead of 'latest'
echo                        Default: %DEFAULT_TAG%
echo   --update-image       Force pulling the image and recreating the container to use it.
echo   --no-backup          ^(Pass-through to setup_course.py^) Skip creating a backup ZIP ^- you will be asked to confirm.
echo   --help               Show this help and exit.
echo.
echo Notes:
echo - This script will always pull from the public Docker Hub image:
echo     %HUB_USER%/%IMAGE_NAME%
echo   Tag defaults to 'latest' unless overridden with --tag.
echo - Because the repo is public, no Docker Hub account is needed.
echo - Any arguments after a literal "--" are forwarded directly to setup_course.py.
echo.
echo Examples:
echo   setup.bat
echo   setup.bat --tag v2025.08.13
echo   setup.bat --update-image
echo   setup.bat -- --no-backup
exit /b 0

:show_image_info
set "_img=%~1"

REM Labels / fields (each query is independent & resilient)
for /f "usebackq delims=" %%V in (`docker image inspect "%_img%" --format "{{index .Config.Labels \"org.opencontainers.image.version\"}}" 2^>nul`) do set "ver=%%V"
for /f "usebackq delims=" %%C in (`docker image inspect "%_img%" --format "{{index .Config.Labels \"org.opencontainers.image.created\"}}" 2^>nul`) do set "created=%%C"
for /f "usebackq delims=" %%R in (`docker image inspect "%_img%" --format "{{index .Config.Labels \"org.opencontainers.image.revision\"}}" 2^>nul`) do set "rev=%%R"
for /f "usebackq delims=" %%S in (`docker image inspect "%_img%" --format "{{index .Config.Labels \"org.opencontainers.image.source\"}}" 2^>nul`) do set "src=%%S"
for /f "usebackq delims=" %%T in (`docker image inspect "%_img%" --format "{{index .Config.Labels \"org.opencontainers.image.title\"}}" 2^>nul`) do set "title=%%T"

REM Fallbacks
if not defined ver set "ver=(no version label)"
if not defined created (
  for /f "usebackq delims=" %%D in (`docker image inspect "%_img%" --format "{{.Created}}" 2^>nul`) do set "created=%%D"
)
if not defined rev set "rev=(no revision label)"
if not defined title set "title=%_img%"

echo ℹ️  Image info %PULL_STATUS%:
echo    • Title:      %title%
echo    • Version:    %ver%
echo    • Created:    %created%
echo    • Revision:   %rev%
if defined src echo    • Source:     %src%

REM Digests (use println to avoid escaping issues)
set "hadDigest="
for /f "usebackq delims=" %%G in (`docker image inspect "%_img%" --format "{{range .RepoDigests}}{{println .}}{{end}}" 2^>nul`) do (
  if not defined hadDigest (
    echo    • Digests:
    set "hadDigest=1"
  )
  echo      - %%G
)
set "hadDigest="
exit /b 0
