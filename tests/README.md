# Tests

The pen window is built on Windows by `build.ps1` and tried by hand. This folder holds what can be checked without
Windows: `run.sh` builds `SimpleDrawingPad.cs` with Mono's C# compiler and runs `SaveTest.cs`, which loads the built
program and calls its save routine under a virtual display, without opening the window.

It checks the Enter and Shift+Enter paths: the PNG in `drawings\`, the extra copy of Shift+Enter, `latest.*`,
`status.txt`, a copy that cannot be written (the drawing is still saved and named in `status.txt`, the copy is written
last and its failure is reported, and `drawings\` holds a single file, also after a second try) and an empty sheet.
It does not check the Save as dialog, the keys, the Windows clipboard, the tablet, the tray helper or its shortcut
dialog; those need a Windows PC, see `windows.md`.

Needs Mono (`mono-devel`) and `xvfb`. Run `tests/run.sh`; it ends with `ALL CHECKS PASSED` or the number of failed checks.
The folder is outside the plugin (`plugins/simple-drawing-pad`), so nothing here is installed on anyone's computer.
