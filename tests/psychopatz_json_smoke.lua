local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local function assertEqual(actual, expected, message)
    assert(actual == expected,
        message .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

local decoded = Json.Decode(
    "\239\187\191{\"text\":\"line\\n\\u0041\","
    .. "\"items\":[true,false,null,3.5],"
    .. "\"emoji\":\"\\uD83D\\uDE00\"}",
    { preserveNull = true }
)
assert(decoded, "bounded JSON document should decode")
assertEqual(decoded.text, "line\nA", "escaped text")
assertEqual(decoded.items[1], true, "boolean array value")
assertEqual(decoded.items[2], false, "false array value")
assertEqual(decoded.items[3], Json.NULL, "preserved null marker")
assertEqual(decoded.items[4], 3.5, "number array value")
assert(#decoded.emoji == 4, "surrogate pair should produce UTF-8")

local encoded = Json.Encode({ b = "line\n", a = 2 })
assertEqual(encoded, '{"a":2,"b":"line\\n"}', "stable object encoding")

local _, duplicateReason = Json.Decode('{"a":1,"a":2}')
assert(string.find(duplicateReason, "duplicate key", 1, true),
    "duplicate key rejection")
local _, collectionReason = Json.Decode("[1,2]", { maxCollection = 1 })
assert(string.find(collectionReason, "collection limit", 1, true),
    "collection limit")
local _, surrogateReason = Json.Decode('"\\uD800"')
assert(string.find(surrogateReason, "unpaired unicode surrogate", 1, true),
    "unpaired surrogate rejection")
local _, typeReason = Json.Decode(42)
assertEqual(typeReason, "json text required", "decode type validation")

print("psychopatz json: ok")
