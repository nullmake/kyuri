/**
 * @class LayerRemap
 * Container for actions mapped to different modifier layers for a single key.
 */
class LayerRemap {
    /** @field {Action} Tap - Default action or action when no modifiers are held */
    Tap := ""
    /** @field {Action} HoldM0 - Action when M0 is held */
    HoldM0 := ""
    /** @field {Action} HoldM1 - Action when M1 is held */
    HoldM1 := ""
    /** @field {Action} HoldBoth - Action when both M0 and M1 are held */
    HoldBoth := ""
}
