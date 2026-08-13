-- Declarative integration boundary for profiler-aware mod features.
-- Consumers should require this module only behind their profiler bootstrap gate.
PsychopatzCore = PsychopatzCore or {}

local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local Registry = PsychopatzCore.ProfilerFeatures or { definitions = {}, active = {} }
PsychopatzCore.ProfilerFeatures = Registry

local function includesEnabledSection(definition, config)
    local sections = definition.sections or { "performance" }
    for index = 1, #sections do
        if config.enabled[tostring(sections[index])] == true then return true end
    end
    return false
end

local function deactivate(id)
    local current = Registry.active[id]
    if not current then return true end
    Registry.active[id] = nil
    local Profiler = PsychopatzCore and PsychopatzCore.Profiler
    if Profiler and Profiler.UnregisterSampler then
        for index = 1, #current.samplers do
            Profiler.UnregisterSampler(current.samplers[index])
        end
        for index = 1, #current.providers do
            Profiler.UnregisterSnapshotProvider(current.providers[index])
        end
    end
    if type(current.cleanup) == "function" then pcall(current.cleanup) end
    if type(current.definition.uninstall) == "function" then
        pcall(current.definition.uninstall)
    end
    return true
end

local function activate(definition, config)
    local Profiler = PsychopatzCore and PsychopatzCore.Profiler
    if not Profiler or not Profiler.IsRunning or not Profiler.IsRunning() then return false end
    local id = definition.id
    local current = { definition = definition, samplers = {}, providers = {}, cleanup = nil }
    Registry.active[id] = current
    if definition.namespace then
        Profiler.RegisterNamespace(definition.namespace, {
            displayName = definition.displayName or definition.namespace,
        })
    end
    if type(definition.install) == "function" then
        local ok, cleanup = pcall(definition.install, Profiler, config)
        if not ok or cleanup == false then
            deactivate(id)
            return false
        end
        if type(cleanup) == "function" then current.cleanup = cleanup end
    end
    for index = 1, #(definition.samplers or {}) do
        local sampler = definition.samplers[index]
        local samplerID = id .. ".sampler." .. tostring(sampler.id or index)
        if Profiler.RegisterSampler(samplerID, sampler.callback, {
            section = sampler.section or "performance",
        }) then
            current.samplers[#current.samplers + 1] = samplerID
        end
    end
    for index = 1, #(definition.snapshotProviders or {}) do
        local provider = definition.snapshotProviders[index]
        local providerID = tostring(provider.id or (id .. ".snapshot." .. tostring(index)))
        if Profiler.RegisterSnapshotProvider(providerID, provider.callback, {
            section = provider.section or "performance", intervalMs = provider.intervalMs,
        }) then
            current.providers[#current.providers + 1] = providerID
        end
    end
    Profiler.RegisterStopHook("ProfilerFeature." .. id, function() deactivate(id) end)
    return true
end

local function apply(id, config)
    local definition = Registry.definitions[id]
    deactivate(id)
    if not definition or config.mode == Bootstrap.MODE_OFF then return true end
    if not includesEnabledSection(definition, config) then return true end
    return activate(definition, config)
end

function Registry.Register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string"
        or definition.id == "" or Registry.definitions[definition.id]
    then
        return false
    end
    if definition.install ~= nil and type(definition.install) ~= "function" then return false end
    Registry.definitions[definition.id] = definition
    local registered = Bootstrap.RegisterCaptureController(
        definition.id,
        function(config) return apply(definition.id, config) end
    )
    if not registered then Registry.definitions[definition.id] = nil end
    return registered
end

function Registry.Unregister(id)
    id = tostring(id or "")
    deactivate(id)
    Registry.definitions[id] = nil
    Bootstrap.UnregisterCaptureController(id)
    return true
end

function Registry.IsActive(id)
    return Registry.active[tostring(id or "")] ~= nil
end

return Registry
