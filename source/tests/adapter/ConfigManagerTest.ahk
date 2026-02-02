#Requires AutoHotkey v2.0

/**
 * Class: ConfigManagerTest
 * Validates ConfigManager using a dedicated test configuration.
 * This ensures tests don't fail due to user-specific config changes.
 */
class ConfigManagerTest {
    /** @field {ConfigManager} config - Instance under test */
    config := ""
    /** @field {String} testDir - Temporary directory for test files */
    testDir := A_ScriptDir . "\_test_temp"

    /**
     * Method: Setup
     * Creates a dummy config.json for isolated testing.
     */
    Setup() {
        if (!DirExist(this.testDir)) {
            DirCreate(this.testDir)
        }

        ; Define test-specific configuration
        testJson := '
        (
        {
            "General": { "Version": "9.9.9" },
            "Modifiers": {
                "M0": { "vkCode": "vk1D", "Fallback": "LAlt" }
            },
            "Remaps": [
                { "Trigger": "h", "HoldM0": "Left" }
            ]
        }
        )'

        testFilePath := this.testDir . "\config.json"
        if (FileExist(testFilePath)) {
            FileDelete(testFilePath)
        }
        FileAppend(testJson, testFilePath, "UTF-8")

        ; Initialize ConfigManager pointing to the test directory
        this.config := ConfigManager(this.testDir)
        this.config.Load()
    }

    /**
     * Test: Get method with nested keys using test data.
     */
    Test_Get_ShouldReturnNestedValuesFromTestData() {
        Assert.Equal("9.9.9", this.config.Get("General.Version"), "Should read test version.")
        Assert.Equal("LAlt", this.config.Get("Modifiers.M0.Fallback"), "Should read test fallback.")
    }

    /**
     * Test: Get method with arrays using test data.
     */
    Test_Get_ShouldReturnArrayDataFromTestData() {
        remaps := this.config.Get("Remaps")
        Assert.Equal("h", remaps[1]["Trigger"], "Should read first remap trigger from test data.")
    }

    /**
     * Test: Fallback value when key is missing.
     */
    Test_Get_ShouldReturnProvidedFallback() {
        Assert.Equal("missing", this.config.Get("Invalid.Path", "missing"), "Should return fallback.")
    }

    /**
     * Method: Teardown
     * Cleans up the temporary test directory.
     */
    Teardown() {
        this.config := ""
        if (DirExist(this.testDir)) {
            DirDelete(this.testDir, true)
        }
    }
}
