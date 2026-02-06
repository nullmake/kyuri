#Requires AutoHotkey v2.0

/**
 * @class SystemActionAdapterTest
 * Validates the public interface of the SystemActionAdapter.
 */
class SystemActionAdapterTest {
    /**
     * @method Test_GetActions_ReturnsCorrectMap
     */
    Test_GetActions_ReturnsCorrectMap() {
        adapter := SystemActionAdapter()
        actions := adapter.GetActions()
        
        Assert.True(actions is Map, "Should return a Map.")
        Assert.True(actions.Has("IMEToggle"), "Should contain IMEToggle.")
        Assert.True(actions.Has("ImeOn"), "Should contain ImeOn.")
        Assert.True(actions.Has("ImeOff"), "Should contain ImeOff.")
        Assert.True(actions.Has("NextWindow"), "Should contain NextWindow.")
        Assert.True(actions.Has("PrevWindow"), "Should contain PrevWindow.")
    }

    /**
     * @method Test_ImeActions_CanBeCalled
     * Ensures IME methods can be called without errors (even if actual state doesn't change in test env).
     */
    Test_ImeActions_CanBeCalled() {
        adapter := SystemActionAdapter()
        ; Call with variadic dummy params to test flexibility
        adapter.IMEToggle()
        adapter.ImeOn(1, 2, 3)
        adapter.ImeOff("dummy")
        
        Assert.True(true, "IME actions should execute without throwing errors.")
    }
}