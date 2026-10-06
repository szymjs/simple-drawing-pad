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
# run from the compiler's own folder: csc looks for referenced libraries in the current folder first
Push-Location -LiteralPath (Split-Path -Parent $csc)
try {
    & $csc /nologo /target:winexe /platform:anycpu /optimize+ /codepage:65001 `
        /reference:System.Windows.Forms.dll /reference:System.Drawing.dll `
        "/out:$(Join-Path $out 'SimpleDrawingPad.exe')" (Join-Path $here 'SimpleDrawingPad.cs') $info
} finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }
"built: $(Join-Path $out 'SimpleDrawingPad.exe')"
