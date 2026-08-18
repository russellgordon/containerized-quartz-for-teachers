<#
Fetches llama.cpp's Windows x64 Vulkan build into windows-app/Vendor/llama/.

The assistant runs its model NATIVELY on the host rather than in WSL2/Docker,
because WSL2 containerization is a Linux VM without direct GPU access.
Running llama-server.exe natively with Vulkan enables hardware-accelerated
inference on Intel (UHD/Iris/Arc), AMD, and NVIDIA GPUs across Windows machines.

The binaries are NOT committed (they are ~35 MB of build output). Run this script
once before building or running the Windows app.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Pinned deliberately. An assistant whose engine changes under it between two
# builds is one whose measurements mean nothing.
$Build = "b10435"
$Archive = "llama-$Build-bin-win-vulkan-x64.zip"
$Url = "https://github.com/ggml-org/llama.cpp/releases/download/$Build/$Archive"

$VendorDir = $PSScriptRoot
$Destination = Join-Path $VendorDir "llama"

if (Test-Path (Join-Path $Destination "llama-server.exe")) {
    Write-Host "[OK] llama.cpp $Build is already in place ($Destination)." -ForegroundColor Green
    Write-Host "     Delete that folder and re-run to fetch it again."
    exit 0
}

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("llama-fetch-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    $ArchivePath = Join-Path $TempDir $Archive
    Write-Host "Fetching llama.cpp $Build for Windows (x64 Vulkan)..." -ForegroundColor Cyan
    
    # Use curl.exe for robust and fast download with redirect following
    & curl.exe -fL --retry 3 -o $ArchivePath $Url
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $ArchivePath)) {
        throw "Failed to download $Url"
    }

    Write-Host "Unpacking..." -ForegroundColor Cyan
    Expand-Archive -Path $ArchivePath -DestinationPath $TempDir -Force

    $ServerExe = Get-ChildItem -Path $TempDir -Filter "llama-server.exe" -Recurse | Select-Object -First 1
    if (-not $ServerExe) {
        throw "Archive did not contain llama-server.exe. Nothing was installed."
    }

    $SourceDir = $ServerExe.DirectoryName
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    # Copy all binaries and DLLs from the archive directory
    Get-ChildItem -Path "$SourceDir\*" -Include *.exe, *.dll -File | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $Destination -Force
    }

    if (-not (Test-Path (Join-Path $Destination "llama-server.exe"))) {
        throw "Failed to copy llama-server.exe to $Destination"
    }

    $sizeMb = ((Get-ChildItem -Path $Destination -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB)
    Write-Host ("[OK] llama.cpp {0} installed into {1} ({2:N1} MB)." -f $Build, $Destination, $sizeMb) -ForegroundColor Green
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
