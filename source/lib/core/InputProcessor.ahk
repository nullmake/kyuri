#Requires AutoHotkey v2.0

#Include LayerType.ahk
#Include KeyActionType.ahk
#Include ModifierState.ahk
#Include KeyAction.ahk
#Include LayerRemap.ahk
#Include KeyState.ahk

/**
 * @class InputProcessor
 * Logic engine that dispatches actions based on modifier states and configuration.
 * Re-implemented to use KeyboardHook for zero-latency and full control.
 */
class InputProcessor {
    /** @field {Logger} log - Application logger instance */
    log := ""
    /** @field {SystemActionAdapter} sysActionSvc - Reference to system action adapter */
    sysActionSvc := ""
    /** @field {Map} builtinActions - Registry of available special action methods */
    builtinActions := Map()

    /** @field {ModifierState} m0 - State for virtual modifier 0 */
    m0 := ModifierState("M0")
    /** @field {ModifierState} m1 - State for virtual modifier 1 */
    m1 := ModifierState("M1")
    /** @field {Map} vkToMod - Mapping of vkCode to ModifierState object */
    vkToMod := Map()

    /** @field {ModifierState} oneshotCandidate - The mod key that might trigger a one-shot action */
    oneshotCandidate := ""
    /** @field {Integer} doublePressInterval - Max time between taps for double-tap detection */
    doublePressInterval := 300

    /** @field {Map} remaps - Mapping of physical key to LayerRemap instance */
    remaps := Map()
    /** @field {Map} keyStates - Mapping of physical key to KeyState instance */
    keyStates := Map()

    /** @field {Array} validationErrors - List of errors found during initialization */
    validationErrors := []

    /**
     * @method __New
     * @constructor
     * @param {ConfigManager} configSvc
     * @param {Logger} logSvc
     * @param {SystemActionAdapter} sysActionSvc
     */
    __New(configSvc, logSvc, sysActionSvc) {
        this.log := logSvc
        this.sysActionSvc := sysActionSvc
        this.builtinActions := sysActionSvc.GetActions()
        this.Initialize(configSvc)
        this.ReportValidationResults()
    }

    /**
     * @method Initialize
     * Loads configuration and prepares internal data structures.
     * @param {ConfigManager} configSvc
     */
    Initialize(configSvc) {
        this.log.Info("Initializing InputProcessor...")

        this.doublePressInterval := configSvc.Get("Modifiers.M0.DoublePressInterval", 300)

        ; 1. Load Modifiers
        mods := Map("M0", this.m0, "M1", this.m1)
        for modName, modObj in mods {
            vk := configSvc.Get("Modifiers." . modName . ".vkCode")
            if (vk == "") {
                continue
            }
            modObj.VkCode := vk
            modObj.FallbackKey := configSvc.Get("Modifiers." . modName . ".Fallback", "")
            this.vkToMod[vk] := modObj
        }

        ; 2. Load DoubleTap Triggers
        doubleTaps := configSvc.Get("Triggers.DoubleTap")
        if (doubleTaps is Map) {
            for key, actionName in doubleTaps {
                if (this.vkToMod.Has(key)) {
                    this.vkToMod[key].DoubleTapAction := actionName
                }
            }
        }

        ; 3. Load Remaps
        remapsConfig := configSvc.Get("Remaps")
        if (remapsConfig is Array) {
            for entry in remapsConfig {
                trigger := entry["Trigger"]
                remap := LayerRemap()

                if (entry.Has("Tap")) {
                    remap.Tap := this.ParseAction(entry["Tap"], trigger)
                }
                if (entry.Has("HoldM0")) {
                    remap.HoldM0 := this.ParseAction(entry["HoldM0"], trigger)
                }
                if (entry.Has("HoldM1")) {
                    remap.HoldM1 := this.ParseAction(entry["HoldM1"], trigger)
                }
                if (entry.Has("HoldBoth")) {
                    remap.HoldBoth := this.ParseAction(entry["HoldBoth"], trigger)
                }

                this.remaps[trigger] := remap
            }
        }
    }

    /**
     * @method ParseAction
     * Parses an action string from configuration.
     * @param {String} actionStr - The action string.
     * @param {String} trigger - The key name associated with this remap.
     * @returns {KeyAction|Blank} - KeyAction object or Blank on failure.
     */
    ParseAction(actionStr, trigger) {
        if (actionStr == "") {
            return ""
        }

        if (RegExMatch(actionStr, "^(\w+)\(\)$", &match)) {
            funcName := match[1]
            if (this.builtinActions.Has(funcName)) {
                return KeyAction(KeyActionType.FUNC, this.builtinActions[funcName], trigger)
            } else {
                this.validationErrors.Push("Undefined built-in function: " . actionStr)
                return ""
            }
        }

        if (RegExMatch(actionStr, "^([\^!+#]*)(.+)$", &match)) {
            mods := match[1]
            keyName := match[2]
            if (GetKeyVK(keyName) == 0) {
                this.validationErrors.Push("Invalid key name: '" . keyName . "' in action '" . actionStr . "'")
                return ""
            }
            return KeyAction(KeyActionType.KEY, mods . "{" . keyName . "}", trigger)
        }

        this.validationErrors.Push("Invalid action syntax: " . actionStr)
        return ""
    }

