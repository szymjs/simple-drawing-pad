# Builds the Microsoft Store package of the helper, SimpleDrawingPad_<version>_x64.msix, from this repository.
# The package is not signed here: Partner Center signs it with a Microsoft certificate after certification, and a
# program inside a Store-signed package is trusted by Smart App Control. Nothing is installed or published by this script.
# Needs makeappx.exe from the Windows SDK Build Tools (the Microsoft.Windows.SDK.BuildTools NuGet package or the Windows SDK):
#   .\build-msix.ps1 -MakeAppx "C:\path\to\makeappx.exe"
# Without -MakeAppx it looks for makeappx.exe on PATH and in the Windows Kits folder.
param([string]$MakeAppx, [string]$Out)
$ErrorActionPreference = 'Stop'
$store = $PSScriptRoot
$repo = Split-Path -Parent $store
$app = Join-Path $repo 'plugins\simple-drawing-pad\app'
if (-not $Out) { $Out = Join-Path $store 'out' }
$version = [string](Get-Content -Raw -LiteralPath (Join-Path $repo 'plugins\simple-drawing-pad\.claude-plugin\plugin.json') | ConvertFrom-Json).version
if ($version -notmatch '^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}\z') { throw "unexpected plugin version '$version'" }
if (-not $MakeAppx) {
    $found = Get-Command makeappx.exe -ErrorAction SilentlyContinue
    if ($found) { $MakeAppx = $found.Source }
    else {
        $kits = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
        $MakeAppx = Get-ChildItem -LiteralPath $kits -Recurse -Filter makeappx.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\' } | Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
}
if (-not $MakeAppx -or -not (Test-Path -LiteralPath $MakeAppx)) { throw 'makeappx.exe not found: pass -MakeAppx "C:\path\to\makeappx.exe"' }

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $app 'build.ps1') | Out-Null   # the same program, built from the same source
$exe = Join-Path $app 'bin\SimpleDrawingPad.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw 'the helper was not built' }

$stage = Join-Path $Out 'stage'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }   # only the staging folder of this script
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item -LiteralPath $exe -Destination $stage
Copy-Item -LiteralPath (Join-Path $store 'Assets') -Destination $stage -Recurse
$manifest = [IO.File]::ReadAllText((Join-Path $store 'AppxManifest.xml')).Replace('@VERSION@', "$version.0")   # the fourth number is reserved by the Store
[IO.File]::WriteAllText((Join-Path $stage 'AppxManifest.xml'), $manifest, (New-Object Text.UTF8Encoding($false)))

$msix = Join-Path $Out "SimpleDrawingPad_${version}_x64.msix"
& $MakeAppx pack /d $stage /p $msix /o
if ($LASTEXITCODE -ne 0) { throw "makeappx failed with exit code $LASTEXITCODE" }
"Built $msix ($([math]::Round((Get-Item -LiteralPath $msix).Length / 1KB)) KB). Upload it in Partner Center; it is not signed on purpose."
