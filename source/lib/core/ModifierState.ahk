/**
 * @class ModifierState
 * Internal class to hold state for each virtual modifier (M0, M1).
 */
class ModifierState {
    /** @field {String} Name - Internal name ("M0" or "M1") */
    Name := ""
    /** @field {String} VkCode - Virtual key code (e.g., "vk1D") */
    VkCode := ""
    /** @field {String} FallbackKey - Key to send if no remap is triggered (e.g., "LAlt") */
    FallbackKey := ""
    /** @field {String} DoubleTapAction - Action/Menu to trigger on double-tap */
    DoubleTapAction := ""
    /** @field {Boolean} IsHeld - Current physical hold state */
    IsHeld := false
    /** @field {Boolean} FallbackSent - Whether the fallback key has been sent during this hold */
    FallbackSent := false
    /** @field {Integer} LastTapTime - Timestamp of the last release for double-tap detection */
    LastTapTime := 0

    /**
     * @method __New
     * @constructor
     * @param {String} name - The internal name of the modifier.
     */
    __New(name) {
        this.Name := name
    }
}
