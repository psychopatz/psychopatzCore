PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Composition = Core.Composition or {}
Core.Composition = Composition

if Composition.sharedLoaded then
    return Core
end

-- 1. Essential Core identity & Runtime role
require "PsychopatzCore/Composition/PC_CoreIdentity"
require "PsychopatzCore/Runtime/PC_RuntimeRole"

-- 2. Minimal Capability Kernel initialization
local Kernel = require "PsychopatzCore/Kernel/PC_Kernel"
Kernel.InitCatalog()

-- 3. Top-level capability shortcuts on PsychopatzCore
Core.Capabilities = Kernel
Core.Kernel = Kernel

Core.Require = function(capId, consumerId, context)
    return Kernel.Require(capId, consumerId, context)
end

Core.RequirePack = function(packId, consumerId, context)
    return Kernel.RequirePack(packId, consumerId, context)
end

Core.Release = function(capId, consumerId, context)
    return Kernel.Release(capId, consumerId, context)
end

Core.GetStatus = function(capId)
    return Kernel.GetStatus(capId)
end

-- 4. Legacy full composition loader for backward compatibility / explicit requests
function Core.RequireLegacySharedFull(consumerId)
    return Kernel.RequirePack("pack.core_legacy_full", consumerId or "LegacySharedFull")
end

-- Property-to-capability map for on-demand resolution of PsychopatzCore.*
local PROPERTY_TO_CAP = {
    Actors = "core.actors",
    Inventory = "core.inventory",
    Currency = "core.currency",
    Conversation = "core.conversation",
    VoiceGateway = "core.voice",
    Journal = "core.journal",
    SpatialRelation = "core.spatial",
    World = "core.world_region",
    DeterministicContent = "core.deterministic_content",
    RadioDeviceState = "core.radio_device_state",
    RadioFrequencies = "core.radio_channels",
    CustomRadio = "core.radio_channels",
    Traits = "core.traits",
    ZombieKillDetector = "core.zombie_kill_detector",
    Debug = "core.debug",
    Profiler = "core.profiler",
    Bridge = "core.bridge",
    Teleport = "core.teleport",
    Preview = "core.preview",
    Keybinds = "core.input_keybinds",
    Audio = "core.audio_settings",
    Semantics = "core.semantics",
    Translation = "core.translation",
}

local resolving = {}
setmetatable(Core, {
    __index = function(t, key)
        if resolving[key] then
            return rawget(t, key)
        end
        local capId = PROPERTY_TO_CAP[key]
        if capId then
            resolving[key] = true
            local ok, facade = Kernel.Require(capId, "auto_access_" .. tostring(key))
            resolving[key] = nil
            if ok then
                local val = rawget(t, key) or facade
                if val then
                    rawset(t, key, val)
                    return val
                end
            end
        end
        return rawget(t, key)
    end
})

Composition.sharedLoaded = true

return Core
