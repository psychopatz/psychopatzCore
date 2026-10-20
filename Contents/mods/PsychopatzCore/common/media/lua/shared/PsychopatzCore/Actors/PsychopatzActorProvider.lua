local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Provider = {}

Provider.SCHEMA = "PsychopatzCore.NPC.ProviderLease"
Provider.SCHEMA_VERSION = 1
Provider.DEFAULT_PROVIDER = "PsychopatzCore"
Provider.PROVIDERS = {
    PsychopatzCore = true,
    DTAbstract = true,
    DTHoomans = true,
}
Provider.STATES = {
    abstract = true,
    materialized = true,
    released = true,
}

local function text(value, fallback)
    return Util.text(value, fallback)
end

local function number(value, fallback)
    return Util.number(value, fallback)
end

local function integer(value, fallback)
    return Util.integer(value, fallback)
end

local function providerName(value)
    value = text(value, Provider.DEFAULT_PROVIDER)
    return Provider.PROVIDERS[value] and value or nil
end

local function stateName(value, fallback)
    value = text(value, fallback or "released")
    return Provider.STATES[value] and value or nil
end

local function actorIDOf(actor)
    return type(actor) == "table" and text(actor.actorId, nil) or nil
end

local function leaseIDFor(actorID)
    return "lease:" .. tostring(actorID)
end

local function active(lease)
    return lease and lease.state ~= "released"
end

local function authorityAllowed(spec)
    return type(spec) ~= "table" or spec.authority == nil
        or spec.authority == "server"
end

function Provider.New(actorID, spec)
    spec = type(spec) == "table" and spec or {}
    actorID = text(actorID or spec.actorID or spec.actorId, nil)
    if not actorID then return nil, "actor_id_required" end

    local provider = providerName(spec.provider)
    if not provider then return nil, "provider_invalid" end
    local owner = text(spec.owner, nil)
    local state = stateName(spec.state,
        owner and "abstract" or "released")
    if not state then return nil, "provider_state_invalid" end
    local bodyID = text(spec.bodyID or spec.bodyId, nil)
    if state == "materialized" and not bodyID then
        return nil, "body_id_required"
    end
    if state ~= "materialized" then bodyID = nil end

    local metadata = spec.metadata
    if metadata ~= nil and not Util.isSerializable(metadata) then
        return nil, "provider_metadata_invalid"
    end

    return {
        schema = Provider.SCHEMA,
        schemaVersion = Provider.SCHEMA_VERSION,
        actorID = actorID,
        leaseID = text(spec.leaseID or spec.leaseId, leaseIDFor(actorID)),
        provider = provider,
        previousProvider = text(spec.previousProvider, nil),
        owner = owner,
        state = state,
        bodyID = bodyID,
        revision = math.max(1, integer(spec.revision, 1)),
        acquiredAt = math.max(0, number(spec.acquiredAt, 0)),
        materializedAt = math.max(0, number(spec.materializedAt, 0)),
        dematerializedAt = math.max(0, number(spec.dematerializedAt, 0)),
        releasedAt = math.max(0, number(spec.releasedAt, 0)),
        lastBodyID = text(spec.lastBodyID or spec.lastBodyId, nil),
        metadata = Util.clone(metadata or {}),
    }
end

function Provider.Normalize(value, actorID)
    if type(value) ~= "table" then
        return Provider.New(actorID, { state = "released" })
    end
    return Provider.New(actorID or value.actorID, value)
end

function Provider.Validate(value, actorID)
    local normalized, reason = Provider.Normalize(value, actorID)
    if not normalized then return false, reason end
    if actorID and normalized.actorID ~= tostring(actorID) then
        return false, "provider_actor_mismatch"
    end
    if normalized.state == "materialized" and not normalized.bodyID then
        return false, "body_id_required"
    end
    if normalized.owner == nil and normalized.state ~= "released" then
        return false, "provider_owner_required"
    end
    if not Util.isSerializable(normalized) then
        return false, "provider_not_serializable"
    end
    return true
end

local function copyActor(actor)
    if type(actor) ~= "table" or not actorIDOf(actor) then
        return nil, "actor_required"
    end
    return Util.clone(actor)
end

local function applyLease(actor, lease)
    actor.providerLease = lease
    actor.revision = math.max(1, integer(actor.revision, 1)) + 1
    return actor
end

local function currentLease(actor)
    return Provider.Normalize(actor.providerLease, actor.actorId)
end

local function ownerMatches(lease, owner)
    owner = text(owner, nil)
    return owner and lease.owner == owner
end

function Provider.Acquire(actor, spec)
    spec = type(spec) == "table" and spec or {}
    if not authorityAllowed(spec) then return nil, "server_authority_required" end
    local nextActor, reason = copyActor(actor)
    if not nextActor then return nil, reason end
    local current = currentLease(nextActor)
    local provider = providerName(spec.provider)
    local owner = text(spec.owner, nil)
    if not provider then return nil, "provider_invalid" end
    if not owner then return nil, "provider_owner_required" end
    if active(current) then
        if current.owner == owner and current.provider == provider then
            return nextActor
        end
        return nil, current.state == "materialized"
            and "body_lease_active" or "provider_lease_owned"
    end

    local lease = Provider.New(nextActor.actorId, {
        leaseID = current.leaseID,
        provider = provider,
        previousProvider = current.provider,
        owner = owner,
        state = "abstract",
        revision = current.revision + 1,
        acquiredAt = number(spec.now, 0),
        metadata = spec.metadata,
    })
    if not lease then return nil, "provider_lease_invalid" end
    return applyLease(nextActor, lease)
