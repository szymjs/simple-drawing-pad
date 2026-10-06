# Builds SimpleDrawingPad.exe with the C# compiler that ships with Windows (.NET Framework 4). No downloads needed.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }   # 32-bit Windows
if (-not (Test-Path -LiteralPath $csc)) { throw "C# compiler not found in $env:WINDIR\Microsoft.NET\Framework64 or Framework\v4.0.30319 (.NET Framework 4 is part of Windows 10/11)." }
$out = Join-Path $here 'bin'
New-Item -ItemType Directory -Force $out | Out-Null
# the plugin version (from plugin.json) goes into the program: its file details and a small label in the toolbar
$version = ''
try { $version = [string](Get-Content -Raw -ErrorAction Stop -LiteralPath (Join-Path $here '..\.claude-plugin\plugin.json') | ConvertFrom-Json).version } catch { }
$info = Join-Path $out 'AssemblyInfo.g.cs'
$attrs = '[assembly: System.Reflection.AssemblyTitle("Simple Drawing Pad")]' + "`n" + '[assembly: System.Reflection.AssemblyProduct("Simple Drawing Pad")]' + "`n"
if ($version -match '^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}\z') { $attrs += "[assembly: System.Reflection.AssemblyVersion(""$version"")]`n[assembly: System.Reflection.AssemblyFileVersion(""$version"")]`n" }
[IO.File]::WriteAllText($info, $attrs)
$exe = Join-Path $out 'SimpleDrawingPad.exe'
# the program file gets the same pencil that the program draws for its tray icon (AppIcon.Make in SimpleDrawingPad.cs;
# keep the two drawings in step), so Windows shows it in Settings > Apps, Task Manager and the startup apps list. It
# is drawn here in a few sizes and put into an .ico file (each size stored as PNG); no image file is involved. If
# this fails, the program is built with Windows' plain program icon and works the same.
$iconArg = @()
try {
    Add-Type -AssemblyName System.Drawing
    function P([double]$x, [double]$y) { New-Object Drawing.PointF ([float]$x), ([float]$y) }
    $images = @()
    foreach ($size in 16, 20, 24, 32, 40, 48, 64, 128) {
        $b = New-Object Drawing.Bitmap $size, $size, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [Drawing.Graphics]::FromImage($b)
        try {
            $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
            [float]$s = $size; [float]$r = $s * 0.22; [float]$e = [Math]::Max(1.0, $s / 24); [float]$wd = $s - $e
            [float]$h = $e / 2; [float]$d = 2 * $r; [float]$far = $wd - 2 * $r
            $tile = New-Object Drawing.Drawing2D.GraphicsPath
            $tile.AddArc($h, $h, $d, $d, [float]180, [float]90); $tile.AddArc($far, $h, $d, $d, [float]270, [float]90)
            $tile.AddArc($far, $far, $d, $d, [float]0, [float]90); $tile.AddArc($h, $far, $d, $d, [float]90, [float]90); $tile.CloseFigure()
            $g.FillPath([Drawing.Brushes]::White, $tile)
            $edge = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(140, 140, 140)), $e
            $g.DrawPath($edge, $tile); $edge.Dispose(); $tile.Dispose()
            # the pencil points to the lower left: body, wood tip, lead
            $g.TranslateTransform([float]($s / 2), [float]($s / 2)); $g.RotateTransform([float]135)
            [float]$len = $s * 0.86; [float]$pw = $s * 0.24; [float]$x0 = -$len / 2 + $len * 0.68
            $ink = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(29, 29, 31))
            $wood = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(234, 138, 0))
            $g.FillRectangle($ink, [float](-$len / 2), [float](-$pw / 2), [float]($len * 0.68), $pw)
            $g.FillPolygon($wood, [Drawing.PointF[]]@((P $x0 (-$pw / 2)), (P ($x0 + $len * 0.32) 0), (P $x0 ($pw / 2))))
            $g.FillPolygon($ink, [Drawing.PointF[]]@((P ($x0 + $len * 0.21) (-$pw * 0.17)), (P ($x0 + $len * 0.32) 0), (P ($x0 + $len * 0.21) ($pw * 0.17))))
            $ink.Dispose(); $wood.Dispose()
        } finally { $g.Dispose() }
        $ms = New-Object IO.MemoryStream; $b.Save($ms, [Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
        $images += , @($size, $ms.ToArray())
    }
    $ico = Join-Path $out 'SimpleDrawingPad.ico'
    $w = New-Object IO.BinaryWriter ([IO.File]::Create($ico))
    try {
        $w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$images.Count)   # header: an icon with N images
        $offset = 6 + 16 * $images.Count
        foreach ($i in $images) {                                                  # one directory entry per image
            $w.Write([byte]$i[0]); $w.Write([byte]$i[0]); $w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]32)
            $w.Write([uint32]$i[1].Length); $w.Write([uint32]$offset); $offset += $i[1].Length
        }
        foreach ($i in $images) { $w.Write([byte[]]$i[1]) }
    } finally { $w.Close() }
    $iconArg = @("/win32icon:$ico")
} catch { $iconArg = @() }
# run from the compiler's own folder: csc looks for referenced libraries in the current folder first
Push-Location -LiteralPath (Split-Path -Parent $csc)
try {
    & $csc /nologo /target:winexe /platform:anycpu /optimize+ /codepage:65001 `
        /reference:System.Windows.Forms.dll /reference:System.Drawing.dll @iconArg `
        "/out:$exe" (Join-Path $here 'SimpleDrawingPad.cs') $info
} finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }
"built: $exe"
