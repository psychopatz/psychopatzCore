local Registry = PsychopatzCore.Conversation.Registry
local Internal = Registry.Internal

function Registry.RegisterConditionHandler(id, handler)
    id = tostring(id or "")
    if not Internal.ValidID(id) or type(handler) ~= "table"
        or type(handler.evaluate) ~= "function"
        or Registry.conditionHandlers[id]
    then return false end
    Registry.conditionHandlers[id] = Internal.Copy(handler)
    Internal.BumpRevision()
    return true
end

function Registry.UnregisterConditionHandler(id)
    id = tostring(id or "")
    if not Registry.conditionHandlers[id] then return false end
    Registry.conditionHandlers[id] = nil
    Internal.BumpRevision()
    return true
end

function Registry.RegisterCategoryEligibilityProvider(id, provider)
    id = tostring(id or "")
    if not Internal.ValidID(id) or type(provider) ~= "table"
        or type(provider.evaluate) ~= "function"
        or Registry.categoryEligibilityProviders[id]
    then
        return false
    end
    Registry.categoryEligibilityProviders[id] = Internal.Copy(provider)
    Internal.BumpRevision()
    return true
end

function Registry.UnregisterCategoryEligibilityProvider(id)
    id = tostring(id or "")
    if not Registry.categoryEligibilityProviders[id] then return false end
    Registry.categoryEligibilityProviders[id] = nil
    Internal.BumpRevision()
    return true
end

function Registry.EvaluateCategoryEligibility(category, context)
    local ids = {}
    local id
    local provider
    local ok
    local passed
    local reason
    for id, _ in pairs(Registry.categoryEligibilityProviders) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for _, id in ipairs(ids) do
        provider = Registry.categoryEligibilityProviders[id]
        ok, passed, reason = pcall(
            provider.evaluate, category, context or {})
        if not ok then
            return false, "category_eligibility_error"
        end
        if passed ~= true then
            return false, reason or "category_not_eligible"
        end
    end
    return true
end

function Registry.RegisterEffectHandler(id, handler)
    id = tostring(id or "")
    if not Internal.ValidID(id) or type(handler) ~= "table"
        or type(handler.validate) ~= "function"
        or type(handler.apply) ~= "function"
        or type(handler.simulate) ~= "function"
        or Registry.effectHandlers[id]
    then return false end
    Registry.effectHandlers[id] = Internal.Copy(handler)
    Internal.BumpRevision()
    return true
end

function Registry.UnregisterEffectHandler(id)
    id = tostring(id or "")
    if not Registry.effectHandlers[id] then return false end
    Registry.effectHandlers[id] = nil
    Internal.BumpRevision()
    return true
end
