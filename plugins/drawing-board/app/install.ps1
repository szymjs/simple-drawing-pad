# Installs the drawing-board pen window for the current Windows user. No downloads, no admin rights.
#   .\install.ps1              build, install to %LOCALAPPDATA%\Programs\drawing-board, start the shortcut helper
#   .\install.ps1 -Autostart   the same, plus start the helper at every Windows logon (HKCU ...\CurrentVersion\Run value)
#   .\install.ps1 -Uninstall   stop the helper and remove what this script installed (drawings are kept)
param([switch]$Autostart, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $env:LOCALAPPDATA 'Programs\drawing-board'
$exe = Join-Path $dir 'DrawingBoard.exe'
$bin = Join-Path $here 'bin\DrawingBoard.exe'
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$lnk = [Environment]::GetFolderPath('Startup')   # older versions used a Startup-folder shortcut
if ($lnk) { $lnk = Join-Path $lnk 'drawing-board.lnk' }

# stops only our helper (installed copy or bin\ copy); other users' processes have no ExecutablePath and are skipped
function Stop-Helper {
    $ours = @(Get-CimInstance Win32_Process -Filter "Name='DrawingBoard.exe'" |
        Where-Object { $_.ExecutablePath -eq $exe -or $_.ExecutablePath -eq $bin } |
        ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue })
    if ($ours | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq 'drawing-board' }) {
        throw 'Close the drawing window (Enter or Esc) first.'
    }
    foreach ($p in $ours) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $p.Id -Timeout 10 -ErrorAction SilentlyContinue
    }
}

if ($Uninstall) {
    Stop-Helper
    Remove-ItemProperty -LiteralPath $run -Name 'drawing-board' -ErrorAction SilentlyContinue
    if ($lnk -and (Test-Path -LiteralPath $lnk)) { Remove-Item -LiteralPath $lnk }
    if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe }
    if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir }
    "drawing-board removed. Your drawings in Pictures\drawing-board and the shortcut setting in %APPDATA%\drawing-board are kept."
    return
}

Stop-Helper   # before the build, so a helper started from bin\ cannot lock the build output
& (Join-Path $here 'build.ps1')
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item -LiteralPath $bin -Destination $exe -Force
if ($Autostart) {
    New-ItemProperty -LiteralPath $run -Name 'drawing-board' -Value ('"' + $exe + '" --tray') -PropertyType String -Force | Out-Null
    if ($lnk -and (Test-Path -LiteralPath $lnk)) { Remove-Item -LiteralPath $lnk }   # else two helpers start at logon
    "Autostart: $run\drawing-board"
}
Start-Process -FilePath $exe -ArgumentList '--tray'
$hk = 'Ctrl+Alt+D'
$hkFile = Join-Path $env:APPDATA 'drawing-board\hotkey.txt'
if (Test-Path -LiteralPath $hkFile) { $t = [IO.File]::ReadAllText($hkFile).Trim(); if ($t) { $hk = $t } }
"Installed: $exe"
"Press $hk to draw (change it from the tray icon menu). Enter sends, Esc cancels."
