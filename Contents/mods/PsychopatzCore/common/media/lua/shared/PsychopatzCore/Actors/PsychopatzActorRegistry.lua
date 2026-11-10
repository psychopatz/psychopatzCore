local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local Persistence = require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"
local Provider = require "PsychopatzCore/Actors/PsychopatzActorProvider"
local Persona = require "PsychopatzCore/Actors/PsychopatzActorPersona"
local Knowledge = require "PsychopatzCore/Actors/PsychopatzActorKnowledge"
local Identity = require "PsychopatzCore/Actors/PsychopatzActorIdentity"

local Registry = {}
Registry.__index = Registry

local function markProjectionDirty(reason)
    local core = PsychopatzCore
    local sync = core and core.ActorProjectionSync or nil
    if sync and type(sync.MarkDirty) == "function" then
        sync.MarkDirty(reason)
    end
end

local function rebuildIdentityIndex(registry)
    if not registry.identityResolver then
        registry.identityResolver = Identity.NewResolver()
    end
    return registry.identityResolver:Rebuild(registry.records)
end

local function mergeIdentityMetadata(base, patch)
    base = type(base) == "table" and base or {}
    patch = type(patch) == "table" and patch or {}
    local output = Util.clone(base)
    local aliases = {}
    local aliasSeen = {}
    local capabilities = {}
    local capabilityCount = 0

    local function addAlias(value)
        if #aliases >= Identity.MAX_ALIASES then return end
        if type(value) == "table" then
            if #value > 0 then
                for _, child in ipairs(value) do
                    addAlias(child)
                    if #aliases >= Identity.MAX_ALIASES then return end
                end
            else
                for child, enabled in pairs(value) do
                    if enabled == true then addAlias(child) end
                    if #aliases >= Identity.MAX_ALIASES then return end
                end
            end
            return
        end
        value = Util.text(value, nil)
        if value and not aliasSeen[value] then
            aliasSeen[value] = true
            aliases[#aliases + 1] = value
        end
    end

    local function addCapability(key, enabled)
        if capabilityCount >= Identity.MAX_CAPABILITIES
            or enabled ~= true
        then
            return
        end
        key = Util.text(key, nil)
        if key and not capabilities[key] then
            capabilities[key] = true
            capabilityCount = capabilityCount + 1
        end
    end

    addAlias(base.aliases)
    addAlias(patch.aliases)
    for key, enabled in pairs(base.capabilities or {}) do
        addCapability(key, enabled)
    end
    for key, enabled in pairs(patch.capabilities or {}) do
        addCapability(key, enabled)
    end

    if #aliases > 0 then output.aliases = aliases end
    if capabilityCount > 0 then
        output.capabilities = capabilities
    end
    for _, key in ipairs({
        "canonicalActorID", "canonicalActorId", "providerID", "provider",
        "presenceState", "presenceMode", "bodyID", "bodyId", "project",
    }) do
        if patch[key] ~= nil then output[key] = Util.clone(patch[key]) end
    end
    output.schema = Identity.SCHEMA
    output.schemaVersion = Identity.SCHEMA_VERSION
    return output
end

local function resolvedSpec(spec)
    local actors = PsychopatzCore and PsychopatzCore.Actors or nil
    local archetypes = actors and actors.Archetypes or nil
    local archetypeID = type(spec) == "table"
        and (spec.coreArchetypeID or spec.archetypeID) or nil
    local plan
    local output
    local identity

    if not archetypes or type(archetypes.ResolvePlan) ~= "function"
        or not archetypeID
    then
        return spec
    end
    plan = archetypes:ResolvePlan(archetypeID, {
        actorId = spec.actorId,
        identitySeed = spec.identitySeed,
        identity = spec.identity,
    })
    if not plan then return spec end

    output = Util.clone(spec)
    output.archetypeID = plan.archetypeID
    identity = type(output.identity) == "table"
        and output.identity or Util.clone(plan.identity)
    identity.archetypeID = plan.archetypeID
    identity.identitySeed = identity.identitySeed
        or plan.identity.identitySeed
    if not identity.gender then identity.gender = plan.identity.gender end
    if type(identity.survivor) ~= "table" then
        identity.survivor = Util.clone(plan.identity.survivor or {})
    end
    output.identity = identity
    if output.appearance == nil then output.appearance = plan.appearance end
    if output.starterItems == nil then
        output.starterItems = plan.starterItems
    end
    return output
end

function Registry.new()
    local registry = setmetatable({ records = {}, revision = 0 }, Registry)
    registry.identityResolver = Identity.NewResolver()
    return registry
end

function Registry:Count()
    local count = 0
    for _ in pairs(self.records) do count = count + 1 end
    return count
end

function Registry:Has(actorId)
    return self.records[actorId] ~= nil
end

function Registry:HasReference(reference)
    if not self.identityResolver then rebuildIdentityIndex(self) end
    return self.identityResolver:Has(reference)
end

function Registry:Resolve(reference)
    if not self.identityResolver then rebuildIdentityIndex(self) end
    local resolved, reason = self.identityResolver:Resolve(reference)
    if not resolved then return nil, reason end
    local actor = self.records[resolved.recordID]
    if not actor then return nil, "actor_not_found" end
    return Util.clone(actor), resolved
end

function Registry:Remove(actorId)
    local removed = self.records[actorId]
    if not removed then return nil, "actor_not_found" end
    self.records[actorId] = nil
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records[actorId] = removed
        rebuildIdentityIndex(self)
        return nil, indexReason
    end
    self.revision = self.revision + 1
    markProjectionDirty("actor_removed")
    return true
end

function Registry:Get(actorId)
    local actor = self.records[actorId]
    if not actor then return nil, "actor_not_found" end
    return Util.clone(actor)
end

-- Attach provider-neutral identity metadata without replacing the actor or
-- changing its opaque canonical ID. Adopters use this seam to publish aliases,
-- capabilities, and presence hints after they claim an actor.
function Registry:AttachIdentity(actorId, spec)
    actorId = tostring(actorId or "")
    local current = self.records[actorId]
    if not current then return nil, "actor_not_found" end
    spec = type(spec) == "table" and spec or {}

    local extensions = Util.clone(current.extensions or {})
    extensions[Identity.EXTENSION] = mergeIdentityMetadata(
        extensions[Identity.EXTENSION], spec
    )
    return self:Commit(actorId, { extensions = extensions }, current.revision)
end

function Registry:AttachExtension(actorId, extensionID, value)
    actorId = tostring(actorId or "")
    extensionID = Util.text(extensionID, nil)
    local current = self.records[actorId]
    if not current then return nil, "actor_not_found" end
    if not extensionID then return nil, "extension_id_required" end

    local extensions = Util.clone(current.extensions or {})
    extensions[extensionID] = Util.clone(value)
    return self:Commit(actorId, { extensions = extensions }, current.revision)
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
    copy.providerLease, reason = Provider.Normalize(
        copy.providerLease, copy.actorId)
    if not copy.providerLease then return nil, reason end
    valid, reason = Provider.Validate(copy.providerLease, copy.actorId)
    if not valid then return nil, reason end
    copy.persona, reason = Persona.NewState(copy.persona)
    if not copy.persona then return nil, reason end
    copy.knowledge, reason = Knowledge.NewState(copy.knowledge)
    if not copy.knowledge then return nil, reason end
    if self.records[actor.actorId] then return nil, "duplicate_actor_id" end
    self.records[actor.actorId] = copy
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records[actor.actorId] = nil
        rebuildIdentityIndex(self)
        return nil, indexReason
    end
    self.revision = self.revision + 1
    markProjectionDirty("actor_registered")
    return Util.clone(self.records[actor.actorId])
end

function Registry:Create(spec)
    local normalizedSpec = resolvedSpec(spec)
    local actor, reason = Factory.Generate(normalizedSpec)
    if not actor then return nil, reason end
    local inventory
    inventory, reason = ActorInventory.CreateForActor(actor.actorId,
        actor.identity.identitySeed, {
            starterVersion = normalizedSpec.starterVersion,
            starterItems = normalizedSpec.starterItems,
        })
    if not inventory then return nil, reason end
    actor.personalInventory = inventory:ToPayload("SEED_ONLY")
    actor.providerLease = Util.clone(normalizedSpec.providerLease)
    return self:Register(actor)
end

-- Return the canonical actor for an adopter-owned stable ID, creating it only
-- when the ID is not already present.  Adopters use this idempotent seam when
-- importing an existing provider record; it must never replace or reset an
-- actor that another provider has already enriched.
function Registry:Ensure(spec)
    if type(spec) ~= "table" then return nil, "spec_required" end
    local actorID = Util.text(spec.actorId or spec.actorID, nil)
    if not actorID then return nil, "actor_id_required" end

    local existing = self.records[actorID]
    if existing then
        return Util.clone(existing), "existing_actor"
    end

    local createSpec = Util.clone(spec)
    createSpec.actorId = actorID
    return self:Create(createSpec)
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
    if patch.persona ~= nil then nextActor.persona = Util.clone(patch.persona) end
    if patch.knowledge ~= nil then nextActor.knowledge = Util.clone(patch.knowledge) end
    if patch.extensions ~= nil then nextActor.extensions = Util.clone(patch.extensions) end
    if patch.social ~= nil then nextActor.social = Util.clone(patch.social) end
    if patch.world ~= nil then nextActor.world = Util.clone(patch.world) end
    if patch.providerLease ~= nil then
        nextActor.providerLease = Util.clone(patch.providerLease)
    end
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
    nextActor.providerLease, reason = Provider.Normalize(
        nextActor.providerLease, actorId)
    if not nextActor.providerLease then return nil, reason end
    valid, reason = Provider.Validate(nextActor.providerLease, actorId)
    if not valid then return nil, reason end
    nextActor.persona, reason = Persona.NewState(nextActor.persona)
    if not nextActor.persona then return nil, reason end
    nextActor.knowledge, reason = Knowledge.NewState(nextActor.knowledge)
    if not nextActor.knowledge then return nil, reason end
    valid, reason = Factory.ValidateActor(nextActor)
    if not valid then return nil, reason end

    self.records[actorId] = nextActor
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records[actorId] = current
        rebuildIdentityIndex(self)
        return nil, indexReason
    end
    self.revision = self.revision + 1
    markProjectionDirty("actor_committed")
    return Util.clone(nextActor)
end

local function commitProvider(registry, actorId, operation, spec)
    local current = registry.records[actorId]
    local updated
    local reason
    if not current then return nil, "actor_not_found" end
    if operation == "Materialize" and type(spec) == "table"
        and spec.bodyID ~= nil
    then
        local bodyID = tostring(spec.bodyID)
        for otherID, other in pairs(registry.records) do
            local lease = other and other.providerLease or nil
            if tostring(otherID) ~= tostring(actorId)
                and lease and lease.state == "materialized"
                and tostring(lease.bodyID or "") == bodyID
            then
                return nil, "body_lease_claimed"
            end
        end
    end
    updated, reason = Provider[operation](Util.clone(current), spec)
    if not updated then return nil, reason end
    return registry:Commit(actorId, {
        providerLease = updated.providerLease,
    }, current.revision)
end

function Registry:AcquireProvider(actorId, spec)
    return commitProvider(self, actorId, "Acquire", spec)
end

function Registry:MaterializeProvider(actorId, spec)
    return commitProvider(self, actorId, "Materialize", spec)
end

function Registry:DematerializeProvider(actorId, spec)
    return commitProvider(self, actorId, "Dematerialize", spec)
end

function Registry:ReleaseProvider(actorId, spec)
    return commitProvider(self, actorId, "Release", spec)
end

function Registry:SwitchProvider(actorId, spec)
    return commitProvider(self, actorId, "Switch", spec)
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
    local previousRecords = self.records
    local previousResolver = self.identityResolver
    self.records = replacement
    self.identityResolver = Identity.NewResolver()
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records = previousRecords
        self.identityResolver = previousResolver
        return nil, indexReason
    end
    self.revision = revision
    markProjectionDirty("actors_loaded")
    return true
end

return Registry
