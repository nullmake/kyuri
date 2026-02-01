#Requires AutoHotkey v2.0

/**
 * Class: Logger
 * Buffers logs in memory and flushes to rotating files.
 */
class Logger {
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
     * Constructor: __New
     * @param {String} baseDir - Application base directory
     * @param {Integer} maxEntries - Buffer size limit
     * @param {Integer} maxFiles - Maximum history files
     */
    __New(baseDir, maxEntries := 1000, maxFiles := 30) {
        this.logDir := baseDir . "\log"
        this.maxEntries := maxEntries
        this.maxFiles := maxFiles

        if !DirExist(this.logDir) {
            DirCreate(this.logDir)
        }

        ; Register exit callback
        OnExit((*) => this.Flush("EXIT"))
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
     */
    Error(message) {
        this.Log("ERROR", message)
        this.Flush("ERR")
    }

    /**
     * Method: Log
     * Internal: Manage buffer and OutputDebug.
     */
    Log(level, message) {
        ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        entry := "[" . ts . "] [" . level . "] " . message
        this.buffer.Push(entry)

        if (this.buffer.Length > this.maxEntries) {
            this.buffer.RemoveAt(1)
        }
        OutputDebug(entry . "`n")
    }

    /**
     * Method: Flush
     * Writes the current full buffer to a file. Does NOT clear the buffer.
     * @param {String} trigger - Label for the filename (Default: MAN)
     */
    Flush(trigger := "MAN") {
        if (this.buffer.Length == 0) {
            return
        }

        ts := FormatTime(, "yyyyMMdd_HHmmss")
        fileName := this.logDir . "\kyuri_" . ts . "_P" . this.pid . "_" . trigger . ".log"

        content := ""
        for entry in this.buffer {
            content .= entry . "`n"
        }

        try {
            if FileExist(fileName) {
                FileDelete(fileName)
            }
            FileAppend(content, fileName, "UTF-8")
            this.Rotate()
        } catch Error as e {
            OutputDebug("Log Flush failed: " . e.Message . "`n")
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
