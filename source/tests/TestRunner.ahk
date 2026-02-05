#Requires AutoHotkey v2.0

/**
 * Class: TestRunner
 * Basic xUnit-style test executor for AutoHotkey v2.
 */
class TestRunner {
    /** @field {Logger} logger - Renamed from 'log' to avoid conflict */
    log := ""

    /**
     * Constructor: __New
     * @param {Logger} logSvc
     */
    __New(logSvc) {
        this.log := logSvc
    }

    /**
     * Method: Run
     * Runs all methods starting with 'Test_' in the given class instance.
     * @param {Object} testSuite - Instance of a test class.
     * @returns {Boolean} - True if all tests passed.
     */
    Run(testSuite) {
        suiteName := Type(testSuite)

        this.log.Info(">>> Starting Test Suite: " . suiteName)

        passCount := 0
        failCount := 0

        ; Inspect the base (prototype) of the instance to find defined methods
        for propName in testSuite.Base.OwnProps() {
            if (SubStr(propName, 1, 5) == "Test_") {
                ; Log the current method being executed (PIE)
                this.log.Info("  Running: " . propName)

                try {
                    ; Run Setup if exists
                    if HasMethod(testSuite, "Setup")
                        testSuite.Setup()

                    ; Execute the test method
                    testSuite.%propName%()

                    passCount++
                    this.log.Info("    => [PASS]")
                } catch Error as e {
                    failCount++
                    this.log.Error("    => [FAIL]", e)
                } finally {
                    ; Run Teardown if exists
                    if HasMethod(testSuite, "Teardown")
                        testSuite.Teardown()
                }
            }
        }

        this.log.Info("--- " . suiteName . " Finished. Pass: " . passCount . ", Fail: " . failCount)
        return (failCount == 0)
    }
}

