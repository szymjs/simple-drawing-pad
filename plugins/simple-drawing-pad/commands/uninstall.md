---
description: Remove the Simple Drawing Pad helper from this Windows computer, the Microsoft Store version and the local build alike (drawings are kept)
---

Remove the Simple Drawing Pad helper program from this Windows computer. The user asked for it by running this command.

`${CLAUDE_PLUGIN_ROOT}` below is the plugin folder (the one that holds `app` and `skills`). If it was not filled in for you, write that absolute path in its place; never leave `${CLAUDE_PLUGIN_ROOT}` in a PowerShell command, where it would be an empty variable. If you cannot run commands on the user's Windows computer (claude.ai, the Claude mobile app, a cloud session), say that the Store version is removed in Windows Settings > Apps > Simple Drawing Pad, and a local build from Claude Code on that PC with this command or with the copy of `uninstall.ps1` in `%USERPROFILE%\simple-drawing-pad\app`; stop there.

1. See what is installed (this changes nothing); its `Program:` line names the Microsoft Store version, a local build, a program of an earlier plugin version, or several of them:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/status.ps1"`

2. If the Store version is installed, remove that one package (it stops its helper too):

   `powershell -NoProfile -Command "Get-AppxPackage -Name SzymonStanszewski.SimpleDrawingPad | Remove-AppxPackage"`

   If that fails, tell the user: Windows Settings > Apps > Installed apps > Simple Drawing Pad > Uninstall.

3. Run this one PowerShell command in every case. It stops a locally built helper and removes the program (`%USERPROFILE%\simple-drawing-pad\app`), the shortcut `Simple Drawing Pad.lnk` in the user's Startup folder, the autostart value and the old program folder `%LOCALAPPDATA%\Programs\simple-drawing-pad` (the program files of versions before 0.8.0) and the entry in Windows Settings > Apps, where present, and it notes that the helper was removed on purpose, so the plugin does not ask about it again on this computer. The user's drawings in `%USERPROFILE%\simple-drawing-pad\drawings` (and any older ones left in `%LOCALAPPDATA%\simple-drawing-pad\drawings` or `Pictures\simple-drawing-pad`) and the shortcut setting `%USERPROFILE%\simple-drawing-pad\shortcut.txt` are kept:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Uninstall`

4. Tell the user in one or two sentences that it is removed, that their drawings are kept, and that the plugin will not ask about it again on this computer (`/simple-drawing-pad:install` installs it again). Without Claude: the Store version is removed in Windows Settings > Apps > Simple Drawing Pad > Uninstall; a local build with the Uninstall button of its own entry there, when Windows shows it (it does not for an install made from the Microsoft Store version of the Claude app, whose sandbox keeps registry entries to itself; the Startup shortcut and the program folder are real there and this command removes them), or with the copy of `uninstall.ps1` in `%USERPROFILE%\simple-drawing-pad\app`, run with PowerShell. If it says a Simple Drawing Pad window is open, ask them to close it (the drawing window with Enter or Esc) and run the command again.
