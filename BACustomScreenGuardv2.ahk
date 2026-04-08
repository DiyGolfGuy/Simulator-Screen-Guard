; ============================================================================
;  BA Custom ScreenGuard v2.0
;  by BA Custom Products
; ----------------------------------------------------------------------------
;  TO COMPILE TO .EXE:
;    1. Install AutoHotkey v1.1
;    2. Open Ahk2Exe, select this file, set custom icon to BACustomScreenGuard.ico
;    3. Click Convert
; ============================================================================

;@Ahk2Exe-SetName BA Custom ScreenGuard
;@Ahk2Exe-SetDescription BA Custom ScreenGuard - Click Blocker and Watchdog
;@Ahk2Exe-SetVersion 2.0.0
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
AppVersion := "v2.0"

MAX_ZONES := 4
MAX_PROGRAMS := 4
BlockedZones := []
WatchedPrograms := []
CurrentProgramSlot := 1
BlockMessage := "Don't close this!"
ReopenMessage := "Please don't close this program again!"
IsProtecting := false
InRecovery := false
IsCapturingZone := false
CaptureZoneIndex := 0
CaptureCorner := 0
TempCornerX := 0
TempCornerY := 0
IsRecordingClicks := false
LastClickTime := 0
AutoProtect := false
SilentStart := false

ConfigDir := A_AppData . "\BA Custom Products\ScreenGuard"
ConfigFile := ConfigDir . "\config.ini"
FileCreateDir, %ConfigDir%

Loop, %MAX_ZONES% {
    BlockedZones.Push("")
}

; Initialize empty program slots
Loop, %MAX_PROGRAMS% {
    WatchedPrograms.Push({ enabled: 0
        , name: ""
        , exePath: ""
        , processName: ""
        , delay: 3000
        , critical: 0
        , clickSequence: [] })
}

GoSub, DoLoadConfig

; ======================== STARTUP ========================

if (AutoProtect && SilentStart) {
    GoSub, DoBuildGUI
    GoSub, DoStartProtection
    TrayTip, %AppName%, Running in background. Right-click tray icon for settings., 5, 1
    goto SkipGUIShow
} else if (AutoProtect) {
    GoSub, DoBuildGUI
    Gui, Main:Show, w680 AutoSize Center, %AppName% %AppVersion%
    GoSub, DoStartProtection
    goto SkipGUIShow
} else {
    GoSub, DoBuildGUI
    Gui, Main:Show, w680 AutoSize Center, %AppName% %AppVersion%
    goto SkipGUIShow
}

SkipGUIShow:
return

; ======================== BUILD GUI ========================

