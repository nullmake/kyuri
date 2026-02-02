#Requires AutoHotkey v2.0

; --- Vendor Libraries ---
#Include lib/vendor/JSON.ahk

; --- Infrastructure Layer ---
#Include lib/infrastructure/ServiceLocator.ahk
#Include lib/infrastructure/Logger.ahk
#Include lib/infrastructure/GlobalErrorHandler.ahk

; --- Adapter Layer ---
#Include lib/adapter/ConfigManager.ahk

/**
 * Application Entry Point: Kyuri Project
 */

; 1. Setup Logging Service first to capture all initialization events
ServiceLocator.Register("Log", Logger(A_ScriptDir, 1000, 30))

; 2. Register Global Error Handler for uncaught exceptions
OnError(GlobalErrorHandler)

throw Error("Test Error before init")

try {
    ServiceLocator.Log.Info("Kyuri Project initialization sequence started.")

    ; 3. Setup Configuration Service
    configSvc := ConfigManager(A_ScriptDir)
    ServiceLocator.Register("Config", configSvc)

    ; Load settings from JSON
    ServiceLocator.Config.Load()

    ; 4. Log basic environment info
    doubleTap := ServiceLocator.Config.Get("double_tap_ms", 200)
    ServiceLocator.Log.Info("Configuration loaded. DoubleTap: " . doubleTap . "ms")
    ServiceLocator.Log.Info("Process ID: " . DllCall("GetCurrentProcessId"))

} catch Error as e {
    ; Immediate logging for predictable startup failures
    ServiceLocator.Log.Error("Initialization failed: " . e.Message)
    MsgBox("Kyuri failed to start.`nCheck the log folder for details.", "Critical Error", 16)
    ExitApp()
}

; --- Main Application Loop / Hotkeys ---
ServiceLocator.Log.Info("Kyuri is now running and ready.")

^!l:: {
    ServiceLocator.Log.Info("Manual log flush triggered by user.")
    ServiceLocator.Log.Flush("MAN")
    MsgBox("Logs have been flushed.", "Kyuri Debug", 64)
}

^!e:: {
    ; Test global handler by throwing an uncaught error
    throw Error("Simulated uncaught exception for debugging.")
}
