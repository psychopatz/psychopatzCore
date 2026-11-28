local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"
local FactionProfiles =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldFactionProfiles"
local FactionService =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldFactionService"
local Persistence =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPersistence"
local Registry =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRegistry"
local Generation =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldGeneration"
local Traversal =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTraversal"
local CorridorGraph =
    require "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local RoutePlanner =
    require "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldRoutePlanner"
local ScavengeLedger =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldScavengeLedger"
local Diplomacy =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiplomacy"
local Hazards =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldHazards"
local Events =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"
local EventMaterializer =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEventMaterializer"
local TravelConditions =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTravelConditions"
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
    FactionProfiles = FactionProfiles,
    FactionService = FactionService,
    Persistence = Persistence,
    Registry = Registry,
    Generation = Generation,
    Traversal = Traversal,
    CorridorGraph = CorridorGraph,
    RoutePlanner = RoutePlanner,
    ScavengeLedger = ScavengeLedger,
    Diplomacy = Diplomacy,
    Hazards = Hazards,
    Events = Events,
    EventMaterializer = EventMaterializer,
    TravelConditions = TravelConditions,
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
