# Drives plantoir-mcp over real JSON-RPC on stdio, the way a client does.
# stdin is held open for the whole session: the SDK's stdio transport exits
# on EOF, so piping a finite file would kill the server mid-answer.
param(
    [Parameter(Mandatory=$true)][string]$Exe,
    [Parameter(Mandatory=$true)][string]$Folder,
    [Parameter(Mandatory=$true)][string]$CallsJson
)

$ErrorActionPreference = 'Stop'

$info = New-Object System.Diagnostics.ProcessStartInfo
$info.FileName = $Exe
$info.Arguments = '--folder "' + $Folder + '"'
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
        if ($obj.PSObject.Properties.Name -contains 'method' -and -not ($obj.PSObject.Properties.Name -contains 'id')) {
            Write-Host ("   [notification] " + $obj.method + " " + ($obj.params | ConvertTo-Json -Compress -Depth 5)) -ForegroundColor DarkGray
            continue
        }
        if ($obj.id -eq $wantId) { return $obj }
    }
}

Send @{ jsonrpc='2.0'; id=1; method='initialize'; params=@{
    protocolVersion='2025-06-18'
    capabilities=@{}
    clientInfo=@{ name='drive-mcp'; version='1.0' } } }
$init = ReadReply 1
Write-Host "=== initialize ===" -ForegroundColor Cyan
Write-Host ("server: " + ($init.result.serverInfo | ConvertTo-Json -Compress))

Send @{ jsonrpc='2.0'; method='notifications/initialized'; params=@{} }

Send @{ jsonrpc='2.0'; id=2; method='tools/list'; params=@{} }
$list = ReadReply 2
Write-Host "`n=== tools/list ===" -ForegroundColor Cyan
foreach ($t in $list.result.tools) {
    $req = ''
    if ($t.inputSchema.required) { $req = ' required=[' + ($t.inputSchema.required -join ',') + ']' }
    $ro = $t.annotations.readOnlyHint
    Write-Host ("  {0,-20} readOnly={1,-5}{2}" -f $t.name, $ro, $req)
}

$calls = Get-Content -Raw $CallsJson | ConvertFrom-Json
$id = 100
foreach ($call in $calls) {
    $id++
    Write-Host ("`n=== call: " + $call.name + " " + ($call.arguments | ConvertTo-Json -Compress)) -ForegroundColor Yellow
    Send @{ jsonrpc='2.0'; id=$id; method='tools/call'; params=@{ name=$call.name; arguments=$call.arguments } }
    $reply = ReadReply $id
    if ($null -eq $reply) { Write-Host "  (no reply - server exited)" -ForegroundColor Red; break }
    if ($reply.error) {
        Write-Host ("  ERROR: " + ($reply.error | ConvertTo-Json -Compress)) -ForegroundColor Red
    } else {
        foreach ($block in $reply.result.content) { Write-Host $block.text }
    }
}

$proc.StandardInput.Close()
if (-not $proc.WaitForExit(5000)) { $proc.Kill() }
$err = $proc.StandardError.ReadToEnd()
if ($err.Trim().Length -gt 0) {
    Write-Host "`n=== stderr ===" -ForegroundColor DarkGray
    Write-Host $err
}
