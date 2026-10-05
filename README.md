# drawing-board

**Draw your idea, then paste it from the clipboard wherever you need it. It just works. Simple as that.**\
*Simple by design, made for simple use.*

A drawing board for Claude: sketch an idea by hand (a layout, wiring, a UI mockup, a diagram, handwriting) and let Claude look at it.

- **Pen window (Windows):** a keyboard shortcut (Ctrl+Alt+D by default) opens a drawing window. With a regular graphics tablet the whole tablet draws in it. Enter sends the drawing.
- **Browser board (any system):** one offline page with pen pressure, eraser, undo and PNG export.

## Install

In Claude Code:

```
/plugin marketplace add szymjs/drawing-board-for-Claude
/plugin install drawing-board@drawing-board
```

Start a new session afterwards so the skill loads. Then ask Claude to install the pen window, or to open the browser board.

## Where it works

- **Anywhere in Windows:** the pen window copies each sent drawing to the clipboard, so you can paste it into Claude (or any app) with Ctrl+V.
- **Claude Code:** Claude installs the pen window when you ask, and picks up the drawing by itself when you press Enter.
- **Other systems:** the offline browser board works in any modern browser.

**Tested so far** with a Wacom graphics tablet on Windows 10. Other tablets, pen displays, touch screens and Windows 11 are not tested yet.

Keys, requirements and everything the program runs and stores: [plugins/drawing-board/README.md](plugins/drawing-board/README.md).

## License

MIT, see [LICENSE](LICENSE).
