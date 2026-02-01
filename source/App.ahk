#Requires AutoHotkey v2.0

; Vendor Libraries
#Include Lib/vendor/JSON.ahk

; Core & Adapter Layers
#Include Lib/Core/ServiceLocator.ahk
#Include Lib/Adapter/ConfigManager.ahk

/**
 * Application Entry Point
 */

; 1. Setup Configuration Service
configSvc := ConfigManager(A_ScriptDir)

; 2. Register Service (Enables ServiceLocator.Config)
ServiceLocator.Register("Config", configSvc)

; 3. Load settings
ServiceLocator.Config.Load()

; --- Verification ---
doubleTapTime := ServiceLocator.Config.Get("double_tap_ms", 200)
msg := "Kyuri Initialized.`nDouble Tap: " . doubleTapTime . "ms"
MsgBox(msg, "Kyuri Project", 64)
