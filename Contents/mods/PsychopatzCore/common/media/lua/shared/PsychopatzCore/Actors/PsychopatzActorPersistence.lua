local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"
local Provider = require "PsychopatzCore/Actors/PsychopatzActorProvider"
local Persona = require "PsychopatzCore/Actors/PsychopatzActorPersona"
local Knowledge = require "PsychopatzCore/Actors/PsychopatzActorKnowledge"

local Persistence = {}

Persistence.SCHEMA = "PsychopatzCore.NPC.Registry"
Persistence.SCHEMA_VERSION = 2
Persistence.LEGACY_SCHEMA_VERSION = 1
Persistence.ACTOR_SCHEMA = "PsychopatzCore.NPC.ActorCompact"
Persistence.ACTOR_SCHEMA_VERSION = 1
Persistence.MAX_ACTORS = 4096
Persistence.MAX_REGISTRY_BYTES = 16 * 1024 * 1024
Persistence.REGISTRY_JSON_LIMITS = {
    maxString = Persistence.MAX_REGISTRY_BYTES,
    maxDepth = 32,
    maxCollection = 8192,
}

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
    copy.persona, reason = Persona.NewState(copy.persona)
    if not copy.persona then return nil, reason end
    copy.knowledge, reason = Knowledge.NewState(copy.knowledge)
    if not copy.knowledge then return nil, reason end
    return copy
end

local function empty(value)
    return type(value) == "table" and next(value) == nil
end

local function same(left, right)
    local leftEncoded = Json.Encode(left)
    local rightEncoded = Json.Encode(right)
    return leftEncoded ~= nil and leftEncoded == rightEncoded
end

local function compactInventory(actor)
    local payload = actor.personalInventory
    if payload == nil then
        local ledger, reason = ActorInventory.CreateForActor(
            actor.actorId,
            actor.identity and actor.identity.identitySeed,
            {}
        )
        if not ledger then return nil, reason end
        return ledger:ToPayload("SEED_ONLY")
    end
    return ActorInventory.CompactPayload(payload)
end

local function encodeCompact(actor)
    local copy, reason = cloneValidated(actor)
    if not copy then return nil, reason end

    local inventory
    inventory, reason = compactInventory(copy)
    if not inventory then return nil, reason end

    local payload = {
        schema = Persistence.ACTOR_SCHEMA,
        schemaVersion = Persistence.ACTOR_SCHEMA_VERSION,
        actorId = copy.actorId,
        revision = copy.revision,
        identity = Util.clone(copy.identity),
        appearance = Util.clone(copy.appearance),
        personalInventory = inventory,
    }

    if copy.ownerMod ~= "PsychopatzCore" then
        payload.ownerMod = copy.ownerMod
    end
    if copy.source ~= nil then payload.source = Util.clone(copy.source) end
    if not empty(copy.extensions or {}) then
        payload.extensions = Util.clone(copy.extensions)
    end

    local defaultSocial = Social.NewState()
    if not same(copy.social, defaultSocial) then
        payload.social = Util.clone(copy.social)
    end

    local defaultWorld = World.NewState(nil, copy.actorId)
    if not same(copy.world, defaultWorld) then
        payload.world = Util.clone(copy.world)
    end

    local defaultProvider = Provider.Normalize(nil, copy.actorId)
    if not same(copy.providerLease, defaultProvider) then
        payload.providerLease = Util.clone(copy.providerLease)
    end

    local defaultPersona = Persona.NewState()
    if not same(copy.persona, defaultPersona) then
        payload.persona = Util.clone(copy.persona)
    end

    local defaultKnowledge = Knowledge.NewState()
    if not same(copy.knowledge, defaultKnowledge) then
        payload.knowledge = Util.clone(copy.knowledge)
    end

    return payload
end

