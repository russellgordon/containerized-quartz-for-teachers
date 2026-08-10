#!/usr/bin/env pwsh
#requires -Version 5.1
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Show-Help {
@"
Usage:
  .\deploy.bat <COURSE_CODE> <SECTION_NUMBER> [--diagnose] [--team <TEAM_SLUG>] [--reset-token|--logout]

Examples:
  .\deploy.bat ICS3U 1
  .\deploy.bat ICS3U 1 --diagnose
  .\deploy.bat ICS3U 1 --team my-org-slug

Notes:
- Deploys from /teaching/courses/<COURSE>/.merged_output/section<SECTION> inside the container.
- You must build first (the static site goes to 'public/' in that section folder).
- The Netlify Personal Access Token (PAT) is stored as a Windows Generic Credential and injected securely at runtime.
- Use --reset-token (or --logout) to remove the saved PAT and re-link on next run.
- If your course code ends with '0' (zero), you'll be prompted to correct it to 'O' for Open-level courses.
"@ | Out-Host
}

function Normalize-HostPath([string]$p) {
  if (-not $p) { return $p }
  try { $r = (Resolve-Path -LiteralPath $p).Path } catch { $r = $p }
  return $r.TrimEnd('\','/')
}

# Ensure we run from the script directory
$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
if (-not $ScriptDir) { $ScriptDir = Get-Location }
Set-Location -LiteralPath $ScriptDir

# ======================
# Defaults / constants
# ======================
$CONTAINER_NAME = 'teaching-quartz'
$KEY_TARGET     = 'containerized-quartz-netlify'  # Windows Credential Manager target
$TOKENS_FILE    = Join-Path -Path $ScriptDir -ChildPath 'courses\.internal\tokens.json'
$KEY_FILE       = Join-Path -Path $ScriptDir -ChildPath 'courses\.internal\.key'

# Image selection: default to hub image unless an existing container specifies otherwise.
$DEFAULT_IMAGE  = if ($env:TEACHING_QUARTZ_IMAGE) { $env:TEACHING_QUARTZ_IMAGE } else { 'rwhgrwhg/teaching-quartz:latest' }
$script:IMAGE_REF = $DEFAULT_IMAGE

# ======================
# Arg parsing
# ======================
if ($args.Count -lt 2) { Show-Help; exit 1 }

$COURSE_CODE = $args[0].ToUpperInvariant()
$SECTION_NUM = $args[1]
$DIAGNOSE    = ''
$TEAM_SLUG   = ''
$RESET_TOKEN = $false

for ($i = 2; $i -lt $args.Count; $i++) {
  switch -Regex ($args[$i]) {
    '^--help$|^-h$'      { Show-Help; exit 0 }
    '^--diagnose$'       { $DIAGNOSE = '--diagnose'; continue }
    '^--team$'           { if ($i + 1 -ge $args.Count) { Write-Host "Missing value for --team"; Show-Help; exit 1 }; $TEAM_SLUG = $args[$i+1]; $i++; continue }
    '^--team=(.+)$'      { $TEAM_SLUG = $Matches[1]; continue }
    '^--team-slug$'      { if ($i + 1 -ge $args.Count) { Write-Host "Missing value for --team-slug"; Show-Help; exit 1 }; $TEAM_SLUG = $args[$i+1]; $i++; continue }
    '^--team-slug=(.+)$' { $TEAM_SLUG = $Matches[1]; continue }
    '^--reset-token$'    { $RESET_TOKEN = $true; continue }
    '^--logout$'         { $RESET_TOKEN = $true; continue }
    default              { Write-Host "Unknown option: $($args[$i])"; Show-Help; exit 1 }
  }
}

# Friendly guard: 'Open' course code ended with zero
if ($COURSE_CODE -match '^[A-Z]{3}[0-9]0$') {
  $suggested = $COURSE_CODE.Substring(0, $COURSE_CODE.Length-1) + 'O'
  Write-Host ""
  Write-Host ("It looks like you entered '{0}' (ends with zero)." -f $COURSE_CODE)
  Write-Host "Ontario 'Open' level course codes end with the LETTER 'O' (oh)."
  $suggestedCfg = Join-Path -Path $ScriptDir -ChildPath ("courses\{0}\course_config.json" -f $suggested)
  $originalCfg  = Join-Path -Path $ScriptDir -ChildPath ("courses\{0}\course_config.json" -f $COURSE_CODE)
  if ((Test-Path $suggestedCfg) -and -not (Test-Path $originalCfg)) {
    Write-Host ("I see setup data for '{0}' on disk." -f $suggested)
  }
  $ans = Read-Host ("Fix course code to '{0}'? [Y/n]" -f $suggested)
  if (-not $ans) { $ans = 'Y' }
  if ($ans -match '^[Yy]$') {
    $COURSE_CODE = $suggested
    Write-Host ("Using corrected course code: {0}" -f $COURSE_CODE)
  } else {
    Write-Host ("Continuing with: {0}" -f $COURSE_CODE)
  }
  Write-Host ""
}

# ======================
# Preflight checks
# ======================
$COURSE_DIR_HOST  = Normalize-HostPath (Join-Path -Path (Get-Location) -ChildPath ("courses\{0}" -f $COURSE_CODE))
$MERGED_DIR_HOST  = Normalize-HostPath (Join-Path -Path $COURSE_DIR_HOST -ChildPath ".merged_output")
$SECTION_DIR_HOST = Normalize-HostPath (Join-Path -Path $MERGED_DIR_HOST -ChildPath ("section{0}" -f $SECTION_NUM))
$PUBLIC_DIR_HOST  = Normalize-HostPath (Join-Path -Path $SECTION_DIR_HOST -ChildPath "public")

$HOST_TZ_OFFSET = (Get-Date).ToString('zzz').Replace(':','')
Write-Host ("Host timezone offset: {0}" -f $HOST_TZ_OFFSET)

if (-not (Test-Path -LiteralPath $COURSE_DIR_HOST)) {
  Write-Host "Course folder not found on host:"
  Write-Host " $COURSE_DIR_HOST"
  Write-Host ""
  Write-Host "Make sure you've run the course setup and/or preview steps."
  Write-Host ("Try: .\preview.bat {0} {1}" -f $COURSE_CODE, $SECTION_NUM)
  $coursesRoot = Join-Path -Path (Get-Location) -ChildPath 'courses'
  if (Test-Path $coursesRoot) {
    Write-Host ""
    Write-Host "Available course folders:"
    Get-ChildItem -LiteralPath $coursesRoot -Directory | ForEach-Object { " - $($_.Name)" } | Out-Host
  }
  exit 1
}

if (-not (Test-Path -LiteralPath $SECTION_DIR_HOST)) {
  Write-Host "Section directory not found on host:"
  Write-Host " $SECTION_DIR_HOST"
  Write-Host ""
  Write-Host "You likely need to build the merged output first:"
  Write-Host (" .\preview.bat {0} {1}" -f $COURSE_CODE, $SECTION_NUM)
  if (Test-Path -LiteralPath $MERGED_DIR_HOST) {
    $existing = Get-ChildItem -LiteralPath $MERGED_DIR_HOST -Directory -Filter 'section*' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    if ($existing) {
      Write-Host ""
      Write-Host ("Existing merged sections for {0}:" -f $COURSE_CODE)
      $existing | ForEach-Object { " - $_" } | Out-Host
    }
  }
  exit 1
}

if (-not (Test-Path -LiteralPath $PUBLIC_DIR_HOST) -or -not (Get-ChildItem -LiteralPath $PUBLIC_DIR_HOST -Force | Select-Object -First 1)) {
  Write-Host "Built site not found at:"
  Write-Host " $PUBLIC_DIR_HOST"
  Write-Host ""
  Write-Host "Build first:"
  Write-Host (" .\preview.bat {0} {1} --build-only" -f $COURSE_CODE, $SECTION_NUM)
  exit 1
}

# ======================
# Netlify token (Windows Credential Manager + legacy migration)
# ======================
$CredCs = @'
using System;
using System.Runtime.InteropServices;

public static class CredApi {
  [DllImport("advapi32", CharSet=CharSet.Unicode, SetLastError=true)]
  public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr pCredential);

  [DllImport("advapi32", CharSet=CharSet.Unicode, SetLastError=true)]
  public static extern bool CredWrite(ref CREDENTIAL userCredential, uint flags);

  [DllImport("advapi32", SetLastError=true)]
  public static extern void CredFree(IntPtr buffer);

  [DllImport("advapi32", CharSet=CharSet.Unicode, SetLastError=true)]
  public static extern bool CredDelete(string target, int type, int flags);

  public const int CRED_TYPE_GENERIC = 1;
  public const uint CRED_PERSIST_LOCAL_MACHINE = 2;

  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
  public struct CREDENTIAL {
    public uint Flags;
    public uint Type;
    public string TargetName;
    public string Comment;
    public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
    public uint CredentialBlobSize;
    public IntPtr CredentialBlob;
    public uint Persist;
    public uint AttributeCount;
    public IntPtr Attributes;
    public string TargetAlias;
    public string UserName;
  }

  public static string ReadSecret(string target) {
    IntPtr pcred;
    if (!CredRead(target, CRED_TYPE_GENERIC, 0, out pcred)) return null;
    try {
      CREDENTIAL cred = (CREDENTIAL) Marshal.PtrToStructure(pcred, typeof(CREDENTIAL));
      if (cred.CredentialBlob == IntPtr.Zero || cred.CredentialBlobSize == 0) return null;
      byte[] bytes = new byte[cred.CredentialBlobSize];
      Marshal.Copy(cred.CredentialBlob, bytes, 0, (int)cred.CredentialBlobSize);
      return System.Text.Encoding.UTF8.GetString(bytes);
    } finally {
      CredFree(pcred);
    }
  }

  public static bool WriteSecret(string target, string username, string secret) {
    byte[] bytes = System.Text.Encoding.UTF8.GetBytes(secret ?? "");
    IntPtr blob = Marshal.AllocHGlobal(bytes.Length);
    try {
      Marshal.Copy(bytes, 0, blob, bytes.Length);
      CREDENTIAL cred = new CREDENTIAL();
      cred.Flags = 0;
      cred.Type = CRED_TYPE_GENERIC;
      cred.TargetName = target;
      cred.UserName = username ?? Environment.UserName;
      cred.CredentialBlobSize = (uint)bytes.Length;
      cred.CredentialBlob = blob;
      cred.Persist = CRED_PERSIST_LOCAL_MACHINE;
      return CredWrite(ref cred, 0);
    } finally {
      Marshal.FreeHGlobal(blob);
    }
  }

  public static bool DeleteSecret(string target) {
    return CredDelete(target, CRED_TYPE_GENERIC, 0);
  }
}
'@
Add-Type -TypeDefinition $CredCs -Language CSharp -IgnoreWarnings

