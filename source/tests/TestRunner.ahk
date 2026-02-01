#Requires AutoHotkey v2.0

/**
 * Class: TestRunner
 * Executes test suites and manages the test lifecycle (Setup/Teardown).
 * Results are reported via ServiceLocator.Log.
 */
class TestRunner {
    /**
     * Method: Run
     * Runs all methods in the given class instance that start with "Test_".
     * @param {Object} testSuite - An instance of a test class.
     * @returns {Boolean} True if all tests passed, otherwise false.
     */
    static Run(testSuite) {
        log := ServiceLocator.Log
        suiteName := Type(testSuite)
        log.Info(">>> Starting Test Suite: " . suiteName)

        passCount := 0
        failCount := 0

        for name in testSuite.OwnProps() {
            ; Only execute methods starting with "Test_"
            if (SubStr(name, 1, 5) !== "Test_") {
                continue
            }

            try {
                ; 1. Lifecycle: Setup
                if testSuite.HasMethod("Setup") {
                    testSuite.Setup()
                }

                ; 2. Execute Test Case
                testSuite.%name%()
                log.Info("[PASS] " . name)
                passCount++

            } catch Error as e {
                ; Failure is logged as Error to trigger an immediate flush
                log.Error("[FAIL] " . name . ": " . e.Message)
                failCount++
            } finally {
                ; 3. Lifecycle: Teardown
                if (testSuite.HasMethod("Teardown")) {
                    testSuite.Teardown()
                }
            }
        }

        summary := "--- " . suiteName . " Finished. Pass: " . passCount . ", Fail: " . failCount
        log.Info(summary)

        return failCount == 0
    }
}
