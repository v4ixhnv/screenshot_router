#Requires AutoHotkey v2.0
#SingleInstance Force

; ===================================================================
; Screenshot Router
; Intercepts PrintScreen / Snipping Tool captures and provides an
; instant single-key routing HUD to organize screenshots.
; ===================================================================

A_IconTip := "Screenshot Router"

; --- Paths and Configuration ---
picturesDir := EnvGet("USERPROFILE") "\Pictures"
defaultSourceDir := picturesDir "\Screenshots"
configFile := A_ScriptDir "\config.ini"
exampleConfigFile := A_ScriptDir "\config.example.ini"

; Default presets in case config.ini is missing or unreadable
defaultPresets := Map(
    "1", { name: "College / Lab", path: picturesDir "\SortedScreenshots\College" },
    "2", { name: "Projects",      path: picturesDir "\SortedScreenshots\Projects" },
    "3", { name: "UI & Refs",     path: picturesDir "\SortedScreenshots\References" }
)

; Ensure config.ini exists (copy from example or generate)
EnsureConfigFile(configFile, exampleConfigFile)

; Load settings from config.ini
screenshotSourceDir := LoadSourceDir(configFile, defaultSourceDir)
filePrefix          := LoadSetting(configFile, "Settings", "FilePrefix", "snap_")
timestampFormat     := LoadSetting(configFile, "Settings", "TimestampFormat", "yyyyMMdd_HHmmss")
waitTimeoutMs       := Integer(LoadSetting(configFile, "Settings", "TimeoutMs", "15000"))
presets             := LoadPresets(configFile, defaultPresets)

; Ensure source folder exists
if !DirExist(screenshotSourceDir)
    DirCreate(screenshotSourceDir)

; Ensure preset destination folders exist
for _, item in presets {
    if !DirExist(item.path)
        DirCreate(item.path)
}

; Build system tray menu
SetupTrayMenu()

pickerGui := 0
pendingFile := ""

