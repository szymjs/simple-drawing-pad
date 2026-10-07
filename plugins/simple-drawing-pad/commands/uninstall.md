---
description: Remove the Simple Drawing Pad helper from this Windows computer (drawings are kept)
---

Remove the Simple Drawing Pad helper program from this Windows computer. The user asked for it by running this command.

1. Run this one PowerShell command. It stops the helper and removes the program (`%USERPROFILE%\simple-drawing-pad\app`), the shortcut `Simple Drawing Pad.lnk` in the user's Startup folder, the autostart value and the program files of versions before 0.8.0 (in `%LOCALAPPDATA%\Programs\simple-drawing-pad`) and the entry in Windows Settings > Apps. The user's drawings in `%USERPROFILE%\simple-drawing-pad\drawings` (and any older ones left in `%LOCALAPPDATA%\simple-drawing-pad\drawings` or `Pictures\simple-drawing-pad`) and the shortcut setting `%USERPROFILE%\simple-drawing-pad\shortcut.txt` are kept:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Uninstall`

2. Tell the user in one or two sentences that it is removed, that their drawings are kept, and that the plugin will not ask about it again on this computer (`/simple-drawing-pad:install` installs it again). Without Claude, the same removal is the Uninstall button in Windows Settings > Apps > Simple Drawing Pad when Windows shows that entry (it does not for an install made from the Microsoft Store version of the Claude app), or the copy of `uninstall.ps1` in `%USERPROFILE%\simple-drawing-pad\app`, run with PowerShell. If it says a Simple Drawing Pad window is open, ask them to close it (the drawing window with Enter or Esc) and run the command again.
