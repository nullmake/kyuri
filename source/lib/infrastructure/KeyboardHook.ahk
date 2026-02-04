#Requires AutoHotkey v2.0

/**
 * Class: KeyboardHook
 * Adapter Layer that encapsulates WH_KEYBOARD_LL.
 */
class KeyboardHook {
    static WH_KEYBOARD_LL := 13
    static WM_KEYDOWN := 0x0100
    static WM_KEYUP := 0x0101
    static WM_SYSKEYDOWN := 0x0104
    static WM_SYSKEYUP := 0x0105

    /** @field {Integer} hHook - Handle to the Windows Hook */
    hHook := 0
    /** @field {Any} proc - Reference to the callback to prevent GC */
    proc := 0
    /** @field {Function} onEvent - Injected event handler */
    onEvent := ""

    /**
     * Constructor: __New
     * @param {Function} onEventCallback - Function to call when a key event occurs.
     */
    __New(onEventCallback) {
        this.onEvent := onEventCallback
        ; Ensure the callback is tied to this instance
        this.proc := CallbackCreate(this._LowLevelKeyboardProc.Bind(this), "Fast", 3)
    }

    /**
     * Method: Start
     * Begins capturing keyboard input.
     */
    Start() {
        if (this.hHook) {
            return
        }

        hMod := DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
        this.hHook := DllCall("SetWindowsHookEx", "Int", KeyboardHook.WH_KEYBOARD_LL
            , "Ptr", this.proc, "Ptr", hMod, "UInt", 0, "Ptr")

        if (!this.hHook) {
            throw Error("Failed to set Keyboard Hook.")
        }
    }

    /**
     * Method: Stop
     * Releases the hook.
     */
    Stop() {
        if (this.hHook) {
            DllCall("UnhookWindowsHookEx", "Ptr", this.hHook)
            this.hHook := 0
        }
    }

    /**
     * Clean up on destruction.
     */
    __Delete() {
        this.Stop()
        if (this.proc) {
            CallbackFree(this.proc)
        }
    }

    /**
     * Low-level Hook Callback Procedure.
     * @private
     */
    _LowLevelKeyboardProc(nCode, wParam, lParam) {
        try {
            if (nCode >= 0) {
                this._HandleRawInput(wParam, lParam)
            }
        } catch Any as e {
            this._SafeLog(e)
        }

        return DllCall("CallNextHookEx", "Ptr", this.hHook, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    /**
     * Parse raw input and dispatch as KeyEvent.
     * @param {Integer} wParam - Message ID (WM_KEYDOWN, etc.)
     * @param {Ptr} lParam - Pointer to KBDLLHOOKSTRUCT
     * @private
     */
    _HandleRawInput(wParam, lParam) {
        ; Extract Virtual Key Code and Flags from KBDLLHOOKSTRUCT
        vkCode := NumGet(lParam, 0, "UInt")
        flags := NumGet(lParam, 8, "UInt")

        ; Determine if key is pressed or released
        isDown := (wParam == KeyboardHook.WM_KEYDOWN || wParam == KeyboardHook.WM_SYSKEYDOWN)

        ; Check LLKHF_INJECTED (0x10) to see if input is physical or artificial
        isPhysical := !(flags & 0x10)

        ; Get AHK-compatible key name (e.g., "vk1D", "a")
        ; Fallback: If GetKeyName returns empty, use "vkXX" format.
        ; This ensures JIS keys like Muhenkan (vk1D) are always identifiable.
        keyName := GetKeyName(Format("vk{:02X}", vkCode))
        if (keyName == "") {
            keyName := Format("vk{:02X}", vkCode)
        }

        ; Create KeyEvent object
        event := KeyEvent(keyName, isDown, isPhysical)

        ; Dispatch via injected callback
        if (this.onEvent) {
            this.onEvent(event)
        }
    }

    _SafeLog(err) {
        ; Use OutputDebug to avoid dependency on Logger class
        OutputDebug("Kyuri Hook Error: " . err.Message . " (" . err.Line . ")")
    }
}
