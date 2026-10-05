# Workshop plugins for Claude Code

A small Claude Code plugin marketplace (`workshop-plugins`) with two plugins from a home workshop.

| Plugin | What it does |
|---|---|
| **drawing-board** | Sketch an idea by hand and let Claude look at it. On Windows a pen window opens with a keyboard shortcut (with a regular tablet the whole tablet draws in it); on any system an offline browser board works too. |
| **safe-device-work** | Guardrails for Claude when it works on real disks, USB sticks, NAS/RAID, microcontroller flash, admin sessions and accounts: no destructive tests on real hardware, ask before deleting or flashing, never handle passwords or accept terms. |

## Install

In Claude Code:

```
/plugin marketplace add szymjs/drawing-board-for-Claude
/plugin install drawing-board@workshop-plugins
/plugin install safe-device-work@workshop-plugins
```

Start a new session afterwards so the skills load.

## drawing-board

- **Anywhere in Windows:** the pen window copies each drawing to the clipboard, so you can paste it into Claude (or any app) with Ctrl+V.
- **Claude Code:** Claude installs the pen window when you ask, and picks up the drawing by itself when you press Enter.
- **Other systems:** the offline browser board works in any modern browser.

Install steps, keys, requirements and everything the program runs and stores: [plugins/drawing-board/README.md](plugins/drawing-board/README.md).

## Safe Device Work

A single skill with rules Claude follows before risky operations: formatting, partitioning, flashing firmware, deleting files, RAID rebuilds, installing software, and anything involving passwords, purchases or terms. It contains no tooling of its own; it only changes how Claude behaves.

## License

MIT, see [LICENSE](LICENSE).
