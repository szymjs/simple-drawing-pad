# Installs the Simple Drawing Pad pen window for the current Windows user. No downloads, no admin rights, and the
# program it builds works only on this computer (no network access).
#   .\install.ps1              build, install to %USERPROFILE%\simple-drawing-pad\app, start the shortcut helper
#   .\install.ps1 -Autostart   the same, plus start the helper at every Windows logon: a shortcut "Simple Drawing Pad.lnk"
#                              in the user's Startup folder (Explorer: shell:startup; Task Manager: Startup apps); the folder
#                              is created when it is missing. When the shortcut cannot be created this is reported and the
#                              helper is started all the same
#   .\install.ps1 -Uninstall   stop the helper and remove what this script installed (drawings are kept): runs uninstall.ps1
# Everything is in one folder directly under the user profile, %USERPROFILE%\simple-drawing-pad (since 0.8.0): app\ has
# the program, a copy of uninstall.ps1, source.sha256 and version.txt; drawings\ has the drawings; the folder itself has
# helper.txt, notice.txt, no-reminder.txt and shortcut.txt. A folder directly under the user profile is the same folder
# for every program that runs as the user, including the Store version of the Claude app, whose sandbox keeps new
# folders under AppData (and registry writes) to itself; Explorer shows it and OneDrive does not sync it.
# An install of 0.5.1-0.7.9 (program in %LOCALAPPDATA%\Programs\simple-drawing-pad, data in %LOCALAPPDATA%\simple-drawing-pad,
# shortcut setting in %APPDATA%\simple-drawing-pad) is moved there: its drawings and its setting are taken along; its
# program files, helper.txt, notice files, Run value and emptied folders are removed. The setting file itself stays.
# The program is also listed in Windows Settings > Apps, for this user only; its Uninstall button runs the copy of
# uninstall.ps1 next to the program. Windows shows that entry when this script ran outside the Store app's sandbox
# (claude in a terminal, the EXE desktop app) and not otherwise; /simple-drawing-pad:uninstall works either way.
# status.ps1 says whether it is installed and works.
param([switch]$Autostart, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Join-Path $env:USERPROFILE 'simple-drawing-pad'                     # one folder for everything on this computer (0.8.0); the helper, status.ps1
$dir = Join-Path $root 'app'                                                # the program and its files (0.8.0); the Settings > Apps entry, status.ps1
$exe = Join-Path $dir 'SimpleDrawingPad.exe'
$bin = Join-Path $here 'bin\SimpleDrawingPad.exe'
$hashFile = Join-Path $dir 'source.sha256'                                  # which source the program was built from (status.ps1)
$versionFile = Join-Path $dir 'version.txt'                                 # which plugin version built it (status.ps1)
$drawings = Join-Path $root 'drawings'                                      # written by the helper (here since 0.8.0); the draw skill, status.ps1
$stateFile = Join-Path $root 'helper.txt'                                   # the helper's report: ok | taken, shortcut, process id, time (here since 0.8.0)
$noticeFile = Join-Path $root 'notice.txt'                                  # the session-start notice already shown here (status.ps1)
$offFile = Join-Path $root 'no-reminder.txt'                                # 0.5.0's version of "already asked"; replaced by notice.txt
$settingFile = Join-Path $root 'shortcut.txt'                               # the shortcut setting, read and written by the helper (here since 0.8.0)
$startupDir = [Environment]::GetFolderPath('Startup', $(if ($Autostart) { 'Create' } else { 'None' }))   # the Startup folder; -Autostart creates it when it is missing; '' when it does not exist or cannot be created
$startup = if ($startupDir) { Join-Path $startupDir 'Simple Drawing Pad.lnk' }   # -Autostart: Windows runs it at logon (0.8.0); status.ps1
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'               # up to 0.7.9 -Autostart wrote the value simple-drawing-pad here; now only removed
$uninstaller = Join-Path $dir 'uninstall.ps1'                               # run by the Settings > Apps entry
$entry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\simple-drawing-pad'   # the Settings > Apps entry (0.6.2+; status.ps1)
# where 0.5.1-0.7.9 kept the program, its data and the shortcut setting (hotkey.txt before 0.7.3); moved to $root below
$oldDir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
$oldExe = Join-Path $oldDir 'SimpleDrawingPad.exe'
$oldData = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad'
$oldSettings = Join-Path $env:APPDATA 'simple-drawing-pad'
# previous name of this program (up to 0.3.0). Only its running helper and its Run value are touched, and only when
# they point to exactly this file; its files, drawings and shortcut setting are left in place.
$legacyExe = Join-Path $env:LOCALAPPDATA 'Programs\drawing-board\DrawingBoard.exe'

# stops only our helper (installed copy, the copy of up to 0.7.9, bin\ copy or the previous version's copy); other users' processes have no ExecutablePath and are skipped.
# A copy of up to 0.7.9 installed from inside the Store app's sandbox runs from the sandbox's private copy of its folder
# (...\Packages\Claude_...\LocalCache\Local\Programs\simple-drawing-pad\), so that folder name is matched by its ending too
function Stop-Helper {
    $ours = @(Get-CimInstance Win32_Process -Filter "Name='SimpleDrawingPad.exe' OR Name='DrawingBoard.exe'" |
        Where-Object { $_.ExecutablePath -eq $exe -or $_.ExecutablePath -eq $oldExe -or $_.ExecutablePath -eq $bin -or $_.ExecutablePath -eq $legacyExe -or $_.ExecutablePath -like '*\Programs\simple-drawing-pad\SimpleDrawingPad.exe' } |
        ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue })
    if ($ours | Where-Object { $_.MainWindowHandle -ne 0 -and ($_.MainWindowTitle -like 'Simple Drawing Pad*' -or $_.MainWindowTitle -eq 'drawing-board') }) {
        throw 'Close the open Simple Drawing Pad window first (the drawing window: Enter or Esc).'
    }
    foreach ($p in $ours) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $p.Id -Timeout 10 -ErrorAction SilentlyContinue
    }
}

