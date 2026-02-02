#Requires AutoHotkey v2.0

/**
 * Test Application Entry Point
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
SplitPath(A_ScriptDir, , &projectRoot)

; 1. Setup Services
ServiceLocator.Register("Log", Logger(A_ScriptDir, 1000, 1))
ServiceLocator.Register("Config", ConfigManager(projectRoot))

; 2. Register Global Error Handler
OnError(GlobalErrorHandler)

try {
    ServiceLocator.Config.Load()
    ServiceLocator.Log.Info("Starting Kyuri Test Suite...")

    ; 3. Execute Test Suites
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

/**
 * Global Error Handler for Test Environment
 */
GlobalErrorHandler(thrownObj, mode) {
    try {
        ServiceLocator.Log.Error(thrownObj)
    } catch {
        OutputDebug("!!! FATAL: Logger unavailable. Original Error: " . thrownObj.Message)
    }
    return 0
}

; 4. Finalize
ServiceLocator.Log.Flush("TEST_END")
MsgBox("Tests completed. Check 'source/tests/log/' for results.", "Kyuri Test", 64)
