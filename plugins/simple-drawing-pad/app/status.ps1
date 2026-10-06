# Says whether the Simple Drawing Pad pen window works on this computer. Read-only: it changes nothing.
#   .\status.ps1                 a short report; the last line is "Result: <state>: <what to do>", where <state> is
#                                ready, not-installed, not-running, shortcut-taken or update-available
#   .\status.ps1 -SessionStart   for the plugin's SessionStart hook (hooks\hooks.json): prints nothing when the pen
#                                window is ready, otherwise one JSON line that tells the user and Claude what to do;
#                                also nothing about a missing or stopped program after install.ps1 -Uninstall
#                                (it leaves %LOCALAPPDATA%\simple-drawing-pad\no-reminder.txt until the next install)
# The plugin comes with the user's Claude account; the program is installed separately on each Windows computer.
param([switch]$SessionStart)
$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 runs only on Windows; PowerShell 7 (pwsh) runs anywhere and sets $IsWindows
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
    if (-not $SessionStart) { 'The pen window is Windows-only. On this system use the browser board of the draw skill.' }
    exit 0
}

# hash of the program's source with line endings normalized, so a checkout with CRLF matches one with LF
function Get-SourceHash([string]$path) {
    $text = [IO.File]::ReadAllText($path) -replace "`r`n", "`n"
    $sha = [Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)) | ForEach-Object { $_.ToString('x2') }) } finally { $sha.Dispose() }
}

