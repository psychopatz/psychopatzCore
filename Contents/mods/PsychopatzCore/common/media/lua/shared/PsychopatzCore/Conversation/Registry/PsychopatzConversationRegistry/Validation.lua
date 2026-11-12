local Registry = PsychopatzCore.Conversation.Registry
local Internal = Registry.Internal

function Registry.ValidateCategory(id, definition)
    local errors = {}
    local ok
    local reason
    ok, reason = Internal.Serializable(definition, {}, "category")
    if not Internal.ValidID(id) then
        Internal.AddError(errors, "category id must be namespaced")
    end
    if not ok then Internal.AddError(errors, reason) end
    if type(definition) ~= "table" then
        Internal.AddError(errors, "category definition is required")
        return false, errors
    end
    if type(definition.ownerModID) ~= "string"
        or definition.ownerModID == ""
    then
        Internal.AddError(errors, "ownerModID is required")
    end
    Internal.ValidateTextSource(definition.textSource, errors)
    if type(definition.labelKey) ~= "string"
        or definition.labelKey == ""
    then
        Internal.AddError(errors, "labelKey is required")
    end
    Internal.ValidateGates(definition.gates, errors, "gates")
    Internal.ValidateRepeat(definition["repeat"], errors, "repeat")
    return #errors == 0, errors
end

function Registry.ValidateBlock(id, definition)
    local errors = {}
    local ok
    local reason
    if definition == nil and type(id) == "table" then
        definition = id
        id = definition.id
    end
    ok, reason = Internal.Serializable(definition, {}, "block")
    if not Internal.ValidID(id) then
        Internal.AddError(errors, "block id must be namespaced")
    end
    if not ok then Internal.AddError(errors, reason) end
    if type(definition) ~= "table" then
        Internal.AddError(errors, "block definition is required")
        return false, errors
    end
    if tonumber(definition.schemaVersion) ~= Registry.SCHEMA_VERSION then
        Internal.AddError(errors, "unsupported schemaVersion")
    end
    if type(definition.ownerModID) ~= "string"
        or definition.ownerModID == ""
    then
        Internal.AddError(errors, "ownerModID is required")
    end
    if not Internal.ValidID(definition.category)
        or not Registry.categories[definition.category]
    then
        Internal.AddError(errors, "registered category is required")
    end
    Internal.ValidateTextSource(definition.textSource, errors)
    Internal.ValidateGates(definition.gates, errors, "gates")
    Internal.ValidateRepeat(definition["repeat"], errors, "repeat")
    Internal.ValidateAudiences(definition.audiences, errors)
    if type(definition.entryNode) ~= "string"
        or definition.entryNode == ""
    then
        Internal.AddError(errors, "entryNode is required")
    end
    Internal.ValidateNodes(definition, errors)
    return #errors == 0, errors
end
