---
name: safe-device-work
description: Safety rules for work that can change or destroy data on real hardware or accounts - disks, USB sticks, partitions, NAS and RAID, microcontroller flash (ESP32, Arduino, etc.), admin or root sessions, installers and downloads, passwords, purchases and terms. Use before formatting, partitioning, flashing, deleting, rebuilding RAID, installing software, or testing code that touches storage, and whenever an admin or root account is in use.
---

# Safe work on devices, disks and accounts

These rules apply in every tool (shells, browsers, SSH, flashing tools, installers) and take priority over speed or convenience. They exist because a "dry run" can be real: on Windows, storage cmdlets do not reliably honour `-WhatIf`, and a normal user can format removable media.

## 1. Never test destructive code on real devices
- Never run format, wipe, partition or raw-write commands (`Format-Volume`, `Clear-Disk`, `Remove-Partition`, `Initialize-Disk`, `diskpart`, `mkfs`, `wipefs`, `dd of=/dev/...`, `fdisk`, `parted` and similar) against the user's real disks or USB sticks while testing, even with `-WhatIf`, "dry run" flags or without admin rights.
- Test such code only by: parsing the generated script without running it, printing the commands instead of executing them, guard checks that stop before any command, or a throw-away disk image the test itself creates (VHD/VHDX, loop device, temp file).
- A "dry run" feature must only print what it would do; never rely on `-WhatIf` alone.

## 2. Admin access is not permission to destroy
An admin or root session is for diagnosis and approved setup work.
- Ask explicitly, per action, before: deleting files, emptying trash or recycle bins, removing configuration that holds user data, formatting, repartitioning, RAID rebuild or repair, assigning a spare disk, factory resets.
- Fine without asking: read-only diagnosis; moving or renaming with an undo log; steps the user already approved one by one.
- Prefer copy over move, move over delete, hide or disable over remove.
- Do not use mirror or sync modes that delete at the destination (`robocopy /MIR`, `rsync --delete`) unless the user asked for exactly that.

## 3. Microcontrollers and firmware
- Before the first write to a board: back up its full flash (for ESP32/ESP8266: `esptool read-flash 0 <size> backup.bin`), note the SHA-256, and get the user's OK.
- Ask before opening a serial port; identify the board (chip, MAC) before writing, especially when several boards share the same USB-serial chip.
- Over-the-air updates also need the user's OK for that specific update.
- Do not reset a board in quick succession; firmware such as ESPHome falls back to safe mode after repeated reboots.

## 4. NAS and RAID
- System, user, permission and service changes on a NAS are the user's to make; give exact steps instead.
- A degraded array has no redundancy: do not start rebuilds, scrubs or heavy scans without the user's go-ahead, and suggest a backup first.
- Avoid needlessly waking sleeping drives: prefer status queries that do not spin disks up (for example `hdparm -C`, `smartctl -n standby`).

## 5. Passwords, purchases, agreements
- Never type, read, print, store or reuse passwords, tokens or API keys, including saved browser logins and ones pasted in chat. If one is pasted, do not use it, say it is now in the conversation history, and suggest changing it. The user logs in themselves.
- Never buy anything, start subscriptions or trials, or accept terms, licences or consent on the user's behalf.
- Downloads and installs: ask per file (name, source, size), even from well-known sites.

## When unsure
Stop, describe exactly what would run and on which device, and ask. A short delay costs nothing; a formatted disk cannot be undone.
