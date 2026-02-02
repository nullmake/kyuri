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
    /** @field {Map} modifierState - Current hold state of virtual modifiers */
    modifierState := Map("M0", false, "M1", false)

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
     * Registers modifiers and remaps. Uses Bind to encapsulate entry data per hotkey.
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
            ; Note: '~' (tilde) is omitted to block the original key's function.
            ; Note: OnModifierPress/Release will also receive 'HotkeyName' as 1st arg.
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
                this.log.Info("Registering hotkey: " . trigger)
                Hotkey("*$" . trigger, this.OnTrigger.Bind(this, trigger, entry))
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
        OutputDebug("[Kyuri] Modifier Down: " . modName)
    }

    /**
     * Callback for modifier release.
     * @param {String} modName - Injected via Bind (e.g., "M0").
     * @param {String} _ - Hotkey name passed by AHK (unused).
     */
    OnModifierRelease(modName, _) {
        this.modifierState[modName] := false
        OutputDebug("[Kyuri] Modifier Up: " . modName)
    }

    /**
     * Main entry point for key processing.
     * @param {String} triggerKey - The physical key name (Injected via Bind).
     * @param {Map/Object} entry - The config entry (Injected via Bind).
     * @param {String} _ - The actual hotkey name from AHK (unused).
     */
    OnTrigger(triggerKey, entry, _) {
        layer := this.GetCurrentLayer()
        OutputDebug("[Kyuri] Trigger: " . triggerKey . " | Layer: " . layer)

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
        OutputDebug("[Kyuri] Dispatch (Base): " . triggerKey)
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
            OutputDebug(Format("[Kyuri] Dispatch (Remap): {1} + {2} -> {3}", layer, triggerKey, targetAction))
            Send("{Blind}{" . targetAction . "}")
        } else {
            ; Fallback to Base behavior if no specific mapping exists for this layer.
            this.HandleBaseLayer(triggerKey)
        }
    }
}