DoBuildGUI:
    guiTitle := AppName . " " . AppVersion
    Gui, Main:New, -MaximizeBox, %guiTitle%
    Gui, Main:Default
    Gui, Main:Color, F0F0F0, FFFFFF
    Gui, Main:Margin, 12, 8

    ; --- Header ---
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
    Gui, Add, Tab2, x8 y130 w664 h560 vMainTabs, Block Zones|Watched Programs|Settings

    ; ================================================================
    ;  TAB 1 - BLOCK ZONES
    ; ================================================================
    Gui, Tab, 1

    ; How It Works - y158
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y158 w636 h52, How It Works
    Gui, Font, s9 Normal c666666, Segoe UI
    howZoneText := "Click Capture then click two opposite corners to block a rectangular area. Any click inside will be blocked. Works over any window on any monitor."
    Gui, Add, Text, x30 y178 w614, %howZoneText%

    ; Blocked Zones - y225
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y225 w636 h180, Blocked Zones (up to 4 rectangles)
    Gui, Font, s9 Normal c333333, Segoe UI

    Loop, %MAX_ZONES% {
        idx := A_Index
        rowY := 250 + ((idx - 1) * 34)
        btnY := rowY - 3
        zoneLabel := GetZoneLabel(idx)
        Gui, Add, Text, x32 y%rowY% w400 vTxtZone%idx%, %zoneLabel%
        Gui, Add, Button, x450 y%btnY% w95 h24 gCaptureZone vBtnCapture%idx%, Capture %idx%
        Gui, Add, Button, x550 y%btnY% w95 h24 gClearZone vBtnClear%idx%, Clear %idx%
    }

    ; Warning Message - y420
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y420 w636 h68, Warning Message
    Gui, Font, s9 Normal c666666, Segoe UI
    Gui, Add, Text, x30 y442 w300, Shown when a blocked click is attempted:
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x30 y460 w614 h22 vEditBlockMsg, %BlockMessage%

    ; ================================================================
    ;  TAB 2 - WATCHED PROGRAMS
    ; ================================================================
    Gui, Tab, 2

    ; How It Works - y158
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y158 w636 h58, How It Works
    Gui, Font, s9 Normal c666666, Segoe UI
    howText1 := "Monitor up to 4 programs. If any watched program closes, ScreenGuard relaunches it and replays its click sequence."
    howText2 := "Mark a program CRITICAL to close ALL watched programs and restart them clean in order when it closes."
    Gui, Add, Text, x30 y178 w614, %howText1%
    Gui, Add, Text, x30 y195 w614, %howText2%

    ; Program slot selector - y226
    Gui, Font, s10 Bold c2563EB, Segoe UI
    Gui, Add, Text, x20 y226 w250, SELECT PROGRAM SLOT TO EDIT:
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Radio, x20 y246 w85 vRadioProg1 gSwitchProgram Checked, Program 1
    Gui, Add, Radio, x110 y246 w85 vRadioProg2 gSwitchProgram, Program 2
    Gui, Add, Radio, x200 y246 w85 vRadioProg3 gSwitchProgram, Program 3
    Gui, Add, Radio, x290 y246 w85 vRadioProg4 gSwitchProgram, Program 4
    Gui, Font, s9 Bold c16A34A, Segoe UI
    Gui, Add, Text, x390 y248 w260 vTxtProgramStatus, Editing: Program 1
    Gui, Font, s9 Normal c333333, Segoe UI

    ; Program Settings GroupBox - y278
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y278 w636 h135, Program Settings
    Gui, Font, s9 Normal c666666, Segoe UI

    Gui, Add, Text, x30 y302 w100, Friendly Name:
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x135 y299 w300 h22 vEditProgName,

    Gui, Font, s9 Normal c666666, Segoe UI
    Gui, Add, Text, x30 y329 w100, Program File:
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x135 y326 w400 h22 vEditProgPath ReadOnly,
    Gui, Add, Button, x540 y325 w100 h24 gBrowseProgExe, Browse...

    Gui, Font, s9 Normal c666666, Segoe UI
    Gui, Add, Text, x30 y356 w180, Delay after relaunch (ms):
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x215 y353 w90 h22 vEditProgDelay Number, 3000
    Gui, Add, UpDown, Range500-60000, 3000

    Gui, Add, CheckBox, x30 y378 vChkProgEnabled gOnProgramToggle, Enable this watched program
    Gui, Add, CheckBox, x30 y395 vChkProgCritical gOnProgramToggle, Critical (closing this restarts ALL watched programs clean)

    ; Click Sequence GroupBox - y425
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y425 w636 h165, Click Sequence for Selected Program
    Gui, Font, s9 Normal c333333, Segoe UI

    Gui, Add, Button, x30 y447 w140 h26 gStartRecording vBtnRecord, Start Recording
    Gui, Add, Button, x178 y447 w120 h26 gClearSequence, Clear Clicks
    Gui, Add, Button, x306 y447 w120 h26 gTestSequence, Test Playback
    Gui, Font, s8 Normal c888888, Segoe UI
    Gui, Add, Text, x434 y452 w200, Right-click or Esc to stop
    Gui, Font, s9 Normal c444444, Segoe UI

    seqLabel := "Recorded Clicks: 0"
    Gui, Add, Text, x30 y480 w300 vTxtSeqCount, %seqLabel%
    Gui, Font, s9 Normal c333333, Consolas
    Gui, Add, Edit, x30 y500 w616 h83 ReadOnly vEditSeqDetails HScroll,

    ; Recovery Message - y600
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y600 w636 h55, Recovery Message (shown during any program recovery)
    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, Edit, x30 y622 w614 h22 vEditReopenMsg, %ReopenMessage%

    ; ================================================================
    ;  TAB 3 - SETTINGS
    ; ================================================================
    Gui, Tab, 3

    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y158 w636 h145, Startup Options
    Gui, Font, s9 Normal c333333, Segoe UI

    Gui, Add, CheckBox, x30 y180 vChkAutoProtect gOnSettingChange Checked%AutoProtect%, Start protection automatically when BA Custom ScreenGuard opens
    Gui, Font, s8 Normal c888888, Segoe UI
    Gui, Add, Text, x42 y200 w600, Protection starts immediately on launch. No need to click anything.

    Gui, Font, s9 Normal c333333, Segoe UI
    Gui, Add, CheckBox, x30 y222 vChkSilentStart gOnSettingChange Checked%SilentStart%, Run silently on startup (no window - tray icon only)
    Gui, Font, s8 Normal c888888, Segoe UI
    silentHelp := "No window appears on launch. To open settings later right-click the BA Custom ScreenGuard icon in the bottom-right system tray area of your taskbar (near the clock)."
    Gui, Add, Text, x42 y240 w600, %silentHelp%

    ; Windows Startup - y318
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y318 w636 h92, Windows Startup
    Gui, Font, s9 Normal c666666, Segoe UI
    startupHelp := "Add to Windows startup so it runs automatically every time the computer turns on. Combined with the options above this gives full hands-off protection after every reboot."
    Gui, Add, Text, x30 y340 w614, %startupHelp%
    Gui, Font, s9 Normal c333333, Segoe UI

    startupLink := A_Startup . "\BA Custom ScreenGuard.lnk"
    if (FileExist(startupLink))
        startupBtnText := "Remove from Windows Startup"
    else
        startupBtnText := "Add to Windows Startup"
    Gui, Add, Button, x30 y375 w220 h26 gToggleStartup vBtnStartup, %startupBtnText%
    Gui, Add, Text, x258 y380 w380 vTxtStartupStatus c888888,
    GoSub, UpdateStartupStatus

    ; How to Open - y425
    Gui, Font, s10 Bold c333333, Segoe UI
    Gui, Add, GroupBox, x20 y425 w636 h70, How to Open This Window
    Gui, Font, s9 Normal c333333, Segoe UI
    trayHelp := "If running silently find the BA Custom ScreenGuard icon in your system tray (bottom-right corner of taskbar near the clock). Right-click it and choose Show BA Custom ScreenGuard or double-click it."
    Gui, Add, Text, x30 y447 w614, %trayHelp%

    ; About - y510
    Gui, Font, s10 Bold c122040, Segoe UI
    Gui, Add, GroupBox, x20 y510 w636 h80, About
    Gui, Font, s9 Normal c444444, Segoe UI
    Gui, Add, Text, x30 y532 w614, BA Custom ScreenGuard is built by BA Custom Products. We build white-label software and hardware solutions for golf simulator facilities.
    Gui, Font, s9 Normal c2563EB, Segoe UI
    Gui, Add, Text, x30 y560 w614, bacustomproducts@gmail.com  |  (218) 684-3290

    ; ================================================================
    ;  END TABS - BOTTOM BAR
    ; ================================================================
    Gui, Tab

    ; Tab ends at y=690 (y130 + h560). Bottom bar starts below.
    Gui, Add, Text, x8 y698 w664 h1 0x10

    Gui, Font, s12 Bold cFFFFFF, Segoe UI
    Gui, Add, Button, x12 y706 w200 h38 gToggleProtection vBtnProtect, START PROTECTION
    Gui, Font, s10 Normal c333333, Segoe UI
    Gui, Add, Button, x220 y709 w130 h32 gRefreshMonitors, Refresh Monitors
    Gui, Font, s8 Normal cAAAAAA, Segoe UI
    Gui, Add, Text, x430 y716 w240 Right, BA Custom Products %AppVersion%

    Gui, Font, s9 Normal c888888, Segoe UI
    Gui, Add, Text, x12 y752 w660 vTxtStatus, Status: Ready - configure settings then click START PROTECTION

    ; Load the first program into the fields
    GoSub, LoadCurrentProgramToGUI
