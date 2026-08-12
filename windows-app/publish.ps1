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

# ---- Version, from the csproj alone ----------------------------------------
$csproj = [xml](Get-Content "Plantoir\Plantoir.csproj")
$version = ($csproj.Project.PropertyGroup.Version | Where-Object { $_ }) | Select-Object -First 1
if (-not $version) { throw "No <Version> found in Plantoir.csproj" }
Write-Host "Publishing Plantoir $version" -ForegroundColor Green

# ---- Publish ----------------------------------------------------------------
dotnet publish Plantoir\Plantoir.csproj -c Release -r win-x64
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed" }
$publishDir = "Plantoir\bin\Release\net9.0-windows10.0.19041.0\win-x64\publish"

# ---- Sign (our own binaries; third-party DLLs carry their makers' signatures)
if ($Sign) {
    $targets = @("$publishDir\Plantoir.exe", "$publishDir\Plantoir.dll", "$publishDir\Plantoir.Core.dll")
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
New-Item -ItemType Directory -Force "dist" | Out-Null
$zip = "dist\Plantoir-$version-win-x64.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$publishDir\*" -DestinationPath $zip
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$size = '{0:N1} MB' -f ((Get-Item $zip).Length / 1MB)

Write-Host ""
Write-Host "Bundle:  $zip ($size)" -ForegroundColor Green
Write-Host "SHA-256: $hash"
Write-Host ""
Write-Host "Next: tag v$version, create the GitHub release, attach the zip."
