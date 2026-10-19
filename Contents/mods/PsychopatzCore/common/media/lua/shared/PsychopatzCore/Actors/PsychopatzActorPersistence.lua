local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"
local Provider = require "PsychopatzCore/Actors/PsychopatzActorProvider"

local Persistence = {}

Persistence.SCHEMA = "PsychopatzCore.NPC.Registry"
Persistence.SCHEMA_VERSION = 1

local function cloneValidated(actor)
    local valid, reason = Factory.ValidateActor(actor)
    if not valid then return nil, reason end
    if actor.personalInventory then
        valid, reason = ActorInventory.ValidatePayload(actor.personalInventory)
        if not valid then return nil, reason end
    end
    local copy = Util.clone(actor)
    if not copy.social then copy.social = Social.NewState() end
    local socialValid
    socialValid, reason = Social.Validate(copy.social)
    if not socialValid then return nil, reason end
    copy.world, reason = World.NewState(copy.world, copy.actorId)
    if not copy.world then return nil, reason end
    local worldValid
    worldValid, reason = World.Validate(copy.world)
    if not worldValid then return nil, reason end
    copy.providerLease, reason = Provider.Normalize(
        copy.providerLease, copy.actorId)
    if not copy.providerLease then return nil, reason end
    local providerValid
    providerValid, reason = Provider.Validate(
        copy.providerLease, copy.actorId)
    if not providerValid then return nil, reason end
    return copy
end

function Persistence.EncodeActor(actor)
    return cloneValidated(actor)
end

function Persistence.SerializeActor(actor)
    local payload, reason = Persistence.EncodeActor(actor)
    if not payload then return nil, reason end
    return Json.Encode(payload)
end

function Persistence.DecodeActor(serialized)
    local payload = serialized
    if type(serialized) == "string" then
        local decodeReason
        payload, decodeReason = Json.Decode(serialized)
        if payload == nil then return nil, decodeReason or "actor_decode_failed" end
    end
    return cloneValidated(payload)
end

function Persistence.SerializeRegistry(records, revision)
    if type(records) ~= "table" then return nil, "records_required" end
    local actors = {}
    local seen = {}
    for index = 1, #records do
        local actor, reason = Persistence.EncodeActor(records[index])
        if not actor then return nil, reason end
        if seen[actor.actorId] then return nil, "duplicate_actor_id" end
        seen[actor.actorId] = true
        actors[index] = actor
    end
    return Json.Encode({
        schema = Persistence.SCHEMA,
        schemaVersion = Persistence.SCHEMA_VERSION,
        revision = math.max(0, math.floor(tonumber(revision) or 0)),
        actors = actors,
    })
end

function Persistence.DecodeRegistry(serialized)
    local payload = serialized
    if type(serialized) == "string" then
        local decodeReason
        payload, decodeReason = Json.Decode(serialized)
        if payload == nil then return nil, decodeReason or "registry_decode_failed" end
    end
    if type(payload) ~= "table"
        or payload.schema ~= Persistence.SCHEMA
        or tonumber(payload.schemaVersion) ~= Persistence.SCHEMA_VERSION
        or type(payload.actors) ~= "table"
    then
        return nil, "registry_schema_mismatch"
    end

    local actors = {}
    local seen = {}
    for index = 1, #payload.actors do
        local actor, reason = Persistence.DecodeActor(payload.actors[index])
        if not actor then return nil, reason end
        if seen[actor.actorId] then return nil, "duplicate_actor_id" end
        seen[actor.actorId] = true
        actors[index] = actor
    end
    return actors, tonumber(payload.revision) or 0
end

return Persistence
