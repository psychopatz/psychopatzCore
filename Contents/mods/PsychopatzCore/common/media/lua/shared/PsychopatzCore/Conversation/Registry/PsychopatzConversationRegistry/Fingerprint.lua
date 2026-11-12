local Registry = PsychopatzCore.Conversation.Registry
local Internal = Registry.Internal

local function hashText(value, seed)
    local total = tonumber(seed) or 5381
    value = tostring(value or "")
    for index = 1, #value do
        total = (total * 33 + string.byte(value, index)) % 2147483647
    end
    return total
end

function Registry.GetFingerprint()
    local ids = {}
    local function appendValue(parts, value)
        local kind = type(value)
        if kind ~= "table" then
            parts[#parts + 1] = kind .. ":" .. tostring(value)
            return
        end
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
            return type(a) .. ":" .. tostring(a) < type(b) .. ":" .. tostring(b)
        end)
        parts[#parts + 1] = "{"
        for _, key in ipairs(keys) do
            appendValue(parts, key)
            appendValue(parts, value[key])
        end
        parts[#parts + 1] = "}"
    end
    for id, category in pairs(Registry.categories) do
        local parts = { "c:", id }
        appendValue(parts, category)
        ids[#ids + 1] = table.concat(parts, "|")
    end
    for id, block in pairs(Registry.blocks) do
        local parts = { "b:", id }
        appendValue(parts, block)
        ids[#ids + 1] = table.concat(parts, "|")
    end
    for id in pairs(Registry.conditionHandlers) do ids[#ids + 1] = "g:" .. id end
    for id in pairs(Registry.categoryEligibilityProviders) do
        ids[#ids + 1] = "cp:" .. id
    end
    for id in pairs(Registry.effectHandlers) do ids[#ids + 1] = "e:" .. id end
    table.sort(ids)
    local value = Registry.API_VERSION
    for _, id in ipairs(ids) do value = hashText(id, value) end
    return tostring(value)
end

function Registry.CollectTextKeys(block)
    local keys = {}
    local seen = {}
    local function add(value)
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            keys[#keys + 1] = value
        end
    end
    for _, node in pairs(block and block.nodes or {}) do
        add(node.textKey)
        for _, textKey in ipairs(node.textKeys or {}) do add(textKey) end
        for _, choice in ipairs(node.choices or {}) do
            add(choice.textKey)
            add(choice.lockedReasonKey)
            for _, outcome in ipairs(choice.outcomes or {}) do
                add(outcome.responseKey)
            end
        end
    end
    table.sort(keys)
    return keys
end

return Registry
