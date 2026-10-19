PsychopatzCore = PsychopatzCore or {}

local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local Registry = require "PsychopatzCore/Actors/PsychopatzActorRegistry"
local Persistence = require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Migration = require "PsychopatzCore/Actors/PsychopatzActorMigration"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local Location = require "PsychopatzCore/Actors/PsychopatzActorLocation"
local Journey = require "PsychopatzCore/Actors/PsychopatzActorJourney"
local Task = require "PsychopatzCore/Actors/PsychopatzActorTask"
local Scheduler = require "PsychopatzCore/Actors/PsychopatzActorScheduler"
local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"

local Actors = PsychopatzCore.Actors or {}
Actors.Factory = Factory
Actors.Registry = Registry
Actors.Persistence = Persistence
Actors.Inventory = ActorInventory
Actors.Migration = Migration
Actors.Social = Social
Actors.Location = Location
Actors.Journey = Journey
Actors.Task = Task
Actors.Scheduler = Scheduler
Actors.World = World
Actors.DefaultRegistry = Actors.DefaultRegistry or Registry.new()

function Actors.NewRegistry()
    return Registry.new()
end

function Actors.Create(spec)
    return Actors.DefaultRegistry:Create(spec)
end

function Actors.Get(actorId)
    return Actors.DefaultRegistry:Get(actorId)
end

function Actors.Save()
    return Actors.DefaultRegistry:Save()
end

function Actors.Load(serialized)
    return Actors.DefaultRegistry:Load(serialized)
end

PsychopatzCore.Actors = Actors
PsychopatzCore.ActorFactory = Factory
PsychopatzCore.ActorPersistence = Persistence

return Actors