# removes the Run value of up to 0.7.9 only if the program it starts is exactly $oldExe (what those versions wrote); $true if removed.
# Since 0.8.0 the shortcut in the Startup folder starts the helper: a Run value written inside the Store app's sandbox never runs
function Remove-OldAutostart {
    $v = Get-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue
    if (-not $v) { return $false }
    $cmd = ([string]$v.'simple-drawing-pad').Trim()
    $path = if ($cmd.StartsWith('"')) { $cmd.Substring(1).Split('"')[0] } else { $cmd.Split(' ')[0] }
    if ($path -ne $oldExe) { return $false }
    Remove-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad'
    return $true
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

# takes the drawings (drawing_*.png) of a folder of up to 0.7.9 along, one by one; a drawing that already exists at the new
# place is not overwritten and stays where it was. latest.png, latest.txt and status.txt name paths in the old folder,
# so they are not taken along: the helper writes new ones at the next drawing, and the migration below removes the old ones
function Move-OldFiles([string]$from, [string]$to) {
    if (-not (Test-Path -LiteralPath $from)) { return }
    New-Item -ItemType Directory -Force $to | Out-Null
    foreach ($f in @(Get-ChildItem -LiteralPath $from -File -Force -Filter 'drawing_*.png')) {
        $target = Join-Path $to $f.Name
        if (-not (Test-Path -LiteralPath $target)) { Move-Item -LiteralPath $f.FullName -Destination $target }
    }
}

if ($Uninstall) {
    & (Join-Path $here 'uninstall.ps1')   # the same steps as the Uninstall button in Settings > Apps
    return
}

# an older copy of the plugin (for example in another Claude app that has not updated yet) must not put its older
# program over a newer one: then the installed program is kept and only started. The installed version is read next
# to the program, or from the folder of up to 0.7.9 while the program is still there
$version = ''
try { $version = [string](Get-Content -Raw -LiteralPath (Join-Path $here '..\.claude-plugin\plugin.json') | ConvertFrom-Json).version } catch { }
$installedVersion = ''
foreach ($f in $versionFile, (Join-Path $oldDir 'version.txt')) { if (-not $installedVersion -and (Test-Path -LiteralPath $f)) { $installedVersion = [IO.File]::ReadAllText($f).Trim() } }
$a = $null; $b = $null
$keep = (Test-Path -LiteralPath $exe) -and [version]::TryParse($version, [ref]$a) -and [version]::TryParse($installedVersion, [ref]$b) -and $b -gt $a

Stop-Helper   # before the build, so a helper started from bin\ cannot lock the build output; also the helper of up to 0.7.9, whose files move below
if ($keep) {
    "The installed program ($b) is newer than this copy of the plugin ($a), so it is kept and only started."
} else {
    # a failed build leaves the installed program as it was: start it again, so the shortcut keeps working
    try { & (Join-Path $here 'build.ps1') }
    catch {
        if (Test-Path -LiteralPath $exe) { Start-Process -FilePath $exe -ArgumentList '--tray' -WorkingDirectory $dir | Out-Null }
        elseif (Test-Path -LiteralPath $oldExe) { Start-Process -FilePath $oldExe -ArgumentList '--tray' -WorkingDirectory $oldDir | Out-Null }
        throw
    }
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item -LiteralPath $bin -Destination $exe -Force
    Copy-Item -LiteralPath (Join-Path $here 'uninstall.ps1') -Destination $uninstaller -Force
    [IO.File]::WriteAllText($hashFile, (Get-SourceHash @((Join-Path $here 'SimpleDrawingPad.cs'), (Join-Path $here 'build.ps1'), (Join-Path $here 'uninstall.ps1'))))   # one line: 0.5.0 compares the whole file
    if ($version) { [IO.File]::WriteAllText($versionFile, $version) } elseif (Test-Path -LiteralPath $versionFile) { Remove-Item -LiteralPath $versionFile }
    # an install of up to 0.7.9 moves here: its drawings file by file, its shortcut setting once (when there is none here
    # yet); then its program files, the report of the helper stopped above, its notice files (this install asks afresh)
    # and the emptied folders go. The new program works without this step, so a problem here is only reported
    try {
        Move-OldFiles (Join-Path $oldData 'drawings\cancelled') (Join-Path $drawings 'cancelled')
        Move-OldFiles (Join-Path $oldData 'drawings') $drawings
        if (-not (Test-Path -LiteralPath $settingFile)) {
            foreach ($f in (Join-Path $oldSettings 'shortcut.txt'), (Join-Path $oldSettings 'hotkey.txt')) {
                if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination $settingFile -Force; break }
            }
        }
        foreach ($f in $oldExe, (Join-Path $oldDir 'uninstall.ps1'), (Join-Path $oldDir 'source.sha256'), (Join-Path $oldDir 'version.txt'),
                       (Join-Path $oldData 'helper.txt'), (Join-Path $oldData 'notice.txt'), (Join-Path $oldData 'no-reminder.txt'),
                       (Join-Path $oldData 'drawings\latest.png'), (Join-Path $oldData 'drawings\latest.txt'), (Join-Path $oldData 'drawings\status.txt')) {
            if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f }
        }
        foreach ($d in $oldDir, (Join-Path $oldData 'drawings\cancelled'), (Join-Path $oldData 'drawings'), $oldData) {
            if ((Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force)) { Remove-Item -LiteralPath $d -ErrorAction SilentlyContinue }
        }
    } catch {
        # names only the folders of the previous version that are still there: after its uninstall only the data folder is
        $left = @($oldData, $oldDir | Where-Object { Test-Path -LiteralPath $_ }) -join ' and '
        if (-not $left) { $left = 'its folders' }
        "WARNING: not everything of the previous version was moved from $left to ${root}: $($_.Exception.Message) The new program works; /simple-drawing-pad:install tries the move again."
    }
    # listed in Windows Settings > Apps, for this user only (no admin rights). Its Uninstall button runs the copy of
    # uninstall.ps1 next to the program, so it works even after the plugin is removed from Claude. Windows shows the
    # entry when this script runs outside the Store app's sandbox (claude in a terminal, the EXE desktop app); inside
    # it, the key lands in the sandbox's private registry and the entry does not appear. The final message says so.
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
# installed (again): start fresh, so a later problem gets its one session-start notice; the notice files of up to 0.7.9
# count for status.ps1 too, so they go as well, also when the installed program is kept and the move above is skipped
foreach ($f in $noticeFile, $offFile, (Join-Path $oldData 'notice.txt'), (Join-Path $oldData 'no-reminder.txt')) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f } }
$oldAutostart = Remove-OldAutostart         # else Windows looks for the removed program of up to 0.7.9 at every logon
$legacyAutostart = Remove-LegacyAutostart   # else the previous version's helper starts again at logon
$autostartProblem = ''   # -Autostart: why the shortcut could not be created; the helper is started all the same
if ($Autostart -and $startup) {
    # the standard per-user autostart: Windows runs the shortcut at logon, Task Manager lists it under Startup apps and
    # Explorer shows it (shell:startup), where it can be deleted. It is real from inside the Store app's sandbox too,
    # because the Startup folder already exists there (a Run value written there stays in the sandbox's private registry).
    # The helper works without it, so a problem here (a read-only or unreachable Startup folder, no WScript.Shell) is only reported
    try {
        $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($startup)
        $lnk.TargetPath = $exe
        $lnk.Arguments = '--tray'
        $lnk.WorkingDirectory = $dir
        $lnk.IconLocation = $exe
        $lnk.Description = 'Simple Drawing Pad helper (Ctrl+Alt+D opens the drawing window)'
        $lnk.Save()
    } catch {
        $autostartProblem = $_.Exception.Message
        "WARNING: the shortcut $startup could not be created, so the helper does not start by itself after a restart: $autostartProblem"
    }
} elseif ($Autostart) {
    'WARNING: your Startup folder is missing and could not be created, so the helper does not start with Windows.'
} elseif ($oldAutostart -or $legacyAutostart) {
    'The previous version started at logon; its autostart entry was removed. Run this again with -Autostart to start the helper at every logon.'
}
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
'Starts with Windows: ' + $(if ($startup -and (Test-Path -LiteralPath $startup)) { "a shortcut in your Startup folder ($startup)" }
                             elseif ($autostartProblem) { "not enabled: the shortcut could not be created (see the warning above). After a restart, run /simple-drawing-pad:install to start the helper, or create the shortcut yourself in shell:startup (target ""$exe"" --tray)." }
                             elseif ($Autostart) { 'not enabled (the Startup folder is missing; see the warning above)' }
                             else { 'not enabled (run this again with -Autostart)' })
if ($report -and $report[0].Trim() -eq 'taken') {
    "WARNING: $hk is taken by another program, so it does not open the drawing window. Right-click the Simple Drawing Pad icon in the notification area and choose ""Change shortcut"" to pick another one."
} else {
    "Press $hk to draw (change it from the tray icon menu). Enter copies to the clipboard, Ctrl+V pastes, Esc cancels."
}
"Drawings stay on this computer in $drawings (the last 10 are kept). The program does not use the network."
'Remove it with /simple-drawing-pad:uninstall; the entry in Windows Settings > Apps appears when Windows can see it.'
