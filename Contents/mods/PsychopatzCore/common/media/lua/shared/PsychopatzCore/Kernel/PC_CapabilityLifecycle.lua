-- PsychopatzCore Capability Lifecycle Coordinator
-- Coordinates lazy loading, activation, consumer tracking, and safe deactivation.

local Contract = require "PsychopatzCore/Kernel/PC_CapabilityContract"
local STATES = Contract.STATES

local Lifecycle = {}

function Lifecycle.Load(registry, capId)
    local state = registry.GetState(capId)
    if not state then
        return nil, "unknown capability: " .. tostring(capId)
    end

    if state.state == STATES.LOADED or state.state == STATES.ACTIVE or state.state == STATES.DORMANT then
        return state.loadedModule, nil
    end

    local desc = registry.Get(capId)
    if not desc then
        return nil, "descriptor missing for: " .. tostring(capId)
    end

    if desc.load then
        local ok, res = pcall(desc.load)
        if not ok then
            state.state = STATES.FAILED
            state.failureReason = "Load failed: " .. tostring(res)
            return nil, state.failureReason
        end
        state.loadedModule = res or true
    else
        state.loadedModule = true
    end

    state.state = STATES.LOADED
    return state.loadedModule, nil
end

function Lifecycle.Activate(registry, resolver, requestedIds, consumerId, context)
    local closure, resolveErr = resolver.ResolveClosure(registry, requestedIds)
    if not closure then
        return false, resolveErr
    end

    context = context or {}

    for _, capId in ipairs(closure) do
        local state = registry.GetState(capId)
        local desc = registry.Get(capId)

        -- 1. Ensure loaded
        if state.state == STATES.REGISTERED or state.state == STATES.FAILED then
            local mod, loadErr = Lifecycle.Load(registry, capId)
            if not mod then
                return false, "Activation aborted for '" .. capId .. "': " .. tostring(loadErr)
            end
        end

        -- 2. Activate if not yet active
        if state.state ~= STATES.ACTIVE then
            if desc.activate then
                local ok, actErr = pcall(desc.activate, context)
                if not ok then
                    state.state = STATES.FAILED
                    state.failureReason = "Activation callback failed: " .. tostring(actErr)
                    return false, state.failureReason
                end
            end
            state.state = STATES.ACTIVE
        end

        -- 3. Register consumer reference
        registry.AddConsumer(capId, consumerId)
    end

    return true, closure
end

function Lifecycle.Deactivate(registry, capId, consumerId, context)
    local state = registry.GetState(capId)
    if not state then
        return false, "unknown capability: " .. tostring(capId)
    end

    local ok, remaining = registry.RemoveConsumer(capId, consumerId)
    if remaining == 0 and state.state == STATES.ACTIVE then
        local desc = registry.Get(capId)
        if desc and desc.deactivate then
            pcall(desc.deactivate, context or {})
        end
        state.state = STATES.DORMANT
    end

    return true, remaining
end

return Lifecycle
