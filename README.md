# BA Custom ScreenGuard

Click blocker, program watchdog, and auto-recovery tool for Windows. Built by BA Custom Products.

Built for golf simulator facilities and kiosk environments where you need to stop users from closing programs or clicking things they shouldn't. When someone closes a watched program, ScreenGuard relaunches it and clicks it back to the right screen automatically.

## Download

Grab the latest `.exe` from the [Releases](../../releases) page. One file, no install needed.

The full source code (`BACustomScreenGuard.ahk`) is included in this repo if you want to review it or modify it. It's an AutoHotkey v1.1 script. To compile your own `.exe`, right-click the `.ahk` file and choose "Compile Script" (requires AutoHotkey v1.1 installed).

## What It Does

**Click Blocking** — Define up to 4 rectangular zones on screen where clicks get blocked. Click two corners to set each zone. Works over any window on any monitor. Shows a customizable warning message when someone clicks a blocked area.

**Program Watchdog** — Monitors a program every 2 seconds. If it gets closed, a recovery message pops up immediately, the program gets relaunched, and your recorded click sequence replays to get it back to the right screen.

**Click Recorder** — Record a series of clicks with the exact timing between them. These replay automatically after the watchdog relaunches a program. If you waited 3 seconds between two clicks during recording, the playback waits 3 seconds too.

**Multi-Monitor** — Works with multiple monitors at different resolutions. Coordinates are stored as percentages of each monitor so everything recalculates if the resolution changes or monitors get rearranged.

**Silent Mode** — Can start protection automatically on launch with no visible window. Settings auto-save so nothing is lost on reboot. One-click button to add itself to Windows Startup. Closing the window while protected just hides to the system tray.

## Setup

1. Run `BACustomScreenGuard.exe`
2. **Block Zones tab** — Capture the areas you want to block (like close buttons)
3. **Watchdog tab** — Browse to the `.exe` you want to keep running, set a delay, enable it
4. **Click Recorder tab** — Record the clicks needed to navigate the program back after a relaunch
5. **Settings tab** — Check "Start protection automatically" and "Run silently" if you want hands-off operation. Click "Add to Windows Startup" if you want it to survive reboots.
6. Hit Start Protection

To open the settings window later, right-click the ScreenGuard icon in the system tray (bottom-right of taskbar near the clock).

## Windows Defender

Defender will probably flag this on first run because it hooks mouse input to block clicks. Add an exclusion:

```powershell
Add-MpPreference -ExclusionPath "C:\YourFolder\BACustomScreenGuard.exe"
```

Or do it manually through Windows Security > Virus & threat protection > Exclusions.

## Reset

Delete the config folder to start fresh:
```
%AppData%\BA Custom Products\ScreenGuard\
```

## BA Custom Products

We build white-label software and hardware for golf simulator facilities — booking systems, league trackers, and pre-configured hardware bundles. Self-hosted, no monthly fees.

bacustomproducts@gmail.com | (218) 684-3290

