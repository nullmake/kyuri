#Requires AutoHotkey v2.0

/**
 * InputProcessor Class (Core Layer)
 * * Responsible for processing normalized KeyEvents and deciding actions.
 */
class InputProcessor {
    /**
     * Handles incoming KeyEvents from the KeyboardHook.
     * @param {KeyEvent} event - The normalized key event.
     */
    OnEvent(event) {
        ; [DEBUG ONLY]
        ; Output to external debugger (e.g., DebugView) instead of persistent logs.
        ; This will be removed once the core logic is implemented.
        state := event.IsDown ? "Down" : "Up"
        type := event.IsPhysical ? "Physical" : "Artificial"

        OutputDebug(Format("Kyuri-Debug: Key={1}, State={2}, Type={3}", event.Name, state, type))

        ; TODO: Implement remapping logic here.
    }
}
