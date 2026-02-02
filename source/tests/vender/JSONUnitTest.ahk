#Requires AutoHotkey v2.0

/**
 * JSONUnitTest Class
 * Comprehensive test runner for JSON.ahk, combining basic and advanced patterns.
 * * Follows strict block formatting (no omitted braces).
 */
class JSONUnitTest {
    /**
     * Runs all registered test cases.
     * @returns {Integer} 1 if all passed, 0 otherwise.
     */
    Run() {
        tests := [
            this.TestPrimitives,
            this.TestArrays,
            this.TestObjects,
            this.TestNestedStructure,
            this.TestEdgeCases,
            this.TestComments,
            this.TestScientificNotation,
            this.TestConsecutiveClosures
        ]

        passed := 0
        failed := 0
        results := "--- JSON.ahk Comprehensive Test Results ---`n"

        for test in tests {
            try {
                test.Call(this)
                results .= "✅ PASSED: " . test.Name . "`n"
                passed++
            } catch Any as e {
                results .= "❌ FAILED: " . test.Name . "`n   Reason: " . e.Message . "`n"
                failed++
            }
        }

        results .= "`nSummary: " . passed . " passed, " . failed . " failed."
        MsgBox(results)
        return (failed == 0)
    }

    /**
     * Primitives: String, Number, Boolean, Null
     */
    Test_Primitives() {
        if (JSON.Load("123") !== 123) {
            throw Error("Integer mismatch")
        }
        if (JSON.Load("-12.34") !== -12.34) {
            throw Error("Float mismatch")
        }
        if (JSON.Load('"Hello World"') !== "Hello World") {
            throw Error("String mismatch")
        }
        if (JSON.Load("true") !== true) {
            throw Error("Boolean True mismatch")
        }
        if (JSON.Load("false") !== false) {
            throw Error("Boolean False mismatch")
        }
        if (JSON.Load("null") !== "") {
            throw Error("Null mismatch")
        }
    }

    /**
     * Basic and Empty Arrays
     */
    Test_Arrays() {
        arr := JSON.Load('[1, "two", true]')
        if (arr.Length !== 3 || arr[2] !== "two") {
            throw Error("Basic Array mismatch")
        }
        if (JSON.Load('[]').Length !== 0) {
            throw Error("Empty Array mismatch")
        }
    }

    /**
     * Basic and Empty Objects (Maps)
     */
    Test_Objects() {
        obj := JSON.Load('{"key": "value", "num": 100}')
        if (obj["key"] !== "value" || obj["num"] !== 100) {
            throw Error("Basic Object mismatch")
        }
        if (JSON.Load('{}').Count !== 0) {
            throw Error("Empty Object mismatch")
        }
    }

    /**
     * Deeply Nested Structures (Object > Array > Object)
     */
    Test_NestedStructure() {
        jsonStr := '{"level1": {"level2": [{"level3": [999]}]}}'
        data := JSON.Load(jsonStr)
        if (data["level1"]["level2"][1]["level3"][1] !== 999) {
            throw Error("Deep nesting mismatch")
        }
    }

    /**
     * Whitespace and Escaped Characters
     */
    Test_EdgeCases() {
        if (JSON.Load('  { "id" : 123 }  ')["id"] !== 123) {
            throw Error("Whitespace mismatch")
        }
        if (JSON.Load('"Line1\nLine2"') !== "Line1`nLine2") {
            throw Error("Escape Sequence mismatch")
        }
    }

    /**
     * Comment Stripping Simulation
     */
    Test_Comments() {
        raw := '{"key": 100 // comment`n}'
        clean := RegExReplace(raw, "\/\/[^\n\r]*", "")
        if (JSON.Load(clean)["key"] !== 100) {
            throw Error("Comment stripping mismatch")
        }
    }

    /**
     * E-notation (Scientific) Numbers
     */
    Test_ScientificNotation() {
        data := JSON.Load('{"big": 1.2e+3, "small": -5.0e-1}')
        if (data["big"] != 1200) {
            throw Error("Positive E-notation mismatch")
        }
        if (data["small"] != -0.5) {
            throw Error("Negative E-notation mismatch")
        }
    }

    /**
     * Consecutive Closing Symbols (The "1304" fix verification)
     */
    Test_ConsecutiveClosures() {
        jsonStr := '{"a": [{"b": {"c": 1}}], "d": 2}'
        data := JSON.Load(jsonStr)
        if (data["a"][1]["b"]["c"] !== 1) {
            throw Error("Consecutive braces failed at nested object")
        }
        if (data["d"] !== 2) {
            throw Error("Consecutive braces failed at subsequent key")
        }
    }
}