; --- Hotkey: PrintScreen ---
$PrintScreen:: {
    global screenshotSourceDir, pendingFile, waitTimeoutMs

    beforeTime := GetLatestFileTime(screenshotSourceDir)

    ; Release PrintScreen cleanly and trigger Windows Snipping overlay (#+s)
    KeyWait "PrintScreen"
    Send "#+s"

    ; Poll briefly for a newly created file in screenshotSourceDir
    newFile := WaitForNewScreenshot(screenshotSourceDir, beforeTime, waitTimeoutMs)
    if (newFile != "") {
        pendingFile := newFile
        ShowDestinationGui(newFile)
    } else {
        TrayTip "No new screenshot detected in " screenshotSourceDir, "Screenshot Router", 1
    }
}

; --- Core Helper Functions ---

GetLatestFileTime(dir) {
    latest := 0
    if !DirExist(dir)
        return latest
    Loop Files, dir "\*.*" {
        if IsImageExt(A_LoopFileExt) && (A_LoopFileTimeModified != "") && (A_LoopFileTimeModified > latest) {
            latest := A_LoopFileTimeModified
        }
    }
    return latest
}

WaitForNewScreenshot(dir, previousLatestTime, timeoutMs) {
    startTick := A_TickCount
    while (A_TickCount - startTick < timeoutMs) {
        Sleep 250
        if !DirExist(dir)
            continue
        Loop Files, dir "\*.*" {
            if IsImageExt(A_LoopFileExt) && (A_LoopFileTimeModified != "") && (A_LoopFileTimeModified > previousLatestTime) {
                ; Brief pause so Windows finishes writing/flushing the image file
                Sleep 250
                return A_LoopFileFullPath
            }
        }
    }
    return ""
}

IsImageExt(ext) {
    ext := StrLower(ext)
    return (ext = "png" || ext = "jpg" || ext = "jpeg" || ext = "webp" || ext = "bmp")
}

ShowDestinationGui(filePath) {
    global pickerGui, presets

    if IsObject(pickerGui) {
        pickerGui.Destroy()
        pickerGui := 0
    }

    SplitPath filePath, &fileName

    g := Gui("+AlwaysOnTop -MinimizeBox", "Route Screenshot")
    g.SetFont("s10", "Segoe UI")
    g.AddText("w360", "Captured: " fileName)
    g.AddText("w360 cGray", "Press 1-" presets.Count " for quick folder, 0 to browse, or Esc:")

    for key, item in presets {
        btn := g.AddButton("w360 h34", "[" key "]  " item.name)
        targetPath := item.path
        btn.OnEvent("Click", ((dest) => (*) => MoveCapturedFile(dest))(targetPath))
    }

    browseBtn := g.AddButton("w360 h34", "[0]  Browse Custom Folder...")
    browseBtn.OnEvent("Click", (*) => BrowseAndMove())

    cancelBtn := g.AddButton("w360 h30", "Keep in Screenshots (Esc)")
    cancelBtn.OnEvent("Click", (*) => ClosePicker())

    g.OnEvent("Escape", (*) => ClosePicker())
    g.OnEvent("Close", (*) => ClosePicker())

    ; Register temporary hotkeys while picker is open
    for key, item in presets {
        targetPath := item.path
        Hotkey(key, ((dest) => (*) => MoveCapturedFile(dest))(targetPath), "On")
    }

    Hotkey("0", (*) => BrowseAndMove(), "On")
    Hotkey("Escape", (*) => ClosePicker(), "On")

    pickerGui := g
    g.Show("AutoSize Center")
    WinActivate("ahk_id " g.Hwnd)
}

BrowseAndMove() {
    global pickerGui, pendingFile, picturesDir

    try Hotkey("0", "Off")

    if IsObject(pickerGui) {
        pickerGui.Opt("-AlwaysOnTop +Disabled")
    }

    chosen := DirSelect("*" picturesDir, 3, "Select destination folder for screenshot")

    if IsObject(pickerGui) {
        pickerGui.Opt("-Disabled +AlwaysOnTop")
    }

    if (chosen != "") {
        MoveCapturedFile(chosen)
    } else if IsObject(pickerGui) {
        Hotkey("0", (*) => BrowseAndMove(), "On")
        WinActivate("ahk_id " pickerGui.Hwnd)
    }
}

MoveCapturedFile(destDir) {
    global pendingFile, filePrefix, timestampFormat
    if (pendingFile = "" || !FileExist(pendingFile)) {
        ClosePicker()
        return
    }

    if !DirExist(destDir)
        DirCreate(destDir)

    SplitPath pendingFile, , , &ext
    stamp := FormatTime(, timestampFormat)
    destFile := destDir "\" filePrefix stamp "." ext

    ; Prevent filename collision if multiple shots taken in the same second
    collisionIndex := 1
    while FileExist(destFile) {
        destFile := destDir "\" filePrefix stamp "_" collisionIndex "." ext
        collisionIndex++
    }

    try {
        FileMove pendingFile, destFile, 1
        TrayTip "Moved to: " destDir, "Screenshot Routed", 1
    } catch as err {
        MsgBox "Failed to move file:`n" err.Message, "Screenshot Router Error", "Icon!"
    }

    pendingFile := ""
    ClosePicker()
}

ClosePicker() {
    global pickerGui, presets

    for key, _ in presets {
        try Hotkey(key, "Off")
    }
    try Hotkey("0", "Off")
    try Hotkey("Escape", "Off")

    if IsObject(pickerGui) {
        pickerGui.Destroy()
        pickerGui := 0
    }
}

; --- Configuration Loaders ---

ExpandEnvVars(str) {
    return RegExReplace(str, "%([^%]+)%", (m) => EnvGet(m[1]))
}

EnsureConfigFile(cfgPath, examplePath) {
    if FileExist(cfgPath)
        return

    if FileExist(examplePath) {
        try {
            FileCopy examplePath, cfgPath
            return
        }
    }

    ; Fallback generation if example is absent
    defaultContent := 
(
"; ===================================================================
; Screenshot Router - Configuration
; ===================================================================

[Settings]
ScreenshotSourceDir =
FilePrefix = snap_
TimestampFormat = yyyyMMdd_HHmmss
TimeoutMs = 15000

[Presets]
1 = College / Lab | %USERPROFILE%\Pictures\SortedScreenshots\College
2 = Projects      | %USERPROFILE%\Pictures\SortedScreenshots\Projects
3 = UI & Refs     | %USERPROFILE%\Pictures\SortedScreenshots\References
"
)
    try FileAppend defaultContent, cfgPath, "UTF-8"
}

LoadSetting(cfgPath, section, key, fallbackVal) {
    try {
        val := IniRead(cfgPath, section, key, fallbackVal)
        return (val != "") ? val : fallbackVal
    } catch {
        return fallbackVal
    }
}

LoadSourceDir(cfgPath, fallbackDir) {
    try {
        val := IniRead(cfgPath, "Settings", "ScreenshotSourceDir", "")
        if (val != "") {
            expanded := ExpandEnvVars(val)
            if DirExist(expanded)
                return expanded
        }
    }
    return fallbackDir
}

LoadPresets(cfgPath, fallbackPresets) {
    presetsMap := Map()

    try {
        raw := IniRead(cfgPath, "Presets")
        Loop Parse, raw, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line = "" || SubStr(line, 1, 1) = ";")
                continue

            eqPos := InStr(line, "=")
            if (eqPos > 0) {
                key := Trim(SubStr(line, 1, eqPos - 1))
                val := Trim(SubStr(line, eqPos + 1))

                pipePos := InStr(val, "|")
                if (pipePos > 0) {
                    pName := Trim(SubStr(val, 1, pipePos - 1))
                    pPath := Trim(SubStr(val, pipePos + 1))
                } else {
                    pName := val
                    pPath := val
                }

                pPath := ExpandEnvVars(pPath)
                presetsMap[key] := { name: pName, path: pPath }
            }
        }
    } catch {
        return fallbackPresets
    }

    return (presetsMap.Count > 0) ? presetsMap : fallbackPresets
}

SetupTrayMenu() {
    global configFile, screenshotSourceDir

    tray := A_TrayMenu
    tray.Delete()
    tray.Add("Screenshot Router (Running)", (*) => "")
    tray.Disable("Screenshot Router (Running)")
    tray.Add() ; Separator
    tray.Add("Edit Config (config.ini)", (*) => Run('notepad.exe "' configFile '"'))
    tray.Add("Open Source Screenshots Folder", (*) => Run('explorer.exe "' screenshotSourceDir '"'))
    tray.Add() ; Separator
    tray.Add("Reload Script", (*) => Reload())
    tray.Add("Exit", (*) => ExitApp())
}
