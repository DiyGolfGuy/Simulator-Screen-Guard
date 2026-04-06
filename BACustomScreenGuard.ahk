; ============================================================================
;  BA Custom ScreenGuard v1.0
;  by BA Custom Products
; ----------------------------------------------------------------------------
;  TO COMPILE TO .EXE:
;    1. Install AutoHotkey v1.1 from https://www.autohotkey.com/
;    2. Open Ahk2Exe from Start Menu (or right-click -> Compile)
;    3. Source: this .ahk file
;    4. Custom Icon: BACustomScreenGuard.ico (included)
;    5. Click Convert - your .exe is ready to deploy
; ============================================================================

;@Ahk2Exe-SetName BA Custom ScreenGuard
;@Ahk2Exe-SetDescription BA Custom ScreenGuard - Click Blocker and Watchdog
;@Ahk2Exe-SetVersion 1.0.0
;@Ahk2Exe-SetCompanyName BA Custom Products
;@Ahk2Exe-SetCopyright (c) 2025 BA Custom Products
;@Ahk2Exe-SetOrigFilename BACustomScreenGuard.exe

#NoEnv
#SingleInstance Force
#Persistent
#InstallMouseHook
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

; ======================== GLOBALS ========================

AppName := "BA Custom ScreenGuard"
AppVersion := "v1.0"

MAX_ZONES := 4
BlockedZones := []
ClickSequence := []
BlockMessage := "Don't close this!"
WatchdogExePath := ""
WatchdogProcessName := ""
WatchdogDelay := 3000
ReopenMessage := "Please don't close this program again!"
IsProtecting := false
IsCapturingZone := false
CaptureZoneIndex := 0
CaptureCorner := 0
TempCornerX := 0
TempCornerY := 0
IsRecordingClicks := false
LastClickTime := 0
WatchdogEnabled := false
AutoProtect := false
SilentStart := false

; Config in AppData under BA Custom Products
ConfigDir := A_AppData . "\BA Custom Products\ScreenGuard"
ConfigFile := ConfigDir . "\config.ini"
FileCreateDir, %ConfigDir%

Loop, %MAX_ZONES% {
    BlockedZones.Push("")
}

GoSub, DoLoadConfig

; ======================== STARTUP LOGIC ========================

