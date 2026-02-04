#Requires AutoHotkey v2.0

/**
 * Class: WindowAdapter
 * Provides methods to control window focus and navigation.
 */
class WindowAdapter {
    /**
     * Switches to the next window (Alt+Tab).
     */
    NextWindow() {
        Send("!{Tab}")
    }

    /**
     * Switches to the previous window (Alt+Shift+Tab).
     */
    PrevWindow() {
        Send("!+{Tab}")
    }

    /**
     * Returns a Map of action names to their method references.
     */
    GetActions() {
        actions := Map()
        actions["NextWindow"] := this.NextWindow.Bind(this)
        actions["PrevWindow"] := this.PrevWindow.Bind(this)
        return actions
    }
}
