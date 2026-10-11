# Tests

The pen window is built on Windows by `build.ps1` and tried by hand. This folder holds what can be checked without
Windows: `run.sh` builds `SimpleDrawingPad.cs` with Mono's C# compiler and runs `SaveTest.cs`, which loads the built
program and calls its save routine under a virtual display, without opening the window.

It checks the Enter, Shift+Enter and Esc paths: `latest.png` in `drawings\` (the one drawing kept, overwritten each
time; no `drawing_*.png`, no `latest.txt`), the extra copy of Shift+Enter, `status.txt` (line 2 is the `latest.png`
path), a copy that cannot be written (the drawing is still saved and named in `status.txt`, the copy is written last
and its failure is reported, and `drawings\` still holds only `latest.png` and `status.txt`), an empty sheet, and Esc
(`status.txt` says `cancelled`, `latest.png` is left as it was). It does not check the Save as dialog, the keys, the
Windows clipboard, the tablet, the tray helper or its shortcut dialog; those need a Windows PC, see `windows.md`. Send
to Claude on the browser board needs a board that Claude Code published as an artifact, opened by its owner in the
Claude app or on claude.ai (a phone is the main case, a desktop browser works too): draw, tap or click Send to Claude,
then write done in the chat; a second tap before the drawing changes stores nothing.

Needs Mono (`mono-devel`) and `xvfb`. Run `tests/run.sh`; it ends with `ALL CHECKS PASSED` or the number of failed checks.
The folder is outside the plugin (`plugins/simple-drawing-pad`), so nothing here is installed on anyone's computer.
