#Requires AutoHotkey v2.0

/**
 * Lib: JSON.ahk
 * JSON lib for AutoHotkey.
 * * Original Author:
 * cocobelgica (v2.1.3 - 04/18/2016)
 * https://github.com/cocobelgica/AutoHotkey-JSON
 * * Modified for Kyuri Project:
 * - Ported and optimized for AutoHotkey v2.0+ syntax.
 * - Added JSON.LoadFile and JSON.DumpFile for easier I/O. (Added for Kyuri)
 * - Improved JSONC (commented JSON) support in LoadFile. (Added for Kyuri)
 * - Fixed AHK v2.0+ grammar issues (statement blocks and variable scopes).
 * * License:
 * WTFPL [http://wtfpl.net/]
 */

class JSON {
    /**
     * Load JSON from a file, stripping // comments.
     */
    static LoadFile(path) {
        if !FileExist(path) {
            throw Error("File not found: " . path)
        }

        content := FileRead(path, "UTF-8")
        ; Strip // comments (JSONC support)
        cleanContent := RegExReplace(content, "\/\/[^\n\r]*", "")
        return this.Load(cleanContent)
    }

    /**
     * Dump AHK value to a JSON file.
     */
    static DumpFile(path, obj) {
        try {
            jsonString := this.Dump(obj)
            if FileExist(path)
                FileDelete(path)
            FileAppend(jsonString, path, "UTF-8")
        } catch Error as e {
            throw Error("Failed to save JSON file: " . e.Message)
        }
    }

    /**
     * Method: Load
     * Parses a JSON string into an AHK value (Map, Array, or primitive)
     */
    static Load(text, reviver := "") {
        pos := 1

        parse_value() {
            eat_whitespace()
            char := SubStr(text, pos, 1)

            if (char == "{")
                return parse_object()
            else if (char == "[")
                return parse_array()
            else if (char == '"')
                return parse_string()
            else if (char == "t" && SubStr(text, pos, 4) == "true") {
                pos += 4
                return true
            } else if (char == "f" && SubStr(text, pos, 5) == "false") {
                pos += 5
                return false
            } else if (char == "n" && SubStr(text, pos, 4) == "null") {
                pos += 4
                return ""
            } else if (char == "}" || char == "]" || char == "") {
                ; Safety: If we hit an end-char where a value was expected,
                ; it's either an empty structure or malformed JSON.
                return ""
            } else {
                return parse_number()
            }
        }

        eat_whitespace() {
            while (pos <= StrLen(text) && RegExMatch(SubStr(text, pos, 1), "\s"))
                pos++
        }

        parse_object() {
            obj := Map()
            pos++ ; skip {
            loop {
                eat_whitespace()
                char := SubStr(text, pos, 1)
                if (char == "}" || char == "") {
                    pos++
                    return obj
                }
                key := parse_string()
                eat_whitespace()
                pos++ ; skip :
                val := parse_value()
                obj[key] := val
                eat_whitespace()
                next := SubStr(text, pos, 1)
                if (next == "}") {
                    pos++
                    return obj
                } else if (next == ",") {
                    pos++
                } else {
                    ; If no comma or brace, check if we've reached the end anyway
                    break
                }
            }
            return obj
        }

        parse_array() {
            arr := []
            pos++ ; skip [
            loop {
                eat_whitespace()
                char := SubStr(text, pos, 1)
                if (char == "]" || char == "") {
                    pos++
                    return arr
                }
                arr.Push(parse_value())
                eat_whitespace()
                next := SubStr(text, pos, 1)
                if (next == "]") {
                    pos++
                    return arr
                } else if (next == ",") {
                    pos++
                } else {
                    break
                }
            }
            return arr
        }

        parse_string() {
            pos++ ; skip "
            str := ""
            while (pos <= StrLen(text)) {
                char := SubStr(text, pos, 1)
                if (char == '"') {
                    pos++
                    return str
                }
                if (char == "\") {
                    next := SubStr(text, pos + 1, 1)
                    if (next == '"') {
                        str .= '"', pos += 2
                    } else if (next == "\") {
                        str .= "\", pos += 2
                    } else if (next == "/") {
                        str .= "/", pos += 2
                    } else if (next == "b") {
                        str .= "`b", pos += 2
                    } else if (next == "f") {
                        str .= "`f", pos += 2
                    } else if (next == "n") {
                        str .= "`n", pos += 2
                    } else if (next == "r") {
                        str .= "`r", pos += 2
                    } else if (next == "t") {
                        str .= "`t", pos += 2
                    } else if (next == "u") {
                        hex := SubStr(text, pos + 2, 4)
                        str .= Chr(Integer("0x" . hex))
                        pos += 6
                    }
                } else {
                    str .= char
                    pos++
                }
            }
            return str
        }

        parse_number() {
            if RegExMatch(text, "S)\G-?\d+(\.\d+)?([eE][+-]?\d+)?", &match, pos) {
                pos += match.Len(0)
                return Number(match[0])
            }
            throw Error("JSON Parse Error: Expected number at position " . pos)
        }

        return parse_value()
    }

    /**
     * Method: Dump
     * Converts an AHK value into a JSON string
     */
    static Dump(obj, indent := "") {
        if IsObject(obj) {
            is_array := (obj is Array)

            res := is_array ? "[" : "{"
            for k, v in obj {
                res .= (A_Index > 1 ? "," : "")
                if (!is_array)
                    res .= '"' k '":'
                res .= this.Dump(v)
            }
            return res (is_array ? "]" : "}")
        } else if IsNumber(obj) {
            return obj
        } else if (obj == true) {
            return "true"
        } else if (obj == false) {
            return "false"
        } else {
            str := StrReplace(obj, "\", "\\")
            str := StrReplace(str, '"', '\"')
            str := StrReplace(str, "`n", "\n")
            str := StrReplace(str, "`r", "\r")
            str := StrReplace(str, "`t", "\t")
            return '"' str '"'
        }
    }
}
