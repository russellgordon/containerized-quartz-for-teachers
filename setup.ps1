#requires -Version 5.1
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ======================
# Defaults
# ---- Determine host OS for help text ---------------------------------
function Get-HostOS {
    try {
        if ($IsWindows) { return 'windows' }
        if ($IsMacOS)   { return 'mac' }
        if ($IsLinux)   { return 'linux' }
    } catch {
        if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) { return 'windows' }
        if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::OSX))     { return 'mac' }
        if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux))   { return 'linux' }
    }
    return 'unknown'
}
$__hostOS = Get-HostOS
if ($__hostOS -eq 'windows') {
    $SELF_CMD = '.\setup.ps1'
} else {
    $SELF_CMD = './setup.sh'
}
# Cross-script command hints for help text
if ($__hostOS -eq 'windows') {
    $SETUP_CMD   = '.\setup.ps1'
    $PREVIEW_CMD = '.\preview.ps1'
    $DEPLOY_CMD  = '.\deploy.ps1'
} else {
    $SETUP_CMD   = './setup.sh'
    $PREVIEW_CMD = './preview.sh'
    $DEPLOY_CMD  = './deploy.sh'
}
# ----------------------------------------------------------------------

# ======================
$HUB_USER        = 'rwhgrwhg'
$DEFAULT_TAG     = 'latest'
$IMAGE_NAME      = 'teaching-quartz'
$CONTAINER_NAME  = 'teaching-quartz'
$HOST_PORT       = 8081
$CONTAINER_PORT  = 8081
$DEV_IMAGE       = 'quartz-teacher:dev'   # convenient local dev image

# ======================
# Config (from flags)
# ======================
$TAG                     = $DEFAULT_TAG
$FORCE_UPDATE_IMAGE      = $false
$OVERRIDE_IMAGE          = $null
$USE_LOCAL_DEV           = $false
$DOCKER_CONTEXT_OVERRIDE = $null
$SKIP_PULL               = $false
$PassthruArgs            = @()

function Show-Help {
@"
Usage: $SELF_CMD [options] [-- <args passed to setup_course.py>]

Options:
  --tag TAG            Use a specific tag instead of 'latest' (default: $DEFAULT_TAG)
  --update-image       Force pulling the image and recreating the container to use it.
  --image REF          Use a specific image reference (overrides Docker Hub default).
                       Examples: ghcr.io/me/teaching-quartz:main  |  quartz-teacher:dev
                       Note: If REF has no '/', it's treated as a local image and won't be pulled.
  --local-dev          Shortcut for --image "$DEV_IMAGE" and skipping docker pull
                       (use after building locally with: docker build -t $DEV_IMAGE .)
  --context NAME       Use a specific Docker context (sets DOCKER_CONTEXT=NAME for this run).
  --no-backup          (Pass-through to setup_course.py) Skip creating a backup ZIP — you will be asked to confirm.
  --help               Show this help and exit.

Notes:
- By default this script pulls from the public Docker Hub image:  $HUB_USER/$IMAGE_NAME
  Tag defaults to 'latest' unless overridden with --tag.
- Use --local-dev to test your locally built image ($DEV_IMAGE) without pulling.
- Any arguments after a literal "--" are forwarded directly to setup_course.py.

Examples:
  $SELF_CMD
  $SELF_CMD --tag v2025.08.13
  $SELF_CMD --update-image
  $SELF_CMD --image ghcr.io/acme/teaching-quartz:edge
  $SELF_CMD --local-dev
  $SELF_CMD --context desktop-linux --local-dev
  $SELF_CMD -- --no-backup
"@ | Out-Host
}

# ======================
# Arg parsing
# ======================
$idx = 0
while ($idx -lt $args.Count) {
    $a = $args[$idx]
    switch -Regex ($a) {
        '^(--help|-h)$' {
            Show-Help
            exit 0
        }
        '^--tag$' {
            if ($idx + 1 -ge $args.Count) { Write-Error '--tag requires a value'; exit 1 }
            $TAG = $args[$idx + 1]; $idx += 2; continue
        }
        '^--update-image$' {
            $FORCE_UPDATE_IMAGE = $true; $idx++; continue
        }
        '^--image$' {
            if ($idx + 1 -ge $args.Count) { Write-Error '--image requires a value'; exit 1 }
            $OVERRIDE_IMAGE = $args[$idx + 1]; $idx += 2; continue
        }
        '^--local-dev$' {
            $USE_LOCAL_DEV = $true; $idx++; continue
        }
        '^--context$' {
            if ($idx + 1 -ge $args.Count) { Write-Error '--context requires a value'; exit 1 }
            $DOCKER_CONTEXT_OVERRIDE = $args[$idx + 1]; $idx += 2; continue
        }
        '^--$' {
            if ($idx + 1 -lt $args.Count) {
                $PassthruArgs = $args[($idx + 1)..($args.Count - 1)]
            } else {
                $PassthruArgs = @()
            }
            $idx = $args.Count
            continue
        }
        default {
            $PassthruArgs += $a
            $idx++
            continue
        }
    }
}

