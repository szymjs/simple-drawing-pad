# Simple Drawing Pad

**Like dictation, but drawn - a quick sketch takes your idea to Claude or any app.**

Sketch a layout, wiring, a UI mockup, a diagram or a handwritten note, and Claude looks at it.

Ctrl+Alt+D = draw\
Enter = copy\
Ctrl+V = paste\
Shift+Enter = save as

Simple as that. A small helper from the Microsoft Store (signed by Microsoft), or built on your PC from the included source (no admin rights either way).

Nothing is collected and nothing goes to third parties: the drawing is only for you and Claude. On your PC everything stays local, with no network. On the board that Claude publishes for you on claude.ai (phone, claude.ai, cloud sessions), Send to Claude uploads your drawing to your own private artifact, and only when you tap it. Starts with Windows. It asks once per computer before installing, and a short local check at each session start tells Claude if it works.

- **Pen window (Windows).** The shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws on the sheet, with pressure, while the window is active; pen displays and touch laptops draw where the pen is; without a tablet the mouse or trackpad draws. Enter copies the drawing to the clipboard and closes the window, so you can paste it into Claude, an email or any other app with Ctrl+V. In Claude Code, Claude picks it up by itself.
- **Browser board (any system).** `skills/draw/assets/simple-drawing-pad.html` is one offline page with pen pressure, eraser, three widths, grid, undo, full screen, Copy (the drawing goes to the clipboard, you paste it into the chat) and Save picture. In Claude Code on macOS or Linux (or Windows without the helper), Claude opens it in its browser pane or in your browser.
- **Phone, claude.ai, cloud sessions, Remote Control.** Claude publishes the board for you as your private artifact, or you draw on paper and send a photo. On the board, tap Send to Claude where that button shows, then write "done" in the chat; elsewhere tap Copy and paste, or attach a screenshot. Nothing is installed. Your phone can be the drawing tablet for a session on your computer: open the same conversation in the Claude app on the phone, tap the board's link there, draw, Send, and write "done".

## What runs on your computer, and what it never does

On Windows the pen window is a small helper program with a pencil icon by the clock (Windows may hide it under ^), installed once per computer and only when you agree. Everything it saves is in one folder, `C:\Users\<you>\simple-drawing-pad`: your last drawing as `drawings\latest.png`, the shortcut setting and the plugin's state files next to it, and a locally built program in `app\`; the Store version keeps its program where Windows keeps Store apps. The program draws the pencil icon itself, and the same pencil marks it in Task Manager, so you can always tell what is running; right-click it for Draw, Change shortcut and Exit. It starts with Windows (the Store version by its startup task, a local build by the shortcut `Simple Drawing Pad.lnk` in your Startup folder), and at the start of each session the plugin runs a short local check, without a prompt, that tells Claude whether it works. Elsewhere nothing is installed: the browser board is one offline page.

- The helper never uses the network: it sends nothing and collects nothing. Claude sees a drawing only when you paste it, send a photo or a screenshot, say "done" with the board open in Claude Code's browser pane, press Enter or close the pen window (Claude Code then reads `latest.png`), or tap Send to Claude on the board.
- The plugin itself never downloads anything and never asks for administrator rights. The Store version is installed and updated by Windows, from the Microsoft Store, with Microsoft's signature; the local build is made from the included source (`app/SimpleDrawingPad.cs`) by the C# compiler that is part of Windows. The Store package is built from that same source (`store/` in the repository).
- It never watches your keyboard: Windows tells it only when its own shortcut is pressed, and keys reach it only while its drawing window is active.
- It never keeps a history: it keeps only the last drawing, `latest.png`, until the next one, and Esc saves nothing. The copy you save with Shift+Enter is the only one that stays.
- It never installs without asking, and it asks only once per computer.

## Install and remove