return

; ======================== PROGRAM SLOT MANAGEMENT ========================

SwitchProgram:
    ; Save current fields to current slot before switching
    GoSub, SaveCurrentGUIToProgram

    ; Figure out which radio is now selected
    GuiControlGet, r1,, RadioProg1
    GuiControlGet, r2,, RadioProg2
    GuiControlGet, r3,, RadioProg3
    GuiControlGet, r4,, RadioProg4
    if (r1)
        CurrentProgramSlot := 1
    else if (r2)
        CurrentProgramSlot := 2
    else if (r3)
        CurrentProgramSlot := 3
    else if (r4)
        CurrentProgramSlot := 4

    GoSub, LoadCurrentProgramToGUI
return

LoadCurrentProgramToGUI:
    prog := WatchedPrograms[CurrentProgramSlot]
    GuiControl, Main:, EditProgName, % prog.name
    GuiControl, Main:, EditProgPath, % prog.exePath
    GuiControl, Main:, EditProgDelay, % prog.delay
    GuiControl, Main:, ChkProgEnabled, % prog.enabled
    GuiControl, Main:, ChkProgCritical, % prog.critical

    statusTxt := "Editing: Program " . CurrentProgramSlot
    if (prog.name != "")
        statusTxt := statusTxt . " (" . prog.name . ")"
    if (prog.enabled)
        statusTxt := statusTxt . "  -  ENABLED"
    if (prog.critical)
        statusTxt := statusTxt . "  [CRITICAL]"
    GuiControl, Main:, TxtProgramStatus, %statusTxt%

    ; Update click count and display
    cnt := prog.clickSequence.Length()
    GuiControl, Main:, TxtSeqCount, Recorded Clicks: %cnt%
    GoSub, DoUpdateSeqDetails
