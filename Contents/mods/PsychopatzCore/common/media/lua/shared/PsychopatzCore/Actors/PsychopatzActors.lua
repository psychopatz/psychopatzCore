PsychopatzCore = PsychopatzCore or {}

local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local Registry = require "PsychopatzCore/Actors/PsychopatzActorRegistry"
local Persistence = require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Migration = require "PsychopatzCore/Actors/PsychopatzActorMigration"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local SocialQuery = require "PsychopatzCore/Actors/PsychopatzSocialQuery"
local SocialAuthority = require "PsychopatzCore/Actors/PsychopatzActorSocialAuthority"
local SocialPolicy = require "PsychopatzCore/Actors/PsychopatzSocialPolicy"
local Archetype = require "PsychopatzCore/Actors/PsychopatzActorArchetype"
local ArchetypeRegistry = require "PsychopatzCore/Actors/PsychopatzActorArchetypeRegistry"
local Location = require "PsychopatzCore/Actors/PsychopatzActorLocation"
local Journey = require "PsychopatzCore/Actors/PsychopatzActorJourney"
local Task = require "PsychopatzCore/Actors/PsychopatzActorTask"
local Scheduler = require "PsychopatzCore/Actors/PsychopatzActorScheduler"
local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"
local Presentation = require "PsychopatzCore/Actors/PsychopatzActorPresentation"
local Map = require "PsychopatzCore/Actors/PsychopatzActorMap"
local Interaction = require "PsychopatzCore/Actors/PsychopatzActorInteraction"
local Notifications = require "PsychopatzCore/Actors/PsychopatzActorNotifications"
local Provider = require "PsychopatzCore/Actors/PsychopatzActorProvider"
local Projection = require "PsychopatzCore/Actors/PsychopatzActorProjection"
local Identity = require "PsychopatzCore/Actors/PsychopatzActorIdentity"
local Names = require "PsychopatzCore/Actors/PsychopatzActorNames"
local RuntimeStore = require "PsychopatzCore/Actors/PsychopatzActorRuntimeStore"
local Persona = require "PsychopatzCore/Actors/PsychopatzActorPersona"
local Knowledge = require "PsychopatzCore/Actors/PsychopatzActorKnowledge"
local PlayerIdentity = require "PsychopatzCore/Actors/PsychopatzPlayerIdentity"
local Lifecycle = require "PsychopatzCore/Actors/PsychopatzActorLifecycle"
local GC = require "PsychopatzCore/Actors/PsychopatzActorGC"

local Actors = PsychopatzCore.Actors or {}
Actors.Factory = Factory
Actors.Registry = Registry
Actors.Persistence = Persistence
Actors.Inventory = ActorInventory
Actors.Migration = Migration
Actors.Social = Social
Actors.SocialQuery = SocialQuery
Actors.SocialAuthority = SocialAuthority
Actors.SocialPolicy = SocialPolicy
Actors.Archetype = Archetype
Actors.Archetypes = Actors.Archetypes or ArchetypeRegistry.new()
Actors.PlayerIdentity = PlayerIdentity
Actors.Names = Names
Actors.Location = Location
Actors.Journey = Journey
Actors.Task = Task
Actors.Scheduler = Scheduler
Actors.World = World
Actors.Presentation = Presentation
Actors.Map = Map
Actors.Interaction = Interaction
Actors.Notifications = Notifications
Actors.Provider = Provider
Actors.Projection = Projection
Actors.Identity = Identity
Actors.RuntimeStore = RuntimeStore
Actors.Persona = Persona
Actors.Knowledge = Knowledge
Actors.Lifecycle = Lifecycle
Actors.GC = GC
GC.RegisterBuiltinProviders()
Actors.DefaultRegistry = Actors.DefaultRegistry or Registry.new()
RuntimeStore.Attach(Actors.DefaultRegistry)

function Actors.NewRegistry()
    return Registry.new()
end

function Actors.Create(spec)
    return Actors.DefaultRegistry:Create(spec)
end

function Actors.Ensure(spec)
    return Actors.DefaultRegistry:Ensure(spec)
end

function Actors.Get(actorId)
    return Actors.DefaultRegistry:Get(actorId)
end

function Actors.Resolve(reference)
    return Actors.DefaultRegistry:Resolve(reference)
end

function Actors.Retire(reference, spec)
    return Actors.DefaultRegistry:Retire(reference, spec)
end

function Actors.HardDelete(actorId, spec)
    return Actors.DefaultRegistry:HardDelete(actorId, spec)
end

function Actors.ProjectIdentity(reference)
    return Actors.DefaultRegistry:ProjectIdentity(reference)
end

function Actors.GetTombstone(reference)
    return Actors.DefaultRegistry:GetTombstone(reference)
end

function Actors.GetLifecycleState(reference)
    return Actors.DefaultRegistry:GetLifecycleState(reference)
end

function Actors.RegisterReferenceProvider(providerID, provider)
    return GC.RegisterReferenceProvider(providerID, provider)
end

function Actors.UnregisterReferenceProvider(providerID)
    return GC.UnregisterReferenceProvider(providerID)
end

function Actors.ExplainRetention(reference, options)
    return GC.ExplainRetention(Actors.DefaultRegistry, reference, options)
end

function Actors.ExplainPurge(reference, options)
    return GC.ExplainPurge(Actors.DefaultRegistry, reference, options)
end

function Actors.AttachIdentity(actorID, spec)
    return Actors.DefaultRegistry:AttachIdentity(actorID, spec)
end

function Actors.AttachExtension(actorID, extensionID, value)
    return Actors.DefaultRegistry:AttachExtension(actorID, extensionID, value)
end

function Actors.QueryNearPosition(x, y, radius, options)
    return Actors.DefaultRegistry:QueryNearPosition(x, y, radius, options)
end

function Actors.HasActiveActor(actorID)
    return Actors.DefaultRegistry:HasActiveActor(actorID)
end

function Actors.GetExtension(actorID, extensionID)
    return Actors.DefaultRegistry:GetExtension(actorID, extensionID)
end

function Actors.ListWithExtension(extensionID)
    return Actors.DefaultRegistry:ListWithExtension(extensionID)
end

function Actors.ListMaterialized()
    return Actors.DefaultRegistry:ListMaterialized()
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