1. Add the plugin: from the Claude directory, or in Claude Code with `/plugin marketplace add szymjs/simple-drawing-pad` and `/plugin install simple-drawing-pad@simple-drawing-pad`. Start a new session.
2. On Windows the first session asks you once whether to install the helper, and says what it is. Answer yes, or run `/simple-drawing-pad:install`; it installs the Store version (recommended: signed by Microsoft, updated by the Store; `winget` or the Store page, then you open the program once from the Start menu), checks that it works and tells you. `/simple-drawing-pad:install local` builds the same program on your PC instead, from the included source (approve the one PowerShell command); use it where the Store is not available. You can also install it yourself from the [Microsoft Store](https://apps.microsoft.com/detail/9NGDN0TGNRKC). Each Windows computer needs this once. On other systems there is nothing to install.
3. Press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**. The skill is `/simple-drawing-pad:draw`, or just ask Claude, for example: "draw", "I want to draw you my idea" or "let me show you what I think". If Ctrl+Alt+D does nothing, ask Claude why: it runs the plugin's check, `app\status.ps1`, whose last line says what to do (`not-installed`, `not-running` or `update-available`: install again or, for the Store version, open the program once from the Start menu; `shortcut-taken`: right-click the pencil icon by the clock and choose "Change shortcut"). If you reach Claude Code on the PC from your phone (Remote Control), say you are away: the window opens on the PC. If Windows blocks a locally built helper ("An application control policy has blocked this file", which Smart App Control does to a program that has no publisher signature), install the Store version, or use the browser board: it needs no program.

`/simple-drawing-pad:uninstall` removes the Store version (as Windows Settings > Apps > Simple Drawing Pad > Uninstall does) and a local build with its Startup shortcut and Settings > Apps entry; your last drawing and the shortcut setting are kept. Where Windows shows the local build's entry (not for an install made from the Microsoft Store version of the Claude app), its Uninstall button does the same, even after the plugin was removed from Claude.

## Keys (pen window)

| Key | Action |
|---|---|
| 1 to 5 | line width |
| 6 / 7 / 8 / 9 / 0 | black / orange / light blue / red / grey |
| Space or E | eraser (in whole-tablet mode the pen's back end and side buttons erase too) |
| Backspace | undo |
| Delete | clear the sheet |
| Enter | copy the drawing to the clipboard, then paste it with **Ctrl+V** (closing the window with X or Alt+F4, or Exit in the tray menu, does the same) |
| Shift+Enter | the same, after asking where to save a copy (Pictures by default). That copy is yours to keep; Pictures may be a OneDrive folder, which then syncs it. If the copy cannot be written, the drawing is still copied to the clipboard and a message names the path that failed |
| Esc | cancel: nothing is copied and nothing is saved |

An empty sheet is never copied. In tablet mode the pointer stays inside the sheet while the pen is near the tablet, so the whole tablet maps to the sheet; lift the pen out of the tablet's range and the mouse is free again, draws too, and reaches the toolbar. If the shortcut collides with a letter on your keyboard layout, change it from the tray menu ("Change shortcut").

## Requirements

- Windows 10 or 11. The Store version needs Windows 10 version 2004 or later and the Microsoft Store; the local build needs the .NET Framework 4 C# compiler (`csc.exe`) that is part of Windows, and a Windows that lets an unsigned program run (Smart App Control off or in evaluation).
- For whole-tablet mode: a regular (opaque) tablet with a Wintab driver, such as the Wacom driver. Without one the window works with the mouse, trackpad or pen pointer. **Tested so far** with a Wacom graphics tablet on Windows 10, and on Windows 11 with a laptop trackpad and the Claude desktop app from the Microsoft Store (local build: install, helper, shortcut, the check, the session-start notice and the start with Windows after a restart; Store version: install with Smart App Control on, helper, shortcut and the check). Other tablets, pen displays and touch screens are not tested yet.
- The browser board works in any modern browser on any system. Its Copy button needs a browser that lets a page put a picture on the clipboard; where it cannot, the board says so and asks for a screenshot, which does the same.

Every file the plugin writes, the board in detail, the Microsoft Store version of the Claude app, updates from older versions, the `/draw` alias and what changed in each release: [DETAILS.md](DETAILS.md).

## Feedback

Questions, ideas or problems: [open an issue](https://github.com/szymjs/simple-drawing-pad/issues/new/choose) on GitHub (a free GitHub account is needed). For a problem, the form asks for your Windows version, how Claude is installed, the plugin version and the last lines of the plugin's check; Claude can run the check for you. Tested with another tablet, pen display or touch screen? That helps too. Please do not attach drawings, screenshots or paths that show private information.

## License

MIT, see [LICENSE](LICENSE).

Wacom is a trademark of Wacom Co., Ltd. Simple Drawing Pad is not affiliated with or endorsed by Wacom, and it contains and distributes no Wacom software: on Windows it uses the Wintab interface of the tablet driver you already have installed.