    /**
     * @method ReportValidationResults
     * Displays a summary of validation errors if any occurred.
     */
    ReportValidationResults() {
        if (this.validationErrors.Length > 0) {
            msg := "Kyuri Configuration Errors:`n`n"
            for err in this.validationErrors {
                this.log.Error("Configuration validation error: " . err)
                msg .= "- " . err . "`n"
            }
            MsgBox(msg, "Kyuri Config Error", 48)
        }
    }

    /**
     * @method ProcessKeyEvent
     * Main event handler called by KeyboardHook.
     * @param {KeyEvent} event
     * @returns {Integer} 1 to suppress, 0 to pass-through.
     */
    ProcessKeyEvent(event) {
        ; Ignore artificial inputs to avoid infinite loops
        if (!event.IsPhysical) {
            return 0
        }

        keyName := event.Name
        isDown := event.IsDown

        ; 1. Check if it's a virtual modifier (M0/M1)
        if (this.vkToMod.Has(keyName)) {
            mod := this.vkToMod[keyName]
            if (isDown) {
                this.HandleModifierDown(mod)
            } else {
                this.HandleModifierUp(mod)
            }
            return 1 ; Always suppress M0/M1 physical keys
        }

        ; 2. Handle other keys
        if (isDown) {
            return this.HandleKeyDown(keyName)
        } else {
            return this.HandleKeyUp(keyName)
        }
    }

    /**
     * @method HandleModifierDown
     * Handler for virtual modifier press.
     * @param {ModifierState} mod - The modifier state object.
     */
    HandleModifierDown(mod) {
        OutputDebug("[Kyuri] Modifier Down: " . mod.Name)
        mod.IsHeld := true
        this.oneshotCandidate := mod
        mod.FallbackSent := false
    }

    /**
     * @method HandleModifierUp
     * Handler for virtual modifier release.
     * @param {ModifierState} mod - The modifier state object.
     */
    HandleModifierUp(mod) {
        OutputDebug("[Kyuri] Modifier Up: " . mod.Name)
        mod.IsHeld := false

        ; DoubleTap detection
        if (this.oneshotCandidate == mod) {
            currentTime := A_TickCount
            if (currentTime - mod.LastTapTime < this.doublePressInterval) {
                this.ExecuteDoubleTap(mod)
                mod.LastTapTime := 0
            } else {
                mod.LastTapTime := currentTime
                ; One-shot logic could go here if needed
            }
        }

        ; Release fallback key if it was sent
        if (mod.FallbackSent) {
            if (mod.FallbackKey != "") {
                OutputDebug("[Kyuri] Releasing Fallback: " . mod.FallbackKey)
                this.Send("{" . mod.FallbackKey . " up}")
            }
            mod.FallbackSent := false
        }

        this.oneshotCandidate := ""
    }

    /**
     * @method HandleKeyDown
     * Handler for physical key down events (non-modifier).
     * @param {String} keyName - The name of the key.
     * @returns {Integer} 1 to suppress, 0 to pass-through.
     */
    HandleKeyDown(keyName) {
        this.oneshotCandidate := "" ; Any key press cancels one-shot

        layer := this.GetCurrentLayer()
        action := ""

        ; Check for remap in current layer
        if (this.remaps.Has(keyName)) {
            action := this.GetActionForLayer(keyName, layer)
        }

        if (action) {
            ; Interrupted by specific remap? Clear active fallbacks first.
            this.ClearActiveFallbacks()
            this.GetKeyState(keyName).IsSuppressed := true
            this.DispatchAction(action)
            return 1
        }

        ; No remap: Handle Fallback if in Modifier layer
        if (layer != LayerType.BASE) {
            this.GetKeyState(keyName).IsSuppressed := true
            this.HandleFallback(keyName, layer)
            return 1
        }

        ; Base layer and no remap: Pass-through
        OutputDebug("[Kyuri] Pass-through: " . keyName)
        return 0
    }

