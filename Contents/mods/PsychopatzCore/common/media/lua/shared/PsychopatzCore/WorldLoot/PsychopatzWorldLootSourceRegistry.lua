PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.WorldLoot = PsychopatzCore.WorldLoot or {}

local Registry = PsychopatzCore.WorldLoot.SourceRegistry or {
    byType = {}, order = {},
}
PsychopatzCore.WorldLoot.SourceRegistry = Registry

local REQUIRED = {
    "Discover", "IsValid", "ListItems", "CreateStore", "GetLocation",
}

function Registry.Register(adapter)
    local sourceType = type(adapter) == "table"
        and tostring(adapter.sourceType or "") or ""
    if sourceType == "" then return false, "source_type_required" end
    for index = 1, #REQUIRED do
        if type(adapter[REQUIRED[index]]) ~= "function" then
            return false, "adapter_method_required:" .. REQUIRED[index]
        end
    end
    if not Registry.byType[sourceType] then
        Registry.order[#Registry.order + 1] = sourceType
    end
    Registry.byType[sourceType] = adapter
    return true, adapter
end

function Registry.Get(sourceType)
    return Registry.byType[tostring(sourceType or "")]
end

function Registry.List(policy)
    local output = {}
    policy = type(policy) == "table" and policy or {}
    for index = 1, #Registry.order do
        local sourceType = Registry.order[index]
        local adapter = Registry.byType[sourceType]
        local policyKey = adapter.policyKey or sourceType
        if policy[policyKey] == true then output[#output + 1] = adapter end
    end
    return output
end

return Registry
