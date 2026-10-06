![it just works!](plugins/simple-drawing-pad/logo.png)

# Simple Drawing Pad

**Draw your idea, then paste it from the clipboard wherever you need it. It just works. Simple as that.**\
*Simple by design, made for simple use.*

A Claude Code plugin: sketch an idea by hand (a layout, wiring, a UI mockup, a diagram, handwriting) and let Claude look at it. Quick notes, as easy as dictating: three keys, draw, Enter, Ctrl+V.

- **Pen window (Windows):** a keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws in it; a mouse or trackpad works too. Enter copies the drawing to the clipboard; paste it with Ctrl+V.
- **Browser board (any system):** one offline page with pen pressure, eraser, undo and PNG export.

**What runs on your computer:** on Windows the pen window is a small helper program (a pencil icon by the clock), installed once per computer and only when you agree. It works only locally: no network, it sends nothing and collects nothing. It is built from the included source (nothing downloaded, no administrator rights), starts with Windows, keeps only your last 10 drawings on this computer, and `/simple-drawing-pad:uninstall` removes it.

## Install

In Claude Code:

```
/plugin marketplace add szymjs/simple-drawing-pad
/plugin install simple-drawing-pad@simple-drawing-pad
```

Or add it from the Claude directory. Start a new session afterwards, then:

1. On Windows the first session asks you **once** whether to install the helper on this computer. Answer "yes" to Claude or run **`/simple-drawing-pad:install`**; Claude checks that it works and tells you. Each Windows computer needs this once (`/simple-drawing-pad:uninstall` removes it).
2. Press **Ctrl+Alt+D**, draw, press Enter, paste with **Ctrl+V**.

If the helper later stops working on a computer, the plugin says so once at the start of a session, with what to do.

The skill is also available as `/simple-drawing-pad:draw` (on other systems it opens the offline browser board).

## Where it works

- **Anywhere in Windows:** Enter copies each drawing to the clipboard, so you can paste it into Claude, an email or any other app with Ctrl+V.
- **Claude Code:** Claude installs the pen window when you agree, and picks up the drawing by itself when you press Enter.
- **Other systems:** the offline browser board works in any modern browser.

**Tested so far** with a Wacom graphics tablet on Windows 10, and on Windows 11 with a laptop trackpad. Other tablets, pen displays and touch screens are not tested yet.

Keys, requirements and everything the program runs and stores: [plugins/simple-drawing-pad/README.md](plugins/simple-drawing-pad/README.md).

## License

MIT, see [LICENSE](LICENSE).
