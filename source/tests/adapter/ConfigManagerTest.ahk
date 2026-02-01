#Requires AutoHotkey v2.0

/**
 * Class: ConfigManagerTest
 * Validates the behavior of ConfigManager.
 * Location: source/tests/adapter/ConfigManagerTest.ahk
 */
class ConfigManagerTest {
    /** @field {ConfigManager} config - Instance under test */
    config := ""

    /**
     * Method: Setup
     * Prepares the test environment before each test case.
     */
    Setup() {
        this.config := ServiceLocator.Config
    }

    /**
     * Test: Get method should return the provided fallback when the key is missing.
     */
    Test_Get_ShouldReturnFallback_WhenKeyIsMissing() {
        expected := "fallback_value"
        actual := this.config.Get("non_existent_key_999", expected)

        Assert.Equal(expected, actual, "Fallback must be returned for missing keys.")
    }

    /**
     * Test: Get method should return an integer for 'double_tap_ms'.
     */
    Test_Get_ShouldReturnInteger_ForDoubleTapMs() {
        val := this.config.Get("double_tap_ms")

        Assert.True(IsInteger(val), "double_tap_ms should be an integer type.")
    }

    /**
     * Test: Config file should exist after Load() is called.
     */
    Test_ConfigFile_ShouldExistAfterLoad() {
        Assert.True(FileExist(this.config.configFilePath), "Config file must be created.")
    }

    /**
     * Method: Teardown
     * Cleans up after each test case.
     */
    Teardown() {
        this.config := ""
    }
}
