#Requires AutoHotkey v2.0

/**
 * Test Application Entry Point
 */

; --- Vendor Libraries ---
#Include ../lib/vendor/JSON.ahk

; --- Infrastructure Layer ---
#Include ../lib/infrastructure/ServiceLocator.ahk
#Include ../lib/infrastructure/Logger.ahk
#Include ../lib/infrastructure/Assert.ahk
#Include ../lib/infrastructure/GlobalErrorHandler.ahk

; --- Adapter Layer ---
#Include ../lib/adapter/ConfigManager.ahk

; --- Core Layer ---

; --- Test Infrastructure & Suites ---
#Include TestRunner.ahk
#Include adapter/ConfigManagerTest.ahk
#Include infrastructure/LoggerTest.ahk
#Include vender/JSONUnitTest.ahk

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
    success := true
    success := TestRunner.Run(ConfigManagerTest()) && success
    success := TestRunner.Run(LoggerTest()) && success
    success := TestRunner.Run(JSONUnitTest()) && success

    if (success) {
        ServiceLocator.Log.Info("All test suites passed.")
    } else {
        ServiceLocator.Log.Error("Test failures detected.")
    }

} catch Error as e {
    ServiceLocator.Log.Error("Test Runner crashed: " . e.Message)
}

; 4. Finalize
ServiceLocator.Log.Flush("TEST_END")
MsgBox("Tests completed. Check 'source/tests/log/' for results.", "Kyuri Test", 64)
