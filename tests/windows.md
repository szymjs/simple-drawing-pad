# Trying 0.9.0 on Windows

What `tests/run.sh` cannot check: the Save as dialog, the Shift+Enter key, the Windows clipboard and the tablet.
About five minutes on a Windows PC with the plugin installed.

## By hand

1. In the repository folder: `git fetch origin claude/drawing-request-response-5v7epy` and
   `git checkout claude/drawing-request-response-5v7epy`.
2. Build and install the helper from the branch, not from the installed plugin (`/simple-drawing-pad:install` builds
   the plugin's own copy, which is the released version, not this branch). In PowerShell, in the repository folder:
   `powershell -NoProfile -ExecutionPolicy Bypass -File plugins\simple-drawing-pad\app\install.ps1 -Autostart`
   then `powershell -NoProfile -ExecutionPolicy Bypass -File plugins\simple-drawing-pad\app\status.ps1`.
   The check must end with `ready`; a build error is the first thing to report. (Afterwards, `/simple-drawing-pad:install`
   puts the released version back.)
3. Press Ctrl+Alt+D, draw a few strokes, hover over the Enter button: the tooltip names Shift+Enter.
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

## With Claude on that PC

Paste this into Claude Code on the Windows PC, in the repository folder:

> Check out the branch `claude/drawing-request-response-5v7epy`, install the helper from the branch as `tests/windows.md`
> step 2 says, and tell me the check's last line. Then walk me through `tests/windows.md` steps 3 to 7 one at a time: tell me what to press, wait for me,
> and after each step read `%USERPROFILE%\simple-drawing-pad\drawings\status.txt` and say whether it matches the
> step. Do not draw or close anything yourself. At the end list what passed and what did not.

Report a failure with the step number, what happened instead, and the last lines of `/simple-drawing-pad:install`.
