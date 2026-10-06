---
description: Remove the Simple Drawing Pad helper from this Windows computer (drawings are kept)
---

Remove the Simple Drawing Pad helper program from this Windows computer. The user asked for it by running this command.

1. Run this one PowerShell command. It stops the helper, removes the program from `%LOCALAPPDATA%\Programs\simple-drawing-pad` and removes its autostart entry and its entry in Windows Settings > Apps. The user's drawings in `%LOCALAPPDATA%\simple-drawing-pad\drawings` (older ones in `Pictures\simple-drawing-pad`) and the shortcut setting are kept:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Uninstall`

2. Tell the user in one or two sentences that it is removed, that their drawings are kept, and that the plugin will not ask about it again on this computer (`/simple-drawing-pad:install` installs it again). Without Claude, the same removal is in Windows Settings > Apps > Simple Drawing Pad > Uninstall. If it says a Simple Drawing Pad window is open, ask them to close it (the drawing window with Enter or Esc) and run the command again.
