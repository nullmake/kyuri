#Requires AutoHotkey v2.0

#Include ../../lib/infrastructure/KeyEvent.ahk

/**
 * @class MockSystemActionAdapter
 * Captures calls to system actions for verification.
 */
class MockSystemActionAdapter extends SystemActionAdapter {
    /** @field {Array} callHistory - Recorded names of called methods */
    callHistory := []

    /**
     * @method IMEToggle
     * Mocked IME toggle that records the call.
     * @param {Any} params* - Variadic parameters.
     */
    IMEToggle(params*) {
        this.callHistory.Push("IMEToggle")
    }

    /**
     * @method GetActions
     * Returns actions mapped to mocked methods.
     * @returns {Map}
     */
    GetActions() {
        actions := Map()
        actions["IMEToggle"] := this.IMEToggle.Bind(this)
        return actions
    }
}

/**
 * @class InputProcessorTest
 * Validates action parsing and state machine logic in InputProcessor.
 */
class InputProcessorTest {
    /** @field {InputProcessor} processor - The instance under test */
    processor := ""
    /** @field {ConfigManager} config - Mocked configuration manager */
    config := ""
    /** @field {Logger} log - Mocked logger */
    log := ""
    /** @field {MockSystemActionAdapter} mockSys - Mocked system action adapter */
    mockSys := ""
    /** @field {Array} sentKeys - Captured key strings from overridden LowLevelSend method */
    sentKeys := []

    /**
     * @method Setup
     * Initializes dependencies and overrides LowLevelSend method before each test.
     */
    Setup() {
        this.log := Logger(A_ScriptDir, 100, 1, false)
        this.config := ConfigManager(A_ScriptDir)

        ; Setup a controlled configuration for testing
        this.config.settings := Map(
            "Modifiers", Map(
                "M0", Map("vkCode", "vk1D", "DoublePressInterval", 300, "Fallback", "LAlt"),
                "M1", Map("vkCode", "vk1C", "DoublePressInterval", 300, "Fallback", "LControl")
            ),
            "Triggers", Map(
                "DoubleTap", Map("vk1D", "Launcher")
            ),
            "Remaps", [
                Map("Trigger", "h", "HoldM0", "Left", "HoldM1", "^Left"),
                Map("Trigger", "j", "HoldM1", "+Down"),
                Map("Trigger", "vkF0", "Tap", "IMEToggle()")
            ]
        )

        this.mockSys := MockSystemActionAdapter()
        this.processor := InputProcessor(this.config, this.log, this.mockSys)

        ; Override only the LowLevelSend method using DefineProp to intercept final key output
        this.sentKeys := []
        this.processor.DefineProp("LowLevelSend", {
            Call: (obj, keyStr) => this.sentKeys.Push(keyStr)
        })
    }

    /**
     * @method Test_ParseAction_ShouldCreateKeyActionObject
     */
    Test_ParseAction_ShouldCreateKeyActionObject() {
        result := this.processor.ParseAction("Left", "h")
        Assert.Equal(KeyActionType.KEY, result.Type, "Action type should be KEY.")
        Assert.Equal("{Left}", result.Data, "Key should be wrapped in braces.")
        Assert.Equal("h", result.Trigger, "Trigger should be recorded.")
    }

    /**
     * @method Test_M0_Hold_Remap_ShouldSuppressAndSendRemappedKey
     */
    Test_M0_Hold_Remap_ShouldSuppressAndSendRemappedKey() {
        ; 1. M0 Down (Suppressed)
        res := this.processor.ProcessKeyEvent(KeyEvent("vk1D", true, true))
        Assert.Equal(1, res, "M0 Down should be suppressed.")
        Assert.True(this.processor.m0.IsHeld, "M0 state should be 'Held'.")

        ; 2. 'h' Down (Suppressed and remapped to Left)
        res := this.processor.ProcessKeyEvent(KeyEvent("h", true, true))
        Assert.Equal(1, res, "'h' Down should be suppressed.")
        Assert.Equal(1, this.sentKeys.Length, "Should have captured one Send call.")
        Assert.Equal("{Blind}{Left}", this.sentKeys[1], "Should have sent remapped key with {Blind}.")

        ; 3. 'h' Up (Suppressed and send Up)
        res := this.processor.ProcessKeyEvent(KeyEvent("h", false, true))
        Assert.Equal(1, res, "'h' Up should be suppressed.")
        Assert.Equal(2, this.sentKeys.Length, "Should have captured two Send calls total.")
        Assert.Equal("{Blind}{h up}", this.sentKeys[2], "Should have sent the original key Up event.")

        ; 4. M0 Up (Suppressed)
        res := this.processor.ProcessKeyEvent(KeyEvent("vk1D", false, true))
        Assert.Equal(1, res, "M0 Up should be suppressed.")
        Assert.False(this.processor.m0.IsHeld, "M0 state should not be 'Held'.")
    }

