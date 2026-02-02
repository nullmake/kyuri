#Requires AutoHotkey v2.0

; --- Vendor Libraries ---
#Include lib/vendor/JSON.ahk

; --- Infrastructure Layer ---
#Include lib/infrastructure/ServiceLocator.ahk
#Include lib/infrastructure/Logger.ahk
#Include lib/infrastructure/GlobalErrorHandler.ahk

; --- Adapter Layer ---
#Include lib/adapter/ConfigManager.ahk

; --- Core Layer ---
#Include lib/core/KeyEvent.ahk
#Include lib/core/InputProcessor.ahk

/**
 * Application Entry Point: Kyuri Project
 */

; 1. Setup Logging Service first to capture all initialization events
ServiceLocator.Register("Log", Logger(A_ScriptDir, 1000, 30))

; 2. Register Global Error Handler for uncaught exceptions
OnError(GlobalErrorHandler)

try {
    ServiceLocator.Log.Info("Kyuri Project initialization sequence started.")

    ; 3. Setup Configuration Service
    configSvc := ConfigManager(A_ScriptDir)
    configSvc.Load()
    ServiceLocator.Register("Config", configSvc)

    ; 4. Initialize Core Engine (InputProcessor)
    ; This handles dynamic hotkey registration internally.
    processor := InputProcessor()
    ServiceLocator.Register("InputProcessor", processor)

    ; 5. Log basic environment info
    ServiceLocator.Log.Info("Config version: " . configSvc.Get("General.Version"))
    ServiceLocator.Log.Info("Process ID: " . DllCall("GetCurrentProcessId"))
    ServiceLocator.Log.Info("Kyuri is now running and ready (Direct Hotkey Mode).")

} catch Error as e {
    ServiceLocator.Log.Error("Initialization failed: " . e.Message . " at " . e.What)
    MsgBox("Kyuri failed to start.`nCheck the log folder for details.", "Critical Error", 16)
    ExitApp()
}

; --- Debug / Utility Hotkeys ---

^!l:: {
    ServiceLocator.Log.Flush("MAN")
    MsgBox("Logs have been flushed.", "Kyuri Debug", 64)
}

^!r:: Reload()

^!e:: {
    throw Error("Simulated uncaught exception for debugging.")
}
