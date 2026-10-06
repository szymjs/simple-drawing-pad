# Removes the Simple Drawing Pad helper program for the current Windows user. Drawings are kept.
# install.ps1 puts a copy of this file next to the program and lists the program in Windows Settings > Apps;
# the Uninstall button there runs that copy, so the program can be removed even after the plugin has
# been removed from Claude. /simple-drawing-pad:uninstall (install.ps1 -Uninstall) runs the plugin's own copy.
#   .\uninstall.ps1            remove it and print what was done
#   .\uninstall.ps1 -Settings  the same, started from Windows Settings: the result is shown in a small message window
param([switch]$Settings)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
$exe = Join-Path $dir 'SimpleDrawingPad.exe'
$bin = Join-Path $here 'bin\SimpleDrawingPad.exe'                           # the build output, when this runs from the plugin
$data = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad'
$noticeFile = Join-Path $data 'notice.txt'                                  # the session-start notice already shown here (status.ps1)
$offFile = Join-Path $data 'no-reminder.txt'                                # 0.5.0's version of "already asked"; replaced by notice.txt
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$entry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\simple-drawing-pad'   # the Settings > Apps entry
# previous name of this program (up to 0.3.0); see install.ps1
$legacyExe = Join-Path $env:LOCALAPPDATA 'Programs\drawing-board\DrawingBoard.exe'

# same as in install.ps1: stops only our helper (installed copy, bin\ copy or the previous version's copy)
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

# same as in install.ps1: removes the previous version's Run value only if it starts exactly $legacyExe
function Remove-LegacyAutostart {
    $v = Get-ItemProperty -LiteralPath $run -Name 'drawing-board' -ErrorAction SilentlyContinue
    if (-not $v) { return }
    $cmd = ([string]$v.'drawing-board').Trim()
    $path = if ($cmd.StartsWith('"')) { $cmd.Substring(1).Split('"')[0] } else { $cmd.Split(' ')[0] }
    if ($path -eq $legacyExe) { Remove-ItemProperty -LiteralPath $run -Name 'drawing-board' }
}

$failed = $null
try {
    # leave the program's folder, so it can be removed at the end
    if ($here -eq $dir) { Set-Location -LiteralPath $env:TEMP; [Environment]::CurrentDirectory = $env:TEMP }
    Stop-Helper
    Remove-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue
    Remove-LegacyAutostart
    foreach ($f in $exe, (Join-Path $dir 'source.sha256'), (Join-Path $dir 'version.txt'), (Join-Path $data 'helper.txt')) {
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f }
    }
    # the Settings entry goes only after the program, so a failed removal can be tried again from Settings
    if (Test-Path -LiteralPath $entry) { Remove-Item -LiteralPath $entry -Recurse }
    $copy = Join-Path $dir 'uninstall.ps1'   # also when it is this file: PowerShell has already read all of it
    if (Test-Path -LiteralPath $copy) { Remove-Item -LiteralPath $copy }
    # an empty folder that is in use (for example a terminal opened in it) is left behind: it does no harm
    if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir -ErrorAction SilentlyContinue }
    # removed on purpose: counts as "already asked", so the session-start question does not come back on this computer;
    # no-reminder.txt says the same to a 0.5.0 copy of the plugin that may still be in another Claude app
    New-Item -ItemType Directory -Force $data | Out-Null
    [IO.File]::WriteAllText($noticeFile, 'not-installed')
    [IO.File]::WriteAllText($offFile, "Written when Simple Drawing Pad was removed. While this file exists, the plugin does not remind you at session start that the drawing window is missing. /simple-drawing-pad:install deletes it.`r`n")
} catch {
    if (-not $Settings) { throw }
    $failed = $_.Exception.Message
}

if (-not $Settings) {
    "Simple Drawing Pad removed, including its entry in Windows Settings > Apps. Your drawings in %LOCALAPPDATA%\simple-drawing-pad\drawings (older ones in Pictures\simple-drawing-pad) and the shortcut setting in %APPDATA%\simple-drawing-pad are kept."
    "The plugin will not ask about the drawing window again on this computer; /simple-drawing-pad:install installs it again."
    return
}
$drawings = Join-Path $data 'drawings'
Add-Type -AssemblyName System.Windows.Forms
if ($failed) {
    [void][Windows.Forms.MessageBox]::Show(
        "Simple Drawing Pad could not be removed completely:`n$failed`n`nTry again in Settings > Apps.",
        'Simple Drawing Pad', 'OK', 'Warning')
    exit 1
}
[void][Windows.Forms.MessageBox]::Show(
    "Simple Drawing Pad has been removed from this computer.`n`nYour drawings in $drawings (older ones in Pictures\simple-drawing-pad) and the shortcut setting in %APPDATA%\simple-drawing-pad are kept. Delete them if you no longer need them.`n`nIf the plugin is still in Claude, /simple-drawing-pad:install installs it again.",
    'Simple Drawing Pad', 'OK', 'Information')
