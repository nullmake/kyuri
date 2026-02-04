#Requires AutoHotkey v2.0

/**
 * Keyboard Event Class (Core Layer)
 * * Represents a normalized keyboard event, isolating the Core logic from
 * Windows-specific raw data.
 */
class KeyEvent {
    /** @prop {String} Name - The AHK key name (e.g., "a", "Space", "vk1D") */
    Name := ""
    /** @prop {Integer} IsDown - True if the key is pressed, False if released */
    IsDown := 0
    /** @prop {Integer} IsPhysical - True if it's a real hardware input */
    IsPhysical := 0

    /**
     * Creates a new KeyEvent instance.
     * @param {String} name - Key name.
     * @param {Integer} isDown - State.
     * @param {Integer} isPhysical - Physical flag.
     */
    __New(name, isDown, isPhysical := 1) {
        this.Name := name
        this.IsDown := isDown
        this.IsPhysical := isPhysical
    }
}
