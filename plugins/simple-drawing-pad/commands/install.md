---
description: Install the Simple Drawing Pad window on Windows (Ctrl+Alt+D opens it, Enter copies, Ctrl+V pastes)
---

Install the Simple Drawing Pad pen window on this Windows computer. The user asked for it by running this command.

1. If this is not Windows, say that the pen window is Windows-only and offer the offline browser board from the `draw` skill instead. Stop there.
2. Run this one PowerShell command. It builds the program from the included source with the C# compiler that ships with Windows (nothing is downloaded, no admin rights), installs it to `%LOCALAPPDATA%\Programs\simple-drawing-pad`, starts the shortcut helper (tray icon) and adds a per-user autostart entry so the shortcut also works after a restart:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Autostart`

3. Tell the user in one or two sentences that it is installed: press the shortcut the installer names (Ctrl+Alt+D by default) to open the drawing window, Enter copies the drawing to the clipboard, Ctrl+V pastes it (for example in the chat). `/simple-drawing-pad:uninstall` removes it again. The program is installed on this computer only; on another computer they run this command there too.

If the installer prints a WARNING that the shortcut is taken by another program, say so instead: the shortcut does not work until they right-click the Simple Drawing Pad icon in the notification area and choose "Change shortcut" ("Zmień skrót" in Polish Windows).

If the installer says the drawing window is open, ask the user to close it (Enter or Esc) and run the command again.

If you cannot run commands on the user's computer directly (for example you work from the cloud and reach the computer through the Claude app), ask the user for a new, empty folder for the installer, such as `C:\Users\<name>\simple-drawing-pad` (not Downloads, so you get no access to their other files). Copy the plugin's `app` folder there and run its `install.ps1 -Autostart`.
