local Support = {}

function Support.copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 12 then return nil end

    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        output[key] = Support.copyValue(item, depth + 1)
    end
    return output
end

function Support.symbolText(symbol)
    return tostring(symbol and (symbol.text or symbol.value) or "")
end

function Support.phraseText(symbols, first, last)
    local values = {}
    local index
    for index = first, last do
        values[#values + 1] = Support.symbolText(symbols[index])
    end
    return table.concat(values, " ")
end

function Support.hasStopWord(symbols, first, last, stopWords)
    if type(stopWords) ~= "table" or #stopWords < 1 then return false end

    local index
    local stopIndex
    local text
    for index = first, last do
        text = " " .. Support.symbolText(symbols[index]) .. " "
        for stopIndex = 1, #stopWords do
            local stop = tostring(stopWords[stopIndex] or "")
            if stop ~= "" and string.find(
                text, " " .. stop .. " ", 1, true)
            then
                return true
            end
        end
    end
    return false
end

function Support.containsVerbForm(symbols, first, last)
    local index
    for index = first, last do
        if symbols[index] and symbols[index].verbForm then return true end
    end
    return false
end

function Support.spanMetrics(symbols, first, last)
    local unresolved = first ~= last and 1 or 0
    local ambiguous = 0
    local fuzzy = 0
    local index
    local symbol
    for index = first, last do
        symbol = symbols[index]
        if symbol.kind ~= "concept" or symbol.id == nil then
            -- A captured phrase is one unresolved semantic slot even when
            -- its display name contains several literal tokens.
            unresolved = 1
        end
        if symbol.kind == "concept" and not symbol.id then
            ambiguous = ambiguous + 1
        end
        if symbol.fuzzy == true then fuzzy = fuzzy + 1 end
    end
    return unresolved, ambiguous, fuzzy
end

return Support
