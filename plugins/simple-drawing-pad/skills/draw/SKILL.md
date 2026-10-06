---
name: draw
description: Let the user sketch an idea by hand (layout, wiring, UI mockup, diagram, handwriting) and look at the drawing. On Windows the plugin uses a small local helper program, installed once per computer with /simple-drawing-pad:install; then Ctrl+Alt+D opens the drawing window (with a graphics tablet, the whole tablet is the drawing area), Enter copies the drawing to the clipboard and the user pastes it with Ctrl+V. Elsewhere an offline browser board is used. Use when the user wants to draw, sketch or show something by hand, or asks why the drawing shortcut does nothing.
---

# Simple Drawing Pad

A quick handwritten note or sketch for Claude (or any app via Ctrl+V), not an archive: it should feel as easy as dictating.

## Pen window (Windows)
The program is in the plugin's `app` folder, i.e. `../../app` relative to this skill's folder (source `SimpleDrawingPad.cs`, built by the C# compiler that ships with Windows, nothing downloaded, no admin rights). It works only on this computer: no network access, it sends and collects nothing.

- **Check first:** the plugin comes with the user's Claude account, but the helper program is installed separately on each Windows computer, so on a new computer the shortcut does nothing yet. Before telling the user to press the shortcut, and whenever they say it does nothing, run this check (it changes nothing) and follow its last line, `Result: <state>: <what to do>`:
  `powershell -NoProfile -ExecutionPolicy Bypass -File "<plugin folder>\app\status.ps1"`
  - `ready`: tell them the shortcut it names.
  - `not-installed`: explain in two or three sentences what would be installed (a small local helper with a tray icon that opens the drawing window, no network, nothing downloaded, no admin rights, starts with Windows, keeps the last 10 drawings, removable with `/simple-drawing-pad:uninstall`) and ask whether to install it; or offer the browser board below.
  - `not-running` or `update-available`: suggest `/simple-drawing-pad:install` (it restarts the helper and updates the program). Before 0.5.1 the program saved drawings elsewhere, so update it before waiting for a drawing.
  - `shortcut-taken`: another program owns the shortcut; tell them to right-click the Simple Drawing Pad icon in the notification area and choose "Change shortcut" ("Zmień skrót" in Polish Windows).
  At the start of a session the plugin's hook runs the same check and tells the user once per computer and problem; it does not repeat itself, and neither should you once the user has declined.
- **Install once per computer:** the user runs `/simple-drawing-pad:install` (and `/simple-drawing-pad:uninstall` to remove it). Install yourself only after the user agreed:
  `powershell -NoProfile -ExecutionPolicy Bypass -File "<plugin folder>\app\install.ps1" -Autostart` (or `-Uninstall` to remove it)
  It builds the program, installs it to `%LOCALAPPDATA%\Programs\simple-drawing-pad` and starts the shortcut helper (tray icon). `-Autostart`, which the install question already told the user about, also starts the helper at every logon (a per-user Run entry in the registry); `-Uninstall` removes the program and autostart and keeps the drawings. Afterwards run the check above and tell the user whether it works.
- **Working from the cloud** (you reach the user's computer through the Claude app instead of running commands on it): ask for a new, empty folder for the installer, such as `C:\Users\<name>\simple-drawing-pad`, not Downloads, copy the plugin's `app` folder there and run its `install.ps1`.
- **Shortcut:** Ctrl+Alt+D by default, changeable from the tray icon menu.
- **Keys:** 1–5 width, 6 black, 7 orange, 8 light blue, 9 red, 0 grey, Space/E eraser, Backspace undo, Delete clear, **Enter = copy to the clipboard** (the user then pastes with Ctrl+V, in the chat or any other app), Esc = cancel. In whole-tablet mode the pen's back end and side buttons erase.
- **Copy:** Enter, and also closing the window (X, Alt+F4), saves a PNG in `%LOCALAPPDATA%\simple-drawing-pad\drawings` and copies it to the clipboard. Esc copies nothing; it keeps the drawing in `...\drawings\cancelled`. An empty sheet is not copied. The folder stays on this computer and keeps the last 10 drawings of each kind. Programs before 0.5.1 saved to `<Pictures>\simple-drawing-pad`, which OneDrive may sync from the user's other computers; those older files may name paths of another computer.
- **Tablets and trackpads:** whole-tablet mode is for regular (opaque) tablets with a Wintab driver. On pen displays and touch laptops the board draws where the pen is; without Wintab it uses the mouse or trackpad.

**Receive it:** every time the board closes, the program writes `%LOCALAPPDATA%\simple-drawing-pad\drawings\status.txt`: line 1 `copied`, `cancelled` or `empty`, line 2 the PNG path (empty for `empty`), line 3 the time. For `copied`, `latest.png` is a copy and line 1 of `latest.txt` is the same PNG path. These files are UTF-8; in PowerShell read them with `Get-Content -Encoding UTF8`. When the user is about to draw, run this in the background, then act on line 1 (look at the PNG only for `copied`). Otherwise the user pastes the drawing into the chat with Ctrl+V.

```powershell
$f = Join-Path $env:LOCALAPPDATA 'simple-drawing-pad\drawings\status.txt'
function Read-Status { if (Test-Path -LiteralPath $f) { Get-Content -LiteralPath $f -Raw -Encoding UTF8 } }
$old = Read-Status; $end = (Get-Date).AddMinutes(30)
do { Start-Sleep -Seconds 2; $now = Read-Status } until ($now -ne $old -or (Get-Date) -gt $end)
if ($now -ne $old) { $now } else { 'timeout' }
```

## Browser board (any system)
Open `assets/simple-drawing-pad.html` as a `file:///` URL, in a built-in browser pane if there is one (then take a screenshot when the user is done), otherwise in the default browser (ask for the PNG it saves).

## Rules
- Never draw or undo on a board the user may be drawing on.
- Say briefly what you see and confirm anything unclear before building from a drawing.
- Never upload a drawing unless asked. Ask before installing, enabling autostart or uninstalling.
