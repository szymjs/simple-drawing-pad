![it just works!](logo.png)

# Simple Drawing Pad

A Claude Code plugin.

**Like dictation, but drawn - a quick sketch takes your idea to Claude or any app.**

Sketch a layout, wiring, a UI mockup, a diagram or a handwritten note, and Claude looks at it.

Ctrl+Alt+D = draw\
Enter = copy\
Ctrl+V = paste\
Shift+Enter = save as

Simple as that. A small helper is built on your PC from the included source (nothing downloaded, no admin rights).

Nothing is collected and nothing goes to third parties: the drawing is only for you and Claude. On your PC everything stays local, with no network. On the board that Claude publishes for you on claude.ai (phone, claude.ai, cloud sessions), Send to Claude uploads your drawing to your own private artifact, and only when you tap it. Starts with Windows (a shortcut in your Startup folder). It asks once per computer before installing, and a short local check at each session start tells Claude if it works.

Pen window for Windows PCs; an offline browser board elsewhere; on a phone or in claude.ai, the board as an artifact or a photo of a paper sketch. The plugin is code and text, plus one picture: the pencil icon for its directory listing, which no code reads.

## What runs on your computer, and what it never does

On Windows the pen window is a small helper program, installed once per computer and only when you agree. The program and everything it saves are in one folder, `C:\Users\<you>\simple-drawing-pad`: the program in `app\`, your last drawing as `drawings\latest.png`, the shortcut setting and the plugin's state files next to them. Its pencil icon, which the program draws itself, marks it by the clock and in Task Manager, so you can always tell what is running. It starts with Windows by a shortcut in your Startup folder, and at the start of each session a short local check, run without a prompt, tells Claude whether it works. Elsewhere nothing is installed: the browser board is one offline page.

- The helper never uses the network: it sends nothing and collects nothing. Claude sees a drawing only when you paste it, send a photo or a screenshot, say "done" with the board open in Claude Code's browser pane, press Enter or close the pen window (Claude Code then reads `latest.png`), or tap Send to Claude on the board.
- It never downloads anything and never asks for administrator rights: the helper is built from the included source by the C# compiler that is part of Windows.
- It never watches your keyboard: Windows tells it only when its own shortcut is pressed, and keys reach it only while its drawing window is active.
- It never keeps a history: it keeps only the last drawing, `latest.png`, until the next one, and Esc saves nothing. The copy you save with Shift+Enter is the only one that stays.
- It never installs without asking, and it asks only once per computer.

## Install and remove

In Claude Code:

```
/plugin marketplace add szymjs/simple-drawing-pad
/plugin install simple-drawing-pad@simple-drawing-pad
```

Or add it from the Claude directory. Start a new session. On Windows the first session asks you once whether to install the helper: answer yes, or run `/simple-drawing-pad:install` yourself; it installs the helper, checks that it works and tells you. Then press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**. The skill is `/simple-drawing-pad:draw`, or just ask Claude, for example: "draw", "I want to draw you my idea" or "let me show you what I think"; on a phone, in claude.ai or in a cloud session it offers the board as an artifact or a photo of a paper sketch. If the helper later stops working, the plugin says so once at the start of a session, with what to do.

`/simple-drawing-pad:uninstall` stops the helper and removes the program, the Startup shortcut and the Windows Settings > Apps entry; your last drawing and the shortcut setting are kept.

Keys, requirements and the browser board: [plugins/simple-drawing-pad/README.md](plugins/simple-drawing-pad/README.md). Every file the plugin writes, the Microsoft Store version of the Claude app, updates from older versions and what changed in each release: [plugins/simple-drawing-pad/DETAILS.md](plugins/simple-drawing-pad/DETAILS.md).

## Feedback

Questions, ideas or problems: [open an issue](https://github.com/szymjs/simple-drawing-pad/issues/new/choose) here on GitHub (a free GitHub account is needed). For a problem, the form asks for your Windows version, how Claude is installed, the plugin version and the last lines of the plugin's check; Claude can run the check for you. Tested with another tablet, pen display or touch screen? That helps too. Please do not attach drawings, screenshots or paths that show private information.

## License

MIT, see [LICENSE](LICENSE).

Wacom is a trademark of Wacom Co., Ltd. Simple Drawing Pad is not affiliated with or endorsed by Wacom, and it contains and distributes no Wacom software: on Windows it uses the Wintab interface of the tablet driver you already have installed.
