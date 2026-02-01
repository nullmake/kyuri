#Requires AutoHotkey v2.0

; --- Vendor Libraries ---
#Include Lib/vendor/JSON.ahk

; --- Core & Adapter Layers ---
#Include Lib/Core/ServiceLocator.ahk
#Include Lib/Adapter/ConfigManager.ahk
#Include Lib/Adapter/Logger.ahk

/**
 * Application Entry Point: Kyuri Project
 */

; 1. Setup Logging Service first to capture all initialization events
; Configuration: 1000 lines buffer, 30 max files
ServiceLocator.Register("Log", Logger(A_ScriptDir, 1000, 30))

try {
    ServiceLocator.Log.Info("Kyuri Project initialization sequence started.")

    ; 2. Setup Configuration Service
    configSvc := ConfigManager(A_ScriptDir)
    ServiceLocator.Register("Config", configSvc)

    ; Load settings from JSON
    ServiceLocator.Config.Load()

    ; 3. Log basic environment info
    doubleTap := ServiceLocator.Config.Get("double_tap_ms", 200)
    ServiceLocator.Log.Info("Configuration loaded. DoubleTap: " . doubleTap . "ms")
    ServiceLocator.Log.Info("Process ID: " . DllCall("GetCurrentProcessId"))

} catch Error as e {
    ; Any failure during startup triggers an immediate log flush
    ServiceLocator.Log.Error("Initialization failed: " . e.Message)
    MsgBox("Kyuri failed to start.`nCheck the log folder for details.", "Critical Error", 16)
    ExitApp()
}

; --- Main Application Loop / Hotkeys ---

ServiceLocator.Log.Info("Kyuri is now running and ready.")

; Simple test hotkey (Ctrl+Alt+L) to manually trigger a log flush
^!l:: {
    ServiceLocator.Log.Info("Manual log flush triggered by user.")
    ServiceLocator.Log.Flush("MAN")
    MsgBox("Logs have been flushed to the log/ directory.", "Kyuri Debug", 64)
}

; Test hotkey to simulate an error (Ctrl+Alt+E)
^!e:: {
    ServiceLocator.Log.Error("Simulated error for logging verification.")
}
