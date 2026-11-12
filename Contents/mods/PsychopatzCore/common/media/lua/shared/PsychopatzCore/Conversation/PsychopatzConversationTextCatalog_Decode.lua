PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Loader = PsychopatzCore.Conversation.TextCatalog or {}
local Internal = Loader.Internal or {}
Loader.Internal = Internal

local function utf8Character(code)
    if code <= 0x7f then return string.char(code) end
    if code <= 0x7ff then
        return string.char(0xc0 + math.floor(code / 0x40),
            0x80 + code % 0x40)
    end
    if code <= 0xffff then
        return string.char(0xe0 + math.floor(code / 0x1000),
            0x80 + math.floor(code / 0x40) % 0x40,
            0x80 + code % 0x40)
    end
    return string.char(0xf0 + math.floor(code / 0x40000),
        0x80 + math.floor(code / 0x1000) % 0x40,
        0x80 + math.floor(code / 0x40) % 0x40,
        0x80 + code % 0x40)
end

local function skipWhitespace(text, index)
    local length = #text
    for _ = index, length do
        if index > length then break end
        local byte = string.byte(text, index)
        if byte ~= 32 and byte ~= 9 and byte ~= 10 and byte ~= 13 then break end
        index = index + 1
    end
    return index
end

local function parseHex(text, index)
    local value = tonumber(string.sub(text, index, index + 3), 16)
    if value == nil then return nil, index, "invalid unicode escape" end
    return value, index + 4
end

local function parseString(text, index)
    if string.sub(text, index, index) ~= '"' then
        return nil, index, "expected string"
    end
    index = index + 1
    local output = {}
    local start = index
    local length = #text
    for _ = index, length do
        if index > length then break end
        local character = string.sub(text, index, index)
        if character == '"' then
            output[#output + 1] = string.sub(text, start, index - 1)
            return table.concat(output), index + 1
        end
        if character == "\\" then
            output[#output + 1] = string.sub(text, start, index - 1)
            index = index + 1
            local escaped = string.sub(text, index, index)
            local replacements = {
                ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
                b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
            }
            if replacements[escaped] then
                output[#output + 1] = replacements[escaped]
                index = index + 1
            elseif escaped == "u" then
                local code
                code, index = parseHex(text, index + 1)
                if not code then return nil, index, "invalid unicode escape" end
                if code >= 0xd800 and code <= 0xdbff
                    and string.sub(text, index, index + 1) == "\\u"
                then
                    local low
                    low, index = parseHex(text, index + 2)
                    if not low or low < 0xdc00 or low > 0xdfff then
                        return nil, index, "invalid unicode surrogate"
                    end
                    code = 0x10000 + (code - 0xd800) * 0x400
                        + (low - 0xdc00)
                elseif code >= 0xd800 and code <= 0xdfff then
                    return nil, index, "unpaired unicode surrogate"
                end
                output[#output + 1] = utf8Character(code)
            else
                return nil, index, "invalid escape"
            end
            start = index
        else
            if string.byte(text, index) < 32 then
                return nil, index, "control character in string"
            end
            index = index + 1
        end
    end
    return nil, index, "unterminated string"
end

function Loader.Decode(text)
    if type(text) ~= "string" then return nil, "json text required" end
    if #text > (Internal.MAX_TRANSLATION_BYTES or 1048576) then
        return nil, "translation file too large"
    end
    local bom = string.char(239, 187, 191)
    if string.sub(text, 1, 3) == bom then text = string.sub(text, 4) end
    local values = {}
    local index = skipWhitespace(text, 1)
    if string.sub(text, index, index) ~= "{" then
        return nil, "expected object"
    end
    index = skipWhitespace(text, index + 1)
    if string.sub(text, index, index) == "}" then
        index = skipWhitespace(text, index + 1)
        if index <= #text then return nil, "trailing content" end
        return values
    end
    local length = #text
    for _ = index, length do
        if index > length then break end
        local key, reason
        key, index, reason = parseString(text, index)
        if not key then return nil, reason end
        if values[key] ~= nil then return nil, "duplicate key " .. key end
        index = skipWhitespace(text, index)
        if string.sub(text, index, index) ~= ":" then return nil, "expected colon" end
        index = skipWhitespace(text, index + 1)
        local value
        value, index, reason = parseString(text, index)
        if value == nil then return nil, reason or "values must be strings" end
        values[key] = value
        index = skipWhitespace(text, index)
        local separator = string.sub(text, index, index)
        if separator == "}" then
            index = skipWhitespace(text, index + 1)
            if index <= #text then return nil, "trailing content" end
            return values
        end
        if separator ~= "," then return nil, "expected comma or object end" end
        index = skipWhitespace(text, index + 1)
    end
    return nil, "unterminated object"
end

return Loader