return

SaveCurrentGUIToProgram:
    Gui, Main:Submit, NoHide
    prog := WatchedPrograms[CurrentProgramSlot]
    prog.name := EditProgName
    prog.exePath := EditProgPath
    prog.delay := EditProgDelay + 0
    prog.enabled := ChkProgEnabled
    prog.critical := ChkProgCritical
    if (prog.exePath != "") {
        SplitPath, % prog.exePath, fileName
        prog.processName := fileName
    }
    WatchedPrograms[CurrentProgramSlot] := prog
    GoSub, DoSaveConfig
return

OnProgramToggle:
    GoSub, SaveCurrentGUIToProgram
    GoSub, LoadCurrentProgramToGUI
return

BrowseProgExe:
    FileSelectFile, selectedFile, 3,, Select the program you want to keep running, Executables (*.exe)
    if (selectedFile != "") {
        prog := WatchedPrograms[CurrentProgramSlot]
        prog.exePath := selectedFile
        SplitPath, selectedFile, fileName
        prog.processName := fileName
        if (prog.name = "") {
            SplitPath, selectedFile, , , , fileNoExt
            prog.name := fileNoExt
        }
        WatchedPrograms[CurrentProgramSlot] := prog
        GoSub, LoadCurrentProgramToGUI
        GoSub, DoSaveConfig
    }
return

; ======================== #If CLICK BLOCK ========================

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

; ======================== MONITORS ========================

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
    capText := "ZONE " . idx . " - STEP 1 of 2`n`nClick the FIRST corner of the area to block.`nPress Escape to cancel."
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
        , absX2: x2, absY2: y2 }

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

; ======================== SETTINGS CHANGES ========================

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
        FileCreateShortcut, %A_ScriptFullPath%, %startupLink%, %A_ScriptDir%,, BA Custom ScreenGuard
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
        prog := WatchedPrograms[CurrentProgramSlot]
        cnt := prog.clickSequence.Length()
        GuiControl, Main:, TxtSeqCount, Recorded Clicks: %cnt%
        GoSub, DoUpdateSeqDetails
        GoSub, DoSaveConfig
        Gui, Main:Show
        return
    }

    ; Save current settings first
    GoSub, SaveCurrentGUIToProgram

    ; Clear the current program's click sequence to start fresh
    prog := WatchedPrograms[CurrentProgramSlot]
    prog.clickSequence := []
    WatchedPrograms[CurrentProgramSlot] := prog

    IsRecordingClicks := true
    LastClickTime := 0
    Gui, Main:Hide
    Sleep, 300
    GuiControl, Main:, BtnRecord, Stop Recording
    slotName := prog.name
    if (slotName = "")
        slotName := "Program " . CurrentProgramSlot
    recText := "RECORDING for " . slotName . "`n`nLeft-click each point in order.`nTiming is recorded automatically.`n`nRight-click or Escape when finished."
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

    prog := WatchedPrograms[CurrentProgramSlot]
    prog.clickSequence.Push({ mon: monIdx
        , xPct: xPct, yPct: yPct
        , absX: mx, absY: my
        , delayBefore: delayBefore })
    WatchedPrograms[CurrentProgramSlot] := prog

    cnt := prog.clickSequence.Length()
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
    prog := WatchedPrograms[CurrentProgramSlot]
    cnt := prog.clickSequence.Length()
    GuiControl, Main:, TxtSeqCount, Recorded Clicks: %cnt%
    GoSub, DoUpdateSeqDetails
    GoSub, DoSaveConfig
    Gui, Main:Show
