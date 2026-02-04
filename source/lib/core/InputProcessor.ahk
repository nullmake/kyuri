#Requires AutoHotkey v2.0

/**
 * Class: InputProcessor
 * Logic engine that dispatches actions based on modifier states and configuration.
 */
class InputProcessor {
    /** @field {ConfigManager} config - Reference to config adapter */
    config := ""
    /** @field {Logger} log - Application logger instance */
    log := ""
    /**
     * @field {Map} modifierState - Current hold state of virtual modifiers (M0, M1).
     */
    modifierState := Map("M0", false, "M1", false)
    /**
     * @field {Map} lastTapTime - Records the last tap time for each key to detect double taps.
     */
    lastTapTime := Map()
    /**
     * @field {Map} doubleTapTrigger - Map of keys to actions for double tap events.
     */
    doubleTapTrigger := Map()
    /**
     * @field {Map} mouseTrigger - Map of mouse buttons to actions for click events.
     */
    mouseTrigger := Map()
    /**
     * @field {Map} builtinActions - Registry of available special action methods.
     */
    builtinActions := Map()
    /**
     * @field {Map} optimizedRemaps - Cache of pre-parsed and validated actions.
     * Structure: optimizedRemaps[triggerKey][layerName] = { type: "key"|"func", data: string|FuncObj }
     */
    optimizedRemaps := Map()
    /**
     * @field {Array} validationErrors - List of errors found during initialization.
     */
    validationErrors := []

    /**
     * Constructor: __New
     * @param {ConfigManager} configSvc
     * @param {Logger} logSvc
     * @param {Map} builtinActions - Pre-registered special actions from Adapter layer.
     */
    __New(configSvc, logSvc, builtinActions) {
        this.config := configSvc
        this.log := logSvc
        this.builtinActions := builtinActions
        this.InitializeHotkeys()
        this.ReportValidationResults()
    }

    /**
     * Method: InitializeHotkeys
     * Registers modifiers, remaps, double-tap, and mouse triggers.
     */
    InitializeHotkeys() {
        this.log.Info("Initializing dynamic hotkeys...")

        ; 1. Register Virtual Modifiers (M0, M1)
        for modName in ["M0", "M1"] {
            vk := this.config.Get("Modifiers." . modName . ".vkCode")
            if (vk == "") {
                continue
            }

            Hotkey("*" . vk, this.OnModifierPress.Bind(this, modName))
            Hotkey("*" . vk . " up", this.OnModifierRelease.Bind(this, modName))
        }

        ; 2. Register Remap Triggers
        remaps := this.config.Get("Remaps")
        if (remaps is Array) {
            for entry in remaps {
                trigger := entry["Trigger"]
                this.optimizedRemaps[trigger] := Map()

                for layerName in ["Tap", "HoldM0", "HoldM1", "HoldBoth"] {
                    if (entry.Has(layerName)) {
                        actionStr := entry[layerName]
                        parsed := this.ParseAction(actionStr)
                        if (parsed) {
                            this.optimizedRemaps[trigger][layerName] := parsed
                        }
                    }
                }
                Hotkey("*$" . trigger, this.OnTrigger.Bind(this, trigger))
            }
        }

        ; 3. Register DoubleTap Triggers
        doubleTaps := this.config.Get("Triggers.DoubleTap")
        if (doubleTaps is Map) {
            for key, actionName in doubleTaps {
                this.doubleTapTrigger[key] := actionName
                Hotkey("*" . key, this.OnDoubleTapCheck.Bind(this, key))
            }
        }

        ; 4. Register Mouse Triggers
        mouseTriggers := this.config.Get("Triggers.Mouse")
        if (mouseTriggers is Map) {
            for button, actionName in mouseTriggers {
                this.mouseTrigger[button] := actionName
                Hotkey(button, this.OnMouseTrigger.Bind(this, button, actionName))
            }
        }
    }

