-- Bounded, dependency-free JSON used only for the external bridge protocol.
local Json = {}

local function escape(value)
    return string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(
        tostring(value), "\\", "\\\\"), '"', '\\"'), "\n", "\\n"), "\r", "\\r"), "\t", "\\t")
end

local function isArray(value)
    local count = 0
    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false, 0 end
        count = math.max(count, key)
    end
    for index = 1, count do if value[index] == nil then return false, 0 end end
    return true, count
end

local function encode(value, depth, limits)
    if depth > limits.maxDepth then return '"[depth-limit]"' end
    local kind = type(value)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return value and "true" or "false" end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then return "null" end
        return tostring(value)
    end
    if kind == "string" then return '"' .. escape(string.sub(value, 1, limits.maxString)) .. '"' end
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
    for key, _ in pairs(value) do if type(key) == "string" then keys[#keys + 1] = key end end
    table.sort(keys)
    for index = 1, math.min(#keys, limits.maxCollection) do
        local key = keys[index]
        parts[#parts + 1] = '"' .. escape(key) .. '":' .. encode(value[key], depth + 1, limits)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function parser(text, limits)
    local position, length = 1, #text
    local parseValue
    local function whitespace()
        while position <= length and string.match(string.sub(text, position, position), "%s") do
            position = position + 1
        end
    end
    local function parseString()
        if string.sub(text, position, position) ~= '"' then error("expected string") end
        position = position + 1
        local output = {}
        while position <= length do
            local character = string.sub(text, position, position)
            position = position + 1
            if character == '"' then return table.concat(output) end
            if character == "\\" then
                local escaped = string.sub(text, position, position)
                position = position + 1
                local replacements = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
                    b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
                if escaped == "u" then
                    local hex = string.sub(text, position, position + 3)
                    if not string.match(hex, "^%x%x%x%x$") then error("invalid unicode escape") end
                    position = position + 4
                    local code = tonumber(hex, 16)
                    output[#output + 1] = code and code < 128 and string.char(code) or "?"
                elseif replacements[escaped] then output[#output + 1] = replacements[escaped]
                else error("invalid escape") end
            else output[#output + 1] = character end
            if #output > limits.maxString then error("string limit") end
        end
        error("unterminated string")
    end
    local function parseNumber()
        local start = position
        while position <= length and string.match(string.sub(text, position, position), "[-+0-9.eE]") do
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
        if string.sub(text, position, position) == close then position = position + 1 return output end
        while position <= length do
            count = count + 1
            if count > limits.maxCollection then error("collection limit") end
            if array then output[count] = parseValue(depth + 1)
            else
                whitespace()
                local key = parseString()
                whitespace()
                if string.sub(text, position, position) ~= ":" then error("expected colon") end
                position = position + 1
                output[key] = parseValue(depth + 1)
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
        if string.sub(text, position, position + 3) == "true" then position = position + 4 return true end
        if string.sub(text, position, position + 4) == "false" then position = position + 5 return false end
        if string.sub(text, position, position + 3) == "null" then position = position + 4 return nil end
        return parseNumber()
    end
    local value = parseValue(0)
    whitespace()
    if position <= length then error("trailing input") end
    return value
end

function Json.Encode(value, limits)
    return encode(value, 0, limits)
end

function Json.Decode(text, limits)
    local ok, value = pcall(parser, text, limits)
    if not ok then return nil, "malformed JSON" end
    return value
end

return Json
