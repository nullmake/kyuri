#Requires AutoHotkey v2.0

/**
 * Class: ImeAdapter
 * Provides methods to control Input Method Editor (IME) status.
 */
class ImeAdapter {
    /**
     * Toggles the current IME status.
     */
    IMEToggle() {
        curr := this.GetIme()
        this.SetIme(!curr)
    }

    /**
     * Forces IME to ON.
     */
    ImeOn() {
        this.SetIme(1)
    }

    /**
     * Forces IME to OFF.
     */
    ImeOff() {
        this.SetIme(0)
    }

    /**
     * Gets current IME status.
     * @param {String} winTitle - Target window (default "A")
     * @returns {Integer} 1 for ON, 0 for OFF
     */
    GetIme(winTitle := "A") {
        hwnd := WinExist(winTitle)
        if (!hwnd) {
            return 0
        }
        
        ; Using standard AHK v2 way to get IME status via ImmGetDefaultIMEWnd
        ; and sending WM_IME_CONTROL message.
        try {
            defaultImeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
            if (!defaultImeWnd) {
                return 0
            }
            
            ; 0x0283 = WM_IME_CONTROL, 0x0005 = IMC_GETOPENSTATUS
            res := SendMessage(0x0283, 0x0005, 0, , "ahk_id " . defaultImeWnd)
            return res
        } catch {
            return 0
        }
    }

    /**
     * Sets IME status.
     * @param {Integer} setStatus - 1 for ON, 0 for OFF
     * @param {String} winTitle - Target window (default "A")
     */
    SetIme(setStatus, winTitle := "A") {
        hwnd := WinExist(winTitle)
        if (!hwnd) {
            return
        }

        try {
            defaultImeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
            if (!defaultImeWnd) {
                return
            }
            
            ; 0x0283 = WM_IME_CONTROL, 0x006 = IMC_SETOPENSTATUS
            SendMessage(0x0283, 0x006, setStatus, , "ahk_id " . defaultImeWnd)
        } catch {
            ; Fail silently
        }
    }

    /**
     * Returns a Map of action names to their method references.
     * Used by InputProcessor to collect available actions.
     */
    GetActions() {
        actions := Map()
        actions["IMEToggle"] := this.IMEToggle.Bind(this)
        actions["ImeOn"] := this.ImeOn.Bind(this)
        actions["ImeOff"] := this.ImeOff.Bind(this)
        return actions
    }
}
