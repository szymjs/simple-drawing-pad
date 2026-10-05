# drawing-board

**Draw your idea, then paste it from the clipboard wherever you need it. It just works. Simple as that.**

Sketch an idea by hand (a layout, wiring, a UI mockup, a diagram, handwriting) and let Claude look at it.

- **Pen window (Windows).** A keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws on the sheet, with pressure, while the window is active. On pen displays and touch laptops it draws where the pen is; with no tablet it uses the mouse. Enter saves the drawing as a PNG and copies it to the clipboard, so you can paste it into Claude anywhere in Windows with Ctrl+V. In Claude Code, Claude can also pick it up by itself.
- **Browser board (any system).** `skills/drawing-board/assets/drawing-board.html` is one offline page with pen pressure, eraser, line widths, grid, undo, full screen and PNG export.

## Install

1. In Claude Code: `/plugin marketplace add szymjs/drawing-board-for-Claude`, then `/plugin install drawing-board@drawing-board`, and start a new session.
2. For the pen window, ask Claude to install it, or run this from the root of a clone of `szymjs/drawing-board-for-Claude`:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "plugins\drawing-board\app\install.ps1"
```

Add `-Autostart` to start the shortcut helper at every logon, or `-Uninstall` to remove it. No admin rights are needed.

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
| Enter | send (closing the window with X or Alt+F4 also sends) |
| Esc | cancel: nothing is sent, a copy is kept in the `cancelled` folder |

An empty sheet is never sent. While the window is active in tablet mode the pointer stays inside the sheet; switch away (Alt+Tab) to release it. Change the shortcut from the tray icon menu ("Change shortcut…").

## What it runs and stores

- `install.ps1` builds `DrawingBoard.exe` from the included source (`app/DrawingBoard.cs`) with the Windows C# compiler `csc.exe` into `app\bin\` inside the plugin folder, copies it to `%LOCALAPPDATA%\Programs\drawing-board` and starts it in the notification area. It stops a running drawing-board helper first.
- With `-Autostart` it adds a per-user autostart value `drawing-board` under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` that starts `DrawingBoard.exe --tray` at logon.
- Each sent drawing is saved as a time-stamped PNG in `Pictures\drawing-board`, together with `latest.png`, `latest.txt` (path of the newest drawing) and `status.txt` (result of the last session: sent, cancelled or empty). Cancelled drawings go to `Pictures\drawing-board\cancelled`.
- The keyboard shortcut is kept in `%APPDATA%\drawing-board\hotkey.txt`.
- A sent drawing is copied to the clipboard.
- The program does not use the network and sends nothing anywhere. Claude sees a drawing only when you paste it or when Claude reads it from your Pictures folder.
- To pick up a drawing by itself in Claude Code, Claude runs a small PowerShell loop in the background that checks `Pictures\drawing-board\status.txt` every 2 seconds, for up to 30 minutes, and then opens the new PNG. It only reads that folder.
- The browser board saves its PNG through the browser's normal download.
- `-Uninstall` stops the helper and removes the installed program and the autostart entry (and a Startup-folder shortcut from older versions). Your drawings and the shortcut setting are kept, and so is the build output in the plugin's `app\bin\` folder.

## License

MIT, see [LICENSE](LICENSE).
