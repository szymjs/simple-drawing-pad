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
# the plugin's pencil icon (../icon.png) becomes the program file's icon too, which Windows shows in Settings > Apps,
# Task Manager and the startup apps list: an .ico file with the picture in a few sizes, each stored as PNG. Without
# it the program is built with Windows' plain program icon and works the same.
$iconArg = @()
$png = Join-Path $here '..\icon.png'
if (Test-Path -LiteralPath $png) { try {
    Add-Type -AssemblyName System.Drawing
    $images = @()
    $src = [Drawing.Image]::FromFile((Resolve-Path -LiteralPath $png).Path)
    try {
        foreach ($size in 16, 24, 32, 48, 64, 128) {
            $bmp = New-Object Drawing.Bitmap $size, $size
            try {
                $g = [Drawing.Graphics]::FromImage($bmp)
                $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
                $g.DrawImage($src, 0, 0, $size, $size); $g.Dispose()
                $ms = New-Object IO.MemoryStream; $bmp.Save($ms, [Drawing.Imaging.ImageFormat]::Png)
                $images += , @($size, $ms.ToArray())
            } finally { $bmp.Dispose() }
        }
    } finally { $src.Dispose() }
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
} catch { $iconArg = @() } }
# run from the compiler's own folder: csc looks for referenced libraries in the current folder first
Push-Location -LiteralPath (Split-Path -Parent $csc)
try {
    & $csc /nologo /target:winexe /platform:anycpu /optimize+ /codepage:65001 `
        /reference:System.Windows.Forms.dll /reference:System.Drawing.dll @iconArg `
        "/out:$(Join-Path $out 'SimpleDrawingPad.exe')" (Join-Path $here 'SimpleDrawingPad.cs') $info
} finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }
"built: $(Join-Path $out 'SimpleDrawingPad.exe')"
