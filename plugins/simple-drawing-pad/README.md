# Simple Drawing Pad

**Like dictation, but drawn - a quick sketch takes your idea to Claude or any app.**

Ctrl+Alt+D = draw\
Enter = copy\
Ctrl+V = paste

Simple as that. A small helper is built on your PC from the included source (nothing downloaded, no admin rights).

Local only, no network, collects nothing. Starts with Windows. It asks once per computer before installing, and a short local check at each session start tells Claude if it works.

Remove it in Windows Settings > Apps

For Windows PCs only.

- **Pen window (Windows).** A keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws on the sheet, with pressure, while the window is active. On pen displays and touch laptops it draws where the pen is; with no tablet it uses the mouse or trackpad. Enter copies the drawing to the clipboard and closes the window, so you can paste it into Claude, an email or any other app with Ctrl+V. In Claude Code, Claude can also pick it up by itself.
- **Browser board (any system).** `skills/draw/assets/simple-drawing-pad.html` is one offline page with pen pressure, eraser, line widths, grid, undo, full screen and PNG export.

The plugin is code and text, plus one picture: the pencil icon for its directory listing, which no code reads.

## What runs on your computer

On Windows the pen window is a **small helper program on your computer**: a pencil icon by the clock (Windows may hide it under ^) that opens the drawing window when you press the shortcut. The plugin comes with your Claude account; the helper is installed once on each computer, and only when you agree.

