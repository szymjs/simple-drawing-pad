# Trying 0.9.9 on Windows

What `tests/run.sh` cannot check: the Save as dialog, the Shift+Enter key, the Windows clipboard, the tablet, the
tray helper and its shortcut dialog.
About ten minutes on a Windows PC with the plugin installed.

## By hand

1. In the repository folder: `git pull` on `main`.
2. Build and install the helper from the repository, not from the installed plugin (`/simple-drawing-pad:install` builds
   the plugin's own copy, which may be an older version). In PowerShell, in the repository folder:
   `powershell -NoProfile -ExecutionPolicy Bypass -File plugins\simple-drawing-pad\app\install.ps1 -Autostart`
   then `powershell -NoProfile -ExecutionPolicy Bypass -File plugins\simple-drawing-pad\app\status.ps1`.
   The check must end with `ready`; a build error is the first thing to report. Keep the output of both commands.
3. Press Ctrl+Alt+D, draw a few strokes: the grey status text on the bar ends with `Shift+Enter: save as`. At a display
   scale of 125% or more the text is shorter (without the colour name, then without `width n/5`), and it still ends
   with `Shift+Enter: save as`. (In tablet mode the cursor stays on the sheet while the pen is near; move the pen away
   to reach the Enter button's tooltip with the mouse.)
4. Press **Shift+Enter**. A Save as dialog opens in Pictures with a name like `drawing_20261009_120000.png`.
   Save it. The window closes. Then:
   - the saved file opens as a picture,
   - Ctrl+V in any app pastes the drawing,
   - `%USERPROFILE%\simple-drawing-pad\drawings\status.txt` says `copied` and names `drawings\latest.png`, not the copy;
     `drawings\` holds only `latest.png` and `status.txt`.
5. Ctrl+Alt+D, draw, Shift+Enter, **Cancel** in the dialog: the window stays open with the drawing; in tablet mode the
   pen still draws. Then Enter: copied as usual.
6. Ctrl+Alt+D, draw nothing, Shift+Enter: the window closes without a dialog; `status.txt` says `empty`.
7. Tablet (if there is one): after step 5 the whole tablet still draws on the sheet (the dialog released and the
   return re-enabled it).
7a. Mouse in tablet mode (a PC with a Wintab driver; with no tablet attached the bar still says `tablet`): the mouse
   draws, and reaches the toolbar buttons. With a tablet: a pen stroke is drawn once, not twice, and the mouse does
   not draw while the pen hovers over the tablet.
8. One helper at a time: in PowerShell run
   `& "$env:USERPROFILE\simple-drawing-pad\app\SimpleDrawingPad.exe" --tray`.
   No second pencil icon appears by the clock and no message is shown; Ctrl+Alt+D still opens the drawing window, and
   the step-2 `status.ps1` command still ends with `ready`.

To go back to the released version afterwards, run `/simple-drawing-pad:uninstall`, then `/simple-drawing-pad:install`.
`/simple-drawing-pad:install` alone keeps this test build, because it is newer than the released plugin.

## With Claude on that PC

Paste this into Claude Code on the Windows PC, in the repository folder:

> In the repository folder, update `main` with `git pull`, install the helper from it as `tests/windows.md`
> step 2 says, and tell me the check's last line. Then walk me through `tests/windows.md` steps 3 to 8 one at a time: tell me what to press, wait for me,
> and after each step read `%USERPROFILE%\simple-drawing-pad\drawings\status.txt` and say whether it matches the
> step. Do not draw or close anything yourself. At the end list what passed and what did not.

Report a failure with the step number, what happened instead, and the output of the step-2 `install.ps1` and
`status.ps1` commands.
