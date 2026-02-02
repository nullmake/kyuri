#Requires AutoHotkey v2.0

/**
 * Class: ConfigManager
 * Handles application configuration lifecycle and template initialization.
 */
class ConfigManager {
    /** @field {String} configFilePath - Absolute path to the config file */
    configFilePath := ""
    /** @field {String} templatePath - Absolute path to the template file */
    templatePath := ""
    /** @field {Map} settings - Parsed configuration data */
    settings := Map()

    /**
     * Constructor: __New
     * @param {String} configDir - Directory where config files reside
     */
    __New(configDir) {
        this.configFilePath := configDir . "\config.json"
        this.templatePath := configDir . "\config.json.template"
    }

    /**
     * Method: Load
     * Ensures the config file exists and loads it into memory.
     */
    Load() {
        if !FileExist(this.configFilePath) {
            this.InitializeFromTemplate()
        }
        try {
            /**
             * JSON.LoadFile strips comments internally.
             * This method ensures the settings map is populated from the physical file.
             */
            this.settings := JSON.LoadFile(this.configFilePath)
        } catch Error as e {
            MsgBox("Failed to load config.json:`n" . e.Message, "Kyuri Error", 16)
            ExitApp()
        }
    }

    /**
     * Gets a value using dot-notation path.
     * @param {String} path - Path string like "General.Version" or "Modifiers.M0".
     * @param {Any} defaultValue - Value to return if the path is not found.
     * @returns {Any} The value found at the path or the defaultValue.
     */
    Get(path, defaultValue := "") {
        if (path == "") {
            return this.settings
        }

        keys := StrSplit(path, ".")
        current := this.settings

        /**
         * Traverse the settings structure recursively based on the dot-notation keys.
         * Supports both Map (JSON objects) and standard objects if necessary.
         */
        for key in keys {
            if (current is Map && current.Has(key)) {
                current := current[key]
            } else if (IsObject(current) && HasProp(current, key)) {
                current := current.%key%
            } else {
                return defaultValue
            }
        }
        return current
    }

    /**
     * Method: InitializeFromTemplate
     * Copies the template file to the active config file path if it doesn't exist.
     */
    InitializeFromTemplate() {
        if !FileExist(this.templatePath) {
            err := "Critical Error: Template file missing.`nPath: " . this.templatePath
            MsgBox(err, "Kyuri Error", 16)
            ExitApp()
        }
        FileCopy(this.templatePath, this.configFilePath)
    }
}
