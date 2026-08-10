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
    $SELF_CMD = '.\preview.bat'
} else {
    $SELF_CMD = './preview.sh'
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
# preview.ps1 — Windows equivalent of preview.sh
# ======================

# ---- Positional args ----
if ($args.Count -lt 2 -or ($args[0] -eq '--help') -or ($args[0] -eq '-h')) {
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host " $SELF_CMD <COURSE_CODE> <SECTION_NUMBER> [options]"
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

# ==================== Container runtime (Docker Engine in WSL2) ====================
# Docker Desktop is no longer required. On Windows this script uses the Docker
# Engine running inside WSL2 (Windows Subsystem for Linux) and installs/starts
# it automatically as needed. If a native 'docker' command already works (for
# example, Docker Desktop or Rancher Desktop), it is used as-is.

$env:WSL_UTF8 = '1'   # make wsl.exe emit UTF-8 so PowerShell can parse its output
$global:DockerViaWsl = $false
$global:WslUserArgs  = @()

function Test-NativeDockerReady {
    if (-not (Get-Command docker -CommandType Application -ErrorAction SilentlyContinue)) { return $false }
    try { docker info *> $null } catch { return $false }
    return ($LASTEXITCODE -eq 0)
}

function Test-WslDockerReady {
    try { wsl $global:WslUserArgs -e docker info *> $null } catch { return $false }
    return ($LASTEXITCODE -eq 0)
}

function Use-WslDocker {
    $global:DockerViaWsl = $true
    # Shadow 'docker' so every call in this script is routed through WSL.
    # PowerShell functions take precedence over external commands.
    function global:docker { & wsl $global:WslUserArgs -e docker @args }
    Write-Host "Using the Docker engine inside WSL2."
}

function Ensure-ContainerRuntime {
    if (Test-NativeDockerReady) { return }

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: No container runtime found."
        Write-Host "Install WSL2 (Windows Subsystem for Linux) by running this in an"
        Write-Host "Administrator PowerShell, then reboot and re-run this script:"
        Write-Host "  wsl --install"
        exit 1
    }

    $distros = @()
    try { $distros = (wsl -l -q) | Where-Object { $_ -and $_.Trim() } } catch {}
    if (-not $distros) {
        Write-Host "ERROR: WSL is present but no Linux distribution is installed."
        Write-Host "Run this in PowerShell, then reboot and re-run this script:"
        Write-Host "  wsl --install"
        exit 1
    }

    # Already-running engine inside WSL? (Try as the default user, then as root.)
    if (Test-WslDockerReady) { Use-WslDocker; return }
    $global:WslUserArgs = @('-u','root')
    if (Test-WslDockerReady) { Use-WslDocker; return }
    $global:WslUserArgs = @()

    # Is the engine installed inside WSL at all?
    $dockerInWsl = $false
    try { wsl -e sh -c "command -v docker" *> $null; $dockerInWsl = ($LASTEXITCODE -eq 0) } catch {}

    if (-not $dockerInWsl) {
        Write-Host "The Docker engine is not installed inside WSL yet."
        $ans = Read-Host "Install it now inside your WSL distribution? (Y/n)"
        if ($ans -and $ans -notmatch '^(?i:y)') { Write-Host "Cancelled. A container runtime is required to continue."; exit 1 }
        Write-Host "Installing the Docker engine inside WSL (this can take a few minutes)..."
        wsl -u root -e sh -c "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Could not install the Docker engine inside WSL."
            Write-Host "Check your internet connection and re-run this script - it is safe to re-run."
            exit 1
        }
        $wslUser = ''
        try { $wslUser = (wsl -e sh -c "whoami" 2>$null | Select-Object -First 1).Trim() } catch {}
        if ($wslUser -and $wslUser -ne 'root') { wsl -u root -e sh -c "usermod -aG docker $wslUser" *> $null }
    }

    Write-Host "Starting the Docker engine inside WSL..."
    try { wsl -u root -e sh -c "service docker start" *> $null } catch {}

    for ($i = 0; $i -lt 30; $i++) {
        if (Test-WslDockerReady) { Use-WslDocker; return }
        $global:WslUserArgs = @('-u','root')
        if (Test-WslDockerReady) { Use-WslDocker; return }
        $global:WslUserArgs = @()
        Start-Sleep -Seconds 2
    }

    Write-Host "ERROR: The Docker engine inside WSL did not become ready."
    Write-Host "Try these commands, then re-run this script:"
    Write-Host "  wsl -u root -e sh -c 'service docker start'"
    Write-Host "  wsl -e docker info"
    exit 1
}

