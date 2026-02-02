#Requires AutoHotkey v2.0

/**
 * Class: Logger
 * Buffers logs in memory and flushes to rotating files.
 * Automatically captures file and line info for all levels.
 */
class Logger {
    /** @field {Boolean} _enabled - Internal logging state */
    _enabled := true
    /** @field {String} logDir - Directory for log files */
    logDir := ""
    /** @field {Array} buffer - Memory storage for log entries */
    buffer := []
    /** @field {Integer} maxEntries - Maximum lines in memory */
    maxEntries := 0
    /** @field {Integer} maxFiles - Maximum history files to keep */
    maxFiles := 0
    /** @field {Integer} pid - Current process ID for uniqueness */
    pid := DllCall("GetCurrentProcessId")

    /**
     * Property: Enabled
     * Handles switching and clears buffer when disabled.
     */
    Enabled {
        get => this._enabled
        set {
            this._enabled := value
            if (!value) {
                this.buffer := []
            }
        }
    }

    /**
     * Constructor: __New
     * @param {String} baseDir - Application base directory
     * @param {Integer} maxEntries - Buffer size limit
     * @param {Integer} maxFiles - Maximum history files
     * @param {Boolean} enabled - Initial logging state
     */
    __New(baseDir, maxEntries := 1000, maxFiles := 30, enabled := true) {
        this.logDir := baseDir . "\log"
        this.maxEntries := maxEntries
        this.maxFiles := maxFiles
        this.Enabled := enabled

        if !DirExist(this.logDir) {
            DirCreate(this.logDir)
        }
    }

    /**
     * Method: Info
     */
    Info(message) => this.Log("INFO", message)

    /**
     * Method: Warn
     */
    Warn(message) {
        this.Log("WARN", message)
        this.Flush("WRN")
    }

    /**
     * Method: Error
     * @param {String|Object} err - Error message or Error object.
     */
    Error(err) {
        if (IsObject(err)) {
            ; Pass Error object directly to Log for special handling
            this.Log("ERROR", err)
        } else {
            this.Log("ERROR", err)
        }
        this.Flush("ERR")
    }

    /**
     * Method: Log (Internal)
     * Handles metadata extraction and buffering.
     * @param {String} level - INFO, WARN, ERROR, etc.
     * @param {String|Object} msg - The message or error object.
     */
    Log(level, msg) {
        if (!this.Enabled) {
            return
        }

        detail := ""
        if (IsObject(msg)) {
            ; Case: Error object passed
            SplitPath(msg.File, &fileName)
            detail := Format("[{1}:{2}] {3}", fileName, msg.Line, msg.Message)
        } else {
            ; Case: String passed - capture caller location using Error(-2)
            ; -2 reaches the method that called Info()/Warn()/Error()
            try {
                throw Error("", -2)
            } catch Error as e {
                SplitPath(e.File, &fileName)
                detail := Format("[{1}:{2}] {3}", fileName, e.Line, msg)
            }
        }

        ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        entry := "[" . ts . "] [" . level . "] " . detail
        this.buffer.Push(entry)

        if (this.buffer.Length > this.maxEntries) {
            this.buffer.RemoveAt(1)
        }
        OutputDebug(entry)
    }

    /**
     * Method: Flush
     * Writes the current full buffer to a file. Does NOT clear the buffer.
     * @param {String} trigger - Label for the filename (Default: MAN)
     */
    Flush(trigger := "MAN") {
        if (!this.Enabled || this.buffer.Length == 0) {
            return
        }

        ts := FormatTime(, "yyyyMMdd_HHmmss")
        fName := "kyuri_" . ts . "_P" . this.pid . "_" . trigger . ".log"
        fullPath := this.logDir . "\" . fName

        content := ""
        for entry in this.buffer {
            content .= entry . "`n"
        }

        try {
            if FileExist(fullPath) {
                FileDelete(fullPath)
            }
            FileAppend(content, fullPath, "UTF-8")
            this.Rotate()
        } catch Error as e {
            OutputDebug("Log Flush failed: " . e.Message)
        }
    }

    /**
     * Method: Rotate
     * Efficiently rotates logs using the built-in Sort function.
     */
    Rotate() {
        filePaths := ""
        loop files, this.logDir . "\kyuri_*.log" {
            filePaths .= A_LoopFileFullPath . "`n"
        }

        ; Remove trailing newline
        filePaths := RTrim(filePaths, "`n")
        if (filePaths == "") {
            return
        }

        ; Use built-in high-performance Sort (lexicographical)
        sortedPaths := Sort(filePaths)
        fileList := StrSplit(sortedPaths, "`n")

        ; Delete oldest files if they exceed maxFiles
        if (fileList.Length > this.maxFiles) {
            deleteCount := fileList.Length - this.maxFiles
            loop deleteCount {
                try {
                    FileDelete(fileList[A_Index])
                }
            }
        }
    }
}
