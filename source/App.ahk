#Requires AutoHotkey v2.0

; --- Vendor Libraries ---
#Include lib/vendor/JSON.ahk

; --- Infrastructure Layer ---
#Include lib/infrastructure/ServiceLocator.ahk
#Include lib/infrastructure/Logger.ahk
#Include lib/infrastructure/GlobalErrorHandler.ahk

; --- Adapter Layer ---
#Include lib/adapter/ConfigManager.ahk
#Include lib/adapter/SystemActionAdapter.ahk

; --- Core Layer ---
#Include lib/core/KeyEvent.ahk
#Include lib/core/InputProcessor.ahk

/**
 * Application Entry Point: Kyuri Project
 */

; 1. Setup Logging Service first to capture all initialization events
_log := Logger(A_ScriptDir, 1000, 30)
ServiceLocator.Register("Log", _log)

; 2. Register Global Error Handler for uncaught exceptions
OnError(GlobalErrorHandler)

try {
    _log.Info("Kyuri Project initialization sequence started.")

    ; 3. Setup Configuration Service
    _configSvc := ConfigManager(A_ScriptDir)
    _configSvc.Load()

    ; 4. Setup System Actions
    _sysActionSvc := SystemActionAdapter()
    _actions := _sysActionSvc.GetActions()

    ; 5. Initialize Core Engine (InputProcessor)
    _processor := InputProcessor(_configSvc, _log, _actions)

    ; 6. Log basic environment info
    _log.Info("Config version: " . _configSvc.Get("General.Version"))
    _log.Info("Process ID: " . DllCall("GetCurrentProcessId"))
    _log.Info("Kyuri is now running and ready (Direct Hotkey Mode).")

} catch Error as e {
    _Log.Error("Initialization failed: ", e)
    MsgBox("Kyuri failed to start.`nCheck the log folder for details.", "Critical Error", 16)
    ExitApp()
}

; --- Debug / Utility Hotkeys ---

^!l:: {
    _log.Flush("MAN")
    MsgBox("Logs have been flushed.", "Kyuri Debug", 64)
}

^!r:: Reload()

^!e:: {
    throw Error("Simulated uncaught exception for debugging.")
}
