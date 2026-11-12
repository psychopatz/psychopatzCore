local Registry = PsychopatzCore.Conversation.Registry
local Internal = Registry.Internal

function Internal.BumpRevision()
    Registry.revision = Registry.revision + 1
end

function Registry.RegisterCategory(id, definition)
    id = tostring(id or "")
    if Registry.categories[id] or Registry.invalidCategories[id] then
        return false, { "duplicate category id" }
    end
    local valid, errors = Registry.ValidateCategory(id, definition)
    if not valid then
        Registry.invalidCategories[id] = {
            id = id,
            definition = type(definition) == "table" and Internal.Copy(definition) or nil,
            errors = Internal.Copy(errors),
        }
        Internal.BumpRevision()
        return false, Internal.Copy(errors)
    end
    local normalized = Internal.Copy(definition)
    normalized.id = id
    normalized.order = tonumber(normalized.order) or 1000
    Registry.categories[id] = normalized
    Internal.BumpRevision()
    return true, Internal.Copy(normalized)
end

function Registry.UnregisterCategory(id)
    id = tostring(id or "")
    if not Registry.categories[id] and not Registry.invalidCategories[id] then
        return false
    end
    for _, block in pairs(Registry.blocks) do
        if block.category == id then return false, "category_in_use" end
    end
    Registry.categories[id] = nil
    Registry.invalidCategories[id] = nil
    Internal.BumpRevision()
    return true
end

function Registry.RegisterBlock(id, definition)
    id = tostring(id or "")
    if Registry.blocks[id] or Registry.invalidBlocks[id] then
        return false, { "duplicate block id" }
    end
    local valid, errors = Registry.ValidateBlock(id, definition)
    if not valid then
        Registry.invalidBlocks[id] = {
            id = id,
            definition = type(definition) == "table" and Internal.Copy(definition) or nil,
            errors = Internal.Copy(errors),
        }
        Internal.BumpRevision()
        return false, Internal.Copy(errors)
    end
    local normalized = Internal.Copy(definition)
    normalized.id = id
    normalized.priority = tonumber(normalized.priority) or 0
    normalized.weight = math.max(1, tonumber(normalized.weight) or 1)
    Registry.blocks[id] = normalized
    Internal.BumpRevision()
    return true, Internal.Copy(normalized)
end

function Registry.UnregisterBlock(id)
    id = tostring(id or "")
    if not Registry.blocks[id] and not Registry.invalidBlocks[id] then return false end
    Registry.blocks[id] = nil
    Registry.invalidBlocks[id] = nil
    Internal.BumpRevision()
    return true
end

function Registry.GetCategory(id)
    local value = Registry.categories[tostring(id or "")]
    return value and Internal.Copy(value) or nil
end

function Registry.GetBlock(id)
    local value = Registry.blocks[tostring(id or "")]
    return value and Internal.Copy(value) or nil
end
