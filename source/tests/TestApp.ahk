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
#Include ../lib/adapter/SystemActionAdapter.ahk

; --- Core Layer ---
#Include ../lib/infrastructure/KeyEvent.ahk
#Include ../lib/core/InputProcessor.ahk

; --- Test Infrastructure & Suites ---
#Include TestRunner.ahk
#Include adapter/ConfigManagerTest.ahk
#Include adapter/SystemActionAdapterTest.ahk
#Include core/InputProcessorTest.ahk
#Include infrastructure/LoggerTest.ahk
#Include infrastructure/ServiceLocatorTest.ahk
#Include infrastructure/KeyEventTest.ahk
#Include infrastructure/AssertTest.ahk
#Include infrastructure/WindowTest.ahk
#Include infrastructure/ImeTest.ahk
#Include vender/JSONUnitTest.ahk

; Determine paths
SplitPath(A_ScriptDir, , &projectRoot)

; 1. Setup Services
_log := Logger(A_ScriptDir, 1000, 1)
ServiceLocator.Register("Log", _log)

; 2. Register Global Error Handler
OnError(GlobalErrorHandler)

try {
    _log.Info("Starting Kyuri Test Suite... (Timestamp: " . A_Now . ")")

    ; 3. Execute Test Suites
    _runner := TestRunner(_log)
    success := true
    success := _runner.Run(ConfigManagerTest()) && success
    success := _runner.Run(SystemActionAdapterTest()) && success
    success := _runner.Run(InputProcessorTest()) && success
    success := _runner.Run(LoggerTest()) && success
    success := _runner.Run(ServiceLocatorTest()) && success
    success := _runner.Run(KeyEventTest()) && success
    success := _runner.Run(AssertTest()) && success
    success := _runner.Run(WindowTest()) && success
    success := _runner.Run(ImeTest()) && success
    success := _runner.Run(JSONUnitTest()) && success

    ; 4. Report final results
    _runner.PrintFinalSummary()

    if (success) {
        _log.Info("All test suites passed.")
    } else {
        _log.Error("Test failures detected.")
    }

} catch Error as e {
    _log.Error("Test Runner crashed.", e)
}

; 5. Finalize
_log.Flush("TEST_END")
ExitApp(success ? 0 : 1)
