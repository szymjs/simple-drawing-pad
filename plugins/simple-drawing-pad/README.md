# Simple Drawing Pad

**Like dictation, but drawn - a quick sketch takes your idea to Claude or any app.**

Sketch a layout, wiring, a UI mockup, a diagram or a handwritten note, and Claude looks at it.

Ctrl+Alt+D = draw\
Enter = copy\
Ctrl+V = paste\
Shift+Enter = save as

Simple as that. A small helper is built on your PC from the included source (nothing downloaded, no admin rights).

Local only, no network, collects nothing. Starts with Windows (a shortcut in your Startup folder). It asks once per computer before installing, and a short local check at each session start tells Claude if it works.

Remove it with `/simple-drawing-pad:uninstall`

Pen window for Windows PCs; an offline browser board elsewhere; on a phone or in claude.ai, the board or a photo of a paper sketch.

- **Pen window (Windows).** A keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws on the sheet, with pressure, while the window is active. On pen displays and touch laptops it draws where the pen is; with no tablet it uses the mouse or trackpad. Enter copies the drawing to the clipboard and closes the window, so you can paste it into Claude, an email or any other app with Ctrl+V. In Claude Code, Claude can also pick it up by itself.
- **Browser board (any system).** `skills/draw/assets/simple-drawing-pad.html` is one offline page with pen pressure, eraser, line widths, grid, undo, full screen, Copy (the drawing goes to the clipboard, you paste it into the chat) and Save picture.
- **Phone, claude.ai or away from your PC.** Where Claude cannot run commands on your computer (claude.ai, the Claude mobile app, a cloud session) or you are not at it, Claude offers two ways in one message: draw on paper and send a photo, or draw on the board, which Claude publishes for you as an artifact. Nothing is installed for either.

The plugin is code and text, plus one picture: the pencil icon for its directory listing, which no code reads.

## What runs on your computer

On Windows the pen window is a **small helper program on your computer**: a pencil icon by the clock (Windows may hide it under ^) that opens the drawing window when you press the shortcut. The plugin comes with your Claude account; the helper is installed once on each computer, and only when you agree. The program and everything it saves are in one folder, `C:\Users\<you>\simple-drawing-pad`; the Startup shortcut and the entry for Windows Settings > Apps are outside it (both below).

