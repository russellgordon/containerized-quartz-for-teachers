#requires -Version 5.1
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ======================
# preview.ps1 — Windows equivalent of preview.sh
# ======================

# ---- Positional args ----
if ($args.Count -lt 2 -or ($args[0] -eq '--help') -or ($args[0] -eq '-h')) {
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  .\preview.ps1 <COURSE_CODE> <SECTION_NUMBER> [options]"
    Write-Host ""
    Write-Host "Required:"
    Write-Host "  <COURSE_CODE>     e.g., ICS3U"
    Write-Host "  <SECTION_NUMBER>  e.g., 1"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --include-social-media-previews   Enable Quartz CustomOgImages emitter"
    Write-Host "  --force-npm-install               Force npm install even if deps present"
    Write-Host "  --full-rebuild                    Clear entire output folder and re-copy scaffold"
    Write-Host "  --build-only                      Build static site only (no local preview server)"
    Write-Host "  --help, -h                        Show this help and exit"
    Write-Host ""
    Write-Host "Output location:"
    Write-Host "  courses/<COURSE>/.merged_output/section<SECTION>"
    exit 1
}

$COURSE  = $args[0].ToUpper()
$SECTION = $args[1]
if (-not ($SECTION -as [int])) {
    Write-Host "SECTION_NUMBER must be an integer. Got: $SECTION"
    exit 1
}

# ---- Shift positional args and parse flags ----
$Flags = @(); if ($args.Count -gt 2) { $Flags = $args | Select-Object -Skip 2 }
$INCLUDE_SOCIAL    = $false
$FORCE_NPM_INSTALL = $false
$FULL_REBUILD      = $false
$BUILD_ONLY        = $false

if ($Flags) {
    $i = 0
    while ($i -lt $Flags.Count) {
        switch ($Flags[$i]) {
            '--include-social-media-previews' { $INCLUDE_SOCIAL = $true; $i++; continue }
            '--force-npm-install'             { $FORCE_NPM_INSTALL = $true; $i++; continue }
            '--full-rebuild'                  { $FULL_REBUILD = $true; $i++; continue }
            '--build-only'                    { $BUILD_ONLY = $true; $i++; continue }
            default {
                Write-Host "Unknown option: $($Flags[$i])"
                exit 1
            }
        }
    }
}

# ---- Guardrail: course codes ending with zero vs letter O ----
if ($COURSE -match '^[A-Z]{3}[0-9]0$') {
    $SUGGESTED = $COURSE.Substring(0, $COURSE.Length - 1) + 'O'
    Write-Host ""
    Write-Host "It looks like you entered '$COURSE' (ends with zero)."
    Write-Host "Ontario 'Open' level course codes end with the LETTER 'O' (oh)."
    if ((Test-Path -LiteralPath ("courses/{0}/course_config.json" -f $SUGGESTED)) -and -not (Test-Path -LiteralPath ("courses/{0}/course_config.json" -f $COURSE))) {
        Write-Host "I see setup data for '$SUGGESTED' on disk."
    }
    $ans = Read-Host ("Fix course code to '{0}'? [Y/n]" -f $SUGGESTED)
    if (($ans -eq '') -or ($ans -match '^(?i:y)$')) {
        $COURSE = $SUGGESTED
        Write-Host "Using corrected course code: $COURSE"
    } else {
        Write-Host "Continuing with: $COURSE"
    }
    Write-Host ""
}

