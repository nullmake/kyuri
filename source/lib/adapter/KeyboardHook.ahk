#Requires AutoHotkey v2.0

/**
 * KeyboardHook Class (Adapter Layer)
 * * Encapsulates WH_KEYBOARD_LL to capture system-wide keyboard input.
 * * Normalizes raw signals into KeyEvent and dispatches to InputProcessor.
 */
class KeyboardHook {
    static WH_KEYBOARD_LL := 13
    static WM_KEYDOWN := 0x0100
    static WM_KEYUP := 0x0101
    static WM_SYSKEYDOWN := 0x0104
    static WM_SYSKEYUP := 0x0105

    /** @prop {Integer} hHook - Handle to the Windows Hook */
    hHook := 0
    /** @prop {Any} proc - Reference to the callback to prevent GC */
    proc := 0

    /**
     * Initializes the hook and starts capturing.
     */
    __New() {
        ; Use CallbackCreate to ensure it's not GC'd
        this.proc := CallbackCreate(this._LowLevelKeyboardProc.Bind(this), "Fast", 3)
    }

    /**
     * Starts the hook.
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
     * Stops the hook.
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

        ; Create normalized KeyEvent
        event := KeyEvent(keyName, isDown, isPhysical)

        ; Dispatch to Core layer via ServiceLocator
        try {
            processor := ServiceLocator.Get("InputProcessor")
            processor.OnEvent(event)
        } catch {
            ; Suppress error if InputProcessor is not yet registered
        }
    }

    /**
     * Defensive logging if ServiceLocator is unavailable.
     * @private
     */
    _SafeLog(err) {
        try {
            ServiceLocator.Log.Error("Hook Error: " . err.Message)
        } catch {
            OutputDebug("!!! HOOK CRITICAL: " . err.Message)
        }
    }
}
