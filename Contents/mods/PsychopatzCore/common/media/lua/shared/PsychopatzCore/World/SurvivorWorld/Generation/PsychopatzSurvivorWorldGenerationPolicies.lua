local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Generation = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationCore"
local I = Generation.Internal

local Policies = {
    Entries = {},
}

local function count()
    local total = 0
    for _ in pairs(Policies.Entries) do total = total + 1 end
    return total
end

function Policies.Register(id, policy)
    id = tostring(id or "")
    if id == "" or #id > 96 or type(policy) ~= "table" then
        return false, "invalid_generation_policy"
    end
    if type(policy.BuildExtension) ~= "function" then
        return false, "generation_policy_builder_required"
    end
    if not Policies.Entries[id]
        and count() >= Generation.MAX_POLICIES
    then
        return false, "generation_policy_capacity"
    end
    Policies.Entries[id] = {
        BuildExtension = policy.BuildExtension,
    }
    return true
end

function Policies.Unregister(id)
    id = tostring(id or "")
    if not Policies.Entries[id] then return false end
    Policies.Entries[id] = nil
    return true
end

function Policies.List()
    local ids = {}
    for id in pairs(Policies.Entries) do ids[#ids + 1] = id end
    table.sort(ids)
    return ids
end

function Policies.BuildExtensions(plan, context)
    local output = {}
    for _, id in ipairs(Policies.List()) do
        local entry = Policies.Entries[id]
        local ok, value = pcall(
            entry.BuildExtension,
            I.Copy(plan),
            I.Copy(context or {})
        )
        if ok and value ~= nil and Util.isSerializable(value) then
            output[id] = I.Copy(value)
        end
    end
    return output
end

Generation.Policies = Policies

return Policies
