-- PsychopatzCore Services Registry & Lookup Facade
-- Provides stable, unified discovery and facade retrieval for adopters.

PsychopatzCore = PsychopatzCore or {}

local Services = {}
PsychopatzCore.Services = Services

local SERVICE_MAP = {
    inventory = "core.inventory",
    currency = "core.currency",
    actors = "core.actors",
    conversation = "core.conversation",
    translation = "core.translation",
    debug = "core.debug",
    radio_os = "core.radio_os",
    radio_device_state = "core.radio_device_state",
    custom_radio = "core.radio_channels",
    traits = "core.traits",
    zombie_kill_detector = "core.zombie_kill_detector",
    profiler = "core.profiler",
    bridge = "core.bridge",
    teleport = "core.teleport",
    keybinds = "core.input_keybinds",
    audio = "core.audio_settings",
    semantics = "core.semantics",
    spatial = "core.spatial",
    world = "core.world_region",
}

function Services.ResolveCapabilityId(serviceName)
    if type(serviceName) ~= "string" then return nil end
    local canonical = string.lower(serviceName):gsub("%s+", "_"):gsub("%-", "_")
    return SERVICE_MAP[canonical] or SERVICE_MAP[serviceName]
end

function Services.Get(serviceName, consumerId)
    local capId = Services.ResolveCapabilityId(serviceName)
    if not capId then
        return nil, "unknown service: " .. tostring(serviceName)
    end

    local Kernel = PsychopatzCore.Capabilities
    if not Kernel then
        return nil, "capabilities kernel not available"
    end

    local status = Kernel.GetStatus(capId)
    if not status or status.state ~= Kernel.STATES.ACTIVE then
        local ok, err = Kernel.Require(capId, consumerId or ("Services:" .. tostring(serviceName)))
        if not ok then
            return nil, "failed to activate service '" .. tostring(serviceName) .. "': " .. tostring(err)
        end
    end

    return Kernel.GetFacade(capId), nil
end

function Services.Has(serviceName)
    local capId = Services.ResolveCapabilityId(serviceName)
    if not capId then return false end
    local Kernel = PsychopatzCore.Capabilities
    if not Kernel then return false end
    local status = Kernel.GetStatus(capId)
    return status ~= nil and status.state == Kernel.STATES.ACTIVE
end

function Services.ListActive()
    local active = {}
    local Kernel = PsychopatzCore.Capabilities
    if not Kernel then return active end
    for name, capId in pairs(SERVICE_MAP) do
        local status = Kernel.GetStatus(capId)
        if status and status.state == Kernel.STATES.ACTIVE then
            table.insert(active, name)
        end
    end
    table.sort(active)
    return active
end

return Services
