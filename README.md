<p align="center">
  <img src="BACustomScreenGuard_preview.png" alt="BA Custom ScreenGuard" width="150">
</p>

<h1 align="center">BA Custom ScreenGuard</h1>

<p align="center">
  <strong>Click Blocker, Program Watchdog & Auto-Recovery Tool for Windows</strong><br>
  Built by <a href="mailto:bacustomproducts@gmail.com">BA Custom Products</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/platform-Windows-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/license-MIT-orange" alt="License">
</p>

---

## What It Does

BA Custom ScreenGuard is a lightweight Windows utility designed for **kiosk environments, simulator stations, and unattended PCs** where you need to prevent users from closing critical programs or clicking areas they shouldn't.

It was originally built for golf simulator facilities where customers would accidentally (or intentionally) close the simulator software, requiring staff to walk over and restart everything. ScreenGuard eliminates that problem entirely.

---

## Download

Head to the [**Releases**](../../releases) page and download the latest `BACustomScreenGuard.exe`.

One file. No installation required. Just run it.

---

## Features

### Click Blocking
- Define up to **4 rectangular zones** on screen where clicks are blocked
- Capture zones by clicking two opposite corners — works over any window
- Customizable warning message appears when a blocked click is attempted
- Works regardless of which application is in front

### Program Watchdog
- Monitors any program every 2 seconds
- If the program is closed, ScreenGuard **immediately displays a recovery message**, relaunches the program, and replays your recorded click sequence to restore it to the correct screen
- Recovery message stays visible throughout the entire restore process

### Click Sequence Recorder
- Record a series of mouse clicks with **exact real-time delays** between them
- When the watchdog relaunches a program, the recorded clicks are replayed automatically with your original timing
- Lets you navigate the program back to the correct state hands-free

### Multi-Monitor Support
- Full support for **multiple monitors at different resolutions**
- Coordinates are stored as a **percentage of each monitor's dimensions**, not as absolute pixels
- If resolution changes or monitors are rearranged, positions recalculate automatically
- Each capture records which physical monitor it belongs to

### Silent Deployment
- **Auto-save** — all settings save automatically as you configure them
- **Auto-start protection** — optionally starts protecting immediately on launch
- **Silent startup** — optionally runs with no visible window (tray icon only)
- **One-click Windows Startup** — adds itself to the Windows Startup folder
- Settings stored where customers never see them
- Closing the window while protection is active **hides to tray** instead of exiting

---

## Usage

### Quick Start
1. **Block Zones** — Go to the Block Zones tab and click Capture for each area you want to block (like close buttons). Click two opposite corners to define the rectangle.
2. **Watchdog** — Go to the Watchdog tab, click Browse to select the program you want to keep running, set the relaunch delay, and check Enable Watchdog.
3. **Click Recorder** — Go to the Click Recorder tab and click Start Recording. Click through the steps needed to restore the program to the correct screen. Right-click or press Escape when done.
4. **Start Protection** — Click the Start Protection button. ScreenGuard minimizes to the system tray.

### Settings Tab
- **Start protection automatically** — Protection activates as soon as ScreenGuard launches
- **Run silently on startup** — No window appears; runs as a tray icon only
- **Add to Windows Startup** — One click to add/remove from the Windows Startup folder

### System Tray
When running, ScreenGuard lives in the system tray (bottom-right of the taskbar near the clock). Right-click the icon to:
- **Show BA Custom ScreenGuard** — Open the settings window
- **Toggle Protection** — Turn protection on/off
- **Exit** — Fully close the application

Double-clicking the tray icon also opens the settings window.

---

## Deployment Guide

For deploying to kiosk PCs, simulator stations, or customer facilities:

### Setup Checklist
1. Copy `BACustomScreenGuard.exe` to a permanent location on the PC
2. Run the `.exe` and configure your block zones, watchdog program, and click sequence
3. Go to the **Settings** tab:
   - Check **Start protection automatically**
   - Check **Run silently on startup**
   - Click **Add to Windows Startup**
4. Click **Start Protection** to verify everything works
5. Reboot the PC to confirm it starts silently and protection activates automatically

### Windows Defender
Windows Defender may flag ScreenGuard on first run because it uses low-level mouse monitoring to block clicks. This is expected behavior — add an exclusion before deploying:

```powershell
# Run as Administrator - update the path to match your install location
Add-MpPreference -ExclusionPath "C:\YourFolder\BACustomScreenGuard.exe"
```

Or manually: **Windows Security** > **Virus & threat protection** > **Manage settings** > **Exclusions** > **Add or remove exclusions** > add the `.exe` file or its folder.

### Resetting Configuration
To reset all settings back to defaults, delete the configuration folder:
```
%AppData%\BA Custom Products\ScreenGuard\
```

---

## Requirements

| Detail | Info |
|---|---|
| Operating System | Windows 7 / 8 / 10 / 11 |
| Dependencies | None — single standalone `.exe` |
| Install Required | No |
| Admin Required | Only for the Windows Defender exclusion |

---

## About BA Custom Products

BA Custom Products builds **white-label software and hardware solutions for golf simulator facilities**. Our products include booking and session management systems, league trackers, and pre-configured hardware bundles — all designed to be self-hosted so facilities own their data without monthly SaaS fees.

**Get in touch:**
- Email: [bacustomproducts@gmail.com](mailto:bacustomproducts@gmail.com)
- Phone: (218) 684-3290

---

## License

MIT License — see [LICENSE](LICENSE) for details.

