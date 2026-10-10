# Removes the Simple Drawing Pad helper program for the current Windows user. Drawings are kept.
# install.ps1 puts a copy of this file next to the program (%USERPROFILE%\simple-drawing-pad\app) and lists the program
# in Windows Settings > Apps, where Windows shows it when the install ran outside the Store app's sandbox; the Uninstall
# button there runs that copy, so the program can be removed even after the plugin has been removed from Claude: this
# file uses nothing from the plugin folder. /simple-drawing-pad:uninstall (install.ps1 -Uninstall) runs the plugin's own copy.
#   .\uninstall.ps1            remove it and print what was done
#   .\uninstall.ps1 -Settings  the same, started from Windows Settings: the result is shown in a small message window
# Removed: the running helper; the shortcut "Simple Drawing Pad.lnk" in the Startup folder (0.8.0); the Run values
# simple-drawing-pad (up to 0.7.9) and drawing-board (up to 0.3.0); the Settings > Apps entry; app\ and helper.txt in
# %USERPROFILE%\simple-drawing-pad; the program files of up to 0.7.9 in %LOCALAPPDATA%\Programs\simple-drawing-pad, or
# the copy of the program and version.txt that install.ps1 leaves there for plugin copies of up to 0.7.9 (0.9.0), and
# helper.txt in %LOCALAPPDATA%\simple-drawing-pad (the helper also writes its report there while that copy exists), with
# that folder when it is empty.
# Kept, where present: drawings\ and shortcut.txt in %USERPROFILE%\simple-drawing-pad, and the drawings and settings of older versions.
# Written: notice.txt and no-reminder.txt in %USERPROFILE%\simple-drawing-pad, so the session-start question stays quiet.
param([switch]$Settings)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Join-Path $env:USERPROFILE 'simple-drawing-pad'                     # one folder for everything on this computer (0.8.0); see install.ps1
$dir = Join-Path $root 'app'                                                # the program and its files (0.8.0)
$exe = Join-Path $dir 'SimpleDrawingPad.exe'
$bin = Join-Path $here 'bin\SimpleDrawingPad.exe'                           # the build output, when this runs from the plugin
$drawings = Join-Path $root 'drawings'                                      # the drawings; kept
$stateFile = Join-Path $root 'helper.txt'                                   # the helper's report; removed with the helper
$noticeFile = Join-Path $root 'notice.txt'                                  # the session-start notice already shown here (status.ps1)
$offFile = Join-Path $root 'no-reminder.txt'                                # 0.5.0's version of "already asked"; replaced by notice.txt
$settingFile = Join-Path $root 'shortcut.txt'                               # the shortcut setting; kept
$startupDir = [Environment]::GetFolderPath('Startup')                        # no Create: an uninstall creates nothing; '' when the folder does not exist
$startup = if ($startupDir) { Join-Path $startupDir 'Simple Drawing Pad.lnk' }   # written by install.ps1 -Autostart (0.8.0)
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'               # values written by -Autostart up to 0.7.9 and by 0.3.0; only removed
$entry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\simple-drawing-pad'   # the Settings > Apps entry (0.6.2+)
# where 0.5.1-0.7.9 kept the program and its data; see install.ps1. Drawings and settings left there are not touched
$oldDir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
$oldExe = Join-Path $oldDir 'SimpleDrawingPad.exe'
$oldData = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad'
# previous name of this program (up to 0.3.0); see install.ps1
$legacyExe = Join-Path $env:LOCALAPPDATA 'Programs\drawing-board\DrawingBoard.exe'

# same as in install.ps1: stops only our helper (installed copy, the copy of up to 0.7.9, bin\ copy or the previous version's copy).
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

# same as in install.ps1: removes the Run value of up to 0.7.9 only if it starts exactly $oldExe; $true if removed
function Remove-OldAutostart {
    $v = Get-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue
    if (-not $v) { return $false }
    $cmd = ([string]$v.'simple-drawing-pad').Trim()
    $path = if ($cmd.StartsWith('"')) { $cmd.Substring(1).Split('"')[0] } else { $cmd.Split(' ')[0] }
    if ($path -ne $oldExe) { return $false }
    Remove-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad'
    return $true
}

