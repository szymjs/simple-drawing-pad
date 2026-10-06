# Says whether the Simple Drawing Pad pen window works on this computer.
#   .\status.ps1                 a short report that changes nothing; the last line is "Result: <state>: <what to do>",
#                                where <state> is ready, not-installed, not-running, shortcut-taken or update-available
#   .\status.ps1 -SessionStart   for the plugin's SessionStart hook (hooks\hooks.json). When something is wrong it shows
#                                the user one notice, once per computer and problem, and always tells Claude the state
#                                (one JSON line); nothing when the pen window is ready. To show each notice only once
#                                it writes %LOCALAPPDATA%\simple-drawing-pad\notice.txt (this computer only).
# The plugin comes with the user's Claude account; the program is installed separately on each Windows computer.
# This file is UTF-8 with a BOM (Windows PowerShell 5.1 needs it for the Polish texts).
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

# the user's notice in Polish when Windows' display language is Polish (as the drawing window does), else English
$pl = [Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq 'pl'
function L([string]$en, [string]$plText) { if ($pl) { $plText } else { $en } }

# a shortcut name read from a file reaches the user and Claude only if it looks like one (Ctrl+Alt+D, Ctrl+Shift+F12)
function Test-Shortcut([string]$s) { $s.Length -le 40 -and $s -match '^((ctrl|control|alt|shift)\s*\+\s*){1,3}[a-z0-9]{1,20}$' }

# JSON with every non-ASCII character escaped, so the hook's output survives any console code page
function ConvertTo-AsciiJson($value) {
    [regex]::Replace(($value | ConvertTo-Json -Compress -Depth 4), '[^\x00-\x7F]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
}

try {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    $dir = Join-Path $env:LOCALAPPDATA 'Programs\simple-drawing-pad'
    $exe = Join-Path $dir 'SimpleDrawingPad.exe'
    $bin = Join-Path $here 'bin\SimpleDrawingPad.exe'
    $src = Join-Path $here 'SimpleDrawingPad.cs'
    $hashFile = Join-Path $dir 'source.sha256'                                      # written by install.ps1
    $versionFile = Join-Path $dir 'version.txt'                                     # written by install.ps1 (0.5.1+)
    $data = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad'
    $stateFile = Join-Path $data 'helper.txt'                                       # written by the helper
    $noticeFile = Join-Path $data 'notice.txt'                                      # the notice already shown here
    $legacyOff = Join-Path $data 'no-reminder.txt'                                  # 0.5.0 -Uninstall: no notice
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
    if (Test-Path -LiteralPath $hkFile) { $t = [IO.File]::ReadAllText($hkFile).Trim(); if (Test-Shortcut $t) { $hk = $t } }
    # helper.txt: ok | taken, shortcut, process id, time. Trusted only from the one running helper: a helper older
    # than 0.5.0 does not write it, and a helper that has ended leaves its last report behind.
    $shortcut = 'unknown'
    if ($helpers.Count -eq 1 -and (Test-Path -LiteralPath $stateFile)) {
        $l = @([IO.File]::ReadAllLines($stateFile))
        if ($l.Count -ge 3 -and $l[2].Trim() -eq [string]$helpers[0].ProcessId -and $l[0].Trim() -in 'ok', 'taken') {
            $shortcut = $l[0].Trim(); if (Test-Shortcut $l[1].Trim()) { $hk = $l[1].Trim() }
        }
    }

    $autostart = $false
    $v = Get-ItemProperty -LiteralPath $run -Name 'simple-drawing-pad' -ErrorAction SilentlyContinue
    if ($v) {
        $cmd = ([string]$v.'simple-drawing-pad').Trim()
        $path = if ($cmd.StartsWith('"')) { $cmd.Substring(1).Split('"')[0] } else { $cmd.Split(' ')[0] }
        $autostart = $path -eq $exe
    }

    # the installed program was built from another source than this plugin copy has (installs before 0.5.0 have no
    # hash file). Only a newer plugin is a reason to install again: an older copy of the plugin on this computer (for
    # example in another Claude app that has not updated yet) must not put its older program back.
    $outdated = $false; $srcHash = ''; $built = ''; $ahead = $null
    if ($installed -and (Test-Path -LiteralPath $src)) {
        $srcHash = Get-SourceHash $src
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

    if (-not $installed) {
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
    # every install deletes it. An update notice is remembered per installed program, so two plugin copies in
    # different Claude apps do not show it again to each other.
    $shown = if (Test-Path -LiteralPath $noticeFile) { [IO.File]::ReadAllText($noticeFile).Trim() } else { '' }
    if (Test-Path -LiteralPath $legacyOff) { $shown = 'not-installed' }
    $updateKey = "update-available $built".Trim()   # trimmed like $shown: an install before 0.5.0 has no hash
    $key = if ($state -eq 'update-available') { $updateKey } else { $state }
    if ($state -eq 'not-running' -and $shown -eq 'not-installed') { $key = 'not-installed' }   # removed on purpose

    if ($SessionStart) {
        if ($state -eq 'ready') {
            # all well: a later problem gets its one notice again (an update notice shown by a newer plugin copy for
            # this same program stays remembered)
            if ((Test-Path -LiteralPath $noticeFile) -and $shown -ne $updateKey) { Remove-Item -LiteralPath $noticeFile }
            exit 0
        }
        $tell = $null
        if ($key -ne $shown) {
            $tell = switch ($state) {
                'not-installed' {
                    (L "Simple Drawing Pad - a one-time question on this computer.`n" "Simple Drawing Pad – jednorazowe pytanie na tym komputerze.`n") +
                    (L "This plugin works together with a small helper program on this computer: a pencil icon by the clock (under ^ if Windows hides it) that opens a drawing window when you press $hk. Enter copies the drawing; Ctrl+V pastes it into the chat or any other app.`n" `
                       "Ta wtyczka działa razem z małym programem na tym komputerze: ikoną ołówka przy zegarze (pod ^, jeśli Windows ją ukryje), która po naciśnięciu $hk otwiera okno do rysowania. Enter kopiuje rysunek, Ctrl+V wkleja go w czacie albo w dowolnym innym programie.`n") +
                    (L "The helper works only locally: it does not use the network, sends nothing and collects nothing. It is built from the source code included in the plugin (nothing is downloaded, no administrator rights), starts with Windows and keeps only your last 10 drawings, on this computer, in %LOCALAPPDATA%\simple-drawing-pad. /simple-drawing-pad:uninstall removes it.`n" `
                       "Program działa wyłącznie lokalnie: nie korzysta z sieci, niczego nie wysyła i niczego nie zbiera. Powstaje z kodu dołączonego do wtyczki (nic nie jest pobierane, bez uprawnień administratora), uruchamia się razem z Windows i przechowuje tylko 10 ostatnich rysunków, na tym komputerze, w %LOCALAPPDATA%\simple-drawing-pad. /simple-drawing-pad:uninstall go usuwa.`n") +
                    (L "To install it, run /simple-drawing-pad:install, or just answer ""yes"" and Claude runs it for you. This question is not shown again on this computer." `
                       "Aby go zainstalować, wpisz /simple-drawing-pad:install albo po prostu odpowiedz `„tak`”, a Claude uruchomi to polecenie za ciebie. To pytanie nie pojawi się ponownie na tym komputerze.")   # `„ `”: PowerShell would end the string at „ or ”
                }
                'not-running' { L "Simple Drawing Pad: the helper program is installed but not running, so $hk does nothing. /simple-drawing-pad:install starts it again. (Shown once.)" `
                                  "Simple Drawing Pad: program jest zainstalowany, ale nie działa w tle, więc $hk nic nie robi. /simple-drawing-pad:install uruchomi go ponownie. (Ten komunikat pojawia się raz.)" }
                'shortcut-taken' { L "Simple Drawing Pad: $hk is taken by another program, so it does not open the drawing window. Right-click the Simple Drawing Pad pencil icon by the clock (under ^ if hidden) and choose ""Change shortcut"". (Shown once.)" `
                                     "Simple Drawing Pad: skrót $hk jest zajęty przez inny program, więc nie otwiera okna do rysowania. Kliknij prawym przyciskiem ikonę ołówka Simple Drawing Pad przy zegarze (pod ^, jeśli ukryta) i wybierz `„Zmień skrót`”. (Ten komunikat pojawia się raz.)" }
                'update-available' { L "Simple Drawing Pad: this plugin version comes with an updated helper program. /simple-drawing-pad:install updates it in a few seconds. (Shown once.)" `
                                       "Simple Drawing Pad: ta wersja wtyczki ma zaktualizowany program. /simple-drawing-pad:install zaktualizuje go w kilka sekund. (Ten komunikat pojawia się raz.)" }
            }
            try { New-Item -ItemType Directory -Force $data | Out-Null; [IO.File]::WriteAllText($noticeFile, $key) } catch { }
        }
        $context = if ($state -eq 'not-installed' -and $tell) {
            'Simple Drawing Pad plugin: the helper program for the pen window is NOT installed on this Windows computer (the plugin comes with the Claude account; the helper is installed separately on each computer). ' +
            'The user has just been shown a one-time question, in the session-start message, whether to install it; it is not shown again. ' +
            "If the user agrees (for example answers yes or tak) or asks for it, run the /simple-drawing-pad:install command for them: it is the plugin's only installation path, and it installs, checks and tells the user whether it works. " +
            'If their first message is about something else, end your reply with one short sentence offering the installation; if they decline or ignore it, do not bring it up again. ' +
            "Facts you may repeat: the helper works only locally (no network, sends and collects nothing), is built from the included source (nothing downloaded, no administrator rights), starts with Windows, keeps only the last 10 drawings in %LOCALAPPDATA%\simple-drawing-pad, and /simple-drawing-pad:uninstall removes it."
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

    'Simple Drawing Pad on this computer'
    'Program:   ' + $(if ($installed) { "installed ($exe)" } else { 'not installed' })
    'Helper:    ' + $(switch ($helpers.Count) { 0 { 'not running' } 1 { "running (process $($helpers[0].ProcessId))" }
                          default { "$_ running (processes $(($helpers | ForEach-Object { $_.ProcessId }) -join ', ')); /simple-drawing-pad:install restarts one" } })
    'Shortcut:  ' + $(switch ($shortcut) { 'ok' { "$hk works" } 'taken' { "$hk is taken by another program" } default { "$hk (not reported by the helper)" } })
    'Autostart: ' + $(if ($autostart) { 'on' } else { 'off (the helper does not start by itself after a restart)' })
    'Drawings:  ' + (Join-Path $data 'drawings') + ' (this computer only, the last 10 are kept)'
    if ($outdated) { 'Update:    this plugin version comes with an updated helper program' }
    if ($ahead) { "Version:   the installed program is newer ($ahead); nothing to do" }
    if ($shown -match '^(not-installed|not-running|shortcut-taken|update-available)( [0-9a-f]{64})?$') { "Notice:    already shown on this computer ($($shown.Split(' ')[0])); not shown again" }
    "Result: ${state}: $todo"
} catch {
    # the SessionStart hook stays silent; a failed check is no reason to bother the user at every session
    if (-not $SessionStart) { "Could not check the pen window: $($_.Exception.Message)" }
}
exit 0
