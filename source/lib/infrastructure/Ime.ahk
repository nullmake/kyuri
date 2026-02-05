#Requires AutoHotkey v2.0

/**
 * Class: Ime
 * Pure infrastructure utility for Input Method Editor (IME) operations.
 */
class Ime {
    /**
     * Gets current IME status.
     * @param {String} winTitle - Target window (default "A")
     * @returns {Integer} 1 for ON, 0 for OFF
     */
    static GetStatus(winTitle := "A") {
        hwnd := WinExist(winTitle)
        if (!hwnd) {
            return 0
        }

        try {
            defaultImeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
            if (!defaultImeWnd) {
                return 0
            }

            ; 0x0283 = WM_IME_CONTROL, 0x0005 = IMC_GETOPENSTATUS
            return SendMessage(0x0283, 0x0005, 0, , "ahk_id " . defaultImeWnd)
        } catch {
            return 0
        }
    }

    /**
     * Sets IME status.
     * @param {Integer} setStatus - 1 for ON, 0 for OFF
     * @param {String} winTitle - Target window (default "A")
     */
    static SetStatus(setStatus, winTitle := "A") {
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
}