    /**
     * Parses an action string and validates it.
     * @param {String} actionStr - The string from config (e.g. "^Left" or "IMEToggle()")
     * @returns {Object|Blank} - {type: "key"|"func", data: value} or Blank on failure.
     */
    ParseAction(actionStr) {
        if (actionStr == "") {
            return ""
        }

        ; Check for function form: Name()
        if (RegExMatch(actionStr, "^(\w+)\(\)$", &match)) {
            funcName := match[1]
            if (this.builtinActions.Has(funcName)) {
                return { type: "func", data: this.builtinActions[funcName] }
            } else {
                this.validationErrors.Push("Undefined built-in function: " . actionStr)
                return ""
            }
        }

        ; Otherwise, treat as key sending form: [Modifiers]Key
        ; Separate optional modifiers (^!+#) from the key name
        if (RegExMatch(actionStr, "^([\^!+#]*)(.+)$", &match)) {
            mods := match[1]
            keyName := match[2]

            if (GetKeyVK(keyName) == 0) {
                this.validationErrors.Push("Invalid key name: '" . keyName . "' in action '" . actionStr . "'")
                return ""
            }

            ; Optimization: Pre-wrap keyName in braces for Send command
            return { type: "key", data: mods . "{" . keyName . "}" }
        }

        this.validationErrors.Push("Invalid action syntax: " . actionStr)
        return ""
    }

    /**
     * Displays a summary of validation errors if any occurred.
     */
    ReportValidationResults() {
        if (this.validationErrors.Length > 0) {
            msg := "Kyuri Configuration Errors:`n`n"
            for err in this.validationErrors {
                this.log.Error(err)
                msg .= "- " . err . "`n"
            }
            MsgBox(msg, "Kyuri Config Error", 48)
        }
    }

    /**
     * Callback for modifier press.
     * @param {String} modName - Injected via Bind (e.g., "M0").
     * @param {String} _ - Hotkey name passed by AHK (unused).
     */
    OnModifierPress(modName, _) {
        this.modifierState[modName] := true
    }

    /**
     * Callback for modifier release.
     * @param {String} modName - Injected via Bind (e.g., "M0").
     * @param {String} _ - Hotkey name passed by AHK (unused).
     */
    OnModifierRelease(modName, _) {
        this.modifierState[modName] := false
    }

    /**
     * Intermediate handler for double-tap detection on relevant keys.
     * This will call OnDoubleTap if a double-tap is detected.
     * @param {String} key - The physical key name.
     * @param {String} _ - Hotkey name passed by AHK (unused).
     * @param {Integer} isLongPress - 1 if this is a long press, 0 otherwise.
     */
    OnDoubleTapCheck(key, _, isLongPress) {
        if (isLongPress) { ; This is a placeholder, actual long press detection might be different
            return ; Don't process as double-tap if it's a long press for a remap
        }
        
        interval := this.config.Get("Modifiers.M0.DoublePressInterval", 300) ; Use M0's interval for now, or a global one
        currentTime := A_TickCount

        if (this.lastTapTime.Has(key) && (currentTime - this.lastTapTime[key] < interval)) {
            ; Double tap detected
            OutputDebug("[Kyuri] Double tap detected for key: " . key)
            this.OnDoubleTap(key, this.doubleTapTrigger[key])
            this.lastTapTime.Delete(key) ; Reset for next double tap
        } else {
            ; First tap, record time
            this.lastTapTime[key] := currentTime
            ; Allow original key action for single tap if no remap.
            ; This part needs careful integration with OnTrigger to avoid conflicts.
        }
    }

    /**
     * Handler for double-tap events.
     * @param {String} key - The key that was double-tapped.
     * @param {String} action - The action to perform (e.g., "Launcher").
     */
    OnDoubleTap(key, action) {
        OutputDebug("[Kyuri] Executing double-tap action: " . action . " for key: " . key)
        ; Placeholder for menu/action dispatch
    }

    /**
     * Handler for mouse trigger events.
     * @param {String} button - The mouse button (e.g., "MButton").
     * @param {String} action - The action to perform (e.g., "Launcher").
     */
    OnMouseTrigger(button, action) {
        OutputDebug("[Kyuri] Executing mouse trigger action: " . action . " for button: " . button)
        ; Placeholder for menu/action dispatch
    }

    /**
     * Executes a parsed action object.
     * @param {Object} action - The parsed action object {type, data}.
     */
    DispatchAction(action) {
        if (action.type == "func") {
            action.data.Call()
        } else {
            ; data is already formatted like "^!{Delete}"
            Send("{Blind}" . action.data)
        }
    }

    /**
     * Main entry point for key processing.
     * @param {String} triggerKey - The physical key name (Injected via Bind).
     * @param {String} _ - The actual hotkey name from AHK (unused).
     */
    OnTrigger(triggerKey, _) {
        ; A_ThisHotkey := "" in OnDoubleTapCheck should prevent this from firing if a double-tap is detected.
        layer := this.GetCurrentLayer()

        if (layer == "Base") {
            this.HandleBaseLayer(triggerKey)
        } else {
            this.HandleModifierLayer(triggerKey, layer)
        }
    }

    /**
     * Method: HandleBaseLayer
     * Standard key pass-through when no virtual modifiers are held.
     * @param {String} triggerKey
     */
    HandleBaseLayer(triggerKey) {
        if (this.optimizedRemaps.Has(triggerKey) && this.optimizedRemaps[triggerKey].Has("Tap")) {
            this.DispatchAction(this.optimizedRemaps[triggerKey]["Tap"])
        } else {
            ; Pass-through to OS
            Send("{Blind}{" . triggerKey . "}")
        }
    }

    /**
     * Method: HandleModifierLayer
     * Executes remapped actions based on the active modifier layer.
     * @param {String} triggerKey
     * @param {String} layer - "M0", "M1", or "Both"
     */
    HandleModifierLayer(triggerKey, layer) {
        configKey := (layer == "Both") ? "HoldBoth" : "Hold" . layer

        if (this.optimizedRemaps.Has(triggerKey) && this.optimizedRemaps[triggerKey].Has(configKey)) {
            this.DispatchAction(this.optimizedRemaps[triggerKey][configKey])
        } else {
            ; Fallback to Base behavior (which might be a Tap or pure pass-through)
            this.HandleBaseLayer(triggerKey)
        }
    }
}
