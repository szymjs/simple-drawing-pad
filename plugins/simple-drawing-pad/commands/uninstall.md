---
description: Remove the Simple Drawing Pad window from Windows (drawings are kept)
---

Remove the Simple Drawing Pad pen window from this Windows computer. The user asked for it by running this command.

1. Run this one PowerShell command. It stops the shortcut helper, removes the program from `%LOCALAPPDATA%\Programs\simple-drawing-pad` and removes its autostart entry. The user's drawings in `Pictures\simple-drawing-pad` and the shortcut setting are kept:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Uninstall`

2. Tell the user in one or two sentences that it is removed, that their drawings are kept, and that the plugin no longer reminds them at session start on this computer (until they run `/simple-drawing-pad:install` again). If the installer says the drawing window is open, ask them to close it (Enter or Esc) and run the command again.
