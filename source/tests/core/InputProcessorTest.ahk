#Requires AutoHotkey v2.0

/**
 * Class: InputProcessorTest
 * Validates action parsing and validation logic in InputProcessor.
 */
class InputProcessorTest {
    /** @field {InputProcessor} processor - Instance under test */
    processor := ""
    /** @field {ConfigManager} config - Mock config */
    config := ""
    /** @field {Logger} log - Mock logger */
    log := ""

    Setup() {
        ; Setup minimal dependencies
        this.log := Logger(A_ScriptDir, 100, 1, false) ; logging disabled
        this.config := ConfigManager(A_ScriptDir)
        ; Prevent real hotkey registration during tests if possible, 
        ; but for now we focus on testing ParseAction which is pure logic.
        this.processor := InputProcessor(this.config, this.log)
        this.processor.validationErrors := []
    }

    /**
     * Test: ParseAction with simple keys.
     */
    Test_ParseAction_ShouldWrapSimpleKeyInBraces() {
        result := this.processor.ParseAction("Left")
        Assert.Equal("key", result.type, "Type should be key.")
        Assert.Equal("{Left}", result.data, "Data should be wrapped in braces.")
    }

    /**
     * Test: ParseAction with modifiers.
     */
    Test_ParseAction_ShouldHandleModifiers() {
        result := this.processor.ParseAction("^!Delete")
        Assert.Equal("key", result.type, "Type should be key.")
        Assert.Equal("^!{Delete}", result.data, "Modifiers should be preserved outside braces.")
    }

    /**
     * Test: ParseAction with function syntax.
     */
    Test_ParseAction_ShouldIdentifyBuiltinFunctions() {
        result := this.processor.ParseAction("IMEToggle()")
        Assert.Equal("func", result.type, "Type should be func.")
        Assert.True(IsObject(result.data), "Data should be a function reference.")
    }

    /**
     * Test: Validation error for invalid key names.
     */
    Test_ParseAction_ShouldReportInvalidKeyNames() {
        this.processor.validationErrors := []
        result := this.processor.ParseAction("InvalidKeyName")
        Assert.Equal("", result, "Result should be empty on failure.")
        Assert.Equal(1, this.processor.validationErrors.Length, "Should have one validation error.")
        Assert.True(InStr(this.processor.validationErrors[1], "Invalid key name"), "Error message should mention invalid key.")
    }

    /**
     * Test: Validation error for undefined functions.
     */
    Test_ParseAction_ShouldReportUndefinedFunctions() {
        this.processor.validationErrors := []
        result := this.processor.ParseAction("UnknownFunc()")
        Assert.Equal("", result, "Result should be empty on failure.")
        Assert.Equal(1, this.processor.validationErrors.Length, "Should have one validation error.")
        Assert.True(InStr(this.processor.validationErrors[1], "Undefined built-in function"), "Error message should mention undefined function.")
    }

    Teardown() {
        this.processor := ""
        this.config := ""
        this.log := ""
    }
}