# ---- Paths ----
# Ensure we run from script directory
if ($PSScriptRoot) {
    Set-Location -LiteralPath $PSScriptRoot
} else {
    Set-Location -LiteralPath (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
}
$CoursesRoot = Join-Path (Get-Location) 'courses'
if (-not (Test-Path -LiteralPath $CoursesRoot)) {
    New-Item -ItemType Directory -Path $CoursesRoot -Force | Out-Null
}
$HOST_COURSES = (Resolve-Path -LiteralPath $CoursesRoot).Path

function Normalize-HostPath([string]$p) {
    if (-not $p) { return $p }
    try { (Resolve-Path -LiteralPath $p).Path.TrimEnd('\','/') } catch { $p.TrimEnd('\','/') }
}

# ---- Container handling (mount-aware) ----
$CONTAINER_NAME = 'teaching-quartz'

function Test-ImagePresent([string]$ref) {
    try { docker image inspect "$ref" *> $null; return $true } catch { return $false }
}

# preview.sh uses local image name `teaching-quartz`. If missing, fall back to pulling Docker Hub image.
$IMAGE = 'teaching-quartz'
if (-not (Test-ImagePresent $IMAGE)) {
    $IMAGE = 'rwhgrwhg/teaching-quartz:latest'
    if (-not (Test-ImagePresent $IMAGE)) {
        Write-Host "Pulling $IMAGE ..."
        docker pull "$IMAGE" | Out-Host
    }
}

function Run-ContainerWithMount {
    Write-Host ("Binding host courses to container: {0} -> /teaching/courses" -f $HOST_COURSES)
    docker run -dit `
        --name "$CONTAINER_NAME" `
        -v "${HOST_COURSES}:/teaching/courses" `
        -p 8081:8081 `
        "$IMAGE" `
        tail -f /dev/null | Out-Null
}

$containerExists = ((docker ps -a --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) -ne $null
if ($containerExists) {
    # check mount
    $CURRENT_MOUNT_SRC = $null
    try {
        $cinfo = docker inspect "$CONTAINER_NAME" | ConvertFrom-Json
        if ($cinfo -and $cinfo.Count -gt 0) {
            foreach ($m in $cinfo[0].Mounts) {
                if ($m.Destination -eq "/teaching/courses") { $CURRENT_MOUNT_SRC = $m.Source; break }
            }
        }
    } catch {}
    $CURRENT_MOUNT_SRC = Normalize-HostPath $CURRENT_MOUNT_SRC
    $HOST_COURSES_N = Normalize-HostPath $HOST_COURSES

    if (-not $CURRENT_MOUNT_SRC) {
        Write-Host "Existing container has no /teaching/courses mount; recreating with correct mount ..."
        if ((docker ps --format '{{.Names}}' | Where-Object { $_ -eq $CONTAINER_NAME })) { docker stop "$CONTAINER_NAME" *> $null }
        docker rm "$CONTAINER_NAME" *> $null
        Run-ContainerWithMount
    } elseif ($CURRENT_MOUNT_SRC -ne $HOST_COURSES_N) {
        Write-Host "Detected different working directory:"
        Write-Host "  Existing mount: $CURRENT_MOUNT_SRC"
        Write-Host "  Desired mount:  $HOST_COURSES_N"
        Write-Host "Recreating container '$CONTAINER_NAME' to point at the new folder ..."
        if ((docker ps --format '{{.Names}}' | Where-Object { $_ -eq $CONTAINER_NAME })) { docker stop "$CONTAINER_NAME" *> $null }
        docker rm "$CONTAINER_NAME" *> $null
        Run-ContainerWithMount
    } else {
        $running = ((docker ps --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) -ne $null
        if (-not $running) {
            Write-Host "Starting existing container $CONTAINER_NAME ..."
            docker start "$CONTAINER_NAME" *> $null
        } else {
            Write-Host "Container $CONTAINER_NAME is already running with correct mount."
        }
    }
} else {
    Write-Host "Creating a new container named $CONTAINER_NAME (image: $IMAGE) ..."
    Run-ContainerWithMount
}

# ---- Validate SECTION against course_config.json ----
Write-Host "Checking allowed timetable sections for $COURSE ..."

# Read course_config.json from host (bind-mounted into container), avoids quoting issues
$configPath = Join-Path (Join-Path $CoursesRoot $COURSE) 'course_config.json'
$allowed = ''
if (Test-Path -LiteralPath $configPath) {
    try {
        $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        $secs = $cfg.section_numbers
        if ($secs -and $secs.Count -gt 0) {
            $allowed = ($secs | ForEach-Object { [int]$_ }) -join ','
        } else {
            $n = 1
            if ($cfg.num_sections) { $n = [int]$cfg.num_sections }
            $allowed = (1..$n) -join ','
        }
    } catch {
        $allowed = ''
    }
} else {
    Write-Host "No course_config.json found at $configPath"
}

$allowed = ($allowed -replace '\r','').Trim()
if ($allowed) {
    Write-Host "Allowed sections: $allowed"
    $list = $allowed.Split(',') | ForEach-Object { $_.Trim() }
    if ($list -notcontains ($SECTION.ToString())) {
        Write-Host "WARNING: Section $SECTION is not listed in course_config.json for $COURSE."
        $c = Read-Host "Continue anyway? [y/N]"
        if ($c -notmatch '^(?i:y)$') { Write-Host "Cancelled."; exit 1 }
    }
} else {
    Write-Host "Could not determine allowed sections from course_config.json; proceeding."
}

# ---- Announce output path ----
$OUTPUT_PATH = "courses/{0}/.merged_output/section{1}" -f $COURSE, $SECTION
Write-Host ("Output will be written to: {0}" -f $OUTPUT_PATH)

# ---- Map flags to build_site.py args ----
$argList = @("--course=$COURSE","--section=$SECTION","--host-os","windows")
if ($INCLUDE_SOCIAL)    { $argList += "--include-social-media-previews" }
if ($FORCE_NPM_INSTALL) { $argList += "--force-npm-install" }
if ($FULL_REBUILD)      { $argList += "--full-rebuild" }
if ($BUILD_ONLY)        { $argList += "--build-only" }

# ---- Run build inside the container ----
Write-Host "Running build_site.py inside the Docker container ..."
# Use -it for interactive prompts; pass array to avoid quoting issues
docker exec -it "$CONTAINER_NAME" python3 /opt/scripts/build_site.py $argList