# ======================
# Pre-flight: context
# ======================
if ($DOCKER_CONTEXT_OVERRIDE) {
    $env:DOCKER_CONTEXT = $DOCKER_CONTEXT_OVERRIDE
}

# ======================
# Resolve image to use
# ======================
if ($USE_LOCAL_DEV) {
    $OVERRIDE_IMAGE = $DEV_IMAGE
    $SKIP_PULL = $true
}
if ($OVERRIDE_IMAGE -and ($OVERRIDE_IMAGE -notmatch '/')) {
    $SKIP_PULL = $true
}

if ($OVERRIDE_IMAGE) {
    $IMAGE = $OVERRIDE_IMAGE
} else {
    $IMAGE = "${HUB_USER}/${IMAGE_NAME}:${TAG}"
}

# ======================
# Pre-flight checks
# ======================
# Resolve this script's directory robustly (PS 3.0+ has $PSScriptRoot)
if ($PSBoundParameters -and $PSBoundParameters['File']) {
    # When invoked with -File, $PSScriptRoot is reliable
    $scriptDir = $PSScriptRoot
} else {
    # Fallback for odd hosts: use -Path with -Parent to avoid LiteralPath ambiguity in PS 5.1
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
}
if (-not $scriptDir) { $scriptDir = Get-Location }
Set-Location -LiteralPath $scriptDir

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host 'Docker is not installed or not on PATH. Please install Docker Desktop first.'
    exit 1
}
try {
    docker info *> $null
} catch {
    Write-Host 'Docker daemon not reachable. Please open Docker Desktop and try again.'
    exit 1
}

$CURRENT_CONTEXT = (docker context show 2>$null) -as [string]; if (-not $CURRENT_CONTEXT) { $CURRENT_CONTEXT = 'unknown' }
$HOST_ARCH       = (docker info --format '{{.Architecture}}' 2>$null) -as [string]; if (-not $HOST_ARCH) { $HOST_ARCH = 'unknown' }
$HOST_OS         = (docker info --format '{{.OSType}}' 2>$null) -as [string]; if (-not $HOST_OS) { $HOST_OS = 'unknown' }
Write-Host "Docker context: $CURRENT_CONTEXT"
Write-Host "Host detected by Docker: $HOST_OS/$HOST_ARCH"
Write-Host "Using image: $IMAGE"

# ======================
# Folders & helpers
# ======================
$CoursesRoot = Join-Path -Path (Get-Location) -ChildPath 'courses'
$BackupsRoot = Join-Path -Path $CoursesRoot -ChildPath '_backups'
if (-not (Test-Path -LiteralPath $CoursesRoot)) {
    Write-Host "Creating 'courses' directory on host..."
    New-Item -ItemType Directory -Path $CoursesRoot -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $BackupsRoot)) {
    Write-Host "Creating 'courses/_backups' directory on host..."
    New-Item -ItemType Directory -Path $BackupsRoot -Force | Out-Null
}

