# Installs the Simple Drawing Pad pen window for the current Windows user. No downloads, no admin rights, and the
# program it builds works only on this computer (no network access).
#   .\install.ps1              build, install to %LOCALAPPDATA%\Programs\simple-drawing-pad, start the shortcut helper
#   .\install.ps1 -Autostart   the same, plus start the helper at every Windows logon (HKCU ...\CurrentVersion\Run value)
#   .\install.ps1 -Uninstall   stop the helper and remove what this script installed (drawings are kept)
# status.ps1 says whether it is installed and works.
param([switch]$Autostart, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
$exe = Join-Path $dir 'SimpleDrawingPad.exe'
$bin = Join-Path $here 'bin\SimpleDrawingPad.exe'
$hashFile = Join-Path $dir 'source.sha256'                                  # which source the program was built from (status.ps1)
$versionFile = Join-Path $dir 'version.txt'                                 # which plugin version built it (status.ps1)
$data = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad'
$stateFile = Join-Path $data 'helper.txt'                                   # the helper's report: ok | taken, shortcut, process id, time
$noticeFile = Join-Path $data 'notice.txt'                                  # the session-start notice already shown here (status.ps1)
$offFile = Join-Path $data 'no-reminder.txt'                                # 0.5.0's version of "already asked"; replaced by notice.txt
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

# a shortcut name read from a file reaches the user and Claude only if it looks like one (Ctrl+Alt+D, Ctrl+Shift+F12)
function Test-Shortcut([string]$s) { $s.Length -le 40 -and $s -match '^((ctrl|control|alt|shift)\s*\+\s*){1,3}[a-z0-9]{1,20}$' }

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
    foreach ($f in $exe, $hashFile, $versionFile, $stateFile) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f } }
    if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir }
    # removed on purpose: counts as "already asked", so the session-start question does not come back on this computer;
    # no-reminder.txt says the same to a 0.5.0 copy of the plugin that may still be in another Claude app
    New-Item -ItemType Directory -Force $data | Out-Null
    [IO.File]::WriteAllText($noticeFile, 'not-installed')
    [IO.File]::WriteAllText($offFile, "Written by /simple-drawing-pad:uninstall. While this file exists, the plugin does not remind you at session start that the drawing window is missing. /simple-drawing-pad:install deletes it.`r`n")
    "Simple Drawing Pad removed. Your drawings in %LOCALAPPDATA%\simple-drawing-pad\drawings (older ones in Pictures\simple-drawing-pad) and the shortcut setting in %APPDATA%\simple-drawing-pad are kept."
    "The plugin will not ask about the drawing window again on this computer; /simple-drawing-pad:install installs it again."
    return
}

# an older copy of the plugin (for example in another Claude app that has not updated yet) must not put its older
# program over a newer one: then the installed program is kept and only started
$version = ''
try { $version = [string](Get-Content -Raw -LiteralPath (Join-Path $here '..\.claude-plugin\plugin.json') | ConvertFrom-Json).version } catch { }
$installedVersion = if (Test-Path -LiteralPath $versionFile) { [IO.File]::ReadAllText($versionFile).Trim() } else { '' }
$a = $null; $b = $null
$keep = (Test-Path -LiteralPath $exe) -and [version]::TryParse($version, [ref]$a) -and [version]::TryParse($installedVersion, [ref]$b) -and $b -gt $a

Stop-Helper   # before the build, so a helper started from bin\ cannot lock the build output
if ($keep) {
    "The installed program ($b) is newer than this copy of the plugin ($a), so it is kept and only started."
} else {
    & (Join-Path $here 'build.ps1')
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item -LiteralPath $bin -Destination $exe -Force
    [IO.File]::WriteAllText($hashFile, (Get-SourceHash (Join-Path $here 'SimpleDrawingPad.cs')))   # one line: 0.5.0 compares the whole file
    if ($version) { [IO.File]::WriteAllText($versionFile, $version) } elseif (Test-Path -LiteralPath $versionFile) { Remove-Item -LiteralPath $versionFile }
}
# installed (again): start fresh, so a later problem gets its one session-start notice
foreach ($f in $noticeFile, $offFile) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f } }
$legacyAutostart = Remove-LegacyAutostart   # else the previous version's helper starts again at logon
if ($Autostart) {
    New-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -Value ('"' + $exe + '" --tray') -PropertyType String -Force | Out-Null
    "Autostart: $run\simple-drawing-pad"
} elseif ($legacyAutostart) {
    'The previous version started at logon; its autostart entry was removed. Run this again with -Autostart to start the helper at every logon.'
}
# started in its own folder, not in the folder this script runs from (for example a project folder)
$helper = Start-Process -FilePath $exe -ArgumentList '--tray' -WorkingDirectory $dir -PassThru
$hk = 'Ctrl+Alt+D'
$hkFile = Join-Path $env:APPDATA 'simple-drawing-pad\hotkey.txt'
if (Test-Path -LiteralPath $hkFile) { $t = [IO.File]::ReadAllText($hkFile).Trim(); if (Test-Shortcut $t) { $hk = $t } }
# wait up to 5 s for the new helper to report whether it could register its shortcut
$report = $null
for ($i = 0; $i -lt 50 -and -not $report; $i++) {
    Start-Sleep -Milliseconds 100
    $l = @(Get-Content -LiteralPath $stateFile -ErrorAction SilentlyContinue)
    if ($l.Count -ge 3 -and $l[2].Trim() -eq [string]$helper.Id) { $report = $l }
}
if ($report -and (Test-Shortcut $report[1].Trim())) { $hk = $report[1].Trim() }
"Installed: $exe"
if ($report -and $report[0].Trim() -eq 'taken') {
    "WARNING: $hk is taken by another program, so it does not open the drawing window. Right-click the Simple Drawing Pad icon in the notification area and choose ""Change shortcut"" to pick another one."
} else {
    "Press $hk to draw (change it from the tray icon menu). Enter copies to the clipboard, Ctrl+V pastes, Esc cancels."
}
"Drawings stay on this computer in $(Join-Path $data 'drawings') (the last 10 are kept). The program does not use the network."
