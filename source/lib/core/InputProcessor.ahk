#Requires AutoHotkey v2.0

/**
 * Class: InputProcessor
 * Logic engine that dispatches actions based on modifier states and configuration.
 * * SOLID: Separates key registration from action execution.
 * * DRY: Uses loops to register multiple modifiers and remaps.
 */
class InputProcessor {
    /** @field {ConfigManager} config - Reference to config adapter */
    config := ""
    /** @field {Map} modifierState - Current hold state of virtual modifiers */
    modifierState := Map("M0", false, "M1", false)

    /**
     * Constructor: __New
     */
    __New() {
        this.config := ServiceLocator.Config
        this.InitializeHotkeys()
    }

    /**
     * Method: InitializeHotkeys
     * Dynamically registers modifiers and trigger keys based on JSON config.
     */
    InitializeHotkeys() {
        ; 1. Register Virtual Modifiers (M0, M1)
        for modName in ["M0", "M1"] {
            vk := this.config.Get("Modifiers." . modName . ".vkCode")
            if (vk == "") {
                continue
            }

            ; Bind Press and Release.
            ; Use '*' to allow any standard modifiers.
            ; Use '~' to not block the key yet (though M0/M1 usually block later).
            Hotkey("* " . vk, (K) => this.OnModifierPress(modName))
            Hotkey("* " . vk . " up", (K) => this.OnModifierRelease(modName))
        }

        ; 2. Register Remap Triggers (h, j, k, l, vkF0, etc.)
        remaps := this.config.Get("Remaps")
        if (remaps is Array) {
            for entry in remaps {
                trigger := entry["Trigger"]
                ; Use '$' to prevent Send from re-triggering this hotkey.
                ; Use '*' to inherit Shift/Ctrl/Alt from the physical press.
                Hotkey("*$" . trigger, (K) => this.OnTrigger(trigger))
            }
        }
    }

    /**
     * Callback when a modifier (M0/M1) is pressed.
     */
    OnModifierPress(modName) {
        this.modifierState[modName] := true
    }

    /**
     * Callback when a modifier (M0/M1) is released.
     */
    OnModifierRelease(modName) {
        this.modifierState[modName] := false
    }

    /**
     * Main entry point for key processing.
     */
    OnTrigger(triggerKey) {
        layer := this.GetCurrentLayer()

        if (layer == "Base") {
            this.HandleBaseLayer(triggerKey)
        } else {
            this.HandleModifierLayer(triggerKey, layer)
        }
    }

    /**
     * Returns the current active layer name.
     */
    GetCurrentLayer() {
        m0 := this.modifierState["M0"]
        m1 := this.modifierState["M1"]

        if (m0 && m1) {
            return "Both"
        }
        return m0 ? "M0" : (m1 ? "M1" : "Base")
    }

    ; ... HandleBaseLayer and HandleModifierLayer (Same as previous skeleton)
}