- **The pencil icon is Simple Drawing Pad.** The program draws this icon itself, and the same pencil marks it by the clock and in Task Manager, so you can always tell what is running. Right-click it for Draw, Change shortcut and Exit. There is one helper at a time: a second start while it runs ends quietly, so you never see two pencils.
- **Only local.** The helper does not use the network: it sends nothing and collects nothing. It is a local module the plugin and Claude use on this computer. It does not watch your keyboard either: Windows tells it only when its own shortcut is pressed, and keys reach it only while its drawing window is active.
- **Built from the included source** (`app/SimpleDrawingPad.cs`) by the C# compiler that is part of Windows. Nothing is downloaded, no administrator rights.
- **Starts with Windows** by a shortcut, `Simple Drawing Pad.lnk` in your Startup folder, so the keyboard shortcut works after a restart. Task Manager lists it under Startup apps; Explorer shows it under `shell:startup`, where you can delete it. This works with the Microsoft Store version of the Claude app too: tested on Windows 11, Windows started the helper from the shortcut after a restart, before Claude was opened.
- **Keeps only your last 10 drawings, on this computer**, in `C:\Users\<you>\simple-drawing-pad\drawings`, which OneDrive does not sync. A drawing is a quick note, not an archive; the clipboard holds the one you paste. (Windows' own clipboard history and its sync, if you turned them on, are Windows features.)
- **Remove it with `/simple-drawing-pad:uninstall`**; your drawings and the shortcut setting are kept. Windows Settings > Apps lists it too, as Simple Drawing Pad for your user only, when Windows can see the entry: it can when the helper was installed from `claude` in a terminal or from the Claude app installed from claude.ai, not when it was installed from the Microsoft Store version of the Claude app. Where the entry shows, its Uninstall button does the same as the command, even after the plugin was removed from Claude.
- **Claude from the Microsoft Store.** The Store version of the Claude app runs the plugin's commands in a sandbox. Registry entries and new AppData folders written from inside it belong to the app alone: Windows does not start from them, Windows Settings > Apps does not list them, and Explorer does not show them. That is why 0.8.0 moved everything to `C:\Users\<you>\simple-drawing-pad`, a folder every program on your computer sees, and starts the helper by a shortcut in your Startup folder, which is real from inside the sandbox too. The Claude app from claude.ai (EXE) and `claude` in a terminal have no sandbox; they use the same folder and shortcut.
- **A short check at each session start.** At the start of each new Claude Code session on Windows, the plugin runs `app/status.ps1` without asking: it looks for its helper and the Startup shortcut, writes only `notice.txt` (which notice it already showed; for that it creates the folder `C:\Users\<you>\simple-drawing-pad` when it does not exist yet), and tells Claude the result. A plugin update can change this script; the helper program itself changes only when you run `/simple-drawing-pad:install`.

## Install

1. Add the plugin: from the Claude directory, or in Claude Code with `/plugin marketplace add szymjs/simple-drawing-pad` and `/plugin install simple-drawing-pad@simple-drawing-pad`. Start a new session.
2. **On Windows, the first session asks you once** whether to install the helper on this computer, and explains what it is (as above). There is one way to install it: **`/simple-drawing-pad:install`**. Run it, or just answer "yes" and Claude runs it for you (approve the one installer command). It installs the helper, checks that it works and tells you. The question is not shown again on that computer; you can install later with the same command. Each Windows computer needs this step once, because the program lives on the computer.
3. Press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**. The skill is `/simple-drawing-pad:draw`, or just ask Claude to let you draw.

On macOS and Linux, in claude.ai, in the Claude mobile app and in cloud sessions there is nothing to install: ask Claude to let you draw (see "Phone, claude.ai and other systems" below).

If you prefer typing `/draw`, add a command of your own: commands from a plugin always carry the plugin's name, so the plugin cannot register `/draw` itself. Create `C:\Users\<you>\.claude\commands\draw.md` (on other systems `~/.claude/commands/draw.md`) with:

```markdown
---
description: Simple Drawing Pad (alias for /simple-drawing-pad:draw)
---
Run the skill `simple-drawing-pad:draw`. Arguments: $ARGUMENTS
```

Later, if something stops working (helper not running, shortcut taken by another program, a newer helper in a plugin update), the plugin says so once at the start of a session, with what to do.

## If Ctrl+Alt+D does nothing

Ask Claude why: it runs the plugin's check, `app\status.ps1`, whose last line says what to do.

- **not-installed / not-running / update-available:** run `/simple-drawing-pad:install` (again).
- **shortcut-taken:** another program uses the shortcut. Right-click the Simple Drawing Pad icon in the notification area and choose "Change shortcut".
- **ready, but you are not at the PC** (for example you use Claude Code on it from your phone through Remote Control): the window opens on the PC, not on your phone. Tell Claude you are away; it uses the board or a photo instead.

## Phone, claude.ai and other systems

- **Phone, claude.ai, cloud sessions, Remote Control.** Claude offers two ways: (a) draw on paper and send a photo with the + or paperclip button, the quickest on a phone; (b) the board, published by Claude as an artifact: draw with your finger or mouse, tap **Copy** and paste the drawing into the chat. If Copy is blocked there, take a screenshot (iPhone: side + volume up; Android: power + volume down; Windows: Win+Shift+S) and attach it. Claude cannot see the board itself, so saying "done" is not enough there: paste or attach the drawing.
- **Claude Code on macOS or Linux** (or Windows without the helper). Claude opens the board in its browser pane, or in your default browser. In the pane, say "done" when you finish and Claude takes a screenshot of it. In a browser, click Copy and paste into the chat, or drag the saved `drawing_*.png` from your Downloads folder into the chat.
- **On the board:** press and hold while moving to draw (on a trackpad: click and drag, or double-tap and drag); a thicker pen is easier. With a pen, a resting palm does not draw. Undo is Ctrl+Z, redo Ctrl+Y or Ctrl+Shift+Z (⌘Z and ⇧⌘Z on a Mac). Save picture downloads a PNG of the whole drawing; where the browser blocks downloads, it shows the picture so you can long-press and save it. Before a reload or closing the tab would lose a drawing, the browser asks first.

## Requirements

- Windows 10 or 11 with the .NET Framework 4 C# compiler (`csc.exe`) that is part of Windows. Nothing is downloaded.
- For whole-tablet mode: a regular (opaque) tablet with a Wintab driver, such as the Wacom driver. Without one the window works with the mouse, trackpad or pen pointer.
- The browser board works in any modern browser on any system. Its Copy button needs a browser that lets a page put a picture on the clipboard; where it cannot, the board says so and a screenshot does the same.
- **Tested so far** with a Wacom graphics tablet on Windows 10, and on Windows 11 with a laptop trackpad and the Claude desktop app from the Microsoft Store (install, helper, shortcut, the check, the session-start notice and the start with Windows after a restart too). Other tablets, pen displays and touch screens are not tested yet.

## Keys (pen window)

| Key | Action |
|---|---|
| 1–5 | line width |
| 6 / 7 / 8 / 9 / 0 | black / orange / light blue / red / grey |
| Space or E | eraser (in whole-tablet mode the pen's back end and side buttons erase too) |
| Backspace | undo |
| Delete | clear the sheet |
| Enter | copy the drawing to the clipboard, then paste it with **Ctrl+V** (closing the window with X or Alt+F4, or Exit in the tray menu, does the same) |
| Shift+Enter | the same, after asking where to save an extra copy (Pictures by default); that copy is yours to keep and is not among the last 10. Pictures may be a OneDrive folder, which then syncs the copy; the plugin's own drawings stay out of OneDrive. If the extra copy cannot be written, the drawing is still copied to the clipboard and a message names the path that failed |
| Esc | cancel: nothing goes to the clipboard; the drawing is kept in the `cancelled` folder |

An empty sheet is never copied. While the window is active in tablet mode the pointer stays inside the sheet; switch away (Alt+Tab) to release it. Change the shortcut from the tray icon menu ("Change shortcut…"). If Ctrl+Alt plus the key you choose types a character on your keyboard layout (AltGr, for example `ś` from Ctrl+Alt+S on Polish Programmer), the dialog warns that the shortcut would stop that character from typing in every program and suggests adding Shift or choosing another key; you can still keep it.

## What it runs and stores

The program and everything it saves are in one folder under your user profile, `C:\Users\<you>\simple-drawing-pad` (below: the folder): the program in `app\`, your drawings in `drawings\`, the shortcut setting and the plugin's state files next to them. Outside it are the Startup shortcut, the entry for Windows Settings > Apps in the registry, the build output in the plugin's `app\bin\` and, after a move from 0.5.1 to 0.7.9, the stub in the old program folder, each with its own bullet below. A folder directly under the user profile is the same folder for every program that runs as you, including the Microsoft Store version of the Claude app; Explorer shows it, and OneDrive does not sync it.

- `/simple-drawing-pad:install` and `/simple-drawing-pad:uninstall` only ask Claude to run `install.ps1 -Autostart` or `install.ps1 -Uninstall` (which runs `uninstall.ps1`); Claude Code asks you to approve the command first.
- `install.ps1` builds `SimpleDrawingPad.exe` from the included source (`app/SimpleDrawingPad.cs`) with the Windows C# compiler `csc.exe` into `app\bin\` inside the plugin folder (the build script also draws the pencil icon, the same drawing as the tray icon, into the program file, so Task Manager shows it), copies it to the folder's `app\` and starts it in the notification area. It stops a running Simple Drawing Pad helper first; if the build or a later install step fails, it starts the installed one again.
- Next to the program, in `app\`, `install.ps1` keeps a copy of `uninstall.ps1` and writes `source.sha256` (a hash of the program's source and its build and uninstall scripts) and `version.txt` (the plugin version), so the check can tell when a plugin update brings a newer program, and an older copy of the plugin never asks to put its older program back.
- With `-Autostart` it creates the shortcut `Simple Drawing Pad.lnk` in your Startup folder (`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`, `shell:startup` in Explorer), which starts `app\SimpleDrawingPad.exe --tray` at logon. This is the usual per-user autostart: Task Manager lists it under Startup apps, and you can delete the shortcut in Explorer. It works from the Microsoft Store version of the Claude app too (tested on Windows 11: after a restart Windows started the helper from the shortcut, before Claude was opened).
- The helper runs once per Windows sign-in: at start it takes a named mutex, `Local\SimpleDrawingPad.Tray`, and a second `--tray` start that finds it taken ends at once, without an icon or a message and without writing `helper.txt`.
- It lists the program in Windows Settings > Apps with a per-user entry `simple-drawing-pad` under `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall` (name, version, icon, folder, size). Windows shows the entry when the install ran from `claude` in a terminal or from the Claude app installed from claude.ai; from the Microsoft Store version of the Claude app the entry stays inside that app's sandbox and does not appear. Where it appears, its Uninstall button runs the copy of `uninstall.ps1` in `app\`: the same steps as `/simple-drawing-pad:uninstall`, so it also works after the plugin is removed from Claude, and a small message window tells you the result. Without Claude and without the entry, the same copy does the same when you run it with PowerShell: `powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\<you>\simple-drawing-pad\app\uninstall.ps1"`.
- Drawings and the plugin's state are kept in the folder, on this computer only:
  - `drawings\`: each copied drawing as a time-stamped PNG, with `latest.png`, `latest.txt` (path of the newest drawing) and `status.txt` (result of the last session: copied, cancelled or empty); cancelled drawings in `drawings\cancelled`. The last 10 of each are kept; older ones are deleted when you save a new one.
  - `shortcut.txt`: the keyboard shortcut, once you changed it from the tray menu.
  - `helper.txt`: written by the helper each time it registers its shortcut (whether it could, which shortcut, its process id, the time), deleted when you exit it from the tray menu. A helper stopped another way leaves it behind; the check then ignores it.
  - `notice.txt`: which session-start notice was already shown, so each one appears only once.
  - `no-reminder.txt`: written when the helper is removed; it tells a 0.5.0 copy of the plugin, which may still be in another Claude app, not to remind you. The next install deletes it.
- `app/status.ps1` reads whether the program is installed, whether its helper is running, `helper.txt`, the Startup shortcut, the Settings entry (as Windows sees it, through WMI), `source.sha256` and `version.txt`; on its own it changes nothing.
- **Session start (hook):** at the start of each new Claude Code session, `hooks/hooks.json` runs `powershell ... status.ps1 -SessionStart`. On Windows it prints nothing when all is well. Otherwise it shows you a notice once per computer and problem (the first one is the one-time question whether to install the helper) and remembers that in `notice.txt` (creating the folder `C:\Users\<you>\simple-drawing-pad` for it when it does not exist yet), and it tells Claude the state so Claude can help when you ask (it asks before installing anything). On macOS and Linux there is no `powershell` command, so it does nothing.
- Each copied drawing is put on the clipboard, and a Windows notification says so ("paste it with Ctrl+V"). If another program keeps the clipboard busy, the drawing is only saved, and the notification says that instead.
- The program does not use the network and sends nothing anywhere. Claude sees a drawing only when you paste it or when Claude opens it from the folder's `drawings\`.
- To pick up a drawing by itself in Claude Code, Claude runs a small PowerShell loop in the background that checks `drawings\status.txt` every 2 seconds, for up to 30 minutes, and then opens the new PNG. It only reads that folder.
- The browser board loads nothing from the network. Its Copy button puts a PNG on the clipboard through the browser; Save picture saves a PNG through the browser's normal download (`drawing_*.png`, usually in Downloads). Where the browser blocks either one, the board shows the picture instead, to long-press (or right-click) and copy or save, or to take a screenshot of. Both cover the whole drawing, also ink outside the current window. When Claude publishes the board as an artifact on claude.ai, it is the same page: the drawing stays in your browser until you copy, save or screenshot it.
- `-Uninstall` (and the Uninstall button in Settings, where Windows shows the entry) stops the helper and removes `app\` with the program, `uninstall.ps1`, `source.sha256` and `version.txt`, removes `helper.txt`, the Startup shortcut and the Settings entry, and writes `notice.txt` and `no-reminder.txt` so the plugin does not ask about the helper again on this computer (the next install deletes them). Your drawings and `shortcut.txt` are kept, and so is the build output in the plugin's `app\bin\` folder.
- 0.8.0 moved everything from the old folders. Versions 0.5.1 to 0.7.9 kept the program in `%LOCALAPPDATA%\Programs\simple-drawing-pad`, the drawings and the state files in `%LOCALAPPDATA%\simple-drawing-pad`, the shortcut setting in `%APPDATA%\simple-drawing-pad\shortcut.txt`, and started with Windows by a value `simple-drawing-pad` under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`. `install.ps1` moves the drawings (cancelled ones too) that are not in the new folder yet, copies the shortcut setting when the new file does not exist (the helper also reads the old file while the new one is missing), removes the old program files (apart from the stub below), the old `helper.txt`, `notice.txt` and `no-reminder.txt`, the old autostart value, and the old folders under `%LOCALAPPDATA%` once they are empty; `uninstall.ps1` removes the old autostart value, the old program files (and that folder when it is empty) and the old `helper.txt` too. Drawings left in the old folder and `%APPDATA%\simple-drawing-pad` are not touched.
- **The stub in the old program folder (0.9.0).** When that move finds the program of 0.5.1 to 0.7.9 in `%LOCALAPPDATA%\Programs\simple-drawing-pad`, `install.ps1` overwrites it with a copy of the new `SimpleDrawingPad.exe` and writes the new version into `version.txt` next to it, and the folder stays. A copy of the plugin from 0.5.1 to 0.7.9 that is still in another Claude app then sees a newer program there and only starts it, instead of installing its old program again; while the helper already runs, that start ends at once (one helper at a time, above). While the stub is there, the helper also writes its report to `%LOCALAPPDATA%\simple-drawing-pad\helper.txt`, the only place such an old copy of the plugin looks, so it sees the helper running and does not offer to install it again. The check does not count the stub as an old install, and `uninstall.ps1` removes the stub with that folder, and that `helper.txt` with its folder when the folder is empty.
- Before 0.5.1 drawings were saved in `Pictures\simple-drawing-pad`, which OneDrive may sync between computers; they stay there untouched.
- Previous name: versions up to 0.3.0 were called drawing-board. If that version's helper is running from `%LOCALAPPDATA%\Programs\drawing-board\DrawingBoard.exe`, `install.ps1` (also with `-Uninstall`) stops it, and it removes that version's autostart value `drawing-board` when the value starts exactly that file. Its files, drawings and shortcut setting are left in place.

## Feedback

Questions, ideas or problems: [open an issue](https://github.com/szymjs/simple-drawing-pad/issues/new/choose) on GitHub (a free GitHub account is needed). For a problem, the form asks for your Windows version, how Claude is installed, the plugin version and the last lines of the plugin's check; Claude can run the check for you. Tested with another tablet, pen display or touch screen? That helps too.

Please do not attach drawings, screenshots or paths that show private information.

## License

MIT, see [LICENSE](LICENSE).
