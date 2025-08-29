#requires -Version 5.1
$ErrorActionPreference = 'Stop'
# ---- Determine host OS for help text ---------------------------------
function Get-HostOS {
    try { if ($IsWindows) { return 'windows' } } catch {}
    try { if ([System.Environment]::OSVersion.Platform.ToString() -eq 'Win32NT') { return 'windows' } } catch {}
    try {
        if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) { return 'windows' }
        if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::OSX))     { return 'mac' }
        if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux))   { return 'linux' }
    } catch {}
    if ($env:OS -eq 'Windows_NT') { return 'windows' }
    try {
        $u = (uname -s 2>$null)
        if ($u -match 'Darwin') { return 'mac' }
        if ($u -match 'Linux')  { return 'linux' }
    } catch {}
    return 'unknown'
}
$__hostOS = Get-HostOS
if ($__hostOS -eq 'windows') {
    $SELF_CMD = '.\deploy.bat'
} else {
    $SELF_CMD = './deploy.sh'
}
# Cross-script command hints for help text
if ($__hostOS -eq 'windows') {
    $SETUP_CMD   = '.\setup.bat'
    $PREVIEW_CMD = '.\preview.bat'
    $DEPLOY_CMD  = '.\deploy.bat'
} else {
    $SETUP_CMD   = './setup.sh'
    $PREVIEW_CMD = './preview.sh'
    $DEPLOY_CMD  = './deploy.sh'
}

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ======================
# deploy.ps1 — Windows equivalent of deploy.sh
# ======================

# ---- Usage ----
if ($args.Count -lt 2 -or $args[0] -in @('--help','-h')) {
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host " $SELF_CMD <COURSE_CODE> <SECTION_NUMBER> [options]"
    Write-Host ""
    Write-Host "Required:"
    Write-Host "  <COURSE_CODE>     e.g., ICS3U"
    Write-Host "  <SECTION_NUMBER>  e.g., 1"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --team <TEAM_SLUG>    Deploy under a specific Netlify team (advanced)"
    Write-Host "  --diagnose            Print extra diagnostics during deploy"
    Write-Host "  --help, -h            Show this help and exit"
    Write-Host ""
    Write-Host "Notes:"
    Write-Host "  - Deploys from /teaching/courses/<COURSE>/.merged_output/section<SECTION> inside the container."
    Write-Host "  - You must build first (static site goes to 'public/' in that section folder)."
    Write-Host "  - On first deploy you'll be prompted for a Netlify Personal Access Token; it's saved for reuse."
    exit 1
}

# ---- Positional ----
$COURSE  = $args[0].ToUpper()
$SECTION = $args[1]
if (-not ($SECTION -as [int])) { Write-Host "SECTION_NUMBER must be an integer. Got: $SECTION"; exit 1 }

# ---- Flags ----
$TEAM_SLUG = $null
$DIAGNOSE  = $false
$Passthru  = @()

if ($args.Count -gt 2) {
    $i = 2
    while ($i -lt $args.Count) {
        switch ($args[$i]) {
            '--team'        { if ($i+1 -ge $args.Count) { Write-Host "--team requires a value"; exit 1 }; $TEAM_SLUG = $args[$i+1]; $i+=2; continue }
            '--team-slug'   { if ($i+1 -ge $args.Count) { Write-Host "--team-slug requires a value"; exit 1 }; $TEAM_SLUG = $args[$i+1]; $i+=2; continue }
            '--diagnose'    { $DIAGNOSE = $true; $i++; continue }
            default         { $Passthru += $args[$i]; $i++; continue }
        }
    }
}

# ---- Guardrail: '0' vs 'O' ----
if ($COURSE -match '^[A-Z]{3}[0-9]0$') {
    $suggested = $COURSE.Substring(0, $COURSE.Length - 1) + 'O'
    Write-Host ""
    Write-Host "It looks like you entered '$COURSE' (ends with zero)."
    Write-Host "Ontario 'Open' level course codes end with the LETTER 'O' (oh)."
    $ans = Read-Host ("Fix course code to '{0}'? [Y/n]" -f $suggested)
    if (($ans -eq '') -or ($ans -match '^(?i:y)$')) {
        $COURSE = $suggested
        Write-Host "Using corrected course code: $COURSE"
    } else {
        Write-Host "Continuing with: $COURSE"
    }
    Write-Host ""
}

# ---- Resolve script dir & host folders ----
# Prefer $PSScriptRoot; fallback to Split-Path
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
if (-not $scriptDir) { $scriptDir = Get-Location }
Set-Location -LiteralPath $scriptDir

$CoursesRoot = Join-Path (Get-Location) 'courses'
if (-not (Test-Path -LiteralPath $CoursesRoot)) {
    New-Item -ItemType Directory -Path $CoursesRoot -Force | Out-Null
}
function Normalize-HostPath([string]$p) {
    if (-not $p) { return $p }
    try { (Resolve-Path -LiteralPath $p).Path.TrimEnd('\','/') } catch { $p.TrimEnd('\','/') }
}
$HOST_COURSES = Normalize-HostPath $CoursesRoot

# ---- Container handling (mount-aware) ----
$CONTAINER_NAME = 'teaching-quartz'
function Test-ImagePresent([string]$ref) { try { docker image inspect "$ref" *> $null; $true } catch { $false } }

# Use local 'teaching-quartz' if present; else pull Hub image
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

    if (-not $CURRENT_MOUNT_SRC) {
        Write-Host "Existing container has no /teaching/courses mount; recreating with correct mount ..."
        if ((docker ps --format '{{.Names}}' | Where-Object { $_ -eq $CONTAINER_NAME })) { docker stop "$CONTAINER_NAME" *> $null }
        docker rm "$CONTAINER_NAME" *> $null
        Run-ContainerWithMount
    } elseif ($CURRENT_MOUNT_SRC -ne $HOST_COURSES) {
        Write-Host "Detected different working directory:"
        Write-Host "  Existing mount: $CURRENT_MOUNT_SRC"
        Write-Host "  Desired mount:  $HOST_COURSES"
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

# ---- Announce and TZ ----
$HOST_TZ_OFFSET = (Get-Date).ToString('zzz').Replace(':','')
Write-Host "Host timezone offset: $HOST_TZ_OFFSET"
$SECTION_PATH_IN_CONTAINER = "/teaching/courses/$COURSE/.merged_output/section$SECTION"
Write-Host ("Deploying {0} S{1} from: {2}" -f $COURSE, $SECTION, $SECTION_PATH_IN_CONTAINER)

# ---- Build deploy.py args ----
$argList = @("--course", $COURSE, "--section", $SECTION, "--host-os", "windows")
if ($TEAM_SLUG) { $argList += @("--team", $TEAM_SLUG) }
if ($DIAGNOSE)  { $argList += "--diagnose" }

# ---- Run deploy inside container ----
docker exec -e HOST_TZ_OFFSET=$HOST_TZ_OFFSET -it "$CONTAINER_NAME" python3 /opt/scripts/deploy.py $argList

docker exec -e HOST_TZ_OFFSET=$HOST_TZ_OFFSET -it "$CONTAINER_NAME" python3 /opt/scripts/deploy.py $argList