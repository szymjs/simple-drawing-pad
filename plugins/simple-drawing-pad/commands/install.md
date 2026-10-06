---
description: Install the Simple Drawing Pad helper on this Windows computer (local only; Ctrl+Alt+D opens the drawing window, Enter copies, Ctrl+V pastes)
---

Install the Simple Drawing Pad helper program on this Windows computer. The user asked for it by running this command (or by agreeing to the one-time question at session start), so do not ask again.

1. If this is not Windows, say that the pen window is Windows-only and offer the offline browser board from the `draw` skill instead. Stop there.
2. If the user has not seen it in this conversation, say in one or two sentences what is installed: a small helper program that works only on this computer (no network, it sends and collects nothing), shows a pencil icon by the clock and opens the drawing window with Ctrl+Alt+D; it is built from the plugin's included source (nothing is downloaded, no administrator rights), starts with Windows, keeps the last 10 drawings in `%LOCALAPPDATA%\simple-drawing-pad`, and can be removed in Windows Settings > Apps or with `/simple-drawing-pad:uninstall`.
3. Run this one PowerShell command. It builds the program with the C# compiler that ships with Windows, installs it to `%LOCALAPPDATA%\Programs\simple-drawing-pad`, starts the helper, adds a per-user autostart entry so the shortcut also works after a restart, and lists the program in Windows Settings > Apps (for this user only) so it can be removed there too:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Autostart`

4. Check that it works with:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/status.ps1"`

5. Tell the user the result in one or two sentences, following the check's last line:
   - `ready`: it works. Press the shortcut it names (Ctrl+Alt+D by default) to open the drawing window, Enter copies the drawing to the clipboard, Ctrl+V pastes it in the chat or in any other app. On another computer they run this command there too.
   - `shortcut-taken`: another program owns the shortcut, so it does not open the window yet; right-click the Simple Drawing Pad icon in the notification area and choose "Change shortcut".
   - anything else: say what the check says to do.

If the installer says a Simple Drawing Pad window is open, ask the user to close it (the drawing window with Enter or Esc) and run the command again.

If you cannot run commands on the user's computer directly (for example you work from the cloud), do not write the installer onto it yourself. Ask the user to run `/simple-drawing-pad:install` in Claude Code on that computer.
