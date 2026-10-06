![it just works!](logo.png)

# Simple Drawing Pad

**Draw your idea, then paste it from the clipboard wherever you need it. It just works. Simple as that.**\
*Simple by design, made for simple use.*

Sketch an idea by hand (a layout, wiring, a UI mockup, a diagram, handwriting) and let Claude look at it.

- **Pen window (Windows).** A keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws on the sheet, with pressure, while the window is active. On pen displays and touch laptops it draws where the pen is; with no tablet it uses the mouse. Enter saves the drawing as a PNG and copies it to the clipboard, so you can paste it into Claude anywhere in Windows with Ctrl+V. In Claude Code, Claude can also pick it up by itself.
- **Browser board (any system).** `skills/draw/assets/simple-drawing-pad.html` is one offline page with pen pressure, eraser, line widths, grid, undo, full screen and PNG export.

## Install

1. Add the plugin: from the Claude directory, or in Claude Code with `/plugin marketplace add szymjs/simple-drawing-pad` and `/plugin install simple-drawing-pad@simple-drawing-pad`. Start a new session.
2. In Claude Code, run **`/simple-drawing-pad:install`** once **on each Windows computer** (approve the one installer command). The plugin comes with your Claude account, but the drawing window is a program on the computer, so a new computer needs this step too; until then Ctrl+Alt+D does nothing. `/simple-drawing-pad:uninstall` removes it again.
3. Press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**. The skill is `/simple-drawing-pad:draw`, or just ask Claude to let you draw.

At the start of each new session the plugin checks the drawing window on this computer and, only if something is wrong, says in one line what to do (not installed, helper not running, shortcut taken by another program, or a newer version to install). Don't want the drawing window on a computer? Run `/simple-drawing-pad:uninstall` there: the reminder then stays off on that computer until you install it again.

Without Claude Code, run this from the root of a clone of [szymjs/simple-drawing-pad](https://github.com/szymjs/simple-drawing-pad):

```
powershell -NoProfile -ExecutionPolicy Bypass -File "plugins\simple-drawing-pad\app\install.ps1"
```

Add `-Autostart` to start the shortcut helper at every logon, or `-Uninstall` to remove it. No admin rights are needed.

## If Ctrl+Alt+D does nothing

Ask Claude why: it runs the plugin's read-only check, `app\status.ps1`, whose last line says what to do. From the root of a clone you can run it yourself:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "plugins\simple-drawing-pad\app\status.ps1"
```

- **not-installed / not-running / update-available:** run `/simple-drawing-pad:install` (again).
- **shortcut-taken:** another program uses the shortcut. Right-click the Simple Drawing Pad icon in the notification area and choose "Change shortcut".

## Requirements

- Windows 10 or 11 with the .NET Framework 4 C# compiler (`csc.exe`) that is part of Windows. Nothing is downloaded.
- For whole-tablet mode: a regular (opaque) tablet with a Wintab driver, such as the Wacom driver. Without one the window works with the mouse or pen pointer.
- The browser board works in any modern browser on any system.
- **Tested so far** with a Wacom graphics tablet on Windows 10. Other tablets, pen displays, touch screens and Windows 11 are not tested yet.

## Keys (pen window)

| Key | Action |
|---|---|
| 1–5 | line width |
| 6 / 7 / 8 / 9 / 0 | black / orange / light blue / red / grey |
| Space or E | eraser (in whole-tablet mode the pen's back end and side buttons erase too) |
| Backspace | undo |
| Delete | clear the sheet |
| Enter | copy the drawing to the clipboard, then paste it with **Ctrl+V** (closing the window with X or Alt+F4 does the same) |
| Esc | cancel: nothing goes to the clipboard; the drawing is kept in the `cancelled` folder |

An empty sheet is never copied. While the window is active in tablet mode the pointer stays inside the sheet; switch away (Alt+Tab) to release it. Change the shortcut from the tray icon menu ("Change shortcut…").

## What it runs and stores

- `/simple-drawing-pad:install` and `/simple-drawing-pad:uninstall` only ask Claude to run `install.ps1 -Autostart` or `install.ps1 -Uninstall`; Claude Code asks you to approve the command first.
- `install.ps1` builds `SimpleDrawingPad.exe` from the included source (`app/SimpleDrawingPad.cs`) with the Windows C# compiler `csc.exe` into `app\bin\` inside the plugin folder, copies it to `%LOCALAPPDATA%\Programs\simple-drawing-pad` and starts it in the notification area. It stops a running Simple Drawing Pad helper first.
- With `-Autostart` it adds a per-user autostart value `simple-drawing-pad` under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` that starts `SimpleDrawingPad.exe --tray` at logon.
- Next to the program, `install.ps1` writes `source.sha256`, a hash of the source it was built from, so the check below can tell when the plugin brings a newer program.
- The shortcut helper writes `%LOCALAPPDATA%\simple-drawing-pad\helper.txt` (whether it could register its shortcut, which shortcut, its process id, the time) each time it registers the shortcut, and deletes it when it exits. It is kept on this computer, not in Pictures, which may be synced to your other computers.
- `app/status.ps1` only reads: whether the program is installed, whether its helper is running, `helper.txt`, the autostart value and `source.sha256`. It changes nothing.
- **Session start (hook):** at the start of each new Claude Code session, `hooks/hooks.json` runs `powershell ... status.ps1 -SessionStart`. On Windows it prints nothing when all is well; otherwise it shows you one line and tells Claude the same, so Claude can offer the fix (it asks before installing anything). It stays silent about a missing or stopped program on a computer where you ran `/simple-drawing-pad:uninstall` (see `no-reminder.txt` below). On macOS and Linux there is no `powershell` command, so it does nothing.
- Each copied drawing is saved as a time-stamped PNG in `Pictures\simple-drawing-pad`, together with `latest.png`, `latest.txt` (path of the newest drawing) and `status.txt` (result of the last session: copied, cancelled or empty). Cancelled drawings go to `Pictures\simple-drawing-pad\cancelled`.
- The keyboard shortcut is kept in `%APPDATA%\simple-drawing-pad\hotkey.txt`.
- Each copied drawing is put on the clipboard, and a Windows notification says so ("paste it with Ctrl+V").
- The program does not use the network and sends nothing anywhere. Claude sees a drawing only when you paste it or when Claude reads it from your Pictures folder.
- To pick up a drawing by itself in Claude Code, Claude runs a small PowerShell loop in the background that checks `Pictures\simple-drawing-pad\status.txt` every 2 seconds, for up to 30 minutes, and then opens the new PNG. It only reads that folder.
- The browser board saves its PNG through the browser's normal download.
- `-Uninstall` stops the helper and removes the installed program, `source.sha256`, `helper.txt` and the autostart entry. It leaves `%LOCALAPPDATA%\simple-drawing-pad\no-reminder.txt`, which keeps the session-start reminder off on this computer; the next install deletes it. Your drawings and the shortcut setting are kept, and so is the build output in the plugin's `app\bin\` folder.
- Previous name: versions up to 0.3.0 were called drawing-board. If that version's helper is running from `%LOCALAPPDATA%\Programs\drawing-board\DrawingBoard.exe`, `install.ps1` (also with `-Uninstall`) stops it, and it removes that version's autostart value `drawing-board` when the value starts exactly that file. Its files, drawings and shortcut setting are left in place.

## License

MIT, see [LICENSE](LICENSE).