    /**
     * @method HandleKeyUp
     * Handler for physical key up events (non-modifier).
     * @param {String} keyName - The name of the key.
     * @returns {Integer} 1 to suppress, 0 to pass-through.
     */
    HandleKeyUp(keyName) {
        if (this.keyStates.Has(keyName)) {
            state := this.keyStates[keyName]
            if (state.IsSuppressed) {
                state.IsSuppressed := false
                OutputDebug("[Kyuri] Releasing suppressed key: " . keyName)
                this.Send("{" . keyName . " up}")
                return 1
            }
        }
        return 0
    }

    /**
     * @method GetKeyState
     * Retrieves or creates the KeyState object for a specific key.
     * @param {String} keyName - The physical key name.
     * @returns {KeyState}
     */
    GetKeyState(keyName) {
        if (!this.keyStates.Has(keyName)) {
            this.keyStates[keyName] := KeyState()
        }
        return this.keyStates[keyName]
    }

    /**
     * @method ClearActiveFallbacks
     * Releases any virtual fallback modifiers currently sent.
     * This is used when a remapped key is pressed while a fallback modifier is held.
     */
    ClearActiveFallbacks() {
        for mod in [this.m0, this.m1] {
            if (mod.FallbackSent) {
                if (mod.FallbackKey != "") {
                    OutputDebug("[Kyuri] Interrupted: Releasing Fallback " . mod.FallbackKey)
                    this.Send("{" . mod.FallbackKey . " up}")
                }
                mod.FallbackSent := false
            }
        }
    }

    /**
     * @method GetCurrentLayer
     * Determines the current active layer based on modifier hold states.
     * @returns {Integer} One of LayerType constants.
     */
    GetCurrentLayer() {
        if (this.m0.IsHeld && this.m1.IsHeld) {
            return LayerType.BOTH
        }
        if (this.m0.IsHeld) {
            return LayerType.M0
        }
        if (this.m1.IsHeld) {
            return LayerType.M1
        }
        return LayerType.BASE
    }

    /**
     * @method GetActionForLayer
     * Retrieves the remapped action for a specific key and layer.
     * @param {String} keyName - The physical key name.
     * @param {Integer} layer - Current active layer ID.
     * @returns {KeyAction|Blank} The action object or empty string.
     */
    GetActionForLayer(keyName, layer) {
        remap := this.remaps[keyName]

        targetAction := ""
        switch layer {
            case LayerType.BOTH: targetAction := remap.HoldBoth
            case LayerType.M0: targetAction := remap.HoldM0
            case LayerType.M1: targetAction := remap.HoldM1
        }

        ; Fallback to Tap if specific hold action not defined
        return targetAction ? targetAction : remap.Tap
    }

    /**
     * @method HandleFallback
     * Handles fallback behavior when a modifier is held but no remap is defined.
     * @param {String} keyName - The physical key name.
     * @param {Integer} layer - Current active layer ID.
     */
    HandleFallback(keyName, layer) {
        ; Send fallback modifier if not already sent
        for mod in [this.m0, this.m1] {
            if (mod.IsHeld && !mod.FallbackSent) {
                if (mod.FallbackKey != "") {
                    OutputDebug("[Kyuri] Holding Fallback: " . mod.FallbackKey)
                    this.Send("{" . mod.FallbackKey . " down}")
                    mod.FallbackSent := true
                }
            }
        }
        ; Send the original key
        OutputDebug("[Kyuri] Fallback: " . keyName . " (Layer: " . layer . ")")
        this.Send("{" . keyName . " down}")
    }

    /**
     * @method Send
     * Sends a key with project-standard flags.
     * @param {String} keyStr - Key string to send.
     */
    Send(keyStr) {
        this.LowLevelSend("{Blind}" . keyStr)
    }

    /**
     * @method LowLevelSend
     * Final stage of key sending. This method can be overridden in tests.
     * @param {String} finalStr - The exact string to pass to AHK's Send.
     */
    LowLevelSend(finalStr) {
        Send(finalStr)
    }

    /**
     * @method DispatchAction
     * Executes a parsed action.
     * @param {KeyAction} action - The action object.
     */
    DispatchAction(action) {
        if (action.Type == KeyActionType.FUNC) {
            OutputDebug("[Kyuri] Remap: " . action.Trigger . " -> Func")
            action.Data.Call()
        } else {
            OutputDebug("[Kyuri] Remap: " . action.Trigger . " -> " . action.Data)
            ; action.Data is like "^!{Left}"
            this.Send(action.Data)
        }
    }

    /**
     * @method ExecuteDoubleTap
     * Executes the action associated with a double-tap event.
     * @param {ModifierState} mod - The modifier state object that was double-tapped.
     */
    ExecuteDoubleTap(mod) {
        if (mod.DoubleTapAction != "") {
            this.log.Info("DoubleTap detected: " . mod.Name . " -> " . mod.DoubleTapAction)
            ; TODO: Dispatch to MenuManager when implemented
        }
    }
}