function Normalize-HostPath([string]$p) {
    if (-not $p) { return $p }
    try {
        $r = (Resolve-Path -LiteralPath $p).Path
    } catch {
        $r = $p
    }
    return $r.TrimEnd('\','/')
}
$HOST_COURSES = Normalize-HostPath $CoursesRoot

# ======================
# Image presence / pull
# ======================
function Test-ImagePresent([string]$ref) {
    try {
        docker image inspect "$ref" *> $null
        return $true
    } catch {
        return $false
    }
}

$IMAGE_PRESENT = Test-ImagePresent $IMAGE
$PULL_STATUS = ''

if (-not $SKIP_PULL) {
    if ($FORCE_UPDATE_IMAGE) {
        Write-Host "Pulling latest for $IMAGE ..."
        docker pull "$IMAGE" | Out-Host
        $PULL_STATUS = '(just pulled)'
    } elseif (-not $IMAGE_PRESENT) {
        Write-Host "Image not found locally. Pulling $IMAGE ..."
        docker pull "$IMAGE" | Out-Host
        $PULL_STATUS = '(just pulled)'
    } else {
        Write-Host "Image already present: $IMAGE"
        $PULL_STATUS = '(already on this machine)'
    }
} else {
    $PULL_STATUS = '(skipped pull)'
}

# ======================
# Container helpers
# ======================
function Run-ContainerWithMount {
    Write-Host "Binding host courses to container: $HOST_COURSES -> /teaching/courses"
    docker run -dit `
        --name "$CONTAINER_NAME" `
        -v "${HOST_COURSES}:/teaching/courses" `
        -p ${HOST_PORT}:${CONTAINER_PORT} `
        "$IMAGE" `
        tail -f /dev/null | Out-Null
}

function Show-ImageInfo([string]$_img) {
    try {
        $info = docker image inspect "$_img" | ConvertFrom-Json
    } catch {
        Write-Host "Could not inspect image $_img"
        return
    }
    if (-not $info) { return }
    $obj = $info[0]

    $labels = $null
    try { $labels = $obj.Config.Labels } catch {}
    if (-not $labels) { $labels = @{} }

    $ver     = $labels['org.opencontainers.image.version']
    $created = $labels['org.opencontainers.image.created']
    $rev     = $labels['org.opencontainers.image.revision']
    $src     = $labels['org.opencontainers.image.source']
    $title   = $labels['org.opencontainers.image.title']

    if (-not $ver)     { $ver = '(no version label)' }
    if (-not $created) { $created = $obj.Created }
    if (-not $rev)     { $rev = '(no revision label)' }
    if (-not $title)   { $title = $_img }

    Write-Host "Image info ${PULL_STATUS}:"
    Write-Host "  Title:    $title"
    Write-Host "  Version:  $ver"
    Write-Host "  Created:  $created"
    Write-Host "  Revision: $rev"
    if ($src) { Write-Host "  Source:   $src" }

    try {
        $digests = $obj.RepoDigests
        if ($digests) {
            Write-Host '  Digests:'
            foreach ($d in $digests) { if ($d) { Write-Host "    - $d" } }
        }
    } catch {}
}

Show-ImageInfo $IMAGE

# ======================
# Create/start container (mount-aware)
# ======================
$containerExists = ((docker ps -a --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) -ne $null

if ($containerExists) {
    $CURRENT_MOUNT_SRC = $null
    try {
        $cinfo = docker inspect "$CONTAINER_NAME" | ConvertFrom-Json
        if ($cinfo -and $cinfo.Count -gt 0) {
            foreach ($m in $cinfo[0].Mounts) {
                if ($m.Destination -eq "/teaching/courses") {
                    $CURRENT_MOUNT_SRC = $m.Source
                    break
                }
            }
        }
    } catch {}

    $CURRENT_MOUNT_SRC = Normalize-HostPath $CURRENT_MOUNT_SRC

    if (-not $CURRENT_MOUNT_SRC) {
        Write-Host 'Existing container has no /teaching/courses mount; recreating with correct mount ...'
        if ((docker ps --format '{{.Names}}' | Where-Object { $_ -eq $CONTAINER_NAME })) {
            docker stop "$CONTAINER_NAME" *> $null
        }
        docker rm "$CONTAINER_NAME" *> $null
        Run-ContainerWithMount
    } elseif ($CURRENT_MOUNT_SRC -ne $HOST_COURSES) {
        Write-Host 'Detected different working directory:'
        Write-Host "  Existing mount: $CURRENT_MOUNT_SRC"
        Write-Host "  Desired mount:  $HOST_COURSES"
        Write-Host "Recreating container '$CONTAINER_NAME' to point at the new folder ..."
        if ((docker ps --format '{{.Names}}' | Where-Object { $_ -eq $CONTAINER_NAME })) {
            docker stop "$CONTAINER_NAME" *> $null
        }
        docker rm "$CONTAINER_NAME" *> $null
        Run-ContainerWithMount
    } else {
        $running = ((docker ps --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) -ne $null
        if ($running) {
            Write-Host "Container $CONTAINER_NAME is already running with correct mount."
        } else {
            Write-Host "Starting existing container $CONTAINER_NAME ..."
            docker start "$CONTAINER_NAME" *> $null
        }
    }
} else {
    Write-Host "Creating a new container named $CONTAINER_NAME (image: $IMAGE) ..."
    Run-ContainerWithMount
}

# ======================
# Backup confirmation & run
# ======================
$HOST_TZ_OFFSET = (Get-Date).ToString('zzz').Replace(':','')
Write-Host "Detected host timezone offset: $HOST_TZ_OFFSET"
Write-Host "Backups will be written to: $BackupsRoot"

if ($PassthruArgs.Count -gt 0 -and ($PassthruArgs -contains '--no-backup')) {
    Write-Host 'You are running with --no-backup.'
    Write-Host 'This will skip creating a safety ZIP before modifying course folders.'
    $confirm = Read-Host 'Are you sure you want to proceed without a backup? (yes/no)'
    if ($confirm -notin @('yes','y','Y')) {
        Write-Host 'Cancelled.'
        exit 1
    } else {
        Write-Host 'Proceeding without backup ...'
    }
}

$PassthruArgs += @('--host-os','windows')

$escaped = @()
foreach ($p in $PassthruArgs) {
    if ($p -match '\s') {
        $escaped += ('"' + ($p -replace '"','\"') + '"')
    } else {
        $escaped += $p
    }
}

Write-Host 'Running setup_course.py inside the Docker container ...'
docker exec -e HOST_TZ_OFFSET=$HOST_TZ_OFFSET -it "$CONTAINER_NAME" `
    python3 /opt/scripts/setup_course.py $escaped