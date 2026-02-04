#Requires AutoHotkey v2.0

#Include ../infrastructure/Ime.ahk
#Include ../infrastructure/Window.ahk

/**
 * Class: SystemActionAdapter
 * Aggregates system-level actions (IME, Window, etc.) and provides them as Kyuri Actions.
 */
class SystemActionAdapter {
    /**
     * Toggles the current IME status.
     */
    IMEToggle(*) {
        curr := Ime.GetStatus()
        Ime.SetStatus(!curr)
    }

    /**
     * Forces IME to ON.
     */
    ImeOn(*) {
        Ime.SetStatus(1)
    }

    /**
     * Forces IME to OFF.
     */
    ImeOff(*) {
        Ime.SetStatus(0)
    }

    /**
     * Returns a Map of action names to their method references.
     * This is the single entry point for InputProcessor to collect builtin actions.
     */
    GetActions() {
        actions := Map()
        actions["IMEToggle"] := this.IMEToggle.Bind(this)
        actions["ImeOn"] := this.ImeOn.Bind(this)
        actions["ImeOff"] := this.ImeOff.Bind(this)
        actions["NextWindow"] := Window.Next
        actions["PrevWindow"] := Window.Prev
        return actions
    }
}
