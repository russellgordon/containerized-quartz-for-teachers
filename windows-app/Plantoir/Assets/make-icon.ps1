<#
Regenerates the Windows icon assets (Plantoir.ico + PlantoirIcon.png)
from the app icon designed in Icon Composer on the mac side.

The design source of truth is mac-app/Plantoir.icon (SVG layers). When it
changes: export a full-bleed 1024x1024 PNG from Icon Composer (the "iOS
Default 1024x1024@1x" export), then run

    powershell -File make-icon.ps1 -Source path\to\export.png

from this folder. The script applies the macOS rounded-rect silhouette
(the iOS export is square) so the icon matches the mac app's everywhere
Windows shows it, then rebuilds both assets in place.
#>
param([Parameter(Mandatory = $true)][string]$Source)

Add-Type -AssemblyName System.Drawing

$src = (Resolve-Path $Source).Path
$outDir = $PSScriptRoot
New-Item -ItemType Directory -Force $outDir | Out-Null

$srcImg = [System.Drawing.Image]::FromFile($src)

# Rounded-rect mask at macOS proportions (radius ~22.37% of edge), so the
# Windows icon wears the same silhouette as the mac one.
function New-RoundedIcon([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $r = [Math]::Round($size * 0.2237)
    $d = $r * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $d, $d, 180, 90)
    $path.AddArc($size - $d, 0, $d, $d, 270, 90)
    $path.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
    $path.AddArc(0, $size - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $g.SetClip($path)
    $g.DrawImage($srcImg, 0, 0, $size, $size)
    $g.Dispose()
    return $bmp
}

# The About-panel PNG (512 keeps the repo light and is plenty at any DPI).
$about = New-RoundedIcon 512
$about.Save("$outDir\PlantoirIcon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$about.Dispose()

# The .ico: PNG-compressed entries, largest first.
$sizes = @(256, 128, 64, 48, 40, 32, 24, 20, 16)
$blobs = @()
foreach ($s in $sizes) {
    $bmp = New-RoundedIcon $s
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $blobs += ,@($s, $ms.ToArray())
    $bmp.Dispose(); $ms.Dispose()
}
$icoPath = "$outDir\Plantoir.ico"
$fs = [System.IO.File]::Create($icoPath)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]$blobs.Count)
$offset = 6 + 16 * $blobs.Count
foreach ($entry in $blobs) {
    $s = $entry[0]; $data = $entry[1]
    $bw.Write([Byte]($(if ($s -ge 256) { 0 } else { $s })))   # width (0 = 256)
    $bw.Write([Byte]($(if ($s -ge 256) { 0 } else { $s })))   # height
    $bw.Write([Byte]0); $bw.Write([Byte]0)                    # colors, reserved
    $bw.Write([UInt16]1); $bw.Write([UInt16]32)               # planes, bpp
    $bw.Write([UInt32]$data.Length); $bw.Write([UInt32]$offset)
    $offset += $data.Length
}
foreach ($entry in $blobs) { $bw.Write($entry[1]) }
$bw.Close(); $fs.Close()
$srcImg.Dispose()
"ico: $((Get-Item $icoPath).Length) bytes, png: $((Get-Item "$outDir\PlantoirIcon.png").Length) bytes"
