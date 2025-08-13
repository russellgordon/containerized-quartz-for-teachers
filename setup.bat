@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Ensure we're in the same directory as this script
cd /d "%~dp0"

REM Ensure the host-side courses folder exists
if not exist "courses" (
  echo 📁 Creating 'courses' directory on host...
  mkdir "courses"
)

REM Ensure a writable backups folder (backups live inside courses\_backups)
if not exist "courses\_backups" (
  echo 📦 Creating 'courses\_backups' directory on host...
  mkdir "courses\_backups"
)

REM Note: chmod is not applicable on Windows/Docker Desktop; skipping permission adjustments.

set "CONTAINER_NAME=teaching-quartz"

REM Check if the container exists
set "EXISTS="
for /f "usebackq delims=" %%A in (`docker ps -a --format "{{.Names}}" ^| findstr /r /c:"^%CONTAINER_NAME%$"`) do (
  set "EXISTS=1"
)

if defined EXISTS (
  REM Container exists; check if it's running
  set "RUNNING="
  for /f "usebackq delims=" %%A in (`docker ps --format "{{.Names}}" ^| findstr /r /c:"^%CONTAINER_NAME%$"`) do (
    set "RUNNING=1"
  )
  if defined RUNNING (
    echo 🛑 Stopping running container %CONTAINER_NAME% to refresh volume mount...
    docker stop "%CONTAINER_NAME%" >nul
  )
  echo 🚀 Starting existing container %CONTAINER_NAME%...
  docker start "%CONTAINER_NAME%" >nul
) else (
  echo 🚀 Creating a new container named %CONTAINER_NAME%...
  REM Bind-mount the host courses folder into the container
  REM Note: Docker Desktop for Windows accepts Windows paths like C:\path in -v.
  docker run -dit ^
    --name "%CONTAINER_NAME%" ^
    -v "%CD%\courses:/teaching/courses" ^
    -p 8081:8081 ^
    teaching-quartz ^
    tail -f /dev/null
  if errorlevel 1 (
    echo ❌ Failed to create the container. Ensure Docker Desktop is running.
    exit /b 1
  )
)

REM Detect host timezone offset in ±HHMM format via PowerShell
for /f "usebackq delims=" %%Z in (`powershell -NoProfile -Command "(Get-Date).ToString('zzz').Replace(':','')"`) do set "HOST_TZ_OFFSET=%%Z"
echo 🕒 Detected host timezone offset: %HOST_TZ_OFFSET%
echo 🛟 Backups will be written to: %CD%\courses\_backups

REM If the user passed --no-backup, require confirmation
set "NOBACKUP="
echo %* | findstr /I /C:"--no-backup" >nul && set "NOBACKUP=1"

if defined NOBACKUP (
  echo ⚠️  You are running with --no-backup.
  echo     This will skip creating a safety ZIP before modifying course folders.
  set /p CONFIRM=❓ Are you sure you want to proceed without a backup? (yes/no) 
  if /I not "%CONFIRM%"=="yes" if /I not "%CONFIRM%"=="y" (
    echo ❌ Cancelled.
    exit /b 1
  )
  echo Proceeding without backup...
)

REM Run the setup script inside the container, passing the timezone offset
REM Forward any flags/args provided to this script (e.g., --no-backup)
echo 📚 Running setup_course.py inside the Docker container...
docker exec -e HOST_TZ_OFFSET="%HOST_TZ_OFFSET%" -it "%CONTAINER_NAME%" ^
  python3 /opt/scripts/setup_course.py %*

endlocal
