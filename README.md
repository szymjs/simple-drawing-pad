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

Local only, no network, collects nothing. Starts with Windows (a shortcut in your Startup folder). It asks once per computer before installing, and a short local check at each session start tells Claude if it works.

Remove it with `/simple-drawing-pad:uninstall`

Pen window for Windows PCs; an offline browser board elsewhere; on a phone or in claude.ai, the board or a photo of a paper sketch.

- **Pen window (Windows):** a keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws in it; a mouse or trackpad works too. Enter copies the drawing to the clipboard; paste it with Ctrl+V. Shift+Enter also saves a copy where you choose.
- **Browser board (any system):** one offline page with pen pressure, eraser, undo, a Copy button (the drawing goes to the clipboard, you paste it into the chat) and Save picture.
- **Phone, claude.ai or away from your PC:** Claude publishes the board for you as an artifact: draw with your finger or mouse, tap Copy and paste it into the chat (or attach a screenshot if Copy is blocked). On a board published from Claude Code, tap Send to Claude instead and the drawing reaches Claude by itself (the first time, the Claude app asks you to let the board comment for you). Or draw on paper and send a photo. Nothing to install.

The plugin is code and text, plus one picture: the pencil icon for its directory listing, which no code reads.

**What runs on your computer:** on Windows the pen window is a small helper program, installed once per computer and only when you agree. The program and everything it saves are in one folder, `C:\Users\<you>\simple-drawing-pad`: the program in `app\`, your drawings in `drawings\`, the shortcut setting next to them; the Startup shortcut and the entry for Windows Settings > Apps are outside it. Its pencil icon, which the program draws itself, marks it by the clock and in Task Manager, so you can always tell what is running. It works only locally: no network, it sends nothing and collects nothing. It is built from the included source (nothing downloaded, no administrator rights), starts with Windows by a shortcut in your Startup folder, keeps only your last 10 drawings on this computer, and you remove it with `/simple-drawing-pad:uninstall` (Windows Settings > Apps lists it too, when Windows can see the entry). At the start of each session a short local check, run without a prompt, tells Claude whether the helper works.

**Claude from the Microsoft Store:** the Store version of the Claude app runs the plugin's commands in a sandbox. Registry entries and new AppData folders written from inside it belong to the app alone: Windows does not start from them, Windows Settings > Apps does not list them, and Explorer does not show them. That is why 0.8.0 moved everything to `C:\Users\<you>\simple-drawing-pad`, a folder every program on your computer sees, and starts the helper by a shortcut in your Startup folder, which is real from inside the sandbox too. Tested on Windows 11 with the Store app: after a restart Windows started the helper from that shortcut, before Claude was opened. Settings > Apps does not list the helper there; remove it with `/simple-drawing-pad:uninstall`. The Claude app from claude.ai (EXE) and `claude` in a terminal have no sandbox; they use the same folder and shortcut.

## Install

In Claude Code:

```
/plugin marketplace add szymjs/simple-drawing-pad
/plugin install simple-drawing-pad@simple-drawing-pad
```

Or add it from the Claude directory. Start a new session afterwards, then:

1. On Windows the first session asks you **once** whether to install the helper on this computer. There is one way to install it: **`/simple-drawing-pad:install`**. Run it, or just answer "yes" and Claude runs it for you; it checks that it works and tells you. Each Windows computer needs this once (remove it with `/simple-drawing-pad:uninstall`).
2. Press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**.

If the helper later stops working on a computer, the plugin says so once at the start of a session, with what to do.

The skill is also available as `/simple-drawing-pad:draw` (on other systems it opens the offline browser board).

On a phone, in claude.ai or in a cloud session, just ask Claude to let you draw: it offers the board as an artifact or a photo of a paper sketch. If you reach Claude Code on your PC from your phone (Remote Control), tell Claude you are away from the PC, because Ctrl+Alt+D opens the window on the PC.

If you prefer typing `/draw`, add a command of your own: commands from a plugin always carry the plugin's name, so the plugin cannot register `/draw` itself. Create `C:\Users\<you>\.claude\commands\draw.md` (on other systems `~/.claude/commands/draw.md`) with:

```markdown
---
description: Simple Drawing Pad (alias for /simple-drawing-pad:draw)
---
Run the skill `simple-drawing-pad:draw`. Arguments: $ARGUMENTS
```

## Where it works

- **Anywhere in Windows:** Enter copies each drawing to the clipboard, so you can paste it into Claude, an email or any other app with Ctrl+V.
- **Claude Code:** Claude installs the pen window when you agree, and picks up the drawing by itself when you press Enter.
- **Other systems:** the offline browser board works in any modern browser.
- **Phone and claude.ai:** the same board as an artifact, with a Copy button for the chat, or a photo of a paper sketch.

**Tested so far** with a Wacom graphics tablet on Windows 10, and on Windows 11 with a laptop trackpad and the Claude desktop app from the Microsoft Store (the helper starts with Windows there too). Other tablets, pen displays and touch screens are not tested yet.

Keys, requirements and everything the program runs and stores: [plugins/simple-drawing-pad/README.md](plugins/simple-drawing-pad/README.md).

## Feedback

Questions, ideas or problems: [open an issue](https://github.com/szymjs/simple-drawing-pad/issues/new/choose) here on GitHub (a free GitHub account is needed). For a problem, the form asks for your Windows version, how Claude is installed, the plugin version and the last lines of the plugin's check; Claude can run the check for you. Tested with another tablet, pen display or touch screen? That helps too.

Please do not attach drawings, screenshots or paths that show private information.

## License

MIT, see [LICENSE](LICENSE).

Wacom is a trademark of Wacom Co., Ltd. Simple Drawing Pad is not affiliated with or endorsed by Wacom, and it contains and distributes no Wacom software: on Windows it uses the Wintab interface of the tablet driver you already have installed.
