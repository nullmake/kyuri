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
            ; JSON.LoadFile strips comments internally
            this.settings := JSON.LoadFile(this.configFilePath)
        } catch Error as e {
            MsgBox("Failed to load config.json:`n" . e.Message, "Kyuri Error", 16)
            ExitApp()
        }
    }

    /**
     * Method: Get
     * @param {String} key - The setting key
     * @param {Any} defaultValue - Fallback value
     * @returns {Any}
     */
    Get(key, defaultValue := "") => (
        this.settings.Has(key) ? this.settings[key] : defaultValue
    )

    /**
     * Method: InitializeFromTemplate
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
