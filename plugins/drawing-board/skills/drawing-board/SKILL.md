---
name: drawing-board
description: Let the user sketch an idea by hand (layout, wiring, UI mockup, diagram, handwriting) with a graphics tablet, mouse or touch screen, then look at the drawing. On Windows a pen window opens with a keyboard shortcut (with a regular tablet the whole tablet draws on the sheet); elsewhere an offline browser board is used. Use when the user wants to draw, sketch or show something by hand.
---

# drawing-board

## Pen window (Windows)
The program is in the plugin's `app` folder, i.e. `../../app` relative to this skill's folder (source `DrawingBoard.cs`, built by the C# compiler that ships with Windows, nothing downloaded, no admin rights).

- **Install once, only after asking the user:**
  `powershell -NoProfile -ExecutionPolicy Bypass -File "<plugin folder>\app\install.ps1" [-Autostart] [-Uninstall]`
  It builds the program, installs it to `%LOCALAPPDATA%\Programs\drawing-board` and starts the shortcut helper (tray icon). `-Autostart` also starts the helper at every logon (a per-user Run entry in the registry); `-Uninstall` removes the program and autostart and keeps the drawings.
- **Shortcut:** Ctrl+Alt+D by default, changeable from the tray icon menu.
- **Keys:** 1–5 width, 6 black, 7 orange, 8 light blue, 9 red, 0 grey, Space/E eraser, Backspace undo, Delete clear, **Enter = send**, Esc = cancel. In whole-tablet mode the pen's back end and side buttons erase.
- **Send:** Enter, and also closing the window (X, Alt+F4), saves a PNG in `<Pictures>\drawing-board` and copies it to the clipboard. Esc does not send; it keeps a copy in `<Pictures>\drawing-board\cancelled`. An empty sheet sends nothing.
- **Tablets:** whole-tablet mode is for regular (opaque) tablets with a Wintab driver. On pen displays and touch laptops the board draws where the pen is; without Wintab it uses the mouse.

**Receive it:** every time the board closes, the program writes `<Pictures>\drawing-board\status.txt`: line 1 `sent`, `cancelled` or `empty`, line 2 the PNG path (empty for `empty`), line 3 the time. For `sent`, `latest.png` is a copy and line 1 of `latest.txt` is the same PNG path. These files are UTF-8; in PowerShell read them with `Get-Content -Encoding UTF8`. When the user is about to draw, run this in the background, then act on line 1 (look at the PNG only for `sent`). Otherwise the user pastes the drawing into the chat with Ctrl+V.

```powershell
$p = [Environment]::GetFolderPath('MyPictures', 'Create'); if (-not $p) { $p = Join-Path $env:USERPROFILE 'Pictures' }
$f = Join-Path $p 'drawing-board\status.txt'
function Read-Status { if (Test-Path -LiteralPath $f) { Get-Content -LiteralPath $f -Raw -Encoding UTF8 } }
$old = Read-Status; $end = (Get-Date).AddMinutes(30)
do { Start-Sleep -Seconds 2; $now = Read-Status } until ($now -ne $old -or (Get-Date) -gt $end)
if ($now -ne $old) { $now } else { 'timeout' }
```

## Browser board (any system)
Open `assets/drawing-board.html` as a `file:///` URL, in a built-in browser pane if there is one (then take a screenshot when the user is done), otherwise in the default browser (ask for the PNG it saves).

## Rules
- Never draw or undo on a board the user may be drawing on.
- Say briefly what you see and confirm anything unclear before building from a drawing.
- Never upload a drawing unless asked. Ask before installing, enabling autostart or uninstalling.