try {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    $dir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
    $exe = Join-Path $dir 'SimpleDrawingPad.exe'
    $bin = Join-Path $here 'bin\SimpleDrawingPad.exe'
    $src = Join-Path $here 'SimpleDrawingPad.cs'
    $hashFile = Join-Path $dir 'source.sha256'                                      # written by install.ps1
    $stateFile = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad\helper.txt'        # written by the helper
    $offFile = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad\no-reminder.txt'     # written by install.ps1 -Uninstall
    $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

    $installed = Test-Path -LiteralPath $exe
    # the helper is our program started with --tray, from the installed copy or the plugin's bin\ copy
    $helpers = @(Get-CimInstance Win32_Process -Filter "Name='SimpleDrawingPad.exe'" |
        Where-Object { ($_.ExecutablePath -eq $exe -or $_.ExecutablePath -eq $bin) -and $_.CommandLine -match '--tray' })
    # a helper started as administrator shows no path or command line to a normal process; the process id it
    # reported in helper.txt still identifies it (same name, same Windows session)
    if ($helpers.Count -eq 0 -and (Test-Path -LiteralPath $stateFile)) {
        $l = @([IO.File]::ReadAllLines($stateFile)); $id = 0
        if ($l.Count -ge 3 -and [int]::TryParse($l[2].Trim(), [ref]$id)) {
            $p = Get-Process -Id $id -ErrorAction SilentlyContinue
            if ($p -and $p.ProcessName -eq 'SimpleDrawingPad' -and $p.SessionId -eq (Get-Process -Id $PID).SessionId) {
                $helpers = @([pscustomobject]@{ ProcessId = $p.Id })
            }
        }
    }

    $hk = 'Ctrl+Alt+D'
    $hkFile = Join-Path $env:APPDATA 'simple-drawing-pad\hotkey.txt'
    if (Test-Path -LiteralPath $hkFile) { $t = [IO.File]::ReadAllText($hkFile).Trim(); if ($t) { $hk = $t } }
    # helper.txt: ok | taken, shortcut, process id, time. Trusted only from the one running helper: a helper older
    # than 0.5.0 does not write it, and a helper that has ended leaves its last report behind.
    $shortcut = 'unknown'
    if ($helpers.Count -eq 1 -and (Test-Path -LiteralPath $stateFile)) {
        $l = @([IO.File]::ReadAllLines($stateFile))
        if ($l.Count -ge 3 -and $l[2].Trim() -eq [string]$helpers[0].ProcessId -and $l[0].Trim() -in 'ok', 'taken') {
            $shortcut = $l[0].Trim(); if ($l[1].Trim()) { $hk = $l[1].Trim() }
        }
    }

    $autostart = $false
    $v = Get-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue
    if ($v) {
        $cmd = ([string]$v.'simple-drawing-pad').Trim()
        $path = if ($cmd.StartsWith('"')) { $cmd.Substring(1).Split('"')[0] } else { $cmd.Split(' ')[0] }
        $autostart = $path -eq $exe
    }

    # the plugin was updated with a newer program than the one installed (installs before 0.5.0 have no hash file)
    $outdated = $false
    if ($installed -and (Test-Path -LiteralPath $src)) {
        $built = if (Test-Path -LiteralPath $hashFile) { [IO.File]::ReadAllText($hashFile).Trim() } else { '' }
        $outdated = $built -ne (Get-SourceHash $src)
    }

    if (-not $installed) {
        $state = 'not-installed'
        $todo = "The drawing window is not installed on this computer, so $hk does nothing. Run /simple-drawing-pad:install once on each Windows computer."
    } elseif ($helpers.Count -eq 0) {
        $state = 'not-running'
        $todo = "The drawing window is installed, but its shortcut helper is not running, so $hk does nothing. Run /simple-drawing-pad:install to start it again."
    } elseif ($shortcut -eq 'taken') {
        $state = 'shortcut-taken'
        $todo = "$hk is taken by another program, so it does not open the drawing window. Right-click the Simple Drawing Pad icon in the notification area and choose ""Change shortcut""."
    } elseif ($outdated) {
        $state = 'update-available'
        $todo = "This version of the plugin has a newer drawing window. Run /simple-drawing-pad:install to update it."
    } else {
        $state = 'ready'
        $todo = "Press $hk to draw. Enter copies the drawing to the clipboard, Ctrl+V pastes it."
    }

    $off = Test-Path -LiteralPath $offFile
    if ($SessionStart) {
        if ($state -eq 'ready') { exit 0 }
        # the user removed the program on purpose: no reminder that it is missing or stopped
        if ($off -and $state -in 'not-installed', 'not-running') { exit 0 }
        $tell = $todo
        if ($state -eq 'not-installed') { $tell += ' (Not wanted on this computer? /simple-drawing-pad:uninstall turns this reminder off here.)' }
        @{
            systemMessage = "Simple Drawing Pad: $tell"
            hookSpecificOutput = @{
                hookEventName = 'SessionStart'
                additionalContext = "Simple Drawing Pad plugin, pen window status on this Windows computer: $state. $todo " +
                    'The plugin comes with the user''s Claude account, but the pen window program is installed separately on each computer. ' +
                    'If the user wants to draw or asks why the shortcut does nothing, explain this and offer the fix; ask before installing.'
            }
        } | ConvertTo-Json -Compress -Depth 3
        exit 0
    }

    'Simple Drawing Pad on this computer'
    'Program:   ' + $(if ($installed) { "installed ($exe)" } else { 'not installed' })
    'Helper:    ' + $(switch ($helpers.Count) { 0 { 'not running' } 1 { "running (process $($helpers[0].ProcessId))" }
                          default { "$_ running (processes $(($helpers | ForEach-Object { $_.ProcessId }) -join ', ')); /simple-drawing-pad:install restarts one" } })
    'Shortcut:  ' + $(switch ($shortcut) { 'ok' { "$hk works" } 'taken' { "$hk is taken by another program" } default { "$hk (not reported by the helper)" } })
    'Autostart: ' + $(if ($autostart) { 'on' } else { 'off (the helper does not start by itself after a restart)' })
    if ($outdated) { 'Update:    the plugin has a newer program than the installed one' }
    if ($off) { 'Reminder:  off on this computer (after /simple-drawing-pad:uninstall; the next install turns it on)' }
    "Result: ${state}: $todo"
} catch {
    # the SessionStart hook stays silent; a failed check is no reason to bother the user at every session
    if (-not $SessionStart) { "Could not check the pen window: $($_.Exception.Message)" }
}
exit 0
