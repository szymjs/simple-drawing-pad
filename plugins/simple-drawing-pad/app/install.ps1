# Installs the Simple Drawing Pad pen window for the current Windows user. No downloads, no admin rights.
#   .\install.ps1              build, install to %LOCALAPPDATA%\Programs\simple-drawing-pad, start the shortcut helper
#   .\install.ps1 -Autostart   the same, plus start the helper at every Windows logon (HKCU ...\CurrentVersion\Run value)
#   .\install.ps1 -Uninstall   stop the helper and remove what this script installed (drawings are kept)
param([switch]$Autostart, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
$exe = Join-Path $dir 'SimpleDrawingPad.exe'
$bin = Join-Path $here 'bin\SimpleDrawingPad.exe'
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
# previous name of this program (up to 0.3.0). Only its running helper and its Run value are touched, and only when
# they point to exactly this file; its files, drawings and shortcut setting are left in place.
$legacyExe = Join-Path $env:LOCALAPPDATA 'Programs\drawing-board\DrawingBoard.exe'

# stops only our helper (installed copy, bin\ copy or the previous version's copy); other users' processes have no ExecutablePath and are skipped
function Stop-Helper {
    $ours = @(Get-CimInstance Win32_Process -Filter "Name='SimpleDrawingPad.exe' OR Name='DrawingBoard.exe'" |
        Where-Object { $_.ExecutablePath -eq $exe -or $_.ExecutablePath -eq $bin -or $_.ExecutablePath -eq $legacyExe } |
        ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue })
    if ($ours | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -in 'Simple Drawing Pad', 'drawing-board' }) {
        throw 'Close the drawing window (Enter or Esc) first.'
    }
    foreach ($p in $ours) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $p.Id -Timeout 10 -ErrorAction SilentlyContinue
    }
}

# removes the previous version's Run value only if the program it starts is exactly $legacyExe; $true if removed
function Remove-LegacyAutostart {
    $v = Get-ItemProperty -LiteralPath $run -Name 'drawing-board' -ErrorAction SilentlyContinue
    if (-not $v) { return $false }
    $cmd = ([string]$v.'drawing-board').Trim()
    $path = if ($cmd.StartsWith('"')) { $cmd.Substring(1).Split('"')[0] } else { $cmd.Split(' ')[0] }
    if ($path -ne $legacyExe) { return $false }
    Remove-ItemProperty -LiteralPath $run -Name 'drawing-board'
    return $true
}

if ($Uninstall) {
    Stop-Helper
    Remove-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue
    [void](Remove-LegacyAutostart)
    if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe }
    if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir }
    "Simple Drawing Pad removed. Your drawings in Pictures\simple-drawing-pad and the shortcut setting in %APPDATA%\simple-drawing-pad are kept."
    return
}

Stop-Helper   # before the build, so a helper started from bin\ cannot lock the build output
& (Join-Path $here 'build.ps1')
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item -LiteralPath $bin -Destination $exe -Force
$legacyAutostart = Remove-LegacyAutostart   # else the previous version's helper starts again at logon
if ($Autostart) {
    New-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -Value ('"' + $exe + '" --tray') -PropertyType String -Force | Out-Null
    "Autostart: $run\simple-drawing-pad"
} elseif ($legacyAutostart) {
    'The previous version started at logon; its autostart entry was removed. Run this again with -Autostart to start the helper at every logon.'
}
Start-Process -FilePath $exe -ArgumentList '--tray'
$hk = 'Ctrl+Alt+D'
$hkFile = Join-Path $env:APPDATA 'simple-drawing-pad\hotkey.txt'
if (Test-Path -LiteralPath $hkFile) { $t = [IO.File]::ReadAllText($hkFile).Trim(); if ($t) { $hk = $t } }
"Installed: $exe"
"Press $hk to draw (change it from the tray icon menu). Enter sends, Esc cancels."
