# Says whether the Simple Drawing Pad pen window works on this computer.
#   .\status.ps1                 a short report that changes nothing; the last line is "Result: <state>: <what to do>",
#                                where <state> is ready, not-installed, not-running, shortcut-taken or update-available
#   .\status.ps1 -SessionStart   for the plugin's SessionStart hook (hooks\hooks.json). When something is wrong it shows
#                                the user one notice, once per computer and problem, and always tells Claude the state
#                                (one JSON line); nothing when the pen window is ready. To show each notice only once
#                                it writes %USERPROFILE%\simple-drawing-pad\notice.txt, creating that folder when needed
#                                (this computer only).
# Since 0.8.0 the program, its files and the drawings live in %USERPROFILE%\simple-drawing-pad: a folder directly under
# the user profile is the same folder for every program that runs as the user, including the Store version of the
# Claude app, whose sandbox keeps new folders under AppData and registry entries to itself; Explorer shows it and
# OneDrive does not sync it. A program still in the old folder (0.5.1 to 0.7.9) is reported as an update to install.
# The report reads the real registry through WMI (StdRegProv) for the Windows Settings > Apps line, so it says what
# Windows shows and not what this process sees, and it names the Store version of the Claude app when it runs inside
# it (found by walking the parent processes). Both lines are informational; neither changes the state.
# The plugin comes with the user's Claude account; the program is installed separately on each Windows computer.
param([switch]$SessionStart)
$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 runs only on Windows; PowerShell 7 (pwsh) runs anywhere and sets $IsWindows
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
    if (-not $SessionStart) { 'The pen window is Windows-only. On this system use the browser board of the draw skill.' }
    exit 0
}

# hash of the program's source with line endings normalized, so a checkout with CRLF matches one with LF
function Get-SourceHash([string[]]$paths) {
    $text = -join ($paths | ForEach-Object { ([IO.File]::ReadAllText($_) -replace "`r`n", "`n") + "`n" })
    $sha = [Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)) | ForEach-Object { $_.ToString('x2') }) } finally { $sha.Dispose() }
}

# a shortcut name read from a file reaches the user and Claude only if it looks like one (Ctrl+Alt+D, Ctrl+Shift+F12)
function Test-Shortcut([string]$s) { $s.Length -le 40 -and $s -match '^((ctrl|control|alt|shift)\s*\+\s*){1,3}[a-z0-9]{1,20}$' }

