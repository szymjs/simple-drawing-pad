# Microsoft Store package

The Microsoft Store version of the helper. It is the same program as the plugin installs, in an MSIX package that
Microsoft signs after certification. A program inside a Store-signed package is trusted by Windows features such as Smart
App Control, which blocks a program that has no publisher signature (the plugin's own install builds the program on the
user's PC, so its program has none).

- `AppxManifest.xml`: the package identity from Partner Center, the full-trust desktop app, and one startup task that
  starts the notification-area helper at sign-in (the user can turn it off in Settings > Apps > Startup).
- `Assets\`: the logos, scaled from the plugin icon.
- `build-msix.ps1`: builds the helper from the plugin's source and packs it into `out\SimpleDrawingPad_<version>_x64.msix`.
  It needs makeappx.exe (Windows SDK Build Tools): `.\build-msix.ps1 -MakeAppx "C:\path\to\makeappx.exe"`.

The plugin folder does not use any of this. The Store package is uploaded by hand in Partner Center and is not part of
what the plugin installs today.

## Notes for certification (restricted capability runFullTrust)

Simple Drawing Pad is a classic Win32 desktop program (.NET Framework). It runs with full trust because it registers a
global keyboard shortcut with RegisterHotKey (no keyboard hook, no keystrokes are read), loads the tablet driver's
Wintab32.dll from System32 for pen input, puts the finished drawing on the clipboard, and writes files under
%USERPROFILE%\simple-drawing-pad. It uses no network, never asks for elevation and starts no services. The startup task
starts the notification-area helper at sign-in; the user can turn it off in Settings.

## Store listing text

Short description:

Just draw and press Enter: paste the sketch into Claude or any app.

Description:

The simplest way to share an idea with Claude or any other app: make a quick sketch and paste it. Skip all the hassle: just draw and press Enter, simple as that. Press Ctrl+Alt+D to open a pop-up drawing window, draw with a pen, mouse or finger, press Enter to copy the drawing, then paste it with Ctrl+V. With a graphics tablet the whole tablet is the drawing area. Nothing is collected and nothing is sent anywhere: the drawing stays on this computer. It works with any app that accepts a pasted picture, and it is the companion of the Simple Drawing Pad plugin for Claude Code.

Copyright and trademark info:

(c) 2026 Szymon Stanszewski. Claude is a trademark of Anthropic. Simple Drawing Pad is not affiliated with or endorsed by Anthropic.