if (AutoProtect && SilentStart) {
    GoSub, BuildGUI_Hidden
    GoSub, DoStartProtection
    TrayTip, %AppName%, Running in the background with protection active.`nRight-click this icon to open settings., 5, 1
    goto SkipGUIShow
} else if (AutoProtect) {
    GoSub, BuildGUI_Visible
    GoSub, DoStartProtection
    goto SkipGUIShow
} else {
    GoSub, BuildGUI_Visible
    goto SkipGUIShow
}

SkipGUIShow:
return

; ======================== BUILD GUI ========================

BuildGUI_Hidden:
    GoSub, DoBuildGUI
return

BuildGUI_Visible:
    GoSub, DoBuildGUI
    Gui, Main:Show, w680 AutoSize Center, %AppName% %AppVersion%
return

DoBuildGUI:
    guiTitle := AppName . " " . AppVersion
    Gui, Main:New, -MaximizeBox, %guiTitle%
    Gui, Main:Default
    Gui, Main:Color, F0F0F0, FFFFFF
    Gui, Main:Margin, 12, 8

    ; --- BA Custom Products Header ---
    Gui, Font, s14 Bold c122040, Segoe UI
    Gui, Add, Text, x12 y10 w400, BA Custom ScreenGuard
    Gui, Font, s9 Normal c888888, Segoe UI
    Gui, Add, Text, x12 y+1 w400, by BA Custom Products
    Gui, Font, s8 Normal cAAAAAA, Segoe UI
    Gui, Add, Text, x430 y10 w240 Right, bacustomproducts@gmail.com
    Gui, Add, Text, x430 y+1 w240 Right, www.bacustomproducts.com

    Gui, Add, Text, x12 y+6 w656 h1 0x10

    ; --- Monitor Info ---
    Gui, Font, s9 Bold c2563EB, Segoe UI
    Gui, Add, Text, x12 y+6 w300, DETECTED MONITORS
    Gui, Font, s9 Normal c555555, Segoe UI
    GoSub, BuildMonitorText
    Gui, Add, Text, x12 y+2 w656 vTxtMonitorInfo, %MonitorInfoText%
    Gui, Font, s8 Normal c999999, Segoe UI
    Gui, Add, Text, x12 y+1 w656, Different resolutions per monitor fully supported.

    Gui, Add, Text, x12 y+6 w656 h1 0x10

    ; --- Tabs ---
    Gui, Font, s10 Normal c333333, Segoe UI
    Gui, Add, Tab2, x8 y+4 w664 h460 vMainTabs, Block Zones|Watchdog|Click Recorder|Settings

    ; ================================================================
    ;  TAB 1 - BLOCK ZONES
    ; ================================================================
    Gui, Tab, 1

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+8 w636 h50, How It Works
    Gui, Font, s9 Normal c666666, Segoe UI
    howZoneText := "Click Capture then click two opposite corners on your screen to block a rectangular area. Any click inside will be blocked. Works over any window on any monitor."
    Gui, Add, Text, xp+10 yp+18 w614, %howZoneText%

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+12 w636 h175, Blocked Zones (up to 4 rectangles)
    Gui, Font, s9 Normal c333333, Segoe UI

    Loop, %MAX_ZONES% {
        idx := A_Index
        if (A_Index = 1)
            yPos := "yp+22"
        else
            yPos := "y+8"
        zoneLabel := GetZoneLabel(idx)
        Gui, Add, Text, x32 %yPos% w400 vTxtZone%idx%, %zoneLabel%
        Gui, Add, Button, x450 yp-3 w95 h24 gCaptureZone vBtnCapture%idx%, Capture %idx%
        Gui, Add, Button, x550 yp w95 h24 gClearZone vBtnClear%idx%, Clear %idx%
    }

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+18 w636 h68, Warning Message
    Gui, Font, s9 Normal c666666, Segoe UI
    Gui, Add, Text, xp+10 yp+18 w300, Shown when a blocked click is attempted:
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x30 y+4 w614 h22 vEditBlockMsg, %BlockMessage%

    ; ================================================================
    ;  TAB 2 - WATCHDOG
    ; ================================================================
    Gui, Tab, 2

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+8 w636 h55, How It Works
    Gui, Font, s9 Normal c666666, Segoe UI
    howWatchText := "Checks every 2 seconds if your program is running. If someone closes it the recovery message appears immediately then the program is relaunched and your recorded clicks are replayed."
    Gui, Add, Text, xp+10 yp+18 w614, %howWatchText%

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+12 w636 h92, Program to Monitor
    Gui, Font, s9 Normal c666666, Segoe UI
    browseHelp := "Browse to the .exe of the program you want to keep running. Example: C:\Program Files\GSPro\GSPro.exe"
    Gui, Add, Text, xp+10 yp+18 w614, %browseHelp%
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x30 y+6 w500 h22 vEditWatchdogPath ReadOnly, %WatchdogExePath%
    Gui, Add, Button, x536 yp-1 w110 h24 gBrowseExe, Browse...

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+12 w636 h140, Watchdog Settings
    Gui, Font, s9 Normal c666666, Segoe UI

    Gui, Add, Text, xp+10 yp+22 w400, Delay after relaunch before auto-clicks (milliseconds):
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x30 y+4 w90 h22 vEditWatchdogDelay Number, %WatchdogDelay%
    Gui, Add, UpDown, Range500-60000, %WatchdogDelay%
    Gui, Font, s8 Normal c888888, Segoe UI
    Gui, Add, Text, x128 yp+3, Give the program enough time to fully load

    Gui, Font, s9 Normal c666666, Segoe UI
    Gui, Add, Text, x30 y+10 w400, Recovery message (shown while restoring):
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x30 y+4 w614 h22 vEditReopenMsg, %ReopenMessage%

    Gui, Font, s10 Bold c2563EB, Segoe UI
    Gui, Add, CheckBox, x30 y+14 vChkWatchdog gToggleWatchdog Checked%WatchdogEnabled%, Enable Watchdog Monitoring
    Gui, Font, s9 Normal c333333, Segoe UI

    ; ================================================================
    ;  TAB 3 - CLICK RECORDER
    ; ================================================================
    Gui, Tab, 3

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+8 w636 h65, How It Works
    Gui, Font, s9 Normal c666666, Segoe UI
    howClickText := "Record mouse clicks that replay after the watchdog relaunches a program. The EXACT timing between your clicks is recorded automatically so the playback matches your real pace."
    Gui, Add, Text, xp+10 yp+18 w614, %howClickText%

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+12 w636 h50, Record Controls
    Gui, Font, s9 Normal c333333, Segoe UI

    Gui, Add, Button, xp+10 yp+20 w140 h26 gStartRecording vBtnRecord, Start Recording
    Gui, Add, Button, x+8 yp w140 h26 gClearSequence, Clear All Clicks
    Gui, Add, Button, x+8 yp w140 h26 gTestSequence, Test Playback
    Gui, Font, s8 Normal c888888, Segoe UI
    Gui, Add, Text, x+10 yp+5, Right-click or Esc to stop

    Gui, Font, s10 Bold c333333, Segoe UI
    seqLabel := "Recorded Clicks: " . ClickSequence.Length()
    Gui, Add, Text, x20 y+14 w300 vTxtSeqCount, %seqLabel%

    Gui, Font, s9 Normal c333333, Consolas
    Gui, Add, Edit, x20 y+4 w636 h200 ReadOnly vEditSeqDetails HScroll,
    GoSub, DoUpdateSeqDetails

    ; ================================================================
    ;  TAB 4 - SETTINGS
    ; ================================================================
    Gui, Tab, 4

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+8 w636 h145, Startup Options
    Gui, Font, s9 Normal c333333, Segoe UI

    Gui, Add, CheckBox, xp+10 yp+22 vChkAutoProtect gOnSettingChange Checked%AutoProtect%, Start protection automatically when BA Custom ScreenGuard opens
    Gui, Font, s8 Normal c888888, Segoe UI
    Gui, Add, Text, x42 y+2 w600, Protection starts immediately on launch. No need to click anything.

    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, CheckBox, x30 y+12 vChkSilentStart gOnSettingChange Checked%SilentStart%, Run silently on startup (no window - tray icon only)
    Gui, Font, s8 Normal c888888, Segoe UI
    silentHelp := "No window appears on launch. To open settings later right-click the BA Custom ScreenGuard icon in the bottom-right system tray area of your taskbar (near the clock)."
    Gui, Add, Text, x42 y+2 w600, %silentHelp%

    ; Startup folder
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+16 w636 h90, Windows Startup
    Gui, Font, s9 Normal c666666, Segoe UI
    startupHelp := "Add to Windows startup so it runs automatically every time the computer turns on. Combined with the options above this gives full hands-off protection after every reboot."
    Gui, Add, Text, xp+10 yp+20 w614, %startupHelp%
    Gui, Font, s9 Normal c333333, Segoe UI

    startupLink := A_Startup . "\BA Custom ScreenGuard.lnk"
    if (FileExist(startupLink))
        startupBtnText := "Remove from Windows Startup"
    else
        startupBtnText := "Add to Windows Startup"
    Gui, Add, Button, x30 y+6 w220 h26 gToggleStartup vBtnStartup, %startupBtnText%
    Gui, Add, Text, x258 yp+5 w380 vTxtStartupStatus c888888,
    GoSub, UpdateStartupStatus

    ; How to access
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y+16 w636 h70, How to Open This Window
    Gui, Font, s9 Normal c333333, Segoe UI
    trayHelp := "If running silently find the BA Custom ScreenGuard icon in your system tray (bottom-right corner of taskbar near the clock). Right-click it and choose Show BA Custom ScreenGuard or just double-click it."
    Gui, Add, Text, xp+10 yp+20 w614, %trayHelp%

    ; BA Custom Products branding
    Gui, Font, s10 Bold c122040, Segoe UI
    Gui, Add, GroupBox, x20 y+16 w636 h75, About
    Gui, Font, s9 Normal c444444, Segoe UI
    Gui, Add, Text, xp+10 yp+20 w614, BA Custom ScreenGuard is built by BA Custom Products. We build white-label software and hardware solutions for golf simulator facilities.
    Gui, Font, s9 Normal c2563EB, Segoe UI
    Gui, Add, Text, xp yp+18 w614, bacustomproducts@gmail.com  |  (218) 684-3290

    ; ================================================================
    ;  END TABS - BOTTOM BAR
    ; ================================================================
    Gui, Tab

    Gui, Add, Text, x8 y+4 w664 h1 0x10

    Gui, Font, s12 Bold cFFFFFF, Segoe UI
    Gui, Add, Button, x12 y+6 w200 h38 gToggleProtection vBtnProtect, START PROTECTION
    Gui, Font, s10 Normal c333333, Segoe UI
    Gui, Add, Button, x220 yp+3 w130 h32 gRefreshMonitors, Refresh Monitors

    ; Footer
    Gui, Font, s8 Normal cAAAAAA, Segoe UI
    Gui, Add, Text, x430 yp+8 w240 Right, BA Custom Products %AppVersion%

    Gui, Font, s9 Normal c888888, Segoe UI
    Gui, Add, Text, x12 y+8 w660 vTxtStatus, Status: Ready - configure settings then click START PROTECTION
return

; ======================== #If CLICK BLOCK FUNCTION ========================

IsClickBlocked() {
    global IsProtecting, BlockedZones, MAX_ZONES, IsCapturingZone, IsRecordingClicks

    if (!IsProtecting || IsCapturingZone || IsRecordingClicks)
        return false

    CoordMode, Mouse, Screen
    MouseGetPos, mx, my

    Loop, %MAX_ZONES% {
        zone := BlockedZones[A_Index]
        if (!IsObject(zone))
            continue
        monIdx := zone.mon
        SysGet, monCount, MonitorCount
        if (monIdx > monCount)
            monIdx := 1
        SysGet, mon, Monitor, %monIdx%
        monW := monRight - monLeft
        monH := monBottom - monTop
        zx1 := monLeft + Round(zone.x1Pct * monW)
        zy1 := monTop + Round(zone.y1Pct * monH)
        zx2 := monLeft + Round(zone.x2Pct * monW)
        zy2 := monTop + Round(zone.y2Pct * monH)
        if (mx >= zx1 && mx <= zx2 && my >= zy1 && my <= zy2)
            return true
    }
    return false
}

HandleBlockedClick:
    CoordMode, Mouse, Screen
    MouseGetPos, bx, by
    Gui, Warn:Destroy
    Gui, Warn:New, +AlwaysOnTop -SysMenu +ToolWindow +Border
    Gui, Warn:Color, 122040
    Gui, Warn:Font, s13 Bold, Segoe UI
    Gui, Warn:Add, Text, cD4AF37 Center w400 y10, BA Custom ScreenGuard
    Gui, Warn:Font, s12 Normal
    Gui, Warn:Add, Text, cFFFFFF Center w400 y+8, %BlockMessage%
    warnX := bx - 210
    warnY := by - 85
    if (warnX < 0)
        warnX := 10
    if (warnY < 0)
        warnY := by + 30
    Gui, Warn:Show, x%warnX% y%warnY% NoActivate
    SetTimer, DismissWarning, -2500
return

DismissWarning:
    Gui, Warn:Destroy
return

; ======================== MONITOR TEXT ========================

BuildMonitorText:
    SysGet, monCount, MonitorCount
    SysGet, priMon, MonitorPrimary
    MonitorInfoText := ""
    Loop, %monCount% {
        SysGet, mon, Monitor, %A_Index%
        w := monRight - monLeft
        h := monBottom - monTop
        if (A_Index = priMon)
            pri := " (Primary)"
        else
            pri := ""
        if (A_Index > 1)
            MonitorInfoText .= "   |   "
        MonitorInfoText .= "Monitor " . A_Index . pri . ": " . w . " x " . h
    }
return

RefreshMonitors:
    GoSub, BuildMonitorText
    GuiControl, Main:, TxtMonitorInfo, %MonitorInfoText%
    MsgBox, 64, %AppName%, Monitor info refreshed!
return

; ======================== GUI EVENTS ========================

MainGuiClose:
MainGuiEscape:
    if (IsProtecting) {
        Gui, Main:Hide
        TrayTip, %AppName%, Still running in the background. Right-click this icon for options., 3, 1
        return
    }
    GoSub, DoStopEverything
    ExitApp
return

; ======================== ZONE CAPTURE ========================

CaptureZone:
    RegExMatch(A_GuiControl, "\d+", idx)
    CaptureZoneIndex := idx
    CaptureCorner := 1
    IsCapturingZone := true
    Gui, Main:Hide
    Sleep, 300
    capText := "ZONE " . idx . " - STEP 1 of 2`n`nClick the FIRST corner of the area you want to block.`nPress Escape to cancel."
    ToolTip, %capText%, 20, 20
    Hotkey, $LButton, DoZoneCornerClick, On
    Hotkey, Escape, CancelZoneCapture, On
return

DoZoneCornerClick:
    if (!IsCapturingZone)
        return
    CoordMode, Mouse, Screen
    MouseGetPos, mx, my

    if (CaptureCorner = 1) {
        TempCornerX := mx
        TempCornerY := my
        CaptureCorner := 2
        monIdx := GetMonitorForPoint(mx, my)
        SysGet, mon, Monitor, %monIdx%
        monW := monRight - monLeft
        monH := monBottom - monTop
        capText2 := "ZONE " . CaptureZoneIndex . " - STEP 2 of 2`n`nFirst corner: (" . mx . ", " . my . ") on Monitor " . monIdx . " [" . monW . "x" . monH . "]`nNow click the OPPOSITE corner.`nPress Escape to cancel."
        ToolTip, %capText2%, 20, 20
        ToolTip, +, %mx%, %my%, 3
        return
    }

    Hotkey, $LButton, DoZoneCornerClick, Off
    Hotkey, Escape, CancelZoneCapture, Off
    IsCapturingZone := false
    CaptureCorner := 0
    ToolTip
    ToolTip,,,, 3

    x1 := (TempCornerX < mx) ? TempCornerX : mx
    y1 := (TempCornerY < my) ? TempCornerY : my
    x2 := (TempCornerX > mx) ? TempCornerX : mx
    y2 := (TempCornerY > my) ? TempCornerY : my

    centerX := (x1 + x2) // 2
    centerY := (y1 + y2) // 2
    monIdx := GetMonitorForPoint(centerX, centerY)
    SysGet, mon, Monitor, %monIdx%
    monW := monRight - monLeft
    monH := monBottom - monTop

    x1Pct := (x1 - monLeft) / monW
    y1Pct := (y1 - monTop) / monH
    x2Pct := (x2 - monLeft) / monW
    y2Pct := (y2 - monTop) / monH

    zone := { mon: monIdx
        , x1Pct: x1Pct, y1Pct: y1Pct
        , x2Pct: x2Pct, y2Pct: y2Pct
        , absX1: x1, absY1: y1
        , absX2: x2, absY2: y2
        , monW: monW, monH: monH }

    BlockedZones[CaptureZoneIndex] := zone
    lbl := GetZoneLabel(CaptureZoneIndex)
    GuiControl, Main:, TxtZone%CaptureZoneIndex%, %lbl%
    GoSub, DoSaveConfig

    zW := x2 - x1
    zH := y2 - y1
    doneText := "Zone " . CaptureZoneIndex . " set!  " . zW . "x" . zH . " px on Monitor " . monIdx
    ToolTip, %doneText%, %centerX%, % centerY - 30
    SetTimer, RemoveToolTip, -2500
    Gui, Main:Show
return

CancelZoneCapture:
    Hotkey, $LButton, DoZoneCornerClick, Off
    Hotkey, Escape, CancelZoneCapture, Off
    IsCapturingZone := false
    CaptureCorner := 0
    ToolTip
    ToolTip,,,, 3
    Gui, Main:Show
return

ClearZone:
    RegExMatch(A_GuiControl, "\d+", idx)
    BlockedZones[idx] := ""
    lbl := GetZoneLabel(idx)
    GuiControl, Main:, TxtZone%idx%, %lbl%
    GoSub, DoSaveConfig
return

; ======================== BROWSE EXE ========================

BrowseExe:
    FileSelectFile, selectedFile, 3,, Select the program you want to keep running, Executables (*.exe)
    if (selectedFile != "") {
        WatchdogExePath := selectedFile
        SplitPath, selectedFile, fileName
        WatchdogProcessName := fileName
        GuiControl, Main:, EditWatchdogPath, %WatchdogExePath%
        GoSub, DoSaveConfig
    }
return

ToggleWatchdog:
    Gui, Main:Submit, NoHide
    WatchdogEnabled := ChkWatchdog
    GoSub, DoSaveConfig
return

; ======================== SETTINGS ========================

OnSettingChange:
    Gui, Main:Submit, NoHide
    AutoProtect := ChkAutoProtect
    SilentStart := ChkSilentStart
    GoSub, DoSaveConfig
return

ToggleStartup:
    startupLink := A_Startup . "\BA Custom ScreenGuard.lnk"
    if (FileExist(startupLink)) {
        FileDelete, %startupLink%
        GuiControl, Main:, BtnStartup, Add to Windows Startup
    } else {
        FileCreateShortcut, %A_ScriptFullPath%, %startupLink%, %A_ScriptDir%,, BA Custom ScreenGuard - by BA Custom Products
        GuiControl, Main:, BtnStartup, Remove from Windows Startup
    }
    GoSub, UpdateStartupStatus
return

UpdateStartupStatus:
    startupLink := A_Startup . "\BA Custom ScreenGuard.lnk"
    if (FileExist(startupLink))
        GuiControl, Main:, TxtStartupStatus, Will run on Windows startup.
    else
        GuiControl, Main:, TxtStartupStatus, Not in Windows startup.
return

; ======================== CLICK RECORDING ========================

StartRecording:
    if (IsRecordingClicks) {
        IsRecordingClicks := false
        Hotkey, $LButton, DoRecordClick, Off
        Hotkey, Escape, StopRecordingEsc, Off
        Hotkey, $RButton, StopRecordingEsc, Off
        ToolTip
        GuiControl, Main:, BtnRecord, Start Recording
        seqLabel := "Recorded Clicks: " . ClickSequence.Length()
        GuiControl, Main:, TxtSeqCount, %seqLabel%
        GoSub, DoUpdateSeqDetails
        GoSub, DoSaveConfig
        Gui, Main:Show
        return
    }
    IsRecordingClicks := true
    LastClickTime := 0
    Gui, Main:Hide
    Sleep, 300
    GuiControl, Main:, BtnRecord, Stop Recording
    recText := "CLICK RECORDER ACTIVE`n`nLeft-click each point in order.`nTiming is recorded automatically.`n`nRight-click or Escape when finished."
    ToolTip, %recText%, 20, 20
    Hotkey, $LButton, DoRecordClick, On
    Hotkey, Escape, StopRecordingEsc, On
    Hotkey, $RButton, StopRecordingEsc, On
return

DoRecordClick:
    if (!IsRecordingClicks)
        return
    CoordMode, Mouse, Screen
    MouseGetPos, mx, my

    currentTick := A_TickCount
    if (LastClickTime = 0)
        delayBefore := 0
    else
        delayBefore := currentTick - LastClickTime
    LastClickTime := currentTick

    monIdx := GetMonitorForPoint(mx, my)
    SysGet, mon, Monitor, %monIdx%
    monW := monRight - monLeft
    monH := monBottom - monTop
    xPct := (mx - monLeft) / monW
    yPct := (my - monTop) / monH

    ClickSequence.Push({ mon: monIdx
        , xPct: xPct, yPct: yPct
        , absX: mx, absY: my
        , delayBefore: delayBefore
        , monW: monW, monH: monH })

    cnt := ClickSequence.Length()
    if (delayBefore > 0) {
        ds := Round(delayBefore / 1000, 1)
        recStatus := "RECORDING - Click " . cnt . " at (" . mx . ", " . my . ") Mon " . monIdx . " [" . ds . "s after previous]`n`nLeft-click next or Right-click/Escape to finish."
    } else {
        recStatus := "RECORDING - Click " . cnt . " at (" . mx . ", " . my . ") Mon " . monIdx . " [first click]`n`nLeft-click next or Right-click/Escape to finish."
    }
    ToolTip, %recStatus%, 20, 20
    ToolTip, %cnt%, %mx%, % my - 18, 2
    SetTimer, RemoveToolTip2, -1500
return

StopRecordingEsc:
    IsRecordingClicks := false
    LastClickTime := 0
    Hotkey, $LButton, DoRecordClick, Off
    Hotkey, Escape, StopRecordingEsc, Off
    Hotkey, $RButton, StopRecordingEsc, Off
    ToolTip
    ToolTip,,,, 2
    GuiControl, Main:, BtnRecord, Start Recording
    seqLabel := "Recorded Clicks: " . ClickSequence.Length()
    GuiControl, Main:, TxtSeqCount, %seqLabel%
    GoSub, DoUpdateSeqDetails
    GoSub, DoSaveConfig
    Gui, Main:Show
return

ClearSequence:
    ClickSequence := []
    GuiControl, Main:, TxtSeqCount, Recorded Clicks: 0
    GuiControl, Main:, EditSeqDetails, (no clicks recorded)
    GoSub, DoSaveConfig
return

TestSequence:
    cnt := ClickSequence.Length()
    if (cnt = 0) {
        MsgBox, 48, %AppName%, No clicks recorded yet. Go to the Click Recorder tab first.
        return
    }
    totalTime := 0
    Loop, % ClickSequence.Length() {
        totalTime += ClickSequence[A_Index].delayBefore
    }
    totalSec := Round(totalTime / 1000, 1)
    testMsg := "Replay " . cnt . " clicks with your exact timing (~" . totalSec . "s total).`n`nMake sure the target window is visible. Ready?"
    MsgBox, 4, Test Playback, %testMsg%
    IfMsgBox No
        return
    Gui, Main:Hide
    ToolTip, Playback starting in 2 seconds..., 20, 20
    Sleep, 2000
    ToolTip
    GoSub, DoPlaybackClicks
    ToolTip, Playback complete!, 20, 20
    SetTimer, RemoveToolTip, -2000
    Sleep, 2200
    Gui, Main:Show
return

DoUpdateSeqDetails:
    if (ClickSequence.Length() = 0) {
        GuiControl, Main:, EditSeqDetails, (no clicks recorded - use Start Recording to begin)
        return
    }
    details := ""
    totalTime := 0
    Loop, % ClickSequence.Length() {
        cl := ClickSequence[A_Index]
        totalTime += cl.delayBefore
        if (cl.delayBefore > 0) {
            ds := Round(cl.delayBefore / 1000, 1)
            details .= "  Click " . A_Index . "  [wait " . ds . "s]  ->  Monitor " . cl.mon . "  (" . cl.absX . ", " . cl.absY . ")`r`n"
        } else {
            details .= "  Click " . A_Index . "  [start]  ->  Monitor " . cl.mon . "  (" . cl.absX . ", " . cl.absY . ")`r`n"
        }
    }
    totalSec := Round(totalTime / 1000, 1)
    details .= "`r`n  Total sequence time: ~" . totalSec . " seconds"
    GuiControl, Main:, EditSeqDetails, %details%
return

; ======================== PROTECTION ========================

ToggleProtection:
    if (IsProtecting) {
        GoSub, DoStopProtection
        return
    }
    Gui, Main:Submit, NoHide
    BlockMessage := EditBlockMsg
    WatchdogDelay := EditWatchdogDelay
    ReopenMessage := EditReopenMsg
    WatchdogEnabled := ChkWatchdog

    hasZones := false
    Loop, %MAX_ZONES% {
        if (IsObject(BlockedZones[A_Index]))
            hasZones := true
    }
    if (!hasZones && !WatchdogEnabled) {
        MsgBox, 48, %AppName%, Nothing to protect! Set up a blocked zone or enable the watchdog first.
        return
    }
    if (WatchdogEnabled && WatchdogExePath = "") {
        MsgBox, 48, %AppName%, Watchdog enabled but no program selected. Go to the Watchdog tab and browse to the .exe.
        return
    }
    GoSub, DoSaveConfig
    GoSub, DoStartProtection
return

DoStartProtection:
    IsProtecting := true
    GuiControl, Main:, BtnProtect, STOP PROTECTION
    if (WatchdogEnabled && WatchdogProcessName != "") {
        SetTimer, WatchdogCheck, 2000
        statusText := "PROTECTION ACTIVE  -  Watching: " . WatchdogProcessName
        GuiControl, Main:, TxtStatus, %statusText%
    } else {
        GuiControl, Main:, TxtStatus, Status: PROTECTION ACTIVE
    }
    Gui, Main:Minimize
    TrayTip, %AppName%, Protection is active. Right-click tray icon for options., 3, 1
return

DoStopProtection:
    IsProtecting := false
    SetTimer, WatchdogCheck, Off
    GuiControl, Main:, BtnProtect, START PROTECTION
    GuiControl, Main:, TxtStatus, Status: Idle - Protection stopped
    TrayTip, %AppName%, Protection stopped., 2, 1
return

DoStopEverything:
    IsProtecting := false
    IsCapturingZone := false
    IsRecordingClicks := false
    SetTimer, WatchdogCheck, Off
return

; ======================== WATCHDOG ========================

WatchdogCheck:
    if (!WatchdogEnabled || !IsProtecting)
        return
    Process, Exist, %WatchdogProcessName%
    if (ErrorLevel = 0) {
        ; STEP 1 - Recovery message IMMEDIATELY
        Gui, Recovery:Destroy
        Gui, Recovery:New, +AlwaysOnTop -SysMenu -MinimizeBox -MaximizeBox +Border, %AppName% - Recovery
        Gui, Recovery:Color, 122040
        Gui, Recovery:Font, s11 Normal, Segoe UI
        Gui, Recovery:Add, Text, x30 y15 w460 Center cD4AF37, BA Custom ScreenGuard
        Gui, Recovery:Font, s18 Bold
        Gui, Recovery:Add, Text, x30 y+10 w460 Center cFFFFFF, %ReopenMessage%
        Gui, Recovery:Font, s10 Normal
        Gui, Recovery:Add, Text, x30 y+14 w460 Center cAAAADD, Restoring the program now...
        Gui, Recovery:Add, Text, x30 y+4 w460 Center cAAAADD, Please do not touch the mouse or keyboard.
        Gui, Recovery:Font, s8
        Gui, Recovery:Add, Text, x30 y+10 w460 Center c667799, This will close automatically when done.
        SysGet, mon, MonitorWorkArea, 1
        guiW := 540
        guiH := 220
        guiX := monLeft + ((monRight - monLeft - guiW) // 2)
        guiY := monTop + ((monBottom - monTop - guiH) // 2)
        Gui, Recovery:Show, x%guiX% y%guiY% w%guiW% h%guiH% NoActivate
        Sleep, 500

        ; STEP 2 - Relaunch
        Run, %WatchdogExePath%
        Sleep, %WatchdogDelay%

        ; STEP 3 - Replay clicks
        if (ClickSequence.Length() > 0)
            GoSub, DoPlaybackClicks

        ; STEP 4 - Dismiss
        Sleep, 1000
        Gui, Recovery:Destroy
    }
return

DoPlaybackClicks:
    oldProtecting := IsProtecting
    IsProtecting := false
    Loop, % ClickSequence.Length() {
        cl := ClickSequence[A_Index]
        if (cl.delayBefore > 0)
            Sleep, % cl.delayBefore
        monIdx := cl.mon
        SysGet, monCount, MonitorCount
        if (monIdx > monCount)
            monIdx := 1
        SysGet, mon, Monitor, %monIdx%
        monW := monRight - monLeft
        monH := monBottom - monTop
        tx := monLeft + Round(cl.xPct * monW)
        ty := monTop + Round(cl.yPct * monH)
        CoordMode, Mouse, Screen
        MouseMove, %tx%, %ty%, 5
        Sleep, 100
        Click, %tx%, %ty%
    }
    IsProtecting := oldProtecting
return

; ======================== HELPERS ========================

GetMonitorForPoint(x, y) {
    SysGet, monCount, MonitorCount
    Loop, %monCount% {
        SysGet, mon, Monitor, %A_Index%
        if (x >= monLeft && x < monRight && y >= monTop && y < monBottom)
            return A_Index
    }
    return 1
}

GetZoneLabel(idx) {
    global BlockedZones
    zone := BlockedZones[idx]
    if (!IsObject(zone))
        return "Zone " . idx . ":  (not set)"
    w := zone.absX2 - zone.absX1
    h := zone.absY2 - zone.absY1
    return "Zone " . idx . ":  SET - Monitor " . zone.mon . "  (" . zone.absX1 . "," . zone.absY1 . ") to (" . zone.absX2 . "," . zone.absY2 . ")  [" . w . "x" . h . "]"
}

; ======================== CONFIG ========================

DoSaveConfig:
    Gui, Main:Submit, NoHide
    BlockMessage := EditBlockMsg
    WatchdogDelay := EditWatchdogDelay
    ReopenMessage := EditReopenMsg

    IniWrite, %BlockMessage%, %ConfigFile%, General, BlockMessage
    IniWrite, %AutoProtect%, %ConfigFile%, General, AutoProtect
    IniWrite, %SilentStart%, %ConfigFile%, General, SilentStart
    IniWrite, %WatchdogExePath%, %ConfigFile%, Watchdog, ExePath
    IniWrite, %WatchdogProcessName%, %ConfigFile%, Watchdog, ProcessName
    IniWrite, %WatchdogDelay%, %ConfigFile%, Watchdog, Delay
    IniWrite, %ReopenMessage%, %ConfigFile%, Watchdog, ReopenMessage
    IniWrite, %WatchdogEnabled%, %ConfigFile%, Watchdog, Enabled

    Loop, %MAX_ZONES% {
        section := "Zone" . A_Index
        zone := BlockedZones[A_Index]
        if (IsObject(zone)) {
            IniWrite, 1, %ConfigFile%, %section%, Active
            IniWrite, % zone.mon, %ConfigFile%, %section%, Mon
            IniWrite, % zone.x1Pct, %ConfigFile%, %section%, X1Pct
            IniWrite, % zone.y1Pct, %ConfigFile%, %section%, Y1Pct
            IniWrite, % zone.x2Pct, %ConfigFile%, %section%, X2Pct
            IniWrite, % zone.y2Pct, %ConfigFile%, %section%, Y2Pct
            IniWrite, % zone.absX1, %ConfigFile%, %section%, AbsX1
            IniWrite, % zone.absY1, %ConfigFile%, %section%, AbsY1
            IniWrite, % zone.absX2, %ConfigFile%, %section%, AbsX2
            IniWrite, % zone.absY2, %ConfigFile%, %section%, AbsY2
        } else {
            IniWrite, 0, %ConfigFile%, %section%, Active
        }
    }

    IniWrite, % ClickSequence.Length(), %ConfigFile%, ClickSeq, Count
    Loop, % ClickSequence.Length() {
        section := "Click" . A_Index
        cl := ClickSequence[A_Index]
        IniWrite, % cl.mon, %ConfigFile%, %section%, Mon
        IniWrite, % cl.xPct, %ConfigFile%, %section%, XPct
        IniWrite, % cl.yPct, %ConfigFile%, %section%, YPct
        IniWrite, % cl.absX, %ConfigFile%, %section%, AbsX
        IniWrite, % cl.absY, %ConfigFile%, %section%, AbsY
        IniWrite, % cl.delayBefore, %ConfigFile%, %section%, DelayBefore
    }
return

DoLoadConfig:
    if (!FileExist(ConfigFile))
        return
    IniRead, BlockMessage, %ConfigFile%, General, BlockMessage, Don't close this!
    IniRead, AutoProtect, %ConfigFile%, General, AutoProtect, 0
    IniRead, SilentStart, %ConfigFile%, General, SilentStart, 0
    IniRead, WatchdogExePath, %ConfigFile%, Watchdog, ExePath, %A_Space%
    IniRead, WatchdogProcessName, %ConfigFile%, Watchdog, ProcessName, %A_Space%
    IniRead, WatchdogDelay, %ConfigFile%, Watchdog, Delay, 3000
    IniRead, ReopenMessage, %ConfigFile%, Watchdog, ReopenMessage, Please don't close this program again!
    IniRead, WatchdogEnabled, %ConfigFile%, Watchdog, Enabled, 0

    BlockedZones := []
    Loop, %MAX_ZONES% {
        section := "Zone" . A_Index
        IniRead, active, %ConfigFile%, %section%, Active, 0
        if (active = 1) {
            IniRead, zMon, %ConfigFile%, %section%, Mon, 1
            IniRead, zX1P, %ConfigFile%, %section%, X1Pct, 0
            IniRead, zY1P, %ConfigFile%, %section%, Y1Pct, 0
            IniRead, zX2P, %ConfigFile%, %section%, X2Pct, 0
            IniRead, zY2P, %ConfigFile%, %section%, Y2Pct, 0
            IniRead, zAX1, %ConfigFile%, %section%, AbsX1, 0
            IniRead, zAY1, %ConfigFile%, %section%, AbsY1, 0
            IniRead, zAX2, %ConfigFile%, %section%, AbsX2, 0
            IniRead, zAY2, %ConfigFile%, %section%, AbsY2, 0
            BlockedZones.Push({ mon: zMon+0, x1Pct: zX1P+0, y1Pct: zY1P+0, x2Pct: zX2P+0, y2Pct: zY2P+0, absX1: zAX1+0, absY1: zAY1+0, absX2: zAX2+0, absY2: zAY2+0 })
        } else {
            BlockedZones.Push("")
        }
    }

    ClickSequence := []
    IniRead, clkCount, %ConfigFile%, ClickSeq, Count, 0
    Loop, %clkCount% {
        section := "Click" . A_Index
        IniRead, cMon, %ConfigFile%, %section%, Mon, 1
        IniRead, cXP, %ConfigFile%, %section%, XPct, 0
        IniRead, cYP, %ConfigFile%, %section%, YPct, 0
        IniRead, cAX, %ConfigFile%, %section%, AbsX, 0
        IniRead, cAY, %ConfigFile%, %section%, AbsY, 0
        IniRead, cDelay, %ConfigFile%, %section%, DelayBefore, 0
        ClickSequence.Push({ mon: cMon+0, xPct: cXP+0, yPct: cYP+0, absX: cAX+0, absY: cAY+0, delayBefore: cDelay+0 })
    }
return

; ======================== TOOLTIPS ========================

RemoveToolTip:
    ToolTip
return

RemoveToolTip2:
    ToolTip,,,, 2
return

; ======================== TRAY MENU ========================

Menu, Tray, NoStandard
Menu, Tray, Add, Show BA Custom ScreenGuard, ShowMainGUI
Menu, Tray, Add, Toggle Protection, TrayToggleProtect
Menu, Tray, Add,
Menu, Tray, Add, Exit, TrayExit
Menu, Tray, Default, Show BA Custom ScreenGuard
Menu, Tray, Tip, BA Custom ScreenGuard v1.0 - by BA Custom Products

ShowMainGUI:
    Gui, Main:Show,, BA Custom ScreenGuard v1.0
return

TrayToggleProtect:
    if (IsProtecting)
        GoSub, DoStopProtection
    else
        GoSub, DoStartProtection
return

TrayExit:
    GoSub, DoStopEverything
    ExitApp
return

; ======================== CONTEXT-SENSITIVE CLICK BLOCKING ========================

#If IsClickBlocked()
LButton::
    GoSub, HandleBlockedClick
return
#If
