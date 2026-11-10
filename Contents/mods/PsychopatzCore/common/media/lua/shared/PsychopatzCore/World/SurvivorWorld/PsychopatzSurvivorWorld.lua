local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"
local Persistence =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPersistence"
local Registry =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRegistry"
local Import =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldImport"
local Generation =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldGeneration"
local Traversal =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTraversal"
local RuntimeStore =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRuntimeStore"
local Bootstrap =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldBootstrap"
local Presentation =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresentation"
local Discovery =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiscovery"
local Presence =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresence"

local SurvivorWorld = {
    Types = Types,
    Persistence = Persistence,
    Registry = Registry,
    Import = Import,
    Generation = Generation,
    Traversal = Traversal,
    RuntimeStore = RuntimeStore,
    Bootstrap = Bootstrap,
    Presentation = Presentation,
    Discovery = Discovery,
    Presence = Presence,
}

function SurvivorWorld.NewRegistry(spec)
    return Registry.new(spec)
end

function SurvivorWorld.ActivateRuntime(spec)
    return RuntimeStore.Activate(spec)
end

function SurvivorWorld.GetRuntimeRegistry()
    return RuntimeStore.GetRegistry()
end

function SurvivorWorld.GetRuntimeSnapshot()
    return RuntimeStore.Snapshot()
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorld = SurvivorWorld

return SurvivorWorld
