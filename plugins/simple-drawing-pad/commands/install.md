---
description: Install the Simple Drawing Pad helper on this Windows computer (local only; Ctrl+Alt+D opens the drawing window, Enter copies, Ctrl+V pastes)
---

Install the Simple Drawing Pad helper program on this Windows computer. The user asked for it by running this command (or by agreeing to the one-time question at session start), so do not ask again.

`${CLAUDE_PLUGIN_ROOT}` below is the plugin folder (the one that holds `app` and `skills`). If it was not filled in for you, write that absolute path in its place; never leave `${CLAUDE_PLUGIN_ROOT}` in a PowerShell command, where it would be an empty variable.

1. If you cannot run commands on the user's own computer directly (claude.ai, the Claude mobile app, Claude Code on the web or another cloud session), do not write the installer onto it yourself. Say that the helper is installed from Claude Code on that PC, and offer the Phone / web path of the `draw` skill for drawing now. Stop there.
2. If the user's own computer, the one you run on, is not Windows, say that the pen window is Windows-only and offer the offline browser board from the `draw` skill instead. Stop there.
3. If the user has not seen it in this conversation (the session-start question counts), say in one or two sentences what is installed: a small helper program that works only on this computer (no network, it sends and collects nothing), shows a pencil icon by the clock and opens the drawing window with Ctrl+Alt+D; it is built from the plugin's included source (nothing is downloaded, no administrator rights), starts with Windows by a shortcut in the Startup folder, keeps everything, including the last 10 drawings, in one folder, `%USERPROFILE%\simple-drawing-pad`, and can be removed with `/simple-drawing-pad:uninstall`. If they have seen it, do not explain again.
4. Before the first PowerShell command in this session, say once: "Claude will ask you to allow a PowerShell command; `-ExecutionPolicy Bypass` only lets this one included script run, it changes no settings."
5. Run this one PowerShell command. It builds the program with the C# compiler that ships with Windows, installs it to `%USERPROFILE%\simple-drawing-pad\app`, starts the helper, creates the shortcut `Simple Drawing Pad.lnk` in the user's Startup folder so the helper also starts after a restart, and lists the program in Windows Settings > Apps for this user. An install over 0.5.1 to 0.7.9 moves the program and the drawings from the old folders under `%LOCALAPPDATA%` to the new one and copies the shortcut setting from `%APPDATA%\simple-drawing-pad` (the old file stays); it leaves a copy of the new program in the old program folder `%LOCALAPPDATA%\Programs\simple-drawing-pad`, so a 0.7.9 copy of the plugin still installed elsewhere only starts the helper instead of installing itself again:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Autostart`

   In the Microsoft Store version of the Claude app this works the same way: after a restart Windows starts the helper from the Startup shortcut, before Claude is opened. Only the Settings > Apps entry is not shown for an install made from inside the Store app, because that app's sandbox keeps registry entries to itself.

6. If the installer's output already ends with a line `Result: <state>: <what to do>`, use it and skip this step. Otherwise check that it works with:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/status.ps1"`

7. Tell the user the result in one or two sentences, following the last line, `Result: <state>: <what to do>`:
   - `ready`: it works. Press the shortcut it names (Ctrl+Alt+D by default) to open the drawing window, Enter copies the drawing to the clipboard, Ctrl+V pastes it in the chat or in any other app. The pencil icon may be hidden under the ^ arrow by the clock. On another computer they run this command there too. If the report has the line `Claude app: Microsoft Store version`, add: "Because Claude came from the Microsoft Store, the helper won't appear in Settings > Apps; remove it with /simple-drawing-pad:uninstall." If it only says that the program is not listed in Windows Settings > Apps, add: "The helper isn't listed in Settings > Apps on this computer; remove it with /simple-drawing-pad:uninstall."
   - `shortcut-taken`: another program owns the shortcut, so it does not open the window yet; right-click the Simple Drawing Pad pencil icon by the clock (it may be hidden under the ^ arrow) and choose "Change shortcut".
   - anything else: say what the check says to do.

If the installer says a Simple Drawing Pad window is open, ask the user to close it (the drawing window with Enter or Esc) and run the command again.
