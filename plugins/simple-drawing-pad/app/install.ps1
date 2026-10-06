# Installs the Simple Drawing Pad pen window for the current Windows user. No downloads, no admin rights.
#   .\install.ps1              build, install to %LOCALAPPDATA%\Programs\simple-drawing-pad, start the shortcut helper
#   .\install.ps1 -Autostart   the same, plus start the helper at every Windows logon (HKCU ...\CurrentVersion\Run value)
#   .\install.ps1 -Uninstall   stop the helper and remove what this script installed (drawings are kept)
# status.ps1 (read-only) says whether it is installed and works.
param([switch]$Autostart, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
$exe = Join-Path $dir 'SimpleDrawingPad.exe'
$bin = Join-Path $here 'bin\SimpleDrawingPad.exe'
$hashFile = Join-Path $dir 'source.sha256'                                  # which source the program was built from (status.ps1)
$stateFile = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad\helper.txt'    # the helper's report: ok | taken, shortcut, process id, time
$offFile = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad\no-reminder.txt' # after -Uninstall: no session-start reminder (status.ps1)
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
# previous name of this program (up to 0.3.0). Only its running helper and its Run value are touched, and only when
# they point to exactly this file; its files, drawings and shortcut setting are left in place.
$legacyExe = Join-Path $env:LOCALAPPDATA 'Programs\drawing-board\DrawingBoard.exe'

# stops only our helper (installed copy, bin\ copy or the previous version's copy); other users' processes have no ExecutablePath and are skipped
function Stop-Helper {
    $ours = @(Get-CimInstance Win32_Process -Filter "Name='SimpleDrawingPad.exe' OR Name='DrawingBoard.exe'" |
        Where-Object { $_.ExecutablePath -eq $exe -or $_.ExecutablePath -eq $bin -or $_.ExecutablePath -eq $legacyExe } |
        ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue })
    if ($ours | Where-Object { $_.MainWindowHandle -ne 0 -and ($_.MainWindowTitle -like 'Simple Drawing Pad*' -or $_.MainWindowTitle -eq 'drawing-board') }) {
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

# same as in status.ps1: hash of the source with line endings normalized
function Get-SourceHash([string]$path) {
    $text = [IO.File]::ReadAllText($path) -replace "`r`n", "`n"
    $sha = [Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)) | ForEach-Object { $_.ToString('x2') }) } finally { $sha.Dispose() }
}

if ($Uninstall) {
    Stop-Helper
    Remove-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue
    [void](Remove-LegacyAutostart)
    if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe }
    if (Test-Path -LiteralPath $hashFile) { Remove-Item -LiteralPath $hashFile }
    if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir }
    if (Test-Path -LiteralPath $stateFile) { Remove-Item -LiteralPath $stateFile }
    # removed on purpose: the plugin's session-start check stops reminding to install it on this computer
    New-Item -ItemType Directory -Force (Split-Path -Parent $offFile) | Out-Null
    [IO.File]::WriteAllText($offFile, "Written by /simple-drawing-pad:uninstall. While this file exists, the plugin does not remind you at session start that the drawing window is missing. /simple-drawing-pad:install deletes it.`r`n")
    "Simple Drawing Pad removed. Your drawings in Pictures\simple-drawing-pad and the shortcut setting in %APPDATA%\simple-drawing-pad are kept."
    "The plugin no longer reminds you at session start on this computer; /simple-drawing-pad:install turns the reminder on again."
    return
}

Stop-Helper   # before the build, so a helper started from bin\ cannot lock the build output
& (Join-Path $here 'build.ps1')
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item -LiteralPath $bin -Destination $exe -Force
[IO.File]::WriteAllText($hashFile, (Get-SourceHash (Join-Path $here 'SimpleDrawingPad.cs')))
if (Test-Path -LiteralPath $offFile) { Remove-Item -LiteralPath $offFile }   # installed again: the reminder is back on
$legacyAutostart = Remove-LegacyAutostart   # else the previous version's helper starts again at logon
if ($Autostart) {
    New-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -Value ('"' + $exe + '" --tray') -PropertyType String -Force | Out-Null
    "Autostart: $run\simple-drawing-pad"
} elseif ($legacyAutostart) {
    'The previous version started at logon; its autostart entry was removed. Run this again with -Autostart to start the helper at every logon.'
}
$helper = Start-Process -FilePath $exe -ArgumentList '--tray' -PassThru
$hk = 'Ctrl+Alt+D'
$hkFile = Join-Path $env:APPDATA 'simple-drawing-pad\hotkey.txt'
if (Test-Path -LiteralPath $hkFile) { $t = [IO.File]::ReadAllText($hkFile).Trim(); if ($t) { $hk = $t } }
# wait up to 5 s for the new helper to report whether it could register its shortcut
$report = $null
for ($i = 0; $i -lt 50 -and -not $report; $i++) {
    Start-Sleep -Milliseconds 100
    $l = @(Get-Content -LiteralPath $stateFile -ErrorAction SilentlyContinue)
    if ($l.Count -ge 3 -and $l[2].Trim() -eq [string]$helper.Id) { $report = $l }
}
if ($report -and $report[1].Trim()) { $hk = $report[1].Trim() }
"Installed: $exe"
if ($report -and $report[0].Trim() -eq 'taken') {
    "WARNING: $hk is taken by another program, so it does not open the drawing window. Right-click the Simple Drawing Pad icon in the notification area and choose ""Change shortcut"" to pick another one."
} else {
    "Press $hk to draw (change it from the tray icon menu). Enter copies to the clipboard, Ctrl+V pastes, Esc cancels."
}
