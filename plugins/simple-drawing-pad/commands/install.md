---
description: Install the Simple Drawing Pad helper on this Windows computer, from the Microsoft Store (recommended) or built from the included source (argument local); Ctrl+Alt+D opens the drawing window, Enter copies, Ctrl+V pastes
---

Install the Simple Drawing Pad helper program on this Windows computer. The user asked for it by running this command (or by agreeing to the one-time question at session start), so do not ask again whether to install. There are two ways to the same program: the **Microsoft Store version** (the default: signed by Microsoft, installed and updated by Windows) and the **local build** (the argument `local`, or when the Store cannot be used: the program is built on this PC from the plugin's included source). Arguments given: $ARGUMENTS

`${CLAUDE_PLUGIN_ROOT}` below is the plugin folder (the one that holds `app` and `skills`). If it was not filled in for you, write that absolute path in its place; never leave `${CLAUDE_PLUGIN_ROOT}` in a PowerShell command, where it would be an empty variable.

1. If you cannot run commands on the user's own computer directly (claude.ai, the Claude mobile app, Claude Code on the web or another cloud session), do not install anything onto it yourself. Say that the helper is installed from Claude Code on that PC, or by the user from the Microsoft Store (https://apps.microsoft.com/detail/9NGDN0TGNRKC), and offer the browser board of the `draw` skill, published as an artifact, for drawing now. Stop there.
2. If the user's own computer, the one you run on, is not Windows, say that the pen window is Windows-only and offer the offline browser board from the `draw` skill instead. Stop there.
3. If the user has not seen it in this conversation (the session-start question counts), say in two or three sentences what is installed: a small helper program that works only on this computer (no network, it sends and collects nothing), shows a pencil icon by the clock and opens the drawing window with Ctrl+Alt+D, a shortcut that works in every program (if it clashes with a character on their keyboard layout, they change it from the icon's menu); it starts with Windows, keeps everything in one folder, `%USERPROFILE%\simple-drawing-pad`, where it keeps only the last drawing, `latest.png`, until the next one, and can be removed in Windows Settings > Apps or with `/simple-drawing-pad:uninstall`. The Store version is installed by Windows and signed by Microsoft; the local build is made from `app\SimpleDrawingPad.cs` by the C# compiler that is part of Windows (nothing downloaded, no administrator rights; Windows may block an unsigned program). If they have seen it, do not explain again.
4. Before the first PowerShell command in this session, say once: "Claude will ask you to allow a PowerShell command; `-ExecutionPolicy Bypass` applies only to this command and changes no settings."
5. Check what is there already (this changes nothing):

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/status.ps1"`

   If its last line says `ready` and the user did not ask for `local`, tell them it already works (step 8) and stop. Its `Program:` line says whether the Store version, a local build, or a program of an earlier plugin version is installed.

6. **Store version** (the default, unless the user asked for `local`):
   - If the `Program:` line names a local build or an earlier version, say that one helper runs at a time and that the Store version updates itself, and ask whether to remove that program first; on yes, run `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Uninstall` (the drawings stay). On no, go on; the local program keeps running until the next restart.
   - Say that winget accepts the Microsoft Store source terms for the user (Windows asks that once per computer), then run:

     `winget install --id 9NGDN0TGNRKC --source msstore --accept-source-agreements --accept-package-agreements`

   - If `winget` is not found or the install fails (no Store on this account, a work or school account, the Store blocked), open the Store page and ask the user to click Install there: `powershell -NoProfile -Command "Start-Process 'ms-windows-store://pdp/?productid=9NGDN0TGNRKC'"`, or give them the link https://apps.microsoft.com/detail/9NGDN0TGNRKC. Wait until they say it is installed. If the Store cannot be used on this computer at all, offer the local build (step 7) or the browser board.
   - Ask the user to open Simple Drawing Pad from the Start menu once: the pencil icon appears by the clock (the drawing window too, from program version 0.9.9), and from then on it also starts with Windows. Wait until they say so.

7. **Local build** (the argument `local`, or when the Store cannot be used). Run this one PowerShell command. It builds the program with the C# compiler that ships with Windows, installs it to `%USERPROFILE%\simple-drawing-pad\app`, starts the helper, creates the shortcut `Simple Drawing Pad.lnk` in the user's Startup folder so the helper also starts after a restart, and lists the program in Windows Settings > Apps for this user. An install over 0.5.1 to 0.7.9 stops the old helper, removes the old program from `%LOCALAPPDATA%\Programs\simple-drawing-pad` and its autostart value, and copies the shortcut setting from `%APPDATA%\simple-drawing-pad` (the old file stays); drawings of the old version stay in `%LOCALAPPDATA%\simple-drawing-pad\drawings`:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/install.ps1" -Autostart`

   In the Microsoft Store version of the Claude app this works the same way: after a restart Windows starts the helper from the Startup shortcut, before Claude is opened. Only the Settings > Apps entry is not shown for an install made from inside the Store app, because that app's sandbox keeps registry entries to itself. If the Store version of the helper is installed as well, say that one helper runs at a time: whichever starts first after a restart is the one that runs.

8. Check that it works (if the local installer's output already ends with a line `Result: <state>: <what to do>`, use it and skip this step):

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/app/status.ps1"`

   Tell the user the result in one or two sentences, following the last line, `Result: <state>: <what to do>`:
   - `ready`: it works. Press the shortcut it names (Ctrl+Alt+D by default) to open the drawing window, Enter copies the drawing to the clipboard, Ctrl+V pastes it in the chat or in any other app. The pencil icon may be hidden under the ^ arrow by the clock. On another computer they run this command there too. If the report says that a local build is not listed in Windows Settings > Apps, add: "The helper isn't listed in Settings > Apps on this computer; remove it with /simple-drawing-pad:uninstall."
   - `shortcut-taken`: another program owns the shortcut, so it does not open the window yet; right-click the Simple Drawing Pad pencil icon by the clock (it may be hidden under the ^ arrow) and choose "Change shortcut".
   - anything else: say what the check says to do. If Windows blocks the locally built helper ("An application control policy has blocked this file", which Smart App Control does to a program that has no publisher signature), install the Store version instead, or use the browser board: it needs no program.

If the local installer says a Simple Drawing Pad window is open, ask the user to close it (the drawing window with Enter or Esc) and run the command again.
