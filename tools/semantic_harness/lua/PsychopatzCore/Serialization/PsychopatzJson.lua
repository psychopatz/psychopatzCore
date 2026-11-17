-- Standalone bounded JSON codec for the installed Semantic Harness.
--
-- The game runtime has a Core-owned codec at the same module name. Keeping a
-- dependency-free copy in the harness package lets the worker run from a
-- wheel without requiring a Project Zomboid checkout.

local Json = {}
Json.NULL = {}

local function limits(value)
    value = type(value) == "table" and value or {}
    return {
        maxString = tonumber(value.maxString) or 1048576,
        maxDepth = tonumber(value.maxDepth) or 32,
        maxCollection = tonumber(value.maxCollection) or 4096,
        preserveNull = value.preserveNull == true,
    }
end

local ESCAPE_MAP = {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local function escapeChar(character)
    local mapped = ESCAPE_MAP[character]
    if mapped then return mapped end
    return string.format("\\u%04x", string.byte(character))
end

local function escaped(value)
    local text = tostring(value)
    if not string.find(text, '[%z\1-\31"\\]') then
        return text
    end
    local result = string.gsub(text, '[%z\1-\31"\\]', escapeChar)
    return result
end

local function isArray(value)
    local count = 0
    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false, 0
        end
        count = math.max(count, key)
    end
    return true, count
end

local function encode(value, depth, config)
    if depth > config.maxDepth then return '"[depth-limit]"' end
    if value == Json.NULL then return "null" end
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
        return '"' .. escaped(string.sub(value, 1, config.maxString)) .. '"'
    end
    if kind ~= "table" then return '"[unsupported]"' end
    local array, count = isArray(value)
    local parts = {}
    if array then
        for index = 1, math.min(count, config.maxCollection) do
            parts[#parts + 1] = encode(value[index], depth + 1, config)
        end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    local keys = {}
    for key, _ in pairs(value) do
        if type(key) == "string" then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for index = 1, math.min(#keys, config.maxCollection) do
        local key = keys[index]
        parts[#parts + 1] = '"' .. escaped(key) .. '":'
            .. encode(value[key], depth + 1, config)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local ESCAPE_REPLACEMENTS = {
    ['"'] = '"',
    ["\\"] = "\\",
    ["/"] = "/",
    b = "\b",
    f = "\f",
    n = "\n",
    r = "\r",
    t = "\t",
}

local function whitespace(text, position)
    local _, finish = string.find(text, "^%s+", position)
    if finish then return finish + 1 end
    return position
end

local function parseString(text, position)
    if string.sub(text, position, position) ~= '"' then
        error("expected JSON string")
    end
    position = position + 1
    local start = position
    local output = nil
    local length = #text
    while position <= length do
        local special = string.find(text, '["\\]', position)
        if not special then
            error("unterminated JSON string")
        end
        if string.byte(text, special) == 34 then
            if not output then
                return string.sub(text, start, special - 1), special + 1
            end
            if special > start then
                output[#output + 1] = string.sub(text, start, special - 1)
            end
            return table.concat(output), special + 1
        end
        output = output or {}
        if special > start then
            output[#output + 1] = string.sub(text, start, special - 1)
        end
        position = special + 1
        local escapedCharacter = string.sub(text, position, position)
        position = position + 1
        if escapedCharacter == "u" then
            local hex = string.sub(text, position, position + 3)
            if not string.match(hex, "^%x%x%x%x$") then
                error("invalid JSON unicode escape")
            end
            position = position + 4
            local code = tonumber(hex, 16)
            if code <= 0x7f then
                output[#output + 1] = string.char(code)
            elseif code <= 0x7ff then
                output[#output + 1] = string.char(
                    0xc0 + math.floor(code / 0x40),
                    0x80 + code % 0x40
                )
            else
                output[#output + 1] = string.char(
                    0xe0 + math.floor(code / 0x1000),
                    0x80 + math.floor(code / 0x40) % 0x40,
                    0x80 + code % 0x40
                )
            end
        else
            output[#output + 1] = ESCAPE_REPLACEMENTS[escapedCharacter]
                or error("invalid JSON escape")
        end
        start = position
    end
    error("unterminated JSON string")
end

local parseValue

local function parseArray(text, position, depth, config)
    position = whitespace(text, position + 1)
    local result = {}
    if string.sub(text, position, position) == "]" then
        return result, position + 1
    end
    while true do
        local value
        value, position = parseValue(text, position, depth + 1, config)
        result[#result + 1] = value
        if #result > config.maxCollection then error("JSON collection limit") end
        position = whitespace(text, position)
        local delimiter = string.sub(text, position, position)
        if delimiter == "]" then return result, position + 1 end
        if delimiter ~= "," then error("expected JSON array delimiter") end
        position = whitespace(text, position + 1)
    end
end

local function parseObject(text, position, depth, config)
    position = whitespace(text, position + 1)
    local result = {}
    if string.sub(text, position, position) == "}" then
        return result, position + 1
    end
    local count = 0
    while true do
        local key
        key, position = parseString(text, position)
        position = whitespace(text, position)
        if string.sub(text, position, position) ~= ":" then
            error("expected JSON object colon")
        end
        local value
        value, position = parseValue(text, whitespace(text, position + 1), depth + 1, config)
        result[key] = value
        count = count + 1
        if count > config.maxCollection then error("JSON collection limit") end
        position = whitespace(text, position)
        local delimiter = string.sub(text, position, position)
        if delimiter == "}" then return result, position + 1 end
        if delimiter ~= "," then error("expected JSON object delimiter") end
        position = whitespace(text, position + 1)
    end
end

parseValue = function(text, position, depth, config)
    if depth > config.maxDepth then error("JSON depth limit") end
    position = whitespace(text, position)
    local character = string.sub(text, position, position)
    if character == '"' then return parseString(text, position) end
    if character == "[" then return parseArray(text, position, depth, config) end
    if character == "{" then return parseObject(text, position, depth, config) end
    if string.sub(text, position, position + 3) == "true" then return true, position + 4 end
    if string.sub(text, position, position + 4) == "false" then return false, position + 5 end
    if string.sub(text, position, position + 3) == "null" then
        return config.preserveNull and Json.NULL or nil, position + 4
    end
    local number = string.match(
        text,
        "^-?%d+%.?%d*[eE]?[+-]?%d*",
        position
    )
    if number and number ~= "" then return tonumber(number), position + #number end
    error("invalid JSON value")
end

function Json.Encode(value, config)
    return encode(value, 0, limits(config))
end

function Json.Decode(text, config)
    if type(text) ~= "string" then return nil, "json text required" end
    local normalized = limits(config)
    if #text > normalized.maxString then return nil, "json text too large" end
    if string.sub(text, 1, 3) == "\239\187\191" then text = string.sub(text, 4) end
    local ok, value, position = pcall(parseValue, text, 1, 0, normalized)
    if not ok then return nil, tostring(value) end
    position = whitespace(text, position)
    if position <= #text then return nil, "trailing JSON content" end
    return value
end

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
