![it just works!](logo.png)

# Simple Drawing Pad

A Claude Code plugin.

**Like dictation, but drawn - a quick sketch takes your idea to Claude or any app.**

Ctrl+Alt+D = draw\
Enter = copy\
Ctrl+V = paste

Simple as that. A small helper is built on your PC from the included source (nothing downloaded, no admin rights).

Local only, no network, collects nothing. Starts with Windows. It asks once per computer before installing, and a short local check at each session start tells Claude if it works.

Remove it in Windows Settings > Apps

For Windows PCs only.

- **Pen window (Windows):** a keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws in it; a mouse or trackpad works too. Enter copies the drawing to the clipboard; paste it with Ctrl+V.
- **Browser board (any system):** one offline page with pen pressure, eraser, undo and PNG export.

The plugin is code and text, plus one picture: the pencil icon for its directory listing, which no code reads.

**What runs on your computer:** on Windows the pen window is a small helper program, installed once per computer and only when you agree. Its pencil icon, which the program draws itself, marks it by the clock, in Task Manager and in Windows Settings > Apps, so you can always tell what is running. It works only locally: no network, it sends nothing and collects nothing. It is built from the included source (nothing downloaded, no administrator rights), starts with Windows, keeps only your last 10 drawings on this computer, and you can remove it in Windows Settings > Apps or with `/simple-drawing-pad:uninstall`. At the start of each session a short local check, run without a prompt, tells Claude whether the helper works.

## Install

In Claude Code:

```
/plugin marketplace add szymjs/simple-drawing-pad
/plugin install simple-drawing-pad@simple-drawing-pad
```

Or add it from the Claude directory. Start a new session afterwards, then:

1. On Windows the first session asks you **once** whether to install the helper on this computer. There is one way to install it: **`/simple-drawing-pad:install`**. Run it, or just answer "yes" and Claude runs it for you; it checks that it works and tells you. Each Windows computer needs this once (remove it in Windows Settings > Apps or with `/simple-drawing-pad:uninstall`).
2. Press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**.

If the helper later stops working on a computer, the plugin says so once at the start of a session, with what to do.

The skill is also available as `/simple-drawing-pad:draw` (on other systems it opens the offline browser board).

## Where it works

- **Anywhere in Windows:** Enter copies each drawing to the clipboard, so you can paste it into Claude, an email or any other app with Ctrl+V.
- **Claude Code:** Claude installs the pen window when you agree, and picks up the drawing by itself when you press Enter.
- **Other systems:** the offline browser board works in any modern browser.

**Tested so far** with a Wacom graphics tablet on Windows 10, and on Windows 11 with a laptop trackpad. Other tablets, pen displays and touch screens are not tested yet.

Keys, requirements and everything the program runs and stores: [plugins/simple-drawing-pad/README.md](plugins/simple-drawing-pad/README.md).

## Feedback

Questions, ideas or problems: [open an issue](https://github.com/szymjs/simple-drawing-pad/issues/new/choose) here on GitHub (a free GitHub account is needed). For a problem, the form asks for your Windows version, the plugin version and the last lines of the plugin's check; Claude can run the check for you. Tested with another tablet, pen display or touch screen? That helps too.

Please do not attach drawings, screenshots or paths that show private information.

## License

MIT, see [LICENSE](LICENSE).