    /**
     * @method Test_M0_Hold_NoRemap_ShouldFallbackToModifier
     */
    Test_M0_Hold_NoRemap_ShouldFallbackToModifier() {
        ; 1. M0 Down
        this.processor.ProcessKeyEvent(KeyEvent("vk1D", true, true))

        ; 2. 'x' Down (No remap for 'x')
        ; Should send Fallback (LAlt) and 'x'
        res := this.processor.ProcessKeyEvent(KeyEvent("x", true, true))
        Assert.Equal(1, res, "'x' Down should be suppressed for fallback.")
        Assert.Equal(2, this.sentKeys.Length, "Should have sent fallback modifier and key.")
        Assert.Equal("{Blind}{LAlt down}", this.sentKeys[1])
        Assert.Equal("{Blind}{x down}", this.sentKeys[2])

        ; 3. 'x' Up
        res := this.processor.ProcessKeyEvent(KeyEvent("x", false, true))
        Assert.Equal(1, res, "'x' Up should be suppressed.")
        Assert.Equal(3, this.sentKeys.Length)
        Assert.Equal("{Blind}{x up}", this.sentKeys[3])

        ; 4. M0 Up
        this.processor.ProcessKeyEvent(KeyEvent("vk1D", false, true))
        Assert.Equal(4, this.sentKeys.Length)
        Assert.Equal("{Blind}{LAlt up}", this.sentKeys[4], "Should release LAlt on M0 Up.")
    }

    /**
     * @method Test_Remap_ShouldClearActiveFallbacks
     * Verifies that active fallback modifiers are released when a remapped key is pressed.
     */
    Test_Remap_ShouldClearActiveFallbacks() {
        ; 1. M1 Down
        this.processor.ProcessKeyEvent(KeyEvent("vk1C", true, true))

        ; 2. 'i' Down (Unregistered, triggers LControl fallback)
        this.processor.ProcessKeyEvent(KeyEvent("i", true, true))
        Assert.Equal("{Blind}{LControl down}", this.sentKeys[1])
        Assert.Equal("{Blind}{i down}", this.sentKeys[2])
        Assert.True(this.processor.m1.FallbackSent)

        ; 3. 'i' Up
        this.processor.ProcessKeyEvent(KeyEvent("i", false, true))
        Assert.Equal("{Blind}{i up}", this.sentKeys[3], "The suppressed key's Up event should be sent.")

        ; 4. 'j' Down (Registered: HoldM1 -> +Down)
        ; This should trigger ClearActiveFallbacks and release LControl
        this.processor.ProcessKeyEvent(KeyEvent("j", true, true))

        Assert.Equal("{Blind}{LControl up}", this.sentKeys[4], "Should release LControl before remapping.")
        Assert.False(this.processor.m1.FallbackSent, "FallbackSent flag should be cleared.")
        Assert.Equal("{Blind}+{Down}", this.sentKeys[5], "Should then send remapped key.")
    }

    /**
     * @method Test_BaseLayer_NoRemap_ShouldPassThrough
     */
    Test_BaseLayer_NoRemap_ShouldPassThrough() {
        ; 'x' Down in Base layer
        res := this.processor.ProcessKeyEvent(KeyEvent("x", true, true))
        Assert.Equal(0, res, "'x' should pass through in Base layer if no remap.")
    }

    /**
     * @method Test_BaseLayer_WithRemap_ShouldSuppressAndSend
     */
    Test_BaseLayer_WithRemap_ShouldSuppressAndSend() {
        ; CapsLock (vkF0) is remapped to IMEToggle() in our mock config
        res := this.processor.ProcessKeyEvent(KeyEvent("vkF0", true, true))
        Assert.Equal(1, res, "Remapped key in Base layer should be suppressed.")
        Assert.Equal(1, this.mockSys.callHistory.Length, "IMEToggle should have been called.")
        Assert.Equal("IMEToggle", this.mockSys.callHistory[1])
    }

    /**
     * @method Test_Initialization_ShouldThrowErrorOnInvalidKey
     */
    Test_Initialization_ShouldThrowErrorOnInvalidKey() {
        badConfig := ConfigManager(A_ScriptDir)
        badConfig.settings := Map(
            "Modifiers", Map("M0", Map("vkCode", "vk1D", "Fallback", "LAlt")),
            "Remaps", [ Map("Trigger", "h", "Tap", "InvalidKeyName") ]
        )
        
        try {
            InputProcessor(badConfig, this.log, this.mockSys)
            Assert.Fail("Should have thrown validation error for invalid key.")
        } catch Error as e {
            Assert.True(InStr(e.Message, "InputProcessor validation failed"), "Error message should mention validation failure.")
        }
    }

    /**
     * @method Test_Initialization_ShouldThrowErrorOnUndefinedFunc
     */
    Test_Initialization_ShouldThrowErrorOnUndefinedFunc() {
        badConfig := ConfigManager(A_ScriptDir)
        badConfig.settings := Map(
            "Modifiers", Map("M0", Map("vkCode", "vk1D", "Fallback", "LAlt")),
            "Remaps", [ Map("Trigger", "h", "Tap", "UnknownFunc()") ]
        )
        
        try {
            InputProcessor(badConfig, this.log, this.mockSys)
            Assert.Fail("Should have thrown validation error for undefined function.")
        } catch Error as e {
            Assert.True(InStr(e.Message, "Undefined built-in function"), "Error message should mention the undefined function.")
        }
    }

    /**
     * @method Teardown
     * Cleans up instances after each test.
     */
    Teardown() {
        this.processor := ""
        this.config := ""
        this.log := ""
        this.mockSys := ""
        this.sentKeys := []
    }
}