# JSON with every non-ASCII character escaped, so the hook's output survives any console code page
function ConvertTo-AsciiJson($value) {
    [regex]::Replace(($value | ConvertTo-Json -Compress -Depth 4), '[^\x00-\x7F]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
}

try {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    $root = Join-Path $env:USERPROFILE 'simple-drawing-pad'                         # one folder for everything (0.8.0+)
    $dir = Join-Path $root 'app'                                                    # the program; written by install.ps1 (0.8.0+)
    $exe = Join-Path $dir 'SimpleDrawingPad.exe'
    $src = Join-Path $here 'SimpleDrawingPad.cs'
    $hashFile = Join-Path $dir 'source.sha256'                                      # written by install.ps1
    $versionFile = Join-Path $dir 'version.txt'                                     # written by install.ps1 (0.5.1+)
    $drawings = Join-Path $root 'drawings'                                          # written by the helper (0.8.0+)
    $stateFile = Join-Path $root 'helper.txt'                                       # written by the helper (0.8.0+)
    $noticeFile = Join-Path $root 'notice.txt'                                      # the notice already shown here (0.8.0+)
    $legacyOff = Join-Path $root 'no-reminder.txt'                                  # written by uninstall.ps1: no notice
    $startup = [Environment]::GetFolderPath('Startup')
    $link = if ($startup) { Join-Path $startup 'Simple Drawing Pad.lnk' }           # written by install.ps1 -Autostart (0.8.0+)
    $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'                    # 'simple-drawing-pad' value: install.ps1 up to 0.7.9
    $entry = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\simple-drawing-pad'   # under HKCU; written by install.ps1 (0.6.2+)
    # up to 0.7.9 the program was in %LOCALAPPDATA%\Programs\simple-drawing-pad, its files and the drawings in
    # %LOCALAPPDATA%\simple-drawing-pad. install.ps1 moves them; this script only reads them.
    $oldDir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
    $oldExe = Join-Path $oldDir 'SimpleDrawingPad.exe'
    $oldHashFile = Join-Path $oldDir 'source.sha256'                                # written by install.ps1 0.5.0 to 0.7.9
    $oldData = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad'
    $oldNoticeFile = Join-Path $oldData 'notice.txt'                                # a notice shown by a plugin up to 0.7.9
    $oldLegacyOff = Join-Path $oldData 'no-reminder.txt'                            # uninstall.ps1 0.5.0 to 0.7.9: no notice

    $installed = Test-Path -LiteralPath $exe
    $legacy = (-not $installed) -and (Test-Path -LiteralPath $oldExe)   # installed by a plugin up to 0.7.9 and not moved yet
    # the helper is found without reading other programs' command lines: by the process id it reports in helper.txt
    # (same name, same Windows session; this also finds a helper started as administrator), else, for helpers older
    # than 0.5.0 that write no helper.txt and for a helper still running from the old folder, by the program's path
    $session = (Get-Process -Id $PID).SessionId
    $helpers = @()
    if (Test-Path -LiteralPath $stateFile) {
        $l = @([IO.File]::ReadAllLines($stateFile)); $id = 0
        if ($l.Count -ge 3 -and [int]::TryParse($l[2].Trim(), [ref]$id)) {
            $p = Get-Process -Id $id -ErrorAction SilentlyContinue
            if ($p -and $p.ProcessName -eq 'SimpleDrawingPad' -and $p.SessionId -eq $session) { $helpers = @([pscustomobject]@{ ProcessId = $p.Id }) }
        }
    }
    if ($helpers.Count -eq 0) {
        $helpers = @(Get-Process -Name SimpleDrawingPad -ErrorAction SilentlyContinue |
            Where-Object { $_.SessionId -eq $session -and ($_.Path -eq $exe -or ($legacy -and $_.Path -eq $oldExe)) } | ForEach-Object { [pscustomobject]@{ ProcessId = $_.Id } })
    }

    $hk = 'Ctrl+Alt+D'   # a changed shortcut is reported by the helper itself (helper.txt)
    # helper.txt: ok | taken, shortcut, process id, time. Trusted only from the one running helper: a helper older
    # than 0.5.0 does not write it, and a helper that has ended leaves its last report behind.
    $shortcut = 'unknown'
    if ($helpers.Count -eq 1 -and (Test-Path -LiteralPath $stateFile)) {
        $l = @([IO.File]::ReadAllLines($stateFile))
        if ($l.Count -ge 3 -and $l[2].Trim() -eq [string]$helpers[0].ProcessId -and $l[0].Trim() -in 'ok', 'taken') {
            $shortcut = $l[0].Trim(); if (Test-Shortcut $l[1].Trim()) { $hk = $l[1].Trim() }
        }
    }

    # since 0.8.0 the helper starts with Windows by a shortcut in the Startup folder (Task Manager > Startup apps, Explorer
    # shell:startup). The Run value written up to 0.7.9 is only reported; install.ps1 and uninstall.ps1 remove it.
    $autostart = [bool]($link -and (Test-Path -LiteralPath $link))
    $oldRun = [bool](Get-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue)

    # the installed program was built from another source than this plugin copy has (installs before 0.5.0 have no
    # hash file). Only a newer plugin is a reason to install again: an older copy of the plugin on this computer (for
    # example in another Claude app that has not updated yet) must not put its older program back.
    $outdated = $false; $srcHash = ''; $built = ''; $ahead = $null
    if ($legacy) {
        # the old program counts as an update to install; its hash makes the update notice remembered per program
        $built = if (Test-Path -LiteralPath $oldHashFile) { [IO.File]::ReadAllText($oldHashFile).Trim() } else { '' }
    } elseif ($installed -and (Test-Path -LiteralPath $src)) {
        $srcHash = Get-SourceHash @($src, (Join-Path $here 'build.ps1'), (Join-Path $here 'uninstall.ps1'))   # the program, how it is built and removed
        $built = if (Test-Path -LiteralPath $hashFile) { [IO.File]::ReadAllText($hashFile).Trim() } else { '' }
        if ($built -ne $srcHash) {
            $mine = ''; $theirs = ''
            try { $mine = [string](Get-Content -Raw -LiteralPath (Join-Path $here '..\.claude-plugin\plugin.json') | ConvertFrom-Json).version } catch { }
            if (Test-Path -LiteralPath $versionFile) { $theirs = [IO.File]::ReadAllText($versionFile).Trim() }
            $a = $null; $b = $null
            if ([version]::TryParse($mine, [ref]$a) -and [version]::TryParse($theirs, [ref]$b) -and $b -gt $a) { $ahead = "$b, this plugin copy is $a" }
            else { $outdated = $true }
        }
    }

    if ($legacy) {
        $state = 'update-available'
        $todo = "The helper program was installed by an earlier plugin version in $oldDir. Since 0.8.0 the program and the drawings are in one folder, $root, and the helper starts with Windows by a shortcut in the Startup folder; with the Claude app from the Microsoft Store the earlier version did not start after a restart and kept the drawings in that app's own storage. Run /simple-drawing-pad:install (it moves the program and your drawings to $root)."
    } elseif (-not $installed) {
        $state = 'not-installed'
        $todo = "The drawing window's helper program is not installed on this computer, so $hk does nothing. Run /simple-drawing-pad:install once on each Windows computer."
    } elseif ($helpers.Count -eq 0) {
        $state = 'not-running'
        $todo = "The helper program is installed but not running, so $hk does nothing. Run /simple-drawing-pad:install to start it again."
    } elseif ($shortcut -eq 'taken') {
        $state = 'shortcut-taken'
        $todo = "$hk is taken by another program, so it does not open the drawing window. Right-click the Simple Drawing Pad icon in the notification area and choose ""Change shortcut""."
    } elseif ($outdated) {
        $state = 'update-available'
        $todo = "This plugin version comes with an updated helper program. Run /simple-drawing-pad:install to update it."
    } else {
        $state = 'ready'
        $todo = "Press $hk to draw. Enter copies the drawing to the clipboard, Ctrl+V pastes it."
    }

    # the notice shown last on this computer. The uninstall marker (also written by 0.5.0) means "already asked";
    # every install deletes them, in the old folder too. A notice shown by a plugin up to 0.7.9 still counts while
    # the program is not yet in $root, so the move to the new folder does not ask again; once it is there the old
    # markers are stale and ignored (an install run outside the Store app's sandbox cannot delete the copies that
    # sandbox keeps to itself, and an old uninstall marker must not silence a later problem). An update notice is
    # remembered per installed program, so two plugin copies in different Claude apps do not show it again to each other.
    $shown = ''
    $markers = if ($installed) { @($noticeFile) } else { $noticeFile, $oldNoticeFile }
    foreach ($f in $markers) { if (-not $shown -and (Test-Path -LiteralPath $f)) { $shown = [IO.File]::ReadAllText($f).Trim() } }
    if ((Test-Path -LiteralPath $legacyOff) -or (-not $installed -and (Test-Path -LiteralPath $oldLegacyOff))) { $shown = 'not-installed' }
    $updateNotice = "update-available $built".Trim()   # trimmed like $shown: an install before 0.5.0 has no hash
    $notice = if ($state -eq 'update-available') { $updateNotice } else { $state }
    if ($state -eq 'not-running' -and $shown -eq 'not-installed') { $notice = 'not-installed' }   # removed on purpose

    if ($SessionStart) {
        if ($state -eq 'ready') {
            # all well: a later problem gets its one notice again (an update notice shown by a newer plugin copy for
            # this same program stays remembered)
            if ((Test-Path -LiteralPath $noticeFile) -and $shown -ne $updateNotice) { Remove-Item -LiteralPath $noticeFile }
            exit 0
        }
        $tell = $null
        if ($notice -ne $shown) {
            $tell = switch ($state) {
                'not-installed' {
                    "Simple Drawing Pad - a one-time question on this computer.`n" +
                    "This plugin works together with a small helper program on this computer: a pencil icon by the clock (under ^ if Windows hides it) that opens a drawing window when you press $hk. Enter copies the drawing; Ctrl+V pastes it into the chat or any other app.`n" +
                    "The helper works only locally: it does not use the network, sends nothing and collects nothing. It is built from the source code included in the plugin (nothing is downloaded, no administrator rights), starts with Windows (a shortcut in your Startup folder) and keeps only your last 10 drawings, on this computer, in $drawings. You can remove it with /simple-drawing-pad:uninstall (also in Windows Settings > Apps, when Windows shows it there).`n" +
                    "To install it, run /simple-drawing-pad:install, or just answer ""yes"" and Claude runs it for you. This question is not shown again on this computer."
                }
                'not-running' { "Simple Drawing Pad: the helper program is installed but not running, so $hk does nothing. /simple-drawing-pad:install starts it again. (Shown once.)" }
                'shortcut-taken' { "Simple Drawing Pad: $hk is taken by another program, so it does not open the drawing window. Right-click the Simple Drawing Pad pencil icon by the clock (under ^ if hidden) and choose ""Change shortcut"". (Shown once.)" }
                'update-available' {
                    if ($legacy) { "Simple Drawing Pad: this update keeps the helper program and your drawings in one folder, $root, and starts the helper with Windows by a shortcut in your Startup folder. With the Claude app from the Microsoft Store the previous version did not start after a restart, and its drawings were in that app's own storage. /simple-drawing-pad:install moves everything there in a few seconds, your drawings included. (Shown once.)" }
                    else { "Simple Drawing Pad: this plugin version comes with an updated helper program. /simple-drawing-pad:install updates it in a few seconds. (Shown once.)" }
                }
            }
            try { [IO.Directory]::CreateDirectory($root) | Out-Null; [IO.File]::WriteAllText($noticeFile, $notice) } catch { }
        }
        $context = if ($state -eq 'not-installed' -and $tell) {
            'Simple Drawing Pad plugin: the helper program for the pen window is NOT installed on this Windows computer (the plugin comes with the Claude account; the helper is installed separately on each computer). ' +
            'The user has just been shown a one-time question, in the session-start message, whether to install it; it is not shown again. ' +
            "If the user agrees (for example answers yes, in any language) or asks for it, run the /simple-drawing-pad:install command for them: it is the plugin's only installation path, and it installs, checks and tells the user whether it works. " +
            'If their first message is about something else, end your reply with one short sentence offering the installation; if they decline or ignore it, do not bring it up again. ' +
            "Facts you may repeat: the helper works only locally (no network, sends and collects nothing), is built from the included source (nothing downloaded, no administrator rights), starts with Windows (a shortcut in the Startup folder), keeps only the last 10 drawings in $drawings (one folder under the user profile, the same for every program on this computer), and can be removed with /simple-drawing-pad:uninstall (also in Windows Settings > Apps, when Windows shows it there)."
        } elseif ($tell) {
            "Simple Drawing Pad plugin, pen window status on this Windows computer: $state. $todo The user has just been shown this once. If they want to draw or ask about it, offer the fix; ask before installing."
        } else {
            "Simple Drawing Pad plugin, pen window status on this Windows computer: $state. $todo The user was already told once; do not bring it up yourself. If the user wants to draw or asks why the shortcut does nothing, offer the fix; ask before installing."
        }
        $out = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $context } }
        if ($tell) { $out.systemMessage = $tell }
        ConvertTo-AsciiJson $out
        exit 0
    }

    # what Windows shows in Settings > Apps: the real registry, read through WMI (2147483649 = HKEY_CURRENT_USER). Inside
    # the Store version of the Claude app this process sees its own copy of HKCU, where the entry can exist although
    # Windows never shows it. Not readable that way (or no WMI) counts as not listed.
    $listed = $false
    try {
        $r = Invoke-CimMethod -Namespace root/default -ClassName StdRegProv -MethodName GetStringValue -Arguments @{ hDefKey = [uint32]2147483649; sSubKeyName = $entry; sValueName = 'DisplayName' }
        $listed = [bool]($r -and $r.ReturnValue -eq 0 -and $r.sValue)
    } catch { }
    # the Store version of the Claude app (an MSIX package) is recognized by its path, by walking up the parent processes
    # of this one; at most 12 levels, and any error means "not found"
    $storeApp = $false
    try {
        $id = [int]$PID
        for ($i = 0; $i -lt 12 -and $id -gt 0; $i++) {
            $p = Get-CimInstance Win32_Process -Filter "ProcessId=$id"
            if (-not $p) { break }
            if ("$($p.ExecutablePath)".StartsWith('C:\Program Files\WindowsApps\Claude_', [StringComparison]::OrdinalIgnoreCase)) { $storeApp = $true; break }
            if ([int]$p.ParentProcessId -eq $id) { break }
            $id = [int]$p.ParentProcessId
        }
    } catch { }

    'Simple Drawing Pad on this computer'
    'Program:   ' + $(if ($installed) { "installed ($exe)" } elseif ($legacy) { "installed by an earlier plugin version ($oldExe); not yet moved to $dir" } else { 'not installed' })
    'Helper:    ' + $(switch ($helpers.Count) { 0 { 'not running' } 1 { "running (process $($helpers[0].ProcessId))" }
                          default { "$_ running (processes $(($helpers | ForEach-Object { $_.ProcessId }) -join ', ')); /simple-drawing-pad:install restarts one" } })
    'Shortcut:  ' + $(switch ($shortcut) { 'ok' { "$hk works" } 'taken' { "$hk is taken by another program" } default { "$hk (not reported by the helper)" } })
    'Autostart: ' + $(if ($autostart) { 'on (shortcut in the Startup folder)' } else { 'off (the helper does not start by itself after a restart)' }) +
                    $(if ($oldRun) { '; legacy registry entry present (removed by /simple-drawing-pad:install)' })
    'Drawings:  ' + $drawings + ' (this computer only, the last 10 are kept)'
    if ($installed -or $legacy) { 'Removal:   /simple-drawing-pad:uninstall ' + $(if ($listed) { '(also listed in Windows Settings > Apps)' } else { '(not listed in Windows Settings > Apps on this computer)' }) }
    if ($storeApp) { 'Claude app: Microsoft Store version (its sandbox keeps registry entries and new AppData folders to itself)' }
    if ($outdated) { 'Update:    this plugin version comes with an updated helper program' }
    elseif ($legacy) { "Update:    this plugin version moves the program and your drawings to $root" }
    if ($ahead) { "Version:   the installed program is newer ($ahead); nothing to do" }
    if ($shown -match '^(not-installed|not-running|shortcut-taken|update-available)( [0-9a-f]{64})?$') { "Notice:    already shown on this computer ($($shown.Split(' ')[0])); not shown again" }
    "Result: ${state}: $todo"
} catch {
    # the SessionStart hook stays silent; a failed check is no reason to bother the user at every session
    if (-not $SessionStart) { "Could not check the pen window: $($_.Exception.Message)" }
}
exit 0