end

function Provider.Materialize(actor, spec)
    spec = type(spec) == "table" and spec or {}
    if not authorityAllowed(spec) then return nil, "server_authority_required" end
    local nextActor, reason = copyActor(actor)
    if not nextActor then return nil, reason end
    local current = currentLease(nextActor)
    local bodyID = text(spec.bodyID or spec.bodyId, nil)
    if not active(current) then return nil, "provider_lease_not_active" end
    if not ownerMatches(current, spec.owner) then
        return nil, "provider_owner_mismatch"
    end
    if spec.provider and current.provider ~= providerName(spec.provider) then
        return nil, "provider_mismatch"
    end
    if current.state == "materialized" then
        if current.bodyID == bodyID then return nextActor end
        return nil, "body_lease_active"
    end
    if not bodyID then return nil, "body_id_required" end
    current.state = "materialized"
    current.bodyID = bodyID
    current.lastBodyID = bodyID
    current.materializedAt = math.max(0, number(spec.now, 0))
    current.revision = current.revision + 1
    return applyLease(nextActor, current)
end

function Provider.Dematerialize(actor, spec)
    spec = type(spec) == "table" and spec or {}
    if not authorityAllowed(spec) then return nil, "server_authority_required" end
    local nextActor, reason = copyActor(actor)
    if not nextActor then return nil, reason end
    local current = currentLease(nextActor)
    if not active(current) then return nil, "provider_lease_not_active" end
    if not ownerMatches(current, spec.owner) then
        return nil, "provider_owner_mismatch"
    end
    if spec.provider and current.provider ~= providerName(spec.provider) then
        return nil, "provider_mismatch"
    end
    if current.state ~= "materialized" then
        return nextActor, "already_abstract"
    end
    if spec.bodyID and current.bodyID ~= tostring(spec.bodyID) then
        return nil, "body_id_mismatch"
    end
    current.state = "abstract"
    current.lastBodyID = current.bodyID
    current.bodyID = nil
    current.dematerializedAt = math.max(0, number(spec.now, 0))
    current.revision = current.revision + 1
    return applyLease(nextActor, current)
end

function Provider.Release(actor, spec)
    spec = type(spec) == "table" and spec or {}
    if not authorityAllowed(spec) then return nil, "server_authority_required" end
    local nextActor, reason = copyActor(actor)
    if not nextActor then return nil, reason end
    local current = currentLease(nextActor)
    if not active(current) then return nextActor end
    if not ownerMatches(current, spec.owner) then
        return nil, "provider_owner_mismatch"
    end
    if current.state == "materialized" and spec.force ~= true then
        return nil, "body_lease_active"
    end
    current.state = "released"
    current.lastBodyID = current.bodyID or current.lastBodyID
    current.bodyID = nil
    current.owner = nil
    current.releasedAt = math.max(0, number(spec.now, 0))
    current.revision = current.revision + 1
    return applyLease(nextActor, current)
end

function Provider.Switch(actor, spec)
    spec = type(spec) == "table" and spec or {}
    if not authorityAllowed(spec) then return nil, "server_authority_required" end
    local nextActor, reason = copyActor(actor)
    if not nextActor then return nil, reason end
    local current = currentLease(nextActor)
    if current.state == "materialized" then return nil, "body_lease_active" end
    if active(current) and not ownerMatches(current, spec.owner) then
        return nil, "provider_owner_mismatch"
    end
    if not active(current) then return Provider.Acquire(nextActor, spec) end
    local provider = providerName(spec.provider)
    local owner = text(spec.owner, current.owner)
    if not provider then return nil, "provider_invalid" end
    if not owner then return nil, "provider_owner_required" end
    current.previousProvider = current.provider
    current.provider = provider
    current.owner = owner
    current.state = "abstract"
    current.revision = current.revision + 1
    current.metadata = Util.clone(spec.metadata or current.metadata or {})
    return applyLease(nextActor, current)
end

function Provider.Project(actor, requestedProvider)
    if type(actor) ~= "table" or not actor.actorId then
        return nil, "actor_required"
    end
    local lease, reason = currentLease(actor)
    if not lease then return nil, reason end
    if requestedProvider and lease.provider ~= tostring(requestedProvider) then
        return nil, "provider_mismatch"
    end
    return {
        schema = "PsychopatzCore.NPC.ActorProjection",
        schemaVersion = 1,
        actorId = tostring(actor.actorId),
        identity = Util.clone(actor.identity),
        appearance = Util.clone(actor.appearance),
        persona = Util.clone(actor.persona),
        knowledge = Util.clone(actor.knowledge),
        personalInventory = Util.clone(actor.personalInventory),
        social = Util.clone(actor.social),
        world = Util.clone(actor.world),
        providerLease = lease,
        extensions = Util.clone(actor.extensions or {}),
    }
end

return Provider
