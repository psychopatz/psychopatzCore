-- PsychopatzCore Capability Diagnostics
-- Inspects capability lifecycle state, consumer attribution, and dependency reasons.

PsychopatzCore = PsychopatzCore or {}

local Diagnostics = {}
PsychopatzCore.Kernel = PsychopatzCore.Kernel or {}
PsychopatzCore.Kernel.Diagnostics = Diagnostics

local function getRegistry()
    return PsychopatzCore.Capabilities and PsychopatzCore.Capabilities.Registry
end

function Diagnostics.Report()
    local registry = getRegistry()
    if not registry then return {} end

    local states = registry.GetAllStates()
    local report = {}

    for id, s in pairs(states) do
        local desc = registry.Get(id)
        local consumerList = {}
        for c, count in pairs(s.consumers or {}) do
            table.insert(consumerList, c .. " (x" .. tostring(count) .. ")")
        end
        table.sort(consumerList)

        report[id] = {
            id = id,
            domain = s.domain,
            state = s.state,
            roles = desc and desc.roles or { shared = true },
            depends = desc and desc.depends or {},
            totalConsumers = s.totalConsumers,
            consumers = s.consumers,
            consumerList = consumerList,
            failureReason = s.failureReason,
        }
    end
    return report
end

function Diagnostics.Explain(capId)
    local registry = getRegistry()
    if not registry then
        return "Kernel registry is not available."
    end

    local desc = registry.Get(capId)
    local state = registry.GetState(capId)

    if not desc or not state then
        return "Capability '" .. tostring(capId) .. "' is NOT REGISTERED."
    end

    local parts = {}
    table.insert(parts, "Capability '" .. capId .. "' (" .. (desc.domain or "Core") .. ") is " .. state.state)

    if state.state == "ACTIVE" then
        local consumers = {}
        for c, count in pairs(state.consumers or {}) do
            table.insert(consumers, c .. " [x" .. tostring(count) .. "]")
        end
        table.sort(consumers)
        table.insert(parts, "Requested by: " .. (#consumers > 0 and table.concat(consumers, ", ") or "unknown"))
    elseif state.state == "REGISTERED" then
        table.insert(parts, "Implementation unrequested and not loaded (0 consumers)")
    elseif state.state == "DORMANT" then
        table.insert(parts, "Implementation loaded but active resources detached (0 consumers)")
    elseif state.state == "FAILED" then
        table.insert(parts, "Failure reason: " .. tostring(state.failureReason))
    end

    if desc.depends and #desc.depends > 0 then
        table.insert(parts, "Dependencies: " .. table.concat(desc.depends, ", "))
    end

    return table.concat(parts, ". ") .. "."
end

function Diagnostics.AssertActive(capId, expectedConsumer)
    local registry = getRegistry()
    assert(registry ~= nil, "Registry unavailable")
    local state = registry.GetState(capId)
    assert(state ~= nil, "Capability '" .. tostring(capId) .. "' is not registered")
    assert(state.state == "ACTIVE", "Expected capability '" .. capId .. "' to be ACTIVE, got: " .. tostring(state.state))

    if expectedConsumer then
        local count = state.consumers and state.consumers[expectedConsumer] or 0
        assert(count > 0, "Expected consumer '" .. expectedConsumer .. "' to hold reference to '" .. capId .. "'")
    end
    return true
end

function Diagnostics.AssertRegistered(capId)
    local registry = getRegistry()
    assert(registry ~= nil, "Registry unavailable")
    local state = registry.GetState(capId)
    assert(state ~= nil, "Capability '" .. tostring(capId) .. "' is not registered")
    assert(state.state == "REGISTERED", "Expected capability '" .. capId .. "' to be REGISTERED, got: " .. tostring(state.state))
    assert(state.totalConsumers == 0, "Expected 0 consumers for REGISTERED capability '" .. capId .. "'")
    return true
end

function Diagnostics.AssertFailed(capId)
    local registry = getRegistry()
    assert(registry ~= nil, "Registry unavailable")
    local state = registry.GetState(capId)
    assert(state ~= nil, "Capability '" .. tostring(capId) .. "' is not registered")
    assert(state.state == "FAILED", "Expected capability '" .. capId .. "' to be FAILED, got: " .. tostring(state.state))
    return true
end

return Diagnostics