function Get-TokenFromCredMan { [CredApi]::ReadSecret($KEY_TARGET) }
function Set-TokenInCredMan([string]$token) {
  $ok = [CredApi]::WriteSecret($KEY_TARGET, $env:USERNAME, $token)
  if (-not $ok) { throw "Failed to write token to Windows Credential Manager." }
}
function Remove-TokenInCredMan { [CredApi]::DeleteSecret($KEY_TARGET) | Out-Null }

function Test-TokenValid([string]$token) {
  if (-not $token) { return $false }
  try {
    $r = Invoke-WebRequest -Uri 'https://api.netlify.com/api/v1/user' -Headers @{ Authorization = "Bearer $token" } -Method GET -UseBasicParsing -TimeoutSec 20
    return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300)
  } catch { return $false }
}

function Read-LegacyTokenXor {
  if (-not (Test-Path $TOKENS_FILE) -or -not (Test-Path $KEY_FILE)) { return $null }
  try {
    $json = Get-Content -LiteralPath $TOKENS_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
    $obf  = $json.tokens.netlify.obf
    if (-not $obf) { return $null }
    $raw  = [Convert]::FromBase64String($obf)
    $key  = [IO.File]::ReadAllBytes($KEY_FILE)
    $out  = New-Object byte[] ($raw.Length)
    for ($i=0; $i -lt $raw.Length; $i++) { $out[$i] = $raw[$i] -bxor $key[$i % $key.Length] }
    return [Text.Encoding]::UTF8.GetString($out)
  } catch { return $null }
}
function Read-LegacyTokenPlain {
  if (-not (Test-Path $TOKENS_FILE)) { return $null }
  try {
    $txt     = Get-Content -LiteralPath $TOKENS_FILE -Raw -Encoding UTF8
    $pattern = '(?i)"(netlify|netlify_token|NETLIFY_AUTH_TOKEN|token)"\s*:\s*"([^"]+)"'
    $m       = [regex]::Match($txt, $pattern)
    if ($m.Success) { return $m.Groups[2].Value }
  } catch {}
  return $null
}
function Prune-LegacyNetlifyEntry {
  if (-not (Test-Path $TOKENS_FILE)) { return }
  try {
    $json = Get-Content -LiteralPath $TOKENS_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($json.tokens -and $json.tokens.netlify) {
      $json.tokens.PSObject.Properties.Remove('netlify')
      if ($json.tokens.PSObject.Properties.Count -gt 0) {
        $json | ConvertTo-Json -Depth 20 | Out-File -LiteralPath $TOKENS_FILE -Encoding UTF8
      } else {
        Remove-Item -LiteralPath $TOKENS_FILE -Force
      }
    }
  } catch {}
}

