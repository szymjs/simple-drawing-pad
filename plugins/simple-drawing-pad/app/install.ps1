# Installs the Simple Drawing Pad pen window for the current Windows user. No downloads, no admin rights, and the
# program it builds works only on this computer (no network access).
#   .\install.ps1              build, install to %LOCALAPPDATA%\Programs\simple-drawing-pad, start the shortcut helper
#   .\install.ps1 -Autostart   the same, plus start the helper at every Windows logon (HKCU ...\CurrentVersion\Run value)
#   .\install.ps1 -Uninstall   stop the helper and remove what this script installed (drawings are kept): runs uninstall.ps1
# The program is also listed in Windows Settings > Apps, for this user only; its Uninstall button runs
# the copy of uninstall.ps1 next to the program. status.ps1 says whether it is installed and works.
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
$uninstaller = Join-Path $dir 'uninstall.ps1'                               # run by the Settings > Apps entry
$entry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\simple-drawing-pad'   # the Settings > Apps entry
# previous name of this program (up to 0.3.0). Only its running helper and its Run value are touched, and only when
# they point to exactly this file; its files, drawings and shortcut setting are left in place.
$legacyExe = Join-Path $env:LOCALAPPDATA 'Programs\drawing-board\DrawingBoard.exe'

# stops only our helper (installed copy, bin\ copy or the previous version's copy); other users' processes have no ExecutablePath and are skipped
function Stop-Helper {
    $ours = @(Get-CimInstance Win32_Process -Filter "Name='SimpleDrawingPad.exe' OR Name='DrawingBoard.exe'" |
        Where-Object { $_.ExecutablePath -eq $exe -or $_.ExecutablePath -eq $bin -or $_.ExecutablePath -eq $legacyExe } |
        ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue })
    if ($ours | Where-Object { $_.MainWindowHandle -ne 0 -and ($_.MainWindowTitle -like 'Simple Drawing Pad*' -or $_.MainWindowTitle -eq 'drawing-board') }) {
        throw 'Close the open Simple Drawing Pad window first (the drawing window: Enter or Esc).'
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
function Get-SourceHash([string[]]$paths) {
    $text = -join ($paths | ForEach-Object { ([IO.File]::ReadAllText($_) -replace "`r`n", "`n") + "`n" })
    $sha = [Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)) | ForEach-Object { $_.ToString('x2') }) } finally { $sha.Dispose() }
}

if ($Uninstall) {
    & (Join-Path $here 'uninstall.ps1')   # the same steps as the Uninstall button in Settings > Apps
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
    # a failed build leaves the installed program as it was: start it again, so the shortcut keeps working
    try { & (Join-Path $here 'build.ps1') }
    catch { if (Test-Path -LiteralPath $exe) { Start-Process -FilePath $exe -ArgumentList '--tray' -WorkingDirectory $dir | Out-Null }; throw }
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item -LiteralPath $bin -Destination $exe -Force
    Copy-Item -LiteralPath (Join-Path $here 'uninstall.ps1') -Destination $uninstaller -Force
    [IO.File]::WriteAllText($hashFile, (Get-SourceHash @((Join-Path $here 'SimpleDrawingPad.cs'), (Join-Path $here 'build.ps1'), (Join-Path $here 'uninstall.ps1'))))   # one line: 0.5.0 compares the whole file
    if ($version) { [IO.File]::WriteAllText($versionFile, $version) } elseif (Test-Path -LiteralPath $versionFile) { Remove-Item -LiteralPath $versionFile }
    # listed in Windows Settings > Apps, for this user only (no admin rights). Its Uninstall button
    # runs the copy of uninstall.ps1 next to the program, so it works even after the plugin is removed from Claude.
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    New-Item -Path $entry -Force | Out-Null
    $values = [ordered]@{
        DisplayName     = 'Simple Drawing Pad'
        DisplayVersion  = $version
        Publisher       = 'szymjs'
        Comments        = 'Helper program of the Simple Drawing Pad plugin for Claude. Works only on this computer, without the network.'
        DisplayIcon     = $exe
        InstallLocation = $dir
        InstallDate     = (Get-Date).ToString('yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture)
        URLInfoAbout    = 'https://github.com/szymjs/simple-drawing-pad'
        UninstallString = '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}" -Settings' -f $ps, $uninstaller
    }
    foreach ($k in $values.Keys) { if ($values[$k]) { New-ItemProperty -LiteralPath $entry -Name $k -Value $values[$k] -PropertyType String -Force | Out-Null } }
    $kb = [int][Math]::Ceiling(((Get-Item -LiteralPath $exe).Length + (Get-Item -LiteralPath $uninstaller).Length) / 1KB)
    foreach ($v in @(@('NoModify', 1), @('NoRepair', 1), @('EstimatedSize', $kb))) { New-ItemProperty -LiteralPath $entry -Name $v[0] -Value $v[1] -PropertyType DWord -Force | Out-Null }
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
# the shortcut setting is kept in %APPDATA%\simple-drawing-pad\shortcut.txt; up to 0.7.3 the file had another name
$settings = Join-Path $env:APPDATA 'simple-drawing-pad'
$oldSetting = Join-Path $settings 'hotkey.txt'
if ((Test-Path -LiteralPath $oldSetting) -and -not (Test-Path -LiteralPath (Join-Path $settings 'shortcut.txt'))) { Rename-Item -LiteralPath $oldSetting -NewName 'shortcut.txt' }
# started in its own folder, not in the folder this script runs from (for example a project folder)
$helper = Start-Process -FilePath $exe -ArgumentList '--tray' -WorkingDirectory $dir -PassThru
$hk = 'Ctrl+Alt+D'   # a changed shortcut is reported by the helper itself (helper.txt)
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
'Listed in Windows Settings > Apps as Simple Drawing Pad: uninstall it there or with /simple-drawing-pad:uninstall.'
