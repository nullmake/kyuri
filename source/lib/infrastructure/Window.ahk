#Requires AutoHotkey v2.0

/**
 * Class: Window
 * Pure infrastructure utility for window operations.
 */
class Window {
    /**
     * Switches to the next window.
     */
    static Next() {
        Send("!{Tab}")
    }

    /**
     * Switches to the previous window.
     */
    static Prev() {
        Send("!+{Tab}")
    }
}
