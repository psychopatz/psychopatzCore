-- Small bounded JSON codec shared by Core subsystems.
--
-- This deliberately has no dependency on the external bridge. Translation
-- catalogs use Decode only, while the bridge continues to use Encode and
-- Fingerprint through this same module.
local Json = {}

local DEFAULT_LIMITS = {
    maxString = 1048576,
    maxDepth = 32,
    maxCollection = 4096,
}

-- Optional marker used by strict object consumers that must distinguish JSON
-- null from an absent Lua table field. Normal bridge decoding keeps null as
-- Lua nil for backwards compatibility.
Json.NULL = {}

local Parser = require
    "PsychopatzCore/Serialization/PsychopatzJson_Parser"

local function limitsOrDefault(limits)
    limits = type(limits) == "table" and limits or {}
    return {
        maxString = tonumber(limits.maxString) or DEFAULT_LIMITS.maxString,
        maxDepth = tonumber(limits.maxDepth) or DEFAULT_LIMITS.maxDepth,
        maxCollection = tonumber(limits.maxCollection)
            or DEFAULT_LIMITS.maxCollection,
        preserveNull = limits.preserveNull == true,
    }
end

local function escape(value)
    return string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(
        tostring(value), "\\", "\\\\"), '"', '\\"'), "\n", "\\n"),
        "\r", "\\r"), "\t", "\\t")
end

local function isArray(value)
    local count = 0
    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false, 0
        end
        count = math.max(count, key)
    end
    for index = 1, count do
        if value[index] == nil then return false, 0 end
    end
    return true, count
end

local function encode(value, depth, limits)
    if depth > limits.maxDepth then return '"[depth-limit]"' end
    local kind = type(value)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return value and "true" or "false" end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "null"
        end
        return tostring(value)
    end
    if kind == "string" then
        return '"' .. escape(string.sub(value, 1, limits.maxString)) .. '"'
    end
    if kind ~= "table" then return '"[unsupported]"' end

    local array, count = isArray(value)
    local parts = {}
    if array then
        for index = 1, math.min(count, limits.maxCollection) do
            parts[#parts + 1] = encode(value[index], depth + 1, limits)
        end
        return "[" .. table.concat(parts, ",") .. "]"
    end

    local keys = {}
    for key, _ in pairs(value) do
        if type(key) == "string" then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for index = 1, math.min(#keys, limits.maxCollection) do
        local key = keys[index]
        parts[#parts + 1] = '"' .. escape(key) .. '":'
            .. encode(value[key], depth + 1, limits)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function Json.Encode(value, limits)
    return encode(value, 0, limitsOrDefault(limits))
end

function Json.Decode(text, limits)
    if type(text) ~= "string" then return nil, "json text required" end
    local normalized = limitsOrDefault(limits)
    if #text > normalized.maxString then return nil, "json text too large" end
    if string.sub(text, 1, 3) == "\239\187\191" then
        text = string.sub(text, 4)
    end
    local ok, value = pcall(
        Parser.Parse,
        text,
        normalized,
        Json.NULL
    )
    if not ok then return nil, tostring(value) end
    return value
end

-- Stable, dependency-free fingerprint for small metadata documents.
function Json.Fingerprint(text)
    text = tostring(text or "")
    local first, second = 5381, 52711
    local modulus = 4294967291
    for index = 1, #text do
        local byte = string.byte(text, index)
        first = (first * 33 + byte) % modulus
        second = (second * 65599 + byte) % modulus
    end
    return tostring(first) .. ":" .. tostring(second) .. ":" .. tostring(#text)
end

return Json
