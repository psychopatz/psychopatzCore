local Support = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher_Support"
local Captures = {}

function Captures.captureValue(symbol)
    local unresolved = symbol.kind ~= "concept" or symbol.id == nil
    local output = {
        kind = symbol.kind,
        id = symbol.id,
        concept = symbol.id,
        category = symbol.id,
        value = symbol.value or symbol.text,
        text = symbol.text,
        unresolved = unresolved,
    }
    if type(symbol.candidates) == "table" then
        output.candidates = Support.copyValue(symbol.candidates)
    end

    local lowered = string.lower(tostring(output.value or ""))
    if lowered == "this" or lowered == "that"
        or lowered == "it" or lowered == "him" or lowered == "her"
        or lowered == "them"
    then
        output.reference = string.upper(lowered)
    end
    return output
end

function Captures.capturePhraseValue(symbols, first, last)
    -- Preserve the richer concept capture when a phrase is exactly one known
    -- concept. This keeps existing emit contracts stable while allowing an
    -- unresolved multi-word world/item name to travel as one value.
    if first == last and symbols[first].kind == "concept"
        and symbols[first].id ~= nil
    then
        local output = Captures.captureValue(symbols[first])
        output.startToken = symbols[first].startToken
        output.endToken = symbols[first].endToken
        output.tokens = { Support.symbolText(symbols[first]) }
        return output
    end

    local output = {
        kind = "phrase",
        value = Support.phraseText(symbols, first, last),
        text = Support.phraseText(symbols, first, last),
        unresolved = true,
        startToken = symbols[first] and symbols[first].startToken or nil,
        endToken = symbols[last] and symbols[last].endToken or nil,
        tokens = {},
    }
    local index
    for index = first, last do
        output.tokens[#output.tokens + 1] = Support.symbolText(symbols[index])
    end
    local lowered = string.lower(output.text)
    if lowered == "this" or lowered == "that"
        or lowered == "it" or lowered == "him" or lowered == "her"
        or lowered == "them"
    then
        output.reference = string.upper(lowered)
    end
    return output
end

function Captures.clone(captures)
    local output = {}
    local key
    local value
    for key, value in pairs(captures) do output[key] = Support.copyValue(value) end
    return output
end

local function resolveReference(value, captures)
    if type(value) ~= "string"
        or string.sub(value, 1, 9) ~= "$capture."
    then
        return value
    end

    local current = captures
    local path = string.sub(value, 10)
    local part
    for part in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return Support.copyValue(current)
end

function Captures.resolveEmit(value, captures)
    if type(value) == "string" then return resolveReference(value, captures) end
    if type(value) ~= "table" then return value end

    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        output[key] = Captures.resolveEmit(item, captures)
    end
    return output
end

return Captures
