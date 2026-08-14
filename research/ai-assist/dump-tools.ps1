# Dump plantoir-mcp's tools/list result as raw JSON, for the routing experiments.
param(
    [Parameter(Mandatory=$true)][string]$Exe,
    [Parameter(Mandatory=$true)][string]$Folder,
    [Parameter(Mandatory=$true)][string]$Course,
    [Parameter(Mandatory=$true)][string]$Out
)
$ErrorActionPreference = 'Stop'

$info = New-Object System.Diagnostics.ProcessStartInfo
$info.FileName = $Exe
$info.Arguments = '--folder "' + $Folder + '" --course ' + $Course
$info.UseShellExecute = $false
$info.RedirectStandardInput = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$proc = [System.Diagnostics.Process]::Start($info)

function Send($obj) {
    $line = $obj | ConvertTo-Json -Depth 20 -Compress
    $proc.StandardInput.WriteLine($line)
    $proc.StandardInput.Flush()
}
function ReadReply($wantId) {
    while ($true) {
        $line = $proc.StandardOutput.ReadLine()
        if ($null -eq $line) { return $null }
        if ($line.Trim().Length -eq 0) { continue }
        try { $obj = $line | ConvertFrom-Json } catch { continue }
        if ($obj.PSObject.Properties.Name -contains 'method' -and -not ($obj.PSObject.Properties.Name -contains 'id')) { continue }
        if ($obj.id -eq $wantId) { return $line }
    }
}

Send @{ jsonrpc='2.0'; id=1; method='initialize'; params=@{
    protocolVersion='2025-06-18'; capabilities=@{}
    clientInfo=@{ name='dump-tools'; version='1.0' } } }
$null = ReadReply 1
Send @{ jsonrpc='2.0'; method='notifications/initialized'; params=@{} }
Send @{ jsonrpc='2.0'; id=2; method='tools/list'; params=@{} }
$raw = ReadReply 2
[System.IO.File]::WriteAllText($Out, $raw, (New-Object System.Text.UTF8Encoding($false)))
$proc.StandardInput.Close()
if (-not $proc.WaitForExit(5000)) { $proc.Kill() }
Write-Host "wrote $Out"
