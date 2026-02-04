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
     * Constructor: __New
     * @param {ConfigManager} configSvc
     * @param {Logger} logSvc
     */
    __New(configSvc, logSvc) {
        this.config := configSvc
        this.log := logSvc
        this.InitializeHotkeys()
    }

    /**
     * Method: InitializeHotkeys
     * Registers modifiers, remaps, double-tap, and mouse triggers.
     * Uses Bind to encapsulate entry data per hotkey.
     */
    InitializeHotkeys() {
        this.log.Info("Initializing dynamic hotkeys...")

        ; 1. Register Virtual Modifiers (M0, M1)
        for modName in ["M0", "M1"] {
            vk := this.config.Get("Modifiers." . modName . ".vkCode")
            if (vk == "") {
                continue
            }

            ; Bind Press and Release.
            ; Use '*' to allow any standard modifiers (Shift, Ctrl, etc.) to be held.

            this.log.Info("Registering hotkey: " . vk . " => " . modName)
            Hotkey("*" . vk, this.OnModifierPress.Bind(this, modName))
            Hotkey("*" . vk . " up", this.OnModifierRelease.Bind(this, modName))
        }

        ; 2. Register Remap Triggers (h, j, k, l, etc.)
        remaps := this.config.Get("Remaps")
        if (remaps is Array) {
            for entry in remaps {
                trigger := entry["Trigger"]

                ; IMPORTANT: Bind the 'entry' object itself to the handler.
                ; This ensures each hotkey has its own copy of the configuration data,
                ; preventing the "all keys become 'l'" variable capture bug.
                this.log.Info("Registering hotkey: *$" . trigger)
                Hotkey("*$" . trigger, this.OnTrigger.Bind(this, trigger, entry))
            }
        }

        ; 3. Register DoubleTap Triggers
        doubleTaps := this.config.Get("Triggers.DoubleTap")
        if (doubleTaps is Map) {
            for key, action in doubleTaps {
                this.doubleTapTrigger[key] := action
                ; Hotkey to capture the press for double-tap detection
                ; The actual double-tap logic will be in OnModifierPress/OnTrigger
                this.log.Info("Registering double-tap trigger: *$" . key)
                Hotkey("*" . key, this.OnDoubleTapCheck.Bind(this, key))
            }
        }

        ; 4. Register Mouse Triggers
        mouseTriggers := this.config.Get("Triggers.Mouse")
        if (mouseTriggers is Map) {
            for button, action in mouseTriggers {
                this.log.Info("Registering mouse trigger: " . button . " => " . action)
                Hotkey(button, this.OnMouseTrigger.Bind(this, button, action))
            }
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
            this.log.Info("Double tap detected for key: " . key)
            this.OnDoubleTap(key, this.doubleTapTrigger[key])
            this.lastTapTime.Delete(key) ; Reset for next double tap
            ; Prevent original key action for double tap
            A_ThisHotkey := "" ; Suppress the current hotkey to prevent it from triggering single-tap action or remap
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
        this.log.Info("Executing double-tap action: " . action . " for key: " . key)
        ; Placeholder for menu/action dispatch
    }

    /**
     * Handler for mouse trigger events.
     * @param {String} button - The mouse button (e.g., "MButton").
     * @param {String} action - The action to perform (e.g., "Launcher").
     */
    OnMouseTrigger(button, action) {
        this.log.Info("Executing mouse trigger action: " . action . " for button: " . button)
        ; Placeholder for menu/action dispatch
    }

    /**
     * Main entry point for key processing.
     * @param {String} triggerKey - The physical key name (Injected via Bind).
     * @param {Map/Object} entry - The config entry (Injected via Bind).
     * @param {String} _ - The actual hotkey name from AHK (unused).
     */
    OnTrigger(triggerKey, entry, _) {
        ; A_ThisHotkey := "" in OnDoubleTapCheck should prevent this from firing if a double-tap is detected.
        layer := this.GetCurrentLayer()

        if (layer == "Base") {
            this.HandleBaseLayer(triggerKey)
        } else {
            this.HandleModifierLayer(triggerKey, layer, entry)
        }
    }

    /**
     * Returns the current active layer name based on modifier states.
     * @returns {String} "Base", "M0", "M1", or "Both"
     */
    GetCurrentLayer() {
        m0 := this.modifierState["M0"]
        m1 := this.modifierState["M1"]

        if (m0 && m1) {
            return "Both"
        }
        return m0 ? "M0" : (m1 ? "M1" : "Base")
    }

    /**
     * Method: HandleBaseLayer
     * Standard key pass-through when no virtual modifiers are held.
     * @param {String} triggerKey
     */
    HandleBaseLayer(triggerKey) {
        ; {Blind} is crucial to allow physical Shift/Ctrl to work with the key.
        Send("{Blind}{" . triggerKey . "}")
    }

    /**
     * Method: HandleModifierLayer
     * Executes remapped actions based on the active modifier layer.
     * @param {String} triggerKey
     * @param {String} layer
     * @param {Map/Object} entry - The config entry (Injected via Bind).
     */
    HandleModifierLayer(triggerKey, layer, entry) {
        targetAction := ""
        configKey := "Hold" . layer

        if (entry.Has(configKey)) {
            targetAction := entry[configKey]
        }

        if (targetAction != "") {
            ; Execute the remapped action (e.g., Send "Left" when M0+h is pressed)
            Send("{Blind}{" . targetAction . "}")
        } else {
            ; Fallback to Base behavior if no specific mapping exists for this layer.
            this.HandleBaseLayer(triggerKey)
        }
    }
}
