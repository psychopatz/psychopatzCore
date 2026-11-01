-- PsychopatzCore Minimal Kernel
-- Demand-driven capability coordinator, facade provider, and lifecycle entry point.

PsychopatzCore = PsychopatzCore or {}

local Contract = require "PsychopatzCore/Kernel/PC_CapabilityContract"
local Registry = require "PsychopatzCore/Kernel/PC_CapabilityRegistry"
local Resolver = require "PsychopatzCore/Kernel/PC_CapabilityResolver"
local Lifecycle = require "PsychopatzCore/Kernel/PC_CapabilityLifecycle"
local Diagnostics = require "PsychopatzCore/Kernel/PC_CapabilityDiagnostics"

local Kernel = {
    Contract = Contract,
    Registry = Registry,
    Resolver = Resolver,
    Lifecycle = Lifecycle,
    Diagnostics = Diagnostics,
    STATES = Contract.STATES,
    catalogInitialized = false,
}

PsychopatzCore.Kernel = Kernel
PsychopatzCore.Capabilities = Kernel

function Kernel.InitCatalog()
    if Kernel.catalogInitialized then
        return true
    end

    local Catalog = require "PsychopatzCore/Kernel/PC_CapabilityCatalog"
    for id, desc in pairs(Catalog.descriptors) do
        Registry.Register(desc)
    end
    for packId, pack in pairs(Catalog.packs) do
        Registry.RegisterPack(pack)
    end

    Kernel.catalogInitialized = true
    return true
end

function Kernel.Require(capId, consumerId, context)
    Kernel.InitCatalog()
    local ok, res = Lifecycle.Activate(Registry, Resolver, capId, consumerId, context)
    if not ok then
        return false, res
    end
    return true, Kernel.GetFacade(capId)
end

function Kernel.RequirePack(packId, consumerId, context)
    Kernel.InitCatalog()
    local pack = Registry.GetPack(packId)
    if not pack then
        return false, "unknown capability pack: " .. tostring(packId)
    end
    return Lifecycle.ActivatePack(Registry, Resolver, packId, consumerId, context)
end

function Kernel.Release(capId, consumerId, context)
    return Lifecycle.Deactivate(Registry, capId, consumerId, context)
end

function Kernel.GetStatus(capId)
    return Registry.GetState(capId)
end

function Kernel.GetAllStatus()
    return Registry.GetAllStates()
end

function Kernel.GetFacade(capId)
    local desc = Registry.Get(capId)
    if not desc then return nil end
    if desc.facade then
        return desc.facade()
    end
    local state = Registry.GetState(capId)
    return state and state.loadedModule
end

function Kernel.Register(desc)
    return Registry.Register(desc)
end

function Kernel.RegisterPack(pack)
    return Registry.RegisterPack(pack)
end

function Kernel.Report()
    Kernel.InitCatalog()
    return Diagnostics.Report()
end

function Kernel.Explain(capId)
    Kernel.InitCatalog()
    return Diagnostics.Explain(capId)
end

return Kernel
