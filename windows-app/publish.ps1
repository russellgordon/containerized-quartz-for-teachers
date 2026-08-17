<#
Builds the Windows release bundle: publish, optionally sign, package.

    powershell -File publish.ps1              # unsigned bundle (local testing)
    powershell -File publish.ps1 -Sign        # signed bundle (real releases)

Output lands in windows-app\dist\Plantoir-<version>-win-x64.zip with its
SHA-256 printed for the release notes. The version comes from ONE place:
<Version> in Plantoir\Plantoir.csproj — bump it there, tag the repo to
match (v<version>), and this script names everything else accordingly.

Signing uses Azure Artifact Signing (a.k.a. Trusted Signing) via the
`sign` dotnet tool and expects a prior `az login`. See the signing
runbook for the one-time account setup. The RFC 3161 timestamp is NOT
optional: Artifact Signing certificates live for days, and an
untimestamped signature stops validating when the certificate does.
#>
param(
    [switch]$Sign,
    [string]$SigningEndpoint = "https://eus.codesigning.azure.net",
    [string]$SigningAccount  = "plantoirsigning",
    [string]$SigningProfile  = "plantoir-public",
    [string]$TimestampUrl    = "http://timestamp.acs.microsoft.com"
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# ---- Signing preflight: fail in seconds, not after a minutes-long build ----
if ($Sign) {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI not found. One-time install:  winget install --exact --id Microsoft.AzureCLI  (then open a NEW terminal)"
    }
    if (-not (Get-Command sign -ErrorAction SilentlyContinue)) {
        throw "The 'sign' tool is not installed. One-time install:  dotnet tool install --global sign --prerelease"
    }
    az account show --output none 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Not signed in to Azure. Run:  az login  (sign in as the Azure signing account) and retry."
    }
    Write-Host "Signing preflight OK: az CLI, sign tool, and an active az login." -ForegroundColor Green
}

# ---- Version, from the csproj alone ----------------------------------------
$csproj = [xml](Get-Content "Plantoir\Plantoir.csproj")
$version = ($csproj.Project.PropertyGroup.Version | Where-Object { $_ }) | Select-Object -First 1
if (-not $version) { throw "No <Version> found in Plantoir.csproj" }
Write-Host "Publishing Plantoir $version" -ForegroundColor Green

# ---- Publish ----------------------------------------------------------------
dotnet publish Plantoir\Plantoir.csproj -c Release -r win-x64
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed" }
$publishDir = "Plantoir\bin\Release\net9.0-windows10.0.19041.0\win-x64\publish"
$pri = "Plantoir\bin\Release\net9.0-windows10.0.19041.0\win-x64\Plantoir.pri"
if (Test-Path $pri) {
    Copy-Item $pri "$publishDir\resources.pri" -Force
    Copy-Item $pri "$publishDir\Plantoir.pri" -Force
}

# ---- The MCP server, into the same folder -----------------------------------
# A second binary, deliberately: Claude Code launches plantoir-mcp.exe itself,
# as a stdio subprocess, so it has to stay a plain console app with a path of
# its own. Folding it into Plantoir.exe would boot the whole WinUI runtime to
# speak JSON-RPC, and would break the Claude Code integration outright.
#
# Shipping it in the SAME folder is what keeps distribution one zip: the app
# looks beside itself first, and teachers never learn there are two files.
# Without this step the assistant reports that Plantoir's own tools cannot be
# found -- on a teacher's machine only, which is the worst place to find out.
dotnet publish Plantoir.Mcp\Plantoir.Mcp.csproj -c Release -r win-x64
if ($LASTEXITCODE -ne 0) { throw "dotnet publish (Plantoir.Mcp) failed" }
$mcpExe = "Plantoir.Mcp\bin\Release\net9.0\win-x64\publish\plantoir-mcp.exe"
if (-not (Test-Path $mcpExe)) { throw "plantoir-mcp.exe not found at $mcpExe" }
Copy-Item $mcpExe $publishDir -Force
Write-Host "Bundled plantoir-mcp.exe ($('{0:N1} MB' -f ((Get-Item $mcpExe).Length / 1MB)))" -ForegroundColor Green

# ---- Sign (our own binaries; third-party DLLs carry their makers' signatures)
if ($Sign) {
    # plantoir-mcp.exe is ours too, and an unsigned executable sitting beside
    # signed ones is exactly what SmartScreen complains about.
    $targets = @("$publishDir\Plantoir.exe", "$publishDir\Plantoir.dll", "$publishDir\Plantoir.Core.dll",
                 "$publishDir\plantoir-mcp.exe")
    Write-Host "Signing $($targets.Count) binaries via $SigningAccount/$SigningProfile" -ForegroundColor Green
    sign code trusted-signing `
        --trusted-signing-endpoint $SigningEndpoint `
        --trusted-signing-account $SigningAccount `
        --trusted-signing-certificate-profile $SigningProfile `
        --timestamp-url $TimestampUrl `
        @targets
    if ($LASTEXITCODE -ne 0) { throw "signing failed (is 'az login' current?)" }

    # A signature without a timestamp dies with the short-lived certificate.
    $sig = Get-AuthenticodeSignature "$publishDir\Plantoir.exe"
    if ($sig.Status -ne 'Valid') { throw "Plantoir.exe signature is $($sig.Status)" }
    if (-not $sig.TimeStamperCertificate) { throw "Plantoir.exe signature has NO TIMESTAMP - do not ship this" }
    Write-Host "Signature valid and timestamped." -ForegroundColor Green
} else {
    Write-Host "Skipping signing (-Sign not given) - fine for local testing only." -ForegroundColor Yellow
}

# ---- Package ----------------------------------------------------------------
# STABLE asset name, deliberately unversioned: plantoir.app's download link
# is releases/latest/download/Plantoir-win-x64.zip, which GitHub resolves to
# the newest release only when every release names the asset identically.
# The version lives inside (exe metadata, About panel) and in the tag.
New-Item -ItemType Directory -Force "dist" | Out-Null
$zip = "dist\Plantoir-win-x64.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$publishDir\*" -DestinationPath $zip
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$size = '{0:N1} MB' -f ((Get-Item $zip).Length / 1MB)

Write-Host ""
Write-Host "Bundle:  $zip ($size)" -ForegroundColor Green
Write-Host "SHA-256: $hash"
Write-Host ""
Write-Host "Next: tag v$version, create the GitHub release, attach the zip."