return

ClearSequence:
    prog := WatchedPrograms[CurrentProgramSlot]
    prog.clickSequence := []
    WatchedPrograms[CurrentProgramSlot] := prog
    GuiControl, Main:, TxtSeqCount, Recorded Clicks: 0
    GuiControl, Main:, EditSeqDetails, (no clicks recorded)
    GoSub, DoSaveConfig
return

TestSequence:
    prog := WatchedPrograms[CurrentProgramSlot]
    cnt := prog.clickSequence.Length()
    if (cnt = 0) {
        MsgBox, 48, %AppName%, No clicks recorded for this program yet.
        return
    }
    totalTime := 0
    Loop, % prog.clickSequence.Length() {
        totalTime += prog.clickSequence[A_Index].delayBefore
    }
    totalSec := Round(totalTime / 1000, 1)
    testMsg := "Replay " . cnt . " clicks with exact timing (~" . totalSec . "s total).`n`nMake sure the target window is visible. Ready?"
    MsgBox, 4, Test Playback, %testMsg%
    IfMsgBox No
        return
    Gui, Main:Hide
    ToolTip, Playback starting in 2 seconds..., 20, 20
    Sleep, 2000
    ToolTip
    testSlotIdx := CurrentProgramSlot
    GoSub, DoPlaybackClicksForSlot
    ToolTip, Playback complete!, 20, 20
    SetTimer, RemoveToolTip, -2000
    Sleep, 2200
    Gui, Main:Show
return