# Docker running inside WSL sees Windows folders under /mnt/<drive>/...;
# translate host paths for bind mounts when routing through WSL.
function Get-MountPath([string]$winPath) {
    if (-not $global:DockerViaWsl) { return $winPath }
    try {
        $p = (wsl -e wslpath -a "$winPath" | Select-Object -First 1)
        if ($p) { return $p.Trim() }
    } catch {}
    return $winPath
}

Ensure-ContainerRuntime
$MOUNT_COURSES = Get-MountPath $HOST_COURSES
# ====================================================================

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

# -------------------- Offer a newer version, if one exists --------------------
# An image already on the machine was never checked again, so a teacher kept
# whatever they first downloaded and fixes never reached them.
function Get-RegistryDigest([string]$ref) {
  try { return (docker buildx imagetools inspect "$ref" --format '{{.Manifest.Digest}}' 2>$null | Select-Object -First 1) } catch { return $null }
}

function Get-InstalledDigest([string]$ref) {
  # Only a digest belonging to THIS repository says anything about whether the
  # local image came from it; a locally built image often carries a digest for
  # another repository, which would look like an available update forever.
  try {
    $repo = $ref.Split(':')[0]
    $entries = docker image inspect "$ref" --format '{{range .RepoDigests}}{{println .}}{{end}}' 2>$null
    foreach ($entry in $entries) {
      if (-not $entry) { continue }
      $parts = $entry.Split('@')
      if ($parts.Length -eq 2 -and $parts[0] -eq $repo) { return $parts[1] }
    }
    return $null
  } catch { return $null }
}

function Offer-NewerImage([string]$ref) {
  # A locally built image has no registry to ask about it.
  if ($ref -notmatch '/') { return }

  $available = Get-RegistryDigest $ref
  $installed = Get-InstalledDigest $ref
  # Offline, or nothing to compare: carry on with what is here.
  if ((-not $available) -or (-not $installed) -or ($available -eq $installed)) { return }

  # A different digest does not mean an older one. If the registry has never
  # heard of the installed digest, this is a locally built image and
  # "updating" it would replace it with something older.
  $repo = $ref.Split(':')[0]
  docker buildx imagetools inspect "$repo@$installed" *> $null
  if ($LASTEXITCODE -ne 0) { return }

  Write-Host "A newer version of the website builder is available."
  if (-not [Environment]::UserInteractive) {
    Write-Host "  Run this again with --update-image when you would like to install it."
    return
  }
  $answer = Read-Host "  Update the website builder now? (y/n) [Default: y]"
  if ($answer -match '^[Nn]') {
    Write-Host "  Keeping the version you have."
    return
  }
  Write-Host "Installing the newer version ..."
  docker pull "$ref" | Out-Host
}

Offer-NewerImage $IMAGE

function Run-ContainerWithMount {
    Write-Host ("Binding host courses to container: {0} -> /teaching/courses" -f $MOUNT_COURSES)
    docker run -dit `
        --name "$CONTAINER_NAME" `
        -v "${MOUNT_COURSES}:/teaching/courses" `
        -p 8081:8081 `
        "$IMAGE" `
        tail -f /dev/null | Out-Null
}

# A container keeps running the version it was created from, so an update
# only takes effect once the container itself is recreated.
$DESIRED_IMAGE_ID = (docker image inspect --format '{{.Id}}' "$IMAGE" 2>$null | Select-Object -First 1)
$RUNNING_IMAGE_ID = (docker inspect -f '{{.Image}}' "$CONTAINER_NAME" 2>$null | Select-Object -First 1)

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
    $HOST_COURSES_N = Normalize-HostPath $MOUNT_COURSES

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
    } elseif ($DESIRED_IMAGE_ID -and $RUNNING_IMAGE_ID -and ($RUNNING_IMAGE_ID -ne $DESIRED_IMAGE_ID)) {
        Write-Host "Your workspace was built from an older version; rebuilding it so the update takes effect ..."
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