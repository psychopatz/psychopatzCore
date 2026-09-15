-- Small bounded JSON codec shared by Core subsystems.
--
-- This deliberately has no dependency on the external bridge.  Translation
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

local function utf8Character(code)
    if code <= 0x7f then return string.char(code) end
    if code <= 0x7ff then
        return string.char(
            0xc0 + math.floor(code / 0x40),
            0x80 + code % 0x40
        )
    end
    if code <= 0xffff then
        return string.char(
            0xe0 + math.floor(code / 0x1000),
            0x80 + math.floor(code / 0x40) % 0x40,
            0x80 + code % 0x40
        )
    end
    return string.char(
        0xf0 + math.floor(code / 0x40000),
        0x80 + math.floor(code / 0x1000) % 0x40,
        0x80 + math.floor(code / 0x40) % 0x40,
        0x80 + code % 0x40
    )
end

local function parser(text, limits)
    local position, length = 1, #text
    local parseValue

    local function whitespace()
        while position <= length
            and string.match(string.sub(text, position, position), "%s")
        do
            position = position + 1
        end
    end

    local function parseString()
        if string.sub(text, position, position) ~= '"' then
            error("expected string")
        end
        position = position + 1
        local output = {}
        while position <= length do
            local character = string.sub(text, position, position)
            position = position + 1
            if character == '"' then return table.concat(output) end
            if character == "\\" then
                local escaped = string.sub(text, position, position)
                position = position + 1
                local replacements = {
                    ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
                    b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
                }
                if escaped == "u" then
                    local hex = string.sub(text, position, position + 3)
                    if not string.match(hex, "^%x%x%x%x$") then
                        error("invalid unicode escape")
                    end
                    position = position + 4
                    local code = tonumber(hex, 16)
                    if code >= 0xd800 and code <= 0xdbff
                        and string.sub(text, position, position + 1) == "\\u"
                    then
                        local lowHex = string.sub(text, position + 2, position + 5)
                        local low = tonumber(lowHex, 16)
                        if not low or low < 0xdc00 or low > 0xdfff then
                            error("invalid unicode surrogate")
                        end
                        position = position + 6
                        code = 0x10000 + (code - 0xd800) * 0x400
                            + (low - 0xdc00)
                    elseif code >= 0xd800 and code <= 0xdfff then
                        error("unpaired unicode surrogate")
                    end
                    output[#output + 1] = utf8Character(code)
                elseif replacements[escaped] then
                    output[#output + 1] = replacements[escaped]
                else
                    error("invalid escape")
                end
            else
                if string.byte(character) < 32 then
                    error("control character in string")
                end
                output[#output + 1] = character
            end
            if #output > limits.maxString then error("string limit") end
        end
        error("unterminated string")
    end

    local function parseNumber()
        local start = position
        while position <= length
            and string.match(string.sub(text, position, position),
                "[-+0-9.eE]")
        do
            position = position + 1
        end
        local value = tonumber(string.sub(text, start, position - 1))
        if value == nil then error("invalid number") end
        return value
    end

    local function parseContainer(close, array, depth)
        if depth > limits.maxDepth then error("depth limit") end
        position = position + 1
        whitespace()
        local output, count = {}, 0
        if string.sub(text, position, position) == close then
            position = position + 1
            return output
        end
        while position <= length do
            count = count + 1
            if count > limits.maxCollection then
                error("collection limit")
            end
            if array then
                output[count] = parseValue(depth + 1)
            else
                whitespace()
                local key = parseString()
                whitespace()
                if string.sub(text, position, position) ~= ":" then
                    error("expected colon")
                end
                position = position + 1
                local value = parseValue(depth + 1)
                if output[key] ~= nil then error("duplicate key " .. key) end
                output[key] = value
            end
            whitespace()
            local delimiter = string.sub(text, position, position)
            position = position + 1
            if delimiter == close then return output end
            if delimiter ~= "," then error("expected delimiter") end
            whitespace()
        end
        error("unterminated collection")
    end

    parseValue = function(depth)
        whitespace()
        local character = string.sub(text, position, position)
        if character == '"' then return parseString() end
        if character == "{" then return parseContainer("}", false, depth) end
        if character == "[" then return parseContainer("]", true, depth) end
        if string.sub(text, position, position + 3) == "true" then
            position = position + 4
            return true
        end
        if string.sub(text, position, position + 4) == "false" then
            position = position + 5
            return false
        end
        if string.sub(text, position, position + 3) == "null" then
            position = position + 4
            return limits.preserveNull and Json.NULL or nil
        end
        return parseNumber()
    end

    local value = parseValue(0)
    whitespace()
    if position <= length then error("trailing input") end
    return value
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
    local ok, value = pcall(parser, text, normalized)
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