if ($RESET_TOKEN) {
  Write-Host "Clearing saved Netlify token from Windows Credential Manager..."
  Remove-TokenInCredMan
  if (Test-Path $TOKENS_FILE) {
    Write-Host "Removing legacy Netlify entry from: $TOKENS_FILE"
    Prune-LegacyNetlifyEntry
  }
  Write-Host "Done. Next run will prompt to create/paste a new token."
  exit 0
}

$TOKEN = Get-TokenFromCredMan
if (-not $TOKEN -and (Test-Path $TOKENS_FILE)) {
  $migrated = $false
  $decoded = Read-LegacyTokenXor
  if ($decoded -and (Test-TokenValid $decoded)) {
    Set-TokenInCredMan $decoded
    $TOKEN = $decoded
    Write-Host "Migrated Netlify token (obfuscated) into Windows Credential Manager."
    Prune-LegacyNetlifyEntry
    $migrated = $true
  }
  if (-not $migrated -and -not $TOKEN) {
    $plain = Read-LegacyTokenPlain
    if ($plain -and (Test-TokenValid $plain)) {
      Set-TokenInCredMan $plain
      $TOKEN = $plain
      Write-Host "Migrated Netlify token into Windows Credential Manager."
      Prune-LegacyNetlifyEntry
    } elseif (-not $plain) {
      Write-Host "Legacy tokens file found, but no Netlify token key detected."
    } else {
      Write-Host "Legacy token value found, but it is invalid."
    }
  }
}

