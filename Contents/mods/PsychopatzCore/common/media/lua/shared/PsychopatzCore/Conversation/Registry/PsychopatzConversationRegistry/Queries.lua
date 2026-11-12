local Registry = PsychopatzCore.Conversation.Registry
local Internal = Registry.Internal

local function matchesFilter(value, filters)
    filters = type(filters) == "table" and filters or {}
    if filters.ownerModID and value.ownerModID ~= filters.ownerModID then return false end
    if filters.category and value.category ~= filters.category then return false end
    if filters.audience then
        local found = false
        for _, audience in ipairs(value.audiences or {}) do
            if audience == filters.audience then found = true break end
        end
        if not found then return false end
    end
    return true
end

function Registry.ListCategories(options)
    options = type(options) == "table" and options or {}
    local output = {}
    for _, category in pairs(Registry.categories) do
        if matchesFilter(category, options) then output[#output + 1] = Internal.Copy(category) end
    end
    if options.includeInvalid == true then
        for _, entry in pairs(Registry.invalidCategories) do
            output[#output + 1] = Internal.Copy(entry)
        end
    end
    table.sort(output, function(first, second)
        local firstOrder = tonumber(first.order) or 1000
        local secondOrder = tonumber(second.order) or 1000
        if firstOrder ~= secondOrder then return firstOrder < secondOrder end
        return tostring(first.id) < tostring(second.id)
    end)
    return output
end

function Registry.ListBlocks(options)
    options = type(options) == "table" and options or {}
    local output = {}
    for _, block in pairs(Registry.blocks) do
        if matchesFilter(block, options) then output[#output + 1] = Internal.Copy(block) end
    end
    if options.includeInvalid == true then
        for _, entry in pairs(Registry.invalidBlocks) do
            output[#output + 1] = Internal.Copy(entry)
        end
    end
    table.sort(output, function(first, second)
        local firstPriority = tonumber(first.priority) or 0
        local secondPriority = tonumber(second.priority) or 0
        if firstPriority ~= secondPriority then return firstPriority > secondPriority end
        return tostring(first.id) < tostring(second.id)
    end)
    return output
end
