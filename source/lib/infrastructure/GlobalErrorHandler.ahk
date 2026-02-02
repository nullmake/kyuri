#Requires AutoHotkey v2.0

/**
 * Global Uncaught Error Handler
 * Ensures that even unexpected crashes are logged for post-mortem analysis.
 */
GlobalErrorHandler(thrownObj, mode) {
    try {
        ServiceLocator.Log.Error(thrownObj)
    } catch {
        OutputDebug("!!! FATAL: Logger unavailable. Original Error: " . thrownObj.Message)
    }
    return 0
}
