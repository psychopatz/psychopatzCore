local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local Persistence = require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"

local Registry = {}
Registry.__index = Registry

function Registry.new()
    return setmetatable({ records = {}, revision = 0 }, Registry)
end

function Registry:Count()
    local count = 0
    for _ in pairs(self.records) do count = count + 1 end
    return count
end

function Registry:Has(actorId)
    return self.records[actorId] ~= nil
end

function Registry:Remove(actorId)
    if not self.records[actorId] then return nil, "actor_not_found" end
    self.records[actorId] = nil
    self.revision = self.revision + 1
    return true
end

function Registry:Get(actorId)
    local actor = self.records[actorId]
    if not actor then return nil, "actor_not_found" end
    return Util.clone(actor)
end

function Registry:List()
    local ids = {}
    for actorId in pairs(self.records) do ids[#ids + 1] = actorId end
    table.sort(ids)
    local result = {}
    for index = 1, #ids do result[index] = Util.clone(self.records[ids[index]]) end
    return result
end

function Registry:Register(actor)
    local valid, reason = Factory.ValidateActor(actor)
    if not valid then return nil, reason end
    if actor.personalInventory then
        valid, reason = ActorInventory.ValidatePayload(actor.personalInventory)
        if not valid then return nil, reason end
    end
    local copy = Util.clone(actor)
    copy.social, reason = Social.NewState(copy.social)
    if not copy.social then return nil, reason end
    valid, reason = Social.Validate(copy.social)
    if not valid then return nil, reason end
    copy.world, reason = World.NewState(copy.world, copy.actorId)
    if not copy.world then return nil, reason end
    valid, reason = World.Validate(copy.world)
    if not valid then return nil, reason end
    if self.records[actor.actorId] then return nil, "duplicate_actor_id" end
    self.records[actor.actorId] = copy
    self.revision = self.revision + 1
    return Util.clone(self.records[actor.actorId])
end

function Registry:Create(spec)
    local actor, reason = Factory.Generate(spec)
    if not actor then return nil, reason end
    local inventory
    inventory, reason = ActorInventory.CreateForActor(actor.actorId,
        actor.identity.identitySeed, {
            starterVersion = spec.starterVersion,
            starterItems = spec.starterItems,
        })
    if not inventory then return nil, reason end
    actor.personalInventory = inventory:ToPayload("FULL")
    return self:Register(actor)
end

function Registry:Commit(actorId, patch, expectedRevision)
    local current = self.records[actorId]
    if not current then return nil, "actor_not_found" end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= current.revision then
        return nil, "revision_conflict"
    end
    if type(patch) ~= "table" then return nil, "patch_required" end

    local nextActor = Util.clone(current)
    if patch.identity ~= nil then nextActor.identity = Util.clone(patch.identity) end
    if patch.appearance ~= nil then nextActor.appearance = Util.clone(patch.appearance) end
    if patch.extensions ~= nil then nextActor.extensions = Util.clone(patch.extensions) end
    if patch.social ~= nil then nextActor.social = Util.clone(patch.social) end
    if patch.world ~= nil then nextActor.world = Util.clone(patch.world) end
    if patch.personalInventory ~= nil then
        local inventoryValid, inventoryReason =
            ActorInventory.ValidatePayload(patch.personalInventory)
        if not inventoryValid then return nil, inventoryReason end
        nextActor.personalInventory = Util.clone(patch.personalInventory)
    end
    nextActor.revision = current.revision + 1
    local valid, reason = Social.NewState(nextActor.social)
    nextActor.social = valid
    if not nextActor.social then return nil, reason end
    valid, reason = Social.Validate(nextActor.social)
    if not valid then return nil, reason end
    nextActor.world, reason = World.NewState(nextActor.world, actorId)
    if not nextActor.world then return nil, reason end
    valid, reason = World.Validate(nextActor.world)
    if not valid then return nil, reason end
    valid, reason = Factory.ValidateActor(nextActor)
    if not valid then return nil, reason end

    self.records[actorId] = nextActor
    self.revision = self.revision + 1
    return Util.clone(nextActor)
end

function Registry:Save()
    return Persistence.SerializeRegistry(self:List(), self.revision)
end

function Registry:Load(serialized)
    local actors, revision = Persistence.DecodeRegistry(serialized)
    if not actors then return nil, revision end
    local replacement = {}
    for index = 1, #actors do
        local actor = actors[index]
        if replacement[actor.actorId] then return nil, "duplicate_actor_id" end
        replacement[actor.actorId] = actor
    end
    self.records = replacement
    self.revision = revision
    return true
end

return Registry
