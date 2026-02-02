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
_log := Logger(A_ScriptDir, 1000, 1)
ServiceLocator.Register("Log", _log)

; 2. Register Global Error Handler
OnError(GlobalErrorHandler)

try {
    _log.Info("Starting Kyuri Test Suite...")

    ; 3. Execute Test Suites
    _runner := TestRunner(_log)
    success := true
    success := _runner.Run(ConfigManagerTest()) && success
    success := _runner.Run(LoggerTest()) && success
    success := _runner.Run(JSONUnitTest()) && success

    if (success) {
        _log.Info("All test suites passed.")
    } else {
        _log.Error("Test failures detected.")
    }

} catch Error as e {
    _Log.Error("Test Runner crashed: " . e.Message)
}

; 4. Finalize
_log.Flush("TEST_END")
MsgBox("Tests completed. Check 'source/tests/log/' for results.", "Kyuri Test", 64)
