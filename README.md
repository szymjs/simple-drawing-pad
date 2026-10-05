![it just works!](plugins/simple-drawing-pad/logo.png)

# Simple Drawing Pad

**Draw your idea, then paste it from the clipboard wherever you need it. It just works. Simple as that.**\
*Simple by design, made for simple use.*

A Claude Code plugin: sketch an idea by hand (a layout, wiring, a UI mockup, a diagram, handwriting) and let Claude look at it.

- **Pen window (Windows):** a keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws in it. Enter copies the drawing to the clipboard; paste it with Ctrl+V.
- **Browser board (any system):** one offline page with pen pressure, eraser, undo and PNG export.

## Install

In Claude Code:

```
/plugin marketplace add szymjs/simple-drawing-pad
/plugin install simple-drawing-pad@simple-drawing-pad
```

Start a new session afterwards so the skill loads. Then ask Claude to install the pen window, or to open the browser board. The skill is also available as `/simple-drawing-pad:draw`.

## Where it works

- **Anywhere in Windows:** the pen window copies each sent drawing to the clipboard, so you can paste it into Claude (or any app) with Ctrl+V.
- **Claude Code:** Claude installs the pen window when you ask, and picks up the drawing by itself when you press Enter.
- **Other systems:** the offline browser board works in any modern browser.

**Tested so far** with a Wacom graphics tablet on Windows 10. Other tablets, pen displays, touch screens and Windows 11 are not tested yet.

Keys, requirements and everything the program runs and stores: [plugins/simple-drawing-pad/README.md](plugins/simple-drawing-pad/README.md).

## License

MIT, see [LICENSE](LICENSE).