local function decodeCompact(payload)
    if type(payload) ~= "table"
        or payload.schema ~= Persistence.ACTOR_SCHEMA
        or tonumber(payload.schemaVersion)
            ~= Persistence.ACTOR_SCHEMA_VERSION
    then
        return nil, "actor_compact_schema_mismatch"
    end
    if type(payload.actorId) ~= "string" or payload.actorId == "" then
        return nil, "actor_id_required"
    end
    if type(payload.identity) ~= "table"
        or type(payload.appearance) ~= "table"
    then
        return nil, "actor_compact_identity_required"
    end

    local actor = {
        schema = Factory.SCHEMA,
        schemaVersion = Factory.SCHEMA_VERSION,
        actorId = payload.actorId,
        ownerMod = payload.ownerMod or "PsychopatzCore",
        revision = math.max(1, math.floor(tonumber(payload.revision) or 1)),
        identity = Util.clone(payload.identity),
        appearance = Util.clone(payload.appearance),
        extensions = Util.clone(payload.extensions or {}),
        source = Util.clone(payload.source),
    }

    local reason
    actor.social, reason = Social.NewState(payload.social)
    if not actor.social then return nil, reason end
    actor.world, reason = World.NewState(payload.world, actor.actorId)
    if not actor.world then return nil, reason end
    actor.providerLease, reason = Provider.Normalize(
        payload.providerLease, actor.actorId)
    if not actor.providerLease then return nil, reason end
    actor.persona, reason = Persona.NewState(payload.persona)
    if not actor.persona then return nil, reason end
    actor.knowledge, reason = Knowledge.NewState(payload.knowledge)
    if not actor.knowledge then return nil, reason end

    if payload.personalInventory ~= nil then
        local valid
        valid, reason = ActorInventory.ValidatePayload(
            payload.personalInventory)
        if not valid then return nil, reason end
        actor.personalInventory = Util.clone(payload.personalInventory)
    else
        local ledger
        ledger, reason = ActorInventory.CreateForActor(
            actor.actorId,
            actor.identity.identitySeed,
            {}
        )
        if not ledger then return nil, reason end
        actor.personalInventory, reason = ledger:ToPayload("SEED_ONLY")
        if not actor.personalInventory then return nil, reason end
    end

    return cloneValidated(actor)
end

function Persistence.EncodeActor(actor)
    return encodeCompact(actor)
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
        if payload == nil then
            return nil, decodeReason or "actor_decode_failed"
        end
    end
    if type(payload) ~= "table" then
        return nil, "actor_decode_failed"
    end
    if payload.schema == Persistence.ACTOR_SCHEMA then
        return decodeCompact(payload)
    end
    if payload.schema == Factory.SCHEMA then
        return cloneValidated(payload)
    end
    return nil, "actor_schema_mismatch"
end

function Persistence.SerializeRegistry(records, revision)
    if type(records) ~= "table" then return nil, "records_required" end
    if #records > Persistence.MAX_ACTORS then
        return nil, "registry_actor_limit"
    end
    local actors = {}
    local seen = {}
    for index = 1, #records do
        local actor, reason = Persistence.EncodeActor(records[index])
        if not actor then return nil, reason end
        if seen[actor.actorId] then return nil, "duplicate_actor_id" end
        seen[actor.actorId] = true
        actors[index] = actor
    end
    local encoded = Json.Encode({
        schema = Persistence.SCHEMA,
        schemaVersion = Persistence.SCHEMA_VERSION,
        revision = math.max(0, math.floor(tonumber(revision) or 0)),
        actors = actors,
    }, Persistence.REGISTRY_JSON_LIMITS)
    if #encoded > Persistence.MAX_REGISTRY_BYTES then
        return nil, "registry_size_limit"
    end
    return encoded
end

function Persistence.DecodeRegistry(serialized)
    local payload = serialized
    if type(serialized) == "string" then
        local decodeReason
        payload, decodeReason = Json.Decode(
            serialized,
            Persistence.REGISTRY_JSON_LIMITS
        )
        if payload == nil then
            return nil, decodeReason or "registry_decode_failed"
        end
    end
    if type(payload) ~= "table"
        or payload.schema ~= Persistence.SCHEMA
        or type(payload.actors) ~= "table"
    then
        return nil, "registry_schema_mismatch"
    end

    local version = tonumber(payload.schemaVersion)
    if version ~= Persistence.SCHEMA_VERSION
        and version ~= Persistence.LEGACY_SCHEMA_VERSION
    then
        return nil, "registry_schema_mismatch"
    end

    if #payload.actors > Persistence.MAX_ACTORS then
        return nil, "registry_actor_limit"
    end

    local actors = {}
    local seen = {}
    for index = 1, #payload.actors do
        local actor
        local reason
        if version == Persistence.LEGACY_SCHEMA_VERSION then
            actor, reason = cloneValidated(payload.actors[index])
        else
            actor, reason = Persistence.DecodeActor(payload.actors[index])
        end
        if not actor then return nil, reason end
        if seen[actor.actorId] then return nil, "duplicate_actor_id" end
        seen[actor.actorId] = true
        actors[index] = actor
    end
    return actors, tonumber(payload.revision) or 0
end

return Persistence