DoUpdateSeqDetails:
    prog := WatchedPrograms[CurrentProgramSlot]
    if (prog.clickSequence.Length() = 0) {
        GuiControl, Main:, EditSeqDetails, (no clicks recorded - click Start Recording to begin)
        return
    }
    details := ""
    totalTime := 0
    Loop, % prog.clickSequence.Length() {
        cl := prog.clickSequence[A_Index]
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

    ; Save current edits before starting
    GoSub, SaveCurrentGUIToProgram
    Gui, Main:Submit, NoHide
    BlockMessage := EditBlockMsg
    ReopenMessage := EditReopenMsg

    hasZones := false
    Loop, %MAX_ZONES% {
        if (IsObject(BlockedZones[A_Index]))
            hasZones := true
    }

    hasProgs := false
    Loop, %MAX_PROGRAMS% {
        prog := WatchedPrograms[A_Index]
        if (prog.enabled && prog.exePath != "")
            hasProgs := true
    }

    if (!hasZones && !hasProgs) {
        MsgBox, 48, %AppName%, Nothing to protect! Set up a blocked zone or enable at least one watched program.
        return
    }

    GoSub, DoSaveConfig
    GoSub, DoStartProtection
return

DoStartProtection:
    IsProtecting := true
    GuiControl, Main:, BtnProtect, STOP PROTECTION

    ; Count enabled programs
    enabledCount := 0
    Loop, %MAX_PROGRAMS% {
        prog := WatchedPrograms[A_Index]
        if (prog.enabled && prog.exePath != "")
            enabledCount += 1
    }

    if (enabledCount > 0) {
        SetTimer, WatchdogCheck, 2000
        statusText := "PROTECTION ACTIVE  -  Watching " . enabledCount . " program(s)"
        GuiControl, Main:, TxtStatus, %statusText%
    } else {
        GuiControl, Main:, TxtStatus, Status: PROTECTION ACTIVE - Click blocking only
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
    InRecovery := false
    SetTimer, WatchdogCheck, Off
return

; ======================== WATCHDOG ========================

WatchdogCheck:
    if (!IsProtecting || InRecovery)
        return

    ; Loop through watched programs
    Loop, %MAX_PROGRAMS% {
        prog := WatchedPrograms[A_Index]
        if (!prog.enabled || prog.exePath = "")
            continue

        Process, Exist, % prog.processName
        if (ErrorLevel = 0) {
            ; This program is down - handle recovery
            InRecovery := true
            recoverySlot := A_Index

            if (prog.critical) {
                ; Full clean restart of all watched programs
                GoSub, DoFullRestartRecovery
            } else {
                ; Just restart this one
                GoSub, DoSingleProgramRecovery
            }

            InRecovery := false
            break  ; Only handle one recovery per tick
        }
    }
return

DoSingleProgramRecovery:
    ; Show recovery message
    GoSub, ShowRecoveryGui
    Sleep, 500

    prog := WatchedPrograms[recoverySlot]
    TrayTip, %AppName%, Relaunching watched program, 3, 2

    Run, % prog.exePath
    Sleep, % prog.delay

    ; Play its click sequence
    if (prog.clickSequence.Length() > 0) {
        testSlotIdx := recoverySlot
        GoSub, DoPlaybackClicksForSlot
    }

    Sleep, 1000
    Gui, Recovery:Destroy
return

DoFullRestartRecovery:
    ; Show recovery message immediately
    GoSub, ShowRecoveryGui
    Sleep, 500

    TrayTip, %AppName%, Critical program closed - restarting all watched programs, 3, 2

    ; STEP 1: Close all currently running watched programs
    Loop, %MAX_PROGRAMS% {
        p := WatchedPrograms[A_Index]
        if (!p.enabled || p.exePath = "")
            continue
        Process, Exist, % p.processName
        if (ErrorLevel != 0) {
            Process, Close, % p.processName
        }
    }

    ; Give Windows a moment to fully close everything
    Sleep, 1500

    ; STEP 2: Relaunch each enabled program in slot order
    Loop, %MAX_PROGRAMS% {
        p := WatchedPrograms[A_Index]
        if (!p.enabled || p.exePath = "")
            continue
        Run, % p.exePath
        Sleep, % p.delay

        ; Play this program's click sequence
        if (p.clickSequence.Length() > 0) {
            testSlotIdx := A_Index
            GoSub, DoPlaybackClicksForSlot
        }
    }

    Sleep, 1000
    Gui, Recovery:Destroy
return

DoPlaybackClicksForSlot:
    ; Temporarily disable click blocking so our automated clicks pass through
    oldProtecting := IsProtecting
    IsProtecting := false

    playProg := WatchedPrograms[testSlotIdx]
    Loop, % playProg.clickSequence.Length() {
        cl := playProg.clickSequence[A_Index]
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

ShowRecoveryGui:
    Gui, Recovery:Destroy
    Gui, Recovery:New, +AlwaysOnTop -SysMenu -MinimizeBox -MaximizeBox +Border, %AppName% - Recovery
    Gui, Recovery:Color, 122040
    Gui, Recovery:Font, s11 Normal, Segoe UI
    Gui, Recovery:Add, Text, x30 y15 w460 Center cD4AF37, BA Custom ScreenGuard
    Gui, Recovery:Font, s18 Bold
    Gui, Recovery:Add, Text, x30 y+10 w460 Center cFFFFFF, %ReopenMessage%
    Gui, Recovery:Font, s10 Normal
    Gui, Recovery:Add, Text, x30 y+14 w460 Center cAAAADD, Restoring your programs now...
    Gui, Recovery:Add, Text, x30 y+4 w460 Center cAAAADD, Please do not touch the mouse or keyboard.
    Gui, Recovery:Font, s8
    Gui, Recovery:Add, Text, x30 y+10 w460 Center c667799, This will close automatically when done.
    SysGet, mon, MonitorWorkArea, 1
    guiW := 540
    guiH := 220
    guiX := monLeft + ((monRight - monLeft - guiW) // 2)
    guiY := monTop + ((monBottom - monTop - guiH) // 2)
    Gui, Recovery:Show, x%guiX% y%guiY% w%guiW% h%guiH% NoActivate
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
    ReopenMessage := EditReopenMsg

    IniWrite, %BlockMessage%, %ConfigFile%, General, BlockMessage
    IniWrite, %ReopenMessage%, %ConfigFile%, General, ReopenMessage
    IniWrite, %AutoProtect%, %ConfigFile%, General, AutoProtect
    IniWrite, %SilentStart%, %ConfigFile%, General, SilentStart

    ; Zones
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

    ; Watched programs
    Loop, %MAX_PROGRAMS% {
        section := "Program" . A_Index
        prog := WatchedPrograms[A_Index]
        progIdx := A_Index
        IniWrite, % prog.enabled, %ConfigFile%, %section%, Enabled
        IniWrite, % prog.name, %ConfigFile%, %section%, Name
        IniWrite, % prog.exePath, %ConfigFile%, %section%, ExePath
        IniWrite, % prog.processName, %ConfigFile%, %section%, ProcessName
        IniWrite, % prog.delay, %ConfigFile%, %section%, Delay
        IniWrite, % prog.critical, %ConfigFile%, %section%, Critical
        IniWrite, % prog.clickSequence.Length(), %ConfigFile%, %section%, ClickCount

        ; Save this program's click sequence
        clickIdx := 0
        for k, cl in prog.clickSequence {
            clickIdx += 1
            csection := "Program" . progIdx . "_Click" . clickIdx
            IniWrite, % cl.mon, %ConfigFile%, %csection%, Mon
            IniWrite, % cl.xPct, %ConfigFile%, %csection%, XPct
            IniWrite, % cl.yPct, %ConfigFile%, %csection%, YPct
            IniWrite, % cl.absX, %ConfigFile%, %csection%, AbsX
            IniWrite, % cl.absY, %ConfigFile%, %csection%, AbsY
            IniWrite, % cl.delayBefore, %ConfigFile%, %csection%, DelayBefore
        }
    }
return

DoLoadConfig:
    if (!FileExist(ConfigFile))
        return

    IniRead, BlockMessage, %ConfigFile%, General, BlockMessage, Don't close this!
    IniRead, ReopenMessage, %ConfigFile%, General, ReopenMessage, Please don't close this program again!
    IniRead, AutoProtect, %ConfigFile%, General, AutoProtect, 0
    IniRead, SilentStart, %ConfigFile%, General, SilentStart, 0

    ; Zones
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

    ; Watched programs
    WatchedPrograms := []
    Loop, %MAX_PROGRAMS% {
        section := "Program" . A_Index
        progIdx := A_Index

        IniRead, pEnabled, %ConfigFile%, %section%, Enabled, 0
        IniRead, pName, %ConfigFile%, %section%, Name, %A_Space%
        IniRead, pExe, %ConfigFile%, %section%, ExePath, %A_Space%
        IniRead, pProc, %ConfigFile%, %section%, ProcessName, %A_Space%
        IniRead, pDelay, %ConfigFile%, %section%, Delay, 3000
        IniRead, pCrit, %ConfigFile%, %section%, Critical, 0
        IniRead, pCount, %ConfigFile%, %section%, ClickCount, 0

        clickSeq := []
        Loop, %pCount% {
            csection := "Program" . progIdx . "_Click" . A_Index
            IniRead, cMon, %ConfigFile%, %csection%, Mon, 1
            IniRead, cXP, %ConfigFile%, %csection%, XPct, 0
            IniRead, cYP, %ConfigFile%, %csection%, YPct, 0
            IniRead, cAX, %ConfigFile%, %csection%, AbsX, 0
            IniRead, cAY, %ConfigFile%, %csection%, AbsY, 0
            IniRead, cDelay, %ConfigFile%, %csection%, DelayBefore, 0
            clickSeq.Push({ mon: cMon+0, xPct: cXP+0, yPct: cYP+0, absX: cAX+0, absY: cAY+0, delayBefore: cDelay+0 })
        }

        WatchedPrograms.Push({ enabled: pEnabled+0
            , name: pName
            , exePath: pExe
            , processName: pProc
            , delay: pDelay+0
            , critical: pCrit+0
            , clickSequence: clickSeq })
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
Menu, Tray, Tip, BA Custom ScreenGuard v2.0 - by BA Custom Products

ShowMainGUI:
    Gui, Main:Show,, BA Custom ScreenGuard v2.0
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

; ======================== CLICK BLOCK HOTKEY ========================

#If IsClickBlocked()
LButton::
    GoSub, HandleBlockedClick
return
#If
