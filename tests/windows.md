# Trying 0.9.0 on Windows

What `tests/run.sh` cannot check: the Save as dialog, the Shift+Enter key, the Windows clipboard, the tablet, the
tray helper and its shortcut dialog.
About ten minutes on a Windows PC with the plugin installed.

## By hand

1. In the repository folder: `git fetch origin claude/drawing-request-response-5v7epy` and
   `git checkout claude/drawing-request-response-5v7epy`.
2. Build and install the helper from the branch, not from the installed plugin (`/simple-drawing-pad:install` builds
   the plugin's own copy, which is the released version, not this branch). In PowerShell, in the repository folder:
   `powershell -NoProfile -ExecutionPolicy Bypass -File plugins\simple-drawing-pad\app\install.ps1 -Autostart`
   then `powershell -NoProfile -ExecutionPolicy Bypass -File plugins\simple-drawing-pad\app\status.ps1`.
   The check must end with `ready`; a build error is the first thing to report. Keep the output of both commands.
3. Press Ctrl+Alt+D, draw a few strokes: the grey status text on the bar ends with `Shift+Enter: save as`. At a display
   scale of 125% or more the text is shorter (without the colour name, then without `width n/5`), and it still ends
   with `Shift+Enter: save as`. (In tablet mode the cursor stays on the sheet, so the Enter button's tooltip is
   reachable only with the tablet unplugged.)
4. Press **Shift+Enter**. A Save as dialog opens in Pictures with a name like `drawing_20261009_120000.png`.
   Save it. The window closes. Then:
   - the saved file opens as a picture,
   - Ctrl+V in any app pastes the drawing,
   - `%USERPROFILE%\simple-drawing-pad\drawings\status.txt` says `copied` and names a file in `drawings\`, not the copy.
5. Ctrl+Alt+D, draw, Shift+Enter, **Cancel** in the dialog: the window stays open with the drawing; in tablet mode the
   pen still draws. Then Enter: copied as usual.
6. Ctrl+Alt+D, draw nothing, Shift+Enter: the window closes without a dialog; `status.txt` says `empty`.
7. Tablet (if there is one): after step 5 the whole tablet still draws on the sheet (the dialog released and the
   return re-enabled it).
8. One helper at a time: in PowerShell run
   `& "$env:USERPROFILE\simple-drawing-pad\app\SimpleDrawingPad.exe" --tray`.
   No second pencil icon appears by the clock and no message is shown; Ctrl+Alt+D still opens the drawing window, and
   the step-2 `status.ps1` command still ends with `ready`.
9. Shortcut dialog: right-click the pencil icon, choose "Change shortcut", press Ctrl+Alt+S. On a layout where AltGr
   types a character with S (Polish Programmer: `ś`), an orange line under the shortcut says what AltGr+S types and
   that this shortcut would stop it from typing in every app, and suggests adding Shift or choosing another key; on
   other layouts there is no warning. Choose Cancel, so Ctrl+Alt+D stays.

To go back to the released version afterwards, run `/simple-drawing-pad:uninstall`, then `/simple-drawing-pad:install`.
`/simple-drawing-pad:install` alone keeps this test build, because it is newer than the released plugin.

## With Claude on that PC

Paste this into Claude Code on the Windows PC, in the repository folder:

> Check out the branch `claude/drawing-request-response-5v7epy`, install the helper from the branch as `tests/windows.md`
> step 2 says, and tell me the check's last line. Then walk me through `tests/windows.md` steps 3 to 9 one at a time: tell me what to press, wait for me,
> and after each step read `%USERPROFILE%\simple-drawing-pad\drawings\status.txt` and say whether it matches the
> step. Do not draw or close anything yourself. At the end list what passed and what did not.

Report a failure with the step number, what happened instead, and the output of the step-2 `install.ps1` and
`status.ps1` commands.
