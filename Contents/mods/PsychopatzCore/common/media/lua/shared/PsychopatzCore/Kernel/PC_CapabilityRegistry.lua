-- PsychopatzCore Capability Registry
-- Stores capability descriptors and state tracking without eager implementation loading.

local Contract = require "PsychopatzCore/Kernel/PC_CapabilityContract"

local Registry = {
    descriptors = {},
    packs = {},
    states = {},
}

local STATES = Contract.STATES

function Registry.Reset()
    Registry.descriptors = {}
    Registry.packs = {}
    Registry.states = {}
end

function Registry.Register(desc)
    local ok, err = Contract.ValidateDescriptor(desc)
    if not ok then
        return false, "Descriptor validation failed: " .. tostring(err)
    end

    if Registry.descriptors[desc.id] ~= nil then
        return false, "Capability already registered: " .. desc.id
    end

    Registry.descriptors[desc.id] = desc
    Registry.states[desc.id] = {
        id = desc.id,
        domain = desc.domain or "Core",
        state = STATES.REGISTERED,
        loadedModule = nil,
        consumers = {},
        totalConsumers = 0,
        failureReason = nil,
        ownedResources = {},
    }
    return true, nil
end

function Registry.RegisterPack(pack)
    local ok, err = Contract.ValidatePack(pack)
    if not ok then
        return false, "Pack validation failed: " .. tostring(err)
    end

    if Registry.packs[pack.id] ~= nil then
        return false, "Pack already registered: " .. pack.id
    end

    Registry.packs[pack.id] = pack
    return true, nil
end

function Registry.Get(id)
    return Registry.descriptors[id]
end

function Registry.GetPack(packId)
    return Registry.packs[packId]
end

function Registry.GetState(id)
    return Registry.states[id]
end

function Registry.GetAllStates()
    local copy = {}
    for id, s in pairs(Registry.states) do
        copy[id] = {
            id = s.id,
            domain = s.domain,
            state = s.state,
            totalConsumers = s.totalConsumers,
            failureReason = s.failureReason,
            consumers = s.consumers,
        }
    end
    return copy
end

function Registry.AddConsumer(id, consumerId)
    local s = Registry.states[id]
    if not s then return false, "unknown capability: " .. tostring(id) end

    consumerId = consumerId or "<anonymous>"
    local count = s.consumers[consumerId] or 0
    s.consumers[consumerId] = count + 1
    s.totalConsumers = s.totalConsumers + 1
    return true, s.totalConsumers
end

function Registry.RemoveConsumer(id, consumerId)
    local s = Registry.states[id]
    if not s then return false, "unknown capability: " .. tostring(id) end

    consumerId = consumerId or "<anonymous>"
    local count = s.consumers[consumerId] or 0
    if count > 0 then
        s.consumers[consumerId] = count - 1
        s.totalConsumers = math.max(0, s.totalConsumers - 1)
        if s.consumers[consumerId] == 0 then
            s.consumers[consumerId] = nil
        end
    end
    return true, s.totalConsumers
end

return Registry
