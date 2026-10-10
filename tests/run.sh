#!/bin/sh
# Builds the pen window program with Mono and runs the headless save test under a virtual display.
# Needs: mono-devel (mcs, System.Windows.Forms) and xvfb. On Debian/Ubuntu: apt-get install mono-devel xvfb
# The test's home folder is a temporary one, so nothing is written to the real %USERPROFILE%\simple-drawing-pad.
set -e
here=$(cd "$(dirname "$0")" && pwd)
app="$here/../plugins/simple-drawing-pad/app"
out=$(mktemp -d)
version=$(sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p' "$here/../plugins/simple-drawing-pad/.claude-plugin/plugin.json" | head -1)
printf '[assembly: System.Reflection.AssemblyVersion("%s")]\n' "$version" > "$out/AssemblyInfo.g.cs"
mcs -sdk:4.5 -target:winexe -platform:anycpu -optimize+ -codepage:65001 \
    -r:System.Windows.Forms.dll -r:System.Drawing.dll -out:"$out/SimpleDrawingPad.exe" "$app/SimpleDrawingPad.cs" "$out/AssemblyInfo.g.cs"
mcs -sdk:4.5 -r:System.Windows.Forms.dll -r:System.Drawing.dll -out:"$out/SaveTest.exe" "$here/SaveTest.cs"
mkdir -p "$out/home"
HOME="$out/home" xvfb-run -a -s "-screen 0 1920x1080x24" mono "$out/SaveTest.exe" "$out/SimpleDrawingPad.exe"
