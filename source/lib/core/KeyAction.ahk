/**
 * @class KeyAction
 * Represents a single executable action (Key or Function).
 */
class KeyAction {
    /** @field {Integer} Type - One of ActionType constants */
    Type := 0
    /** @field {Any} Data - Key string or Function object */
    Data := ""
    /** @field {String} Trigger - The physical key name that triggered this action */
    Trigger := ""

    /**
     * @method __New
     * @constructor
     * @param {Integer} type
     * @param {Any} data
     * @param {String} trigger
     */
    __New(type, data, trigger) {
        this.Type := type
        this.Data := data
        this.Trigger := trigger
    }
}