local Parser = {}

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

function Parser.New(text, limits, nullMarker)
    return {
        text = text,
        length = #text,
        position = 1,
        limits = limits,
        nullMarker = nullMarker,
    }
end

function Parser.Whitespace(state)
    while state.position <= state.length
        and string.match(
            string.sub(state.text, state.position, state.position), "%s")
    do
        state.position = state.position + 1
    end
end

function Parser.ParseString(state)
    if string.sub(state.text, state.position, state.position) ~= '"' then
        error("expected string")
    end
    state.position = state.position + 1
    local output = {}
    while state.position <= state.length do
        local character = string.sub(
            state.text, state.position, state.position)
        state.position = state.position + 1
        if character == '"' then return table.concat(output) end
        if character == "\\" then
            local escaped = string.sub(
                state.text, state.position, state.position)
            state.position = state.position + 1
            local replacements = {
                ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
                b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
            }
            if escaped == "u" then
                local hex = string.sub(
                    state.text, state.position, state.position + 3)
                if not string.match(hex, "^%x%x%x%x$") then
                    error("invalid unicode escape")
                end
                state.position = state.position + 4
                local code = tonumber(hex, 16)
                if code >= 0xd800 and code <= 0xdbff
                    and string.sub(
                        state.text, state.position, state.position + 1)
                        == "\\u"
                then
                    local lowHex = string.sub(
                        state.text, state.position + 2, state.position + 5)
                    local low = tonumber(lowHex, 16)
                    if not low or low < 0xdc00 or low > 0xdfff then
                        error("invalid unicode surrogate")
                    end
                    state.position = state.position + 6
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
        if #output > state.limits.maxString then error("string limit") end
    end
    error("unterminated string")
end

function Parser.ParseNumber(state)
    local start = state.position
    while state.position <= state.length
        and string.match(
            string.sub(state.text, state.position, state.position),
            "[-+0-9.eE]")
    do
        state.position = state.position + 1
    end
    local value = tonumber(string.sub(state.text, start, state.position - 1))
    if value == nil then error("invalid number") end
    return value
end

function Parser.ParseContainer(state, close, array, depth)
    if depth > state.limits.maxDepth then error("depth limit") end
    state.position = state.position + 1
    Parser.Whitespace(state)
    local output, count = {}, 0
    if string.sub(state.text, state.position, state.position) == close then
        state.position = state.position + 1
        return output
    end
    while state.position <= state.length do
        count = count + 1
        if count > state.limits.maxCollection then
            error("collection limit")
        end
        if array then
            output[count] = Parser.ParseValue(state, depth + 1)
        else
            Parser.Whitespace(state)
            local key = Parser.ParseString(state)
            Parser.Whitespace(state)
            if string.sub(state.text, state.position, state.position) ~= ":" then
                error("expected colon")
            end
            state.position = state.position + 1
            local value = Parser.ParseValue(state, depth + 1)
            if output[key] ~= nil then error("duplicate key " .. key) end
            output[key] = value
        end
        Parser.Whitespace(state)
        local delimiter = string.sub(
            state.text, state.position, state.position)
        state.position = state.position + 1
        if delimiter == close then return output end
        if delimiter ~= "," then error("expected delimiter") end
        Parser.Whitespace(state)
    end
    error("unterminated collection")
end

function Parser.ParseValue(state, depth)
    Parser.Whitespace(state)
    local character = string.sub(
        state.text, state.position, state.position)
    if character == '"' then return Parser.ParseString(state) end
    if character == "{" then
        return Parser.ParseContainer(state, "}", false, depth)
    end
    if character == "[" then
        return Parser.ParseContainer(state, "]", true, depth)
    end
    if string.sub(state.text, state.position, state.position + 3) == "true" then
        state.position = state.position + 4
        return true
    end
    if string.sub(state.text, state.position, state.position + 4) == "false" then
        state.position = state.position + 5
        return false
    end
    if string.sub(state.text, state.position, state.position + 3) == "null" then
        state.position = state.position + 4
        return state.limits.preserveNull and state.nullMarker or nil
    end
    return Parser.ParseNumber(state)
end

function Parser.Parse(text, limits, nullMarker)
    local state = Parser.New(text, limits, nullMarker)
    local value = Parser.ParseValue(state, 0)
    Parser.Whitespace(state)
    if state.position <= state.length then error("trailing input") end
    return value
end

return Parser