if (-not $TOKEN) {
@"
You need a Netlify Personal Access Token (PAT) to deploy.
1) Open this page: https://app.netlify.com/user/applications#personal-access-tokens
2) Create a new token.
   Tips:
   a. Name it something like 'For class website deploys'
   b. Set the expiration time to 'No expiration'
3) Copy the generated token and paste it here.
"@ | Out-Host
  try { Start-Process "https://app.netlify.com/user/applications#personal-access-tokens" | Out-Null } catch {}
  $pastedSec = Read-Host -AsSecureString "Paste Netlify token"
  $plain = $null
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pastedSec)
  try   { $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
  if (-not (Test-TokenValid $plain)) {
    Write-Host "Token invalid (Netlify rejected it). Please try again."
    exit 1
  }
  Set-TokenInCredMan $plain
  $TOKEN = $plain
  Write-Host "Saved token to Windows Credential Manager (target: $KEY_TARGET)."
}

# ======================
# Docker / container (mount-aware + writability probe)
# ======================
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

# How to invoke docker as a raw process (used by the token-injection steps
# below, which bypass PowerShell command resolution).
$DOCKER_EXE    = 'docker'
$DOCKER_PREFIX = ''
if ($global:DockerViaWsl) {
  $DOCKER_EXE    = 'wsl'
  $DOCKER_PREFIX = ((@($global:WslUserArgs) + @('-e','docker')) -join ' ') + ' '
}
# ====================================================================

