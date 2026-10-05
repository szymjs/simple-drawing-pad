---
description: Remove the Simple Drawing Pad window from Windows (drawings are kept)
---

Remove the Simple Drawing Pad pen window from this Windows computer. The user asked for it by running this command.

1. Run this one PowerShell command. It stops the shortcut helper, removes the program from `%LOCALAPPDATA%\Programs\simple-drawing-pad` and removes its autostart entry. The user's drawings in `Pictures\simple-drawing-pad` and the shortcut setting are kept:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Uninstall`

2. Tell the user in one sentence that it is removed and that their drawings are kept. If the installer says the drawing window is open, ask them to close it (Enter or Esc) and run the command again.