- **The pencil icon is Simple Drawing Pad.** The program draws this icon itself, and the same pencil marks it by the clock, in Task Manager and in Windows Settings > Apps, so you can always tell what is running. Right-click it for Draw, Change shortcut and Exit.
- **Only local.** The helper does not use the network: it sends nothing and collects nothing. It is a local module the plugin and Claude use on this computer. It does not watch your keyboard either: Windows tells it only when its own shortcut is pressed, and keys reach it only while its drawing window is active.
- **Built from the included source** (`app/SimpleDrawingPad.cs`) by the C# compiler that is part of Windows. Nothing is downloaded, no administrator rights.
- **Starts with Windows** (a per-user autostart entry), so the shortcut works after a restart.
- **Keeps only your last 10 drawings, on this computer**, in `%LOCALAPPDATA%\simple-drawing-pad\drawings`, never in a synced folder. A drawing is a quick note, not an archive; the clipboard holds the one you paste. (Windows' own clipboard history and its sync, if you turned them on, are Windows features.)
- **Remove it in Windows Settings > Apps** (listed as Simple Drawing Pad, for your user only) **or with `/simple-drawing-pad:uninstall`**; your drawings and the shortcut setting are kept. The Settings entry works even if you removed the plugin from Claude first.
- **A short check at each session start.** At the start of each new Claude Code session on Windows, the plugin runs `app/status.ps1` without asking: it looks for its helper and autostart entry, writes only `notice.txt` (which notice it already showed), and tells Claude the result. A plugin update can change this script; the helper program itself changes only when you run `/simple-drawing-pad:install`.

## Install

1. Add the plugin: from the Claude directory, or in Claude Code with `/plugin marketplace add szymjs/simple-drawing-pad` and `/plugin install simple-drawing-pad@simple-drawing-pad`. Start a new session.
2. **On Windows, the first session asks you once** whether to install the helper on this computer, and explains what it is (as above). There is one way to install it: **`/simple-drawing-pad:install`**. Run it, or just answer "yes" and Claude runs it for you (approve the one installer command). It installs the helper, checks that it works and tells you. The question is not shown again on that computer; you can install later with the same command. Each Windows computer needs this step once, because the program lives on the computer.
3. Press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**. The skill is `/simple-drawing-pad:draw`, or just ask Claude to let you draw.

Later, if something stops working (helper not running, shortcut taken by another program, a newer helper in a plugin update), the plugin says so once at the start of a session, with what to do.

## If Ctrl+Alt+D does nothing

Ask Claude why: it runs the plugin's check, `app\status.ps1`, whose last line says what to do.

- **not-installed / not-running / update-available:** run `/simple-drawing-pad:install` (again).
- **shortcut-taken:** another program uses the shortcut. Right-click the Simple Drawing Pad icon in the notification area and choose "Change shortcut".

## Requirements

- Windows 10 or 11 with the .NET Framework 4 C# compiler (`csc.exe`) that is part of Windows. Nothing is downloaded.
- For whole-tablet mode: a regular (opaque) tablet with a Wintab driver, such as the Wacom driver. Without one the window works with the mouse, trackpad or pen pointer.
- The browser board works in any modern browser on any system.
- **Tested so far** with a Wacom graphics tablet on Windows 10, and on Windows 11 with a laptop trackpad (install, helper, shortcut, the check and the session-start notice too). Other tablets, pen displays and touch screens are not tested yet.

## Keys (pen window)

| Key | Action |
|---|---|
| 1–5 | line width |
| 6 / 7 / 8 / 9 / 0 | black / orange / light blue / red / grey |
| Space or E | eraser (in whole-tablet mode the pen's back end and side buttons erase too) |
| Backspace | undo |
| Delete | clear the sheet |
| Enter | copy the drawing to the clipboard, then paste it with **Ctrl+V** (closing the window with X or Alt+F4, or Exit in the tray menu, does the same) |
| Esc | cancel: nothing goes to the clipboard; the drawing is kept in the `cancelled` folder |

An empty sheet is never copied. While the window is active in tablet mode the pointer stays inside the sheet; switch away (Alt+Tab) to release it. Change the shortcut from the tray icon menu ("Change shortcut…").

## What it runs and stores

- `/simple-drawing-pad:install` and `/simple-drawing-pad:uninstall` only ask Claude to run `install.ps1 -Autostart` or `install.ps1 -Uninstall` (which runs `uninstall.ps1`); Claude Code asks you to approve the command first.
- `install.ps1` builds `SimpleDrawingPad.exe` from the included source (`app/SimpleDrawingPad.cs`) with the Windows C# compiler `csc.exe` into `app\bin\` inside the plugin folder (the build script also draws the pencil icon, the same drawing as the tray icon, into the program file, so Windows shows it in Settings > Apps and Task Manager), copies it to `%LOCALAPPDATA%\Programs\simple-drawing-pad` and starts it in the notification area. It stops a running Simple Drawing Pad helper first; if the build fails, it starts the installed one again.
- With `-Autostart` it adds a per-user autostart value `simple-drawing-pad` under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` that starts `SimpleDrawingPad.exe --tray` at logon.
- It lists the program in Windows Settings > Apps with a per-user entry `simple-drawing-pad` under `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall` (name, version, icon, folder, size). Its Uninstall button runs the copy of `uninstall.ps1` next to the program: the same steps as `/simple-drawing-pad:uninstall`, so it also works after the plugin is removed from Claude, and a small message window tells you the result.
- Next to the program, `install.ps1` writes `source.sha256` (a hash of the program's source and its build and uninstall scripts) and `version.txt` (the plugin version), so the check can tell when a plugin update brings a newer program, and an older copy of the plugin never asks to put its older program back.
- Drawings and the plugin's state are kept on this computer only, in `%LOCALAPPDATA%\simple-drawing-pad` (Local AppData never roams or syncs):
  - `drawings\`: each copied drawing as a time-stamped PNG, with `latest.png`, `latest.txt` (path of the newest drawing) and `status.txt` (result of the last session: copied, cancelled or empty); cancelled drawings in `drawings\cancelled`. The last 10 of each are kept; older ones are deleted when you save a new one.
  - `helper.txt`: written by the helper each time it registers its shortcut (whether it could, which shortcut, its process id, the time), deleted when you exit it from the tray menu. A helper stopped another way leaves it behind; the check then ignores it.
  - `notice.txt`: which session-start notice was already shown, so each one appears only once.
  - `no-reminder.txt`: written when the helper is removed; it tells a 0.5.0 copy of the plugin, which may still be in another Claude app, not to remind you. The next install deletes it.
- `app/status.ps1` reads whether the program is installed, whether its helper is running, `helper.txt`, the autostart value, the Settings entry, `source.sha256` and `version.txt`; on its own it changes nothing.
- **Session start (hook):** at the start of each new Claude Code session, `hooks/hooks.json` runs `powershell ... status.ps1 -SessionStart`. On Windows it prints nothing when all is well. Otherwise it shows you a notice once per computer and problem (the first one is the one-time question whether to install the helper) and remembers that in `notice.txt`, and it tells Claude the state so Claude can help when you ask (it asks before installing anything). On macOS and Linux there is no `powershell` command, so it does nothing.
- The keyboard shortcut is kept in `%APPDATA%\simple-drawing-pad\shortcut.txt` (the installer carries the setting file of versions up to 0.7.3 over to this name).
- Each copied drawing is put on the clipboard, and a Windows notification says so ("paste it with Ctrl+V"). If another program keeps the clipboard busy, the drawing is only saved, and the notification says that instead.
- The program does not use the network and sends nothing anywhere. Claude sees a drawing only when you paste it or when Claude opens it from `%LOCALAPPDATA%\simple-drawing-pad\drawings`.
- To pick up a drawing by itself in Claude Code, Claude runs a small PowerShell loop in the background that checks `drawings\status.txt` every 2 seconds, for up to 30 minutes, and then opens the new PNG. It only reads that folder.
- The browser board saves its PNG through the browser's normal download.
- `-Uninstall` (and the Uninstall button in Settings) stops the helper and removes the installed program, `uninstall.ps1`, `source.sha256`, `version.txt`, `helper.txt`, the autostart entry and the Settings entry, and writes `notice.txt` and `no-reminder.txt` so the plugin does not ask about the helper again on this computer (the next install deletes them). Your drawings and the shortcut setting are kept, and so is the build output in the plugin's `app\bin\` folder.
- Before 0.5.1 drawings were saved in `Pictures\simple-drawing-pad`, which OneDrive may sync between computers; they stay there untouched.
- Previous name: versions up to 0.3.0 were called drawing-board. If that version's helper is running from `%LOCALAPPDATA%\Programs\drawing-board\DrawingBoard.exe`, `install.ps1` (also with `-Uninstall`) stops it, and it removes that version's autostart value `drawing-board` when the value starts exactly that file. Its files, drawings and shortcut setting are left in place.

## Feedback

Questions, ideas or problems: [open an issue](https://github.com/szymjs/simple-drawing-pad/issues/new/choose) on GitHub (a free GitHub account is needed). For a problem, the form asks for your Windows version, the plugin version and the last lines of the plugin's check; Claude can run the check for you. Tested with another tablet, pen display or touch screen? That helps too.

Please do not attach drawings, screenshots or paths that show private information.

## License

MIT, see [LICENSE](LICENSE).
