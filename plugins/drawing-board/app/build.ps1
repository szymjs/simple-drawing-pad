# Builds DrawingBoard.exe with the C# compiler that ships with Windows (.NET Framework 4). No downloads needed.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }   # 32-bit Windows
if (-not (Test-Path -LiteralPath $csc)) { throw "C# compiler not found in $env:WINDIR\Microsoft.NET\Framework64 or Framework\v4.0.30319 (.NET Framework 4 is part of Windows 10/11)." }
$out = Join-Path $here 'bin'
New-Item -ItemType Directory -Force $out | Out-Null
& $csc /nologo /target:winexe /platform:anycpu /optimize+ /codepage:65001 `
    /reference:System.Windows.Forms.dll /reference:System.Drawing.dll `
    "/out:$(Join-Path $out 'DrawingBoard.exe')" (Join-Path $here 'DrawingBoard.cs')
if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }
"built: $(Join-Path $out 'DrawingBoard.exe')"
