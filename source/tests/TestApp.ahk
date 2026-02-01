#Requires AutoHotkey v2.0

/**
 * Test Application Entry Point
 * Location: source/tests/TestApp.ahk
 */

; --- Vendor Libraries ---
#Include ../lib/vendor/JSON.ahk

; --- Core & Adapter Layers ---
#Include ../lib/core/ServiceLocator.ahk
#Include ../lib/core/Assert.ahk
#Include ../lib/adapter/ConfigManager.ahk
#Include ../lib/adapter/Logger.ahk

; --- Test Infrastructure & Suites ---
#Include TestRunner.ahk
#Include adapter/ConfigManagerTest.ahk
#Include adapter/LoggerTest.ahk

; Determine paths
; projectRoot is for Config (source/), while A_ScriptDir is for Test Logs (source/tests/)
SplitPath(A_ScriptDir, , &projectRoot)

; 1. Setup Services
; Log: Output to source/tests/log/
; Config: Load from source/config.json
ServiceLocator.Register("Log", Logger(A_ScriptDir, 1000, 1))
ServiceLocator.Register("Config", ConfigManager(projectRoot))

try {
    ServiceLocator.Config.Load()
    ServiceLocator.Log.Info("Starting Kyuri Test Suite...")

    ; 2. Execute Test Suites
    success := TestRunner.Run(ConfigManagerTest())
    success := TestRunner.Run(LoggerTest()) && success

    if (success) {
        ServiceLocator.Log.Info("All test suites passed.")
    } else {
        ServiceLocator.Log.Error("Test failures detected.")
    }

} catch Error as e {
    ServiceLocator.Log.Error("Test Runner crashed: " . e.Message)
}

; 3. Finalize
; Explicitly mark the end of the test without redundant EXIT log
ServiceLocator.Log.Flush("TEST_END")
MsgBox("Tests completed. Check 'source/tests/log/' for results.", "Kyuri Test", 64)
