<p align="center">
  <img src="BACustomScreenGuard_preview.png" alt="BA Custom ScreenGuard" width="150">
</p>

<h1 align="center">BA Custom ScreenGuard</h1>

<p align="center">
  <strong>Click Blocker, Program Watchdog & Auto-Recovery Tool</strong><br>
  Built by <a href="mailto:bacustomproducts@gmail.com">BA Custom Products</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/platform-Windows-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/AutoHotkey-v1.1-green" alt="AutoHotkey">
  <img src="https://img.shields.io/badge/license-MIT-orange" alt="License">
</p>

---

## What It Does

BA Custom ScreenGuard is a lightweight Windows utility designed for **kiosk environments, simulator stations, and unattended PCs** where you need to prevent users from closing critical programs or clicking areas they shouldn't.

It was originally built for golf simulator facilities where customers would accidentally (or intentionally) close the simulator software, requiring staff to walk over and restart everything. ScreenGuard eliminates that problem entirely.

---

## Features

### Click Blocking
- Define up to **4 rectangular zones** on screen where clicks are blocked
- Capture zones by clicking two opposite corners — works over any window
- Customizable warning message appears when a blocked click is attempted
- Uses raw screen coordinates — completely independent of which application is in front

### Program Watchdog
- Monitors any `.exe` process every 2 seconds
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
- **Hidden configuration** — settings stored in `%AppData%\BA Custom Products\ScreenGuard\` where customers never see them
- Closing the window while protection is active **hides to tray** instead of exiting

---

## Installation

### Option 1: Run the Script Directly
1. Install [AutoHotkey v1.1](https://www.autohotkey.com/)
2. Download `BACustomScreenGuard.ahk`
3. Double-click to run

### Option 2: Compile to Standalone .exe (Recommended)
1. Install [AutoHotkey v1.1](https://www.autohotkey.com/)
2. Open **Ahk2Exe** from your Start Menu
3. Set **Source** to `BACustomScreenGuard.ahk`
4. Set **Custom Icon** to `BACustomScreenGuard.ico`
5. Click **Convert**
6. Deploy the resulting `.exe` to any Windows PC — no AutoHotkey install required on target machines

The `.exe` is fully self-contained. The icon is embedded and all code is baked in. One file is all you need.

> **Note:** The compiled `.ahk` files include `@Ahk2Exe` directives that automatically set the product name, company name, version, and description in the `.exe` file properties.

---

## Usage

### Quick Start
1. **Block Zones** — Go to the Block Zones tab and click Capture for each area you want to block (like close buttons). Click two opposite corners to define the rectangle.
2. **Watchdog** — Go to the Watchdog tab, click Browse to select the `.exe` you want to keep running, set the relaunch delay, and check Enable Watchdog.
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
1. Copy `BACustomScreenGuard.exe` to a permanent location (e.g. `C:\TURF\`)
2. Run the `.exe` and configure your block zones, watchdog program, and click sequence
3. Go to the **Settings** tab:
   - Check **Start protection automatically**
   - Check **Run silently on startup**
   - Click **Add to Windows Startup**
4. Click **Start Protection** to verify everything works
5. Reboot the PC to confirm it starts silently and protection activates automatically

### Windows Defender Exclusion
Compiled AutoHotkey scripts use mouse hooks which Windows Defender may flag as suspicious. This is a false positive. Add an exclusion before deploying:

```powershell
# Run as Administrator
Add-MpPreference -ExclusionPath "C:\TURF\BACustomScreenGuard.exe"
```

Or manually: **Windows Security** > **Virus & threat protection** > **Manage settings** > **Exclusions** > **Add or remove exclusions** > add the `.exe` file or its folder.

---

## Configuration

Settings are stored automatically in:
```
%AppData%\BA Custom Products\ScreenGuard\config.ini
```

This is the standard Windows location for application settings. The file is created automatically on first use and updated every time a setting changes. Users never need to interact with it directly.

To reset all settings, delete the `config.ini` file or the entire `ScreenGuard` folder in AppData.

---

## Technical Details

| Detail | Info |
|---|---|
| Platform | Windows 7 / 8 / 10 / 11 |
| Language | AutoHotkey v1.1 |
| Architecture | 32-bit (runs on both 32 and 64-bit Windows) |
| Dependencies | None (standalone `.exe`) |
| Config Location | `%AppData%\BA Custom Products\ScreenGuard\` |
| Click Blocking Method | `#If` context-sensitive hotkeys (no mouse state desync) |
| Coordinate System | `CoordMode Screen` — raw screen pixels, window-independent |
| Resolution Handling | Percentage-based per monitor with live recalculation |
| Watchdog Interval | 2 seconds |

---

## Repository Contents

```
BACustomScreenGuard.ahk        # Source script
BACustomScreenGuard.ico         # Application icon (multi-size: 16-256px)
BACustomScreenGuard_preview.png # Icon preview image
README.md                       # This file
LICENSE                         # License file
```

---

## About BA Custom Products

BA Custom Products builds **white-label software and hardware solutions for golf simulator facilities**. Our products include booking systems, league trackers, and hardware bundles — all designed to be self-hosted so facilities own their data without monthly SaaS fees.

**Contact:**
- Email: [bacustomproducts@gmail.com](mailto:bacustomproducts@gmail.com)
- Phone: (218) 684-3290

---

## License

MIT License — see [LICENSE](LICENSE) for details.