# same as in install.ps1: removes the previous version's Run value only if it starts exactly $legacyExe; $true if removed
function Remove-LegacyAutostart {
    $v = Get-ItemProperty -LiteralPath $run -Name 'drawing-board' -ErrorAction SilentlyContinue
    if (-not $v) { return $false }
    $cmd = ([string]$v.'drawing-board').Trim()
    $path = if ($cmd.StartsWith('"')) { $cmd.Substring(1).Split('"')[0] } else { $cmd.Split(' ')[0] }
    if ($path -ne $legacyExe) { return $false }
    Remove-ItemProperty -LiteralPath $run -Name 'drawing-board'
    return $true
}

$failed = $null
try {
    # leave the program's folder, so it can be removed at the end
    if ($here -eq $dir) { Set-Location -LiteralPath $env:TEMP; [Environment]::CurrentDirectory = $env:TEMP }
    Stop-Helper
    if ($startup -and (Test-Path -LiteralPath $startup)) { Remove-Item -LiteralPath $startup }
    Remove-OldAutostart | Out-Null
    Remove-LegacyAutostart | Out-Null
    foreach ($f in $exe, (Join-Path $dir 'source.sha256'), (Join-Path $dir 'version.txt'), $stateFile,
                   $oldExe, (Join-Path $oldDir 'source.sha256'), (Join-Path $oldDir 'version.txt'), (Join-Path $oldData 'helper.txt')) {
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f }
    }
    # the Settings entry goes only after the program, so a failed removal can be tried again from Settings
    if (Test-Path -LiteralPath $entry) { Remove-Item -LiteralPath $entry -Recurse }
    # also when one of them is this file: PowerShell has already read all of it
    foreach ($copy in (Join-Path $dir 'uninstall.ps1'), (Join-Path $oldDir 'uninstall.ps1')) { if (Test-Path -LiteralPath $copy) { Remove-Item -LiteralPath $copy } }
    # an empty folder that is in use (for example a terminal opened in it) is left behind: it does no harm
    foreach ($d in $dir, $oldDir, $oldData) { if ((Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force)) { Remove-Item -LiteralPath $d -ErrorAction SilentlyContinue } }
    # removed on purpose: counts as "already asked", so the session-start question does not come back on this computer;
    # no-reminder.txt says the same to a 0.5.0 copy of the plugin that may still be in another Claude app
    New-Item -ItemType Directory -Force $root | Out-Null
    [IO.File]::WriteAllText($noticeFile, 'not-installed')
    [IO.File]::WriteAllText($offFile, "Written when Simple Drawing Pad was removed. While this file exists, the plugin does not remind you at session start that the drawing window is missing. /simple-drawing-pad:install deletes it.`r`n")
} catch {
    if (-not $Settings) { throw }
    $failed = $_.Exception.Message
}

if (-not $Settings) {
    "Simple Drawing Pad removed: the program in $dir, its shortcut in the Startup folder and its entry in Windows Settings > Apps, where present. Not removed: your drawings in $drawings and the shortcut setting $settingFile, where present (drawings of older versions may be in %LOCALAPPDATA%\simple-drawing-pad\drawings or Pictures\simple-drawing-pad)."
    "The plugin will not ask about the drawing window again on this computer; /simple-drawing-pad:install installs it again."
    return
}
Add-Type -AssemblyName System.Windows.Forms
if ($failed) {
    [void][Windows.Forms.MessageBox]::Show(
        "Simple Drawing Pad could not be removed completely:`n$failed`n`nTry again in Windows Settings > Apps, or with /simple-drawing-pad:uninstall in Claude.",
        'Simple Drawing Pad', 'OK', 'Warning')
    exit 1
}
[void][Windows.Forms.MessageBox]::Show(
    "Simple Drawing Pad has been removed from this computer.`n`nNot removed: your drawings in $drawings and the shortcut setting $settingFile, where present (drawings of older versions may be in %LOCALAPPDATA%\simple-drawing-pad\drawings or Pictures\simple-drawing-pad). Delete them if you no longer need them.`n`nIf the plugin is still in Claude, /simple-drawing-pad:install installs it again.",
    'Simple Drawing Pad', 'OK', 'Information')