$HOST_COURSES = Normalize-HostPath (Join-Path -Path (Get-Location) -ChildPath 'courses')
$MOUNT_COURSES = Get-MountPath $HOST_COURSES

function Ensure-Image([string]$ref) {
  docker image inspect "$ref" *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Pulling image '$ref'..."
    docker pull "$ref" | Out-Host
  }
}

function Run-ContainerWithMount {
  Write-Host "Binding host courses to container: $MOUNT_COURSES -> /teaching/courses"
  Ensure-Image $script:IMAGE_REF
  docker run -dit `
    --name "$CONTAINER_NAME" `
    -v "${MOUNT_COURSES}:/teaching/courses" `
    -p 8081-8084:8081-8084 `
        -p 9081-9084:9081-9084 `
    "$script:IMAGE_REF" `
    tail -f /dev/null | Out-Null
}

function Test-ContainerWriteable {
  param([string]$Name)
  try {
    docker exec $Name sh -lc 'mkdir -p /teaching/courses &&
      echo ok >/teaching/courses/.write_probe &&
      rm -f /teaching/courses/.write_probe' *> $null
    return $true
  } catch { return $false }
}

Write-Host "Ensuring container is running with the correct, writable mount..."
$containerExists = ((docker ps -a --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) -ne $null
if ($containerExists) {
  # If we have an existing container, adopt its image for any recreation.
  try {
    $cinfo = docker inspect "$CONTAINER_NAME" | ConvertFrom-Json
    if ($cinfo -and $cinfo.Count -gt 0 -and $cinfo[0].Config.Image) {
      $script:IMAGE_REF = $cinfo[0].Config.Image
    }
  } catch {}

  $CURRENT_MOUNT_SRC = $null
  try {
    if ($cinfo -and $cinfo.Count -gt 0) {
      foreach ($m in $cinfo[0].Mounts) {
        if ($m.Destination -eq "/teaching/courses") { $CURRENT_MOUNT_SRC = $m.Source; break }
      }
    }
  } catch {}
  $CURRENT_MOUNT_SRC = Normalize-HostPath $CURRENT_MOUNT_SRC

  if (-not $CURRENT_MOUNT_SRC) {
    Write-Host "Existing container has no /teaching/courses mount; recreating with correct mount..."
    if ((docker ps --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) { docker stop "$CONTAINER_NAME" *> $null }
    docker rm "$CONTAINER_NAME" *> $null
    Run-ContainerWithMount
  }
  elseif ($CURRENT_MOUNT_SRC -ne (Normalize-HostPath $MOUNT_COURSES)) {
    Write-Host "Detected different working directory:"
    Write-Host "  Existing mount: $CURRENT_MOUNT_SRC"
    Write-Host "  Desired mount:  $MOUNT_COURSES"
    Write-Host "Recreating container '$CONTAINER_NAME' to point at the new folder..."
    if ((docker ps --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) { docker stop "$CONTAINER_NAME" *> $null }
    docker rm "$CONTAINER_NAME" *> $null
    Run-ContainerWithMount
  }
  else {
    $running = ((docker ps --format '{{.Names}}') | Where-Object { $_ -eq $CONTAINER_NAME }) -ne $null
    if ($running) {
      if (-not (Test-ContainerWriteable -Name $CONTAINER_NAME)) {
        Write-Host "Mounted 'courses/' is not writable from the container - recreating it..."
        docker rm -f "$CONTAINER_NAME" *> $null
        Run-ContainerWithMount
      } else {
        Write-Host "Container is already running with correct, writable mount."
      }
    } else {
      Write-Host "Starting existing container $CONTAINER_NAME..."
      docker start "$CONTAINER_NAME" *> $null
      if (-not (Test-ContainerWriteable -Name $CONTAINER_NAME)) {
        Write-Host "Mounted 'courses/' is not writable from the container after start - recreating it..."
        docker rm -f "$CONTAINER_NAME" *> $null
        Run-ContainerWithMount
      }
    }
  }
}
else {
  Write-Host "Creating new container named $CONTAINER_NAME with correct mount..."
  # No pre-existing container -> use default/override image.
  $script:IMAGE_REF = $DEFAULT_IMAGE
  Run-ContainerWithMount
}

# ======================
# Deploy
# ======================
$SECTION_DIR_IN_CONTAINER = "/teaching/courses/$COURSE_CODE/.merged_output/section$SECTION_NUM"
Write-Host ("Deploying {0} S{1} from: {2}" -f $COURSE_CODE, $SECTION_NUM, $SECTION_DIR_IN_CONTAINER)

# 1) Securely inject token: filter CRLF and BOM inside the container before saving.
$tokenBytes = [Text.Encoding]::UTF8.GetBytes($TOKEN + "`n")

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $DOCKER_EXE
$psi.Arguments = $DOCKER_PREFIX + "exec -i $CONTAINER_NAME sh -lc ""umask 077; tr -d '\r' | sed '1s/^\xEF\xBB\xBF//' > /tmp/netlify_pat"""
$psi.RedirectStandardInput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$proc = [System.Diagnostics.Process]::Start($psi)
try {
  $proc.StandardInput.BaseStream.Write($tokenBytes, 0, $tokenBytes.Length)
  $proc.StandardInput.Close()
  $proc.WaitForExit()
} finally {
  if ($proc -and -not $proc.HasExited) { $proc.Kill() | Out-Null }
}

# 2) Compose inner shell and stream it through the same CRLF/BOM filter.
$inner = @'
tok=$(cat /tmp/netlify_pat)
rm -f /tmp/netlify_pat

opts=""
if [ -n "$DIAGNOSE" ]; then opts="$opts $DIAGNOSE"; fi
if [ -n "$TEAM_SLUG" ]; then opts="$opts --team $TEAM_SLUG"; fi

NETLIFY_AUTH_TOKEN="$tok" python3 /opt/scripts/deploy.py --host-os windows --course __COURSE__ --section __SECTION__ $opts
'@
$inner = $inner.Replace('__COURSE__', $COURSE_CODE).Replace('__SECTION__', $SECTION_NUM)
$innerBytes = [Text.Encoding]::UTF8.GetBytes($inner + "`n")

$psi2 = New-Object System.Diagnostics.ProcessStartInfo
$psi2.FileName  = $DOCKER_EXE
$psi2.Arguments = $DOCKER_PREFIX + "exec -i $CONTAINER_NAME sh -lc ""tr -d '\r' | sed '1s/^\xEF\xBB\xBF//' > /tmp/deploy_inner.sh && chmod +x /tmp/deploy_inner.sh"""
$psi2.RedirectStandardInput = $true
$psi2.UseShellExecute = $false
$psi2.CreateNoWindow = $true
$proc2 = [System.Diagnostics.Process]::Start($psi2)
try {
  $proc2.StandardInput.BaseStream.Write($innerBytes, 0, $innerBytes.Length)
  $proc2.StandardInput.Close()
  $proc2.WaitForExit()
} finally {
  if ($proc2 -and -not $proc2.HasExited) { $proc2.Kill() | Out-Null }
}

# 3) Execute the inner script with the right env (stable arg ordering)
$envList = @("-e","HOST_TZ_OFFSET=$HOST_TZ_OFFSET")
if ($DIAGNOSE)  { $envList += @("-e","DIAGNOSE=$DIAGNOSE") }
if ($TEAM_SLUG) { $envList += @("-e","TEAM_SLUG=$TEAM_SLUG") }
$execArgs = @("exec","-it") + $envList + @("$CONTAINER_NAME","sh","-lc","/bin/sh /tmp/deploy_inner.sh")
& docker @execArgs
