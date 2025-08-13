@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Ensure we're in the same directory as this script
cd /d "%~dp0"

REM ---------------------------
REM Arguments
REM ---------------------------
set "COURSE=%~1"
set "SECTION=%~2"

REM Shift COURSE and SECTION out of the way
shift
shift

REM Initialize flags
set "INCLUDE_SOCIAL="
set "FORCE_NPM_INSTALL="
set "FULL_REBUILD="

REM Display help text if requested
if /I "%~1"=="--help"  goto :help
if /I "%~1"=="-h"      goto :help
goto :parseFlags

:help
echo.
echo 🧰 Usage:
echo   preview.bat ^<COURSE_CODE^> ^<SECTION_NUMBER^> [options]
echo.
echo 📘 Required arguments:
echo   ^<COURSE_CODE^>               The course code (e.g., ICS3U)
echo   ^<SECTION_NUMBER^>            The TIMETABLE section number (e.g., 1, 3, 4)
echo.
echo ⚙️ Optional flags:
echo   --include-social-media-previews    Enable Quartz CustomOgImages emitter
echo   --force-npm-install                Force npm install even if dependencies are present
echo   --full-rebuild                     Clear entire output folder and re-copy Quartz scaffold
echo   --help, -h                         Show this help message
echo.
echo 📂 Output location (hidden in Obsidian Files pane):
echo   courses\^<COURSE_CODE^>\.merged_output\section^<SECTION_NUMBER^>
echo.
exit /b 0

:parseFlags
REM Parse optional flags
:flagLoop
if "%~1"=="" goto :afterFlags

if /I "%~1"=="--include-social-media-previews" (
  set "INCLUDE_SOCIAL=--include-social-media-previews"
) else if /I "%~1"=="--force-npm-install" (
  set "FORCE_NPM_INSTALL=--force-npm-install"
) else if /I "%~1"=="--full-rebuild" (
  set "FULL_REBUILD=--full-rebuild"
) else (
  echo ❌ Unknown option: %~1
  echo Use "preview.bat --help" to see usage instructions.
  exit /b 1
)
shift
goto :flagLoop

:afterFlags
REM Validate course and section
if not defined COURSE (
  echo ❌ Missing required arguments.
  echo Use "preview.bat --help" to see usage instructions.
  exit /b 1
)
if not defined SECTION (
  echo ❌ Missing required arguments.
  echo Use "preview.bat --help" to see usage instructions.
  exit /b 1
)

REM Ensure SECTION looks like a positive integer
echo %SECTION%| findstr /R "^[0-9][0-9]*$" >nul
if errorlevel 1 (
  echo ❌ SECTION must be a positive integer (the timetable section number).
  exit /b 1
)

set "OUTPUT_PATH=courses\%COURSE%\.merged_output\section%SECTION%"

REM Preflight: ensure this course has been set up (host-side)
set "COURSE_CFG=courses\%COURSE%\course_config.json"
if not exist "%COURSE_CFG%" (
  echo ⚠️  "%COURSE_CFG%" not found.
  echo    It looks like you haven't completed setup for "%COURSE%" yet.
  echo    Run: setup.bat
  echo    (Then select or create the course "%COURSE%" when prompted.)
  exit /b 1
)

REM Preflight: the section folder should exist (setup_course.py creates "section<N>")
if not exist "courses\%COURSE%\section%SECTION%" (
  echo ⚠️  courses\%COURSE%\section%SECTION% does not exist.
  echo    If this is one of your timetable sections, run "setup.bat" again and include section %SECTION%.
  echo    Otherwise, choose one of YOUR assigned sections when running this command.
  REM don't exit here yet; we'll validate against section_numbers below
)

echo 🚀 Starting container if needed...
docker start teaching-quartz >nul 2>&1
if errorlevel 1 (
  echo 🚀 Creating new container named teaching-quartz...
  docker run -dit ^
    --name teaching-quartz ^
    -v "%CD%\courses:/teaching/courses" ^
    -p 8081:8081 ^
    teaching-quartz ^
    tail -f /dev/null
  if errorlevel 1 (
    echo ❌ Failed to start or create the Docker container. Is Docker Desktop running?
    exit /b 1
  )
)

REM Preflight: nudge if quartz.layout.ts in the container wasn't initialized by setup.bat
echo 🔎 Preflight: checking Quartz sidebar anchor...
docker exec teaching-quartz sh -lc "test -f /opt/quartz/quartz.layout.ts && grep -q 'const omit = new Set' /opt/quartz/quartz.layout.ts" >nul 2>&1
if errorlevel 1 (
  echo ⚠️  Sidebar omit anchor not found in container's Quartz layout.
  echo    Did you run: setup.bat and complete setup for "%COURSE%"?
  echo    (Continuing anyway; the build will attempt a safe fallback.)
)

REM NEW: Validate that SECTION is one of the allowed timetable sections for this course
echo 📋 Checking allowed timetable sections for %COURSE%...
set "ALLOWED_SECTIONS="

for /f "usebackq delims=" %%S in (`docker exec teaching-quartz python3 -c "import json,sys; p=r'/teaching/courses/%COURSE%/course_config.json'; 
try:
    with open(p,'r',encoding='utf-8') as f:
        cfg=json.load(f)
    secs=cfg.get('section_numbers')
    if isinstance(secs,list) and secs:
        print(','.join(str(int(x)) for x in secs))
    else:
        n=int(cfg.get('num_sections',1))
        print(','.join(str(i) for i in range(1,n+1)))
except Exception as e:
    print('')"`) do (
  set "ALLOWED_SECTIONS=%%S"
)

if defined ALLOWED_SECTIONS (
  echo    Allowed sections: %ALLOWED_SECTIONS%
  set "FOUND="
  for %%A in (%ALLOWED_SECTIONS%) do (
    if "%%~A"=="%SECTION%" set "FOUND=1"
  )
  if not defined FOUND (
    echo ❌ Section %SECTION% is not one of YOUR timetable sections for %COURSE%.
    echo    Choose one of: %ALLOWED_SECTIONS%
    exit /b 1
  )
) else (
  echo ℹ️ Could not read allowed sections from course_config.json ^(continuing^).
)

echo 🔧 Building site for %COURSE%, section %SECTION%...
echo 📂 Output will be written to: %OUTPUT_PATH%

docker exec -it teaching-quartz python3 /opt/scripts/build_site.py ^
  --course="%COURSE%" ^
  --section="%SECTION%" ^
  %INCLUDE_SOCIAL% ^
  %FORCE_NPM_INSTALL% ^
  %FULL_REBUILD%

endlocal
