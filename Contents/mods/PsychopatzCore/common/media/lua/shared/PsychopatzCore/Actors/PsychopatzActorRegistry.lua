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
local Lifecycle = require "PsychopatzCore/Actors/PsychopatzActorLifecycle"

local Registry = {}
Registry.__index = Registry

local DEFAULT_SPATIAL_CELL_SIZE = 32

local function markProjectionDirty(reason)
    local core = PsychopatzCore
    local sync = core and core.ActorProjectionSync or nil
    if sync and type(sync.MarkDirty) == "function" then
        sync.MarkDirty(reason)
    end
end

local function extractActorPosition(actor)
    if type(actor) ~= "table" then return nil end
    local world = type(actor.world) == "table" and actor.world or nil
    if not world then return nil end
    local location = type(world.location) == "table" and world.location or nil
    local pos = (location and type(location.position) == "table" and location.position)
        or (type(world.position) == "table" and world.position)
        or nil
    if type(pos) ~= "table" then return nil end
    local x = tonumber(pos.x)
    local y = tonumber(pos.y)
    if not x or not y or x ~= x or y ~= y
        or x == math.huge or y == math.huge
        or x == -math.huge or y == -math.huge
    then
        return nil
    end
    local z = tonumber(pos.z)
    if not z or z ~= z or z == math.huge or z == -math.huge then
        z = 0
    end
    return x, y, z
end

local function ensureSpatialIndex(registry)
    local index = registry._spatialIndex
    if not index then
        index = {
            cellSize = DEFAULT_SPATIAL_CELL_SIZE,
            builtRevision = -1,
            cells = {},
            membership = {},
        }
        registry._spatialIndex = index
    end
    return index
end

local function spatialCellCoords(cellSize, x, y)
    return math.floor(x / cellSize), math.floor(y / cellSize)
end

local function spatialRemove(registry, actorId)
    local index = registry._spatialIndex
    if not index then return end
    actorId = tostring(actorId or "")
    local existing = index.membership[actorId]
    if not existing then return end
    local column = index.cells[existing.cx]
    local bucket = column and column[existing.cy] or nil
    if bucket then
        bucket[actorId] = nil
        local hasAny = false
        for _ in pairs(bucket) do
            hasAny = true
            break
        end
        if not hasAny then
            column[existing.cy] = nil
            column._count = math.max(0, (tonumber(column._count) or 1) - 1)
            if column._count <= 0 then
                index.cells[existing.cx] = nil
            end
        end
    end
    index.membership[actorId] = nil
end

local function spatialUpsert(registry, actor)
    local index = ensureSpatialIndex(registry)
    if type(actor) ~= "table" or actor.actorId == nil then return end
    local actorId = tostring(actor.actorId)
    local x, y, z = extractActorPosition(actor)
    if x == nil then
        spatialRemove(registry, actorId)
        return
    end
    local cx, cy = spatialCellCoords(index.cellSize, x, y)
    local prev = index.membership[actorId]
    if prev and prev.cx == cx and prev.cy == cy then
        prev.x = x
        prev.y = y
        prev.z = z
        return
    end
    if prev then
        spatialRemove(registry, actorId)
    end
    local column = index.cells[cx]
    if not column then
        column = { _count = 0 }
        index.cells[cx] = column
    end
    local bucket = column[cy]
    if not bucket then
        bucket = {}
        column[cy] = bucket
        column._count = (tonumber(column._count) or 0) + 1
    end
    bucket[actorId] = true
    index.membership[actorId] = {
        cx = cx,
        cy = cy,
        x = x,
        y = y,
        z = z,
    }
end

local function spatialReset(registry)
    local index = ensureSpatialIndex(registry)
    index.builtRevision = -1
    index.cells = {}
    index.membership = {}
end

local function spatialEnsureBuilt(registry)
    local index = ensureSpatialIndex(registry)
    if index.builtRevision == registry.revision then
        return index
    end
    index.cells = {}
    index.membership = {}
    for _, actor in pairs(registry.records) do
        spatialUpsert(registry, actor)
    end
    index.builtRevision = registry.revision
    return index
end

local function valuesEqual(left, right)
    if left == right then return true end
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return false end
    for k, v in pairs(left) do
        if not valuesEqual(v, right[k]) then return false end
    end
    for k, _ in pairs(right) do
        if left[k] == nil then return false end
    end
    return true
end

local function identityMetadataChanged(current, nextActor, patch)
    if patch.identity ~= nil or patch.source ~= nil then
        return true
    end
    if patch.extensions ~= nil then
        local oldExt = type(current.extensions) == "table"
            and current.extensions[Identity.EXTENSION] or nil
        local newExt = type(nextActor.extensions) == "table"
            and nextActor.extensions[Identity.EXTENSION] or nil
        if not valuesEqual(oldExt, newExt) then
            return true
        end
    end
    return false
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
    local registry = setmetatable({
        records = {},
        tombstones = {},
        tombstoneAliases = {},
        tombstoneAmbiguousAliases = {},
        revision = 0,
        lifecycleRevision = 0,
        gcMeta = { generation = 0, lastSweepAt = 0 },
        _spatialIndex = {
            cellSize = DEFAULT_SPATIAL_CELL_SIZE,
            builtRevision = -1,
            cells = {},
            membership = {},
        },
    }, Registry)
    registry.identityResolver = Identity.NewResolver()
    return registry
end

function Registry:Count()
    local count = 0
    for _ in pairs(self.records) do count = count + 1 end
    return count
end

function Registry:TombstoneCount()
    local count = 0
    for _ in pairs(self.tombstones or {}) do count = count + 1 end
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

-- Legacy direct removal kept for rollback/superseded paths when spec is omitted;
-- new callers should prefer :Retire() for death/departure and :HardDelete()
-- for proven rollback/uncommitted/superseded cleanup.
function Registry:Remove(actorId, spec)
    if spec ~= nil then
        local allowed, authErr = Lifecycle.RequireServerAuthority(spec)
        if not allowed then return nil, authErr end
    end
    local removed = self.records[actorId]
    if not removed then return nil, "actor_not_found" end
    local prevRevision = self.revision
    self.records[actorId] = nil
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records[actorId] = removed
        rebuildIdentityIndex(self)
        return nil, indexReason
    end
    self.revision = self.revision + 1
    if self._spatialIndex and self._spatialIndex.builtRevision == prevRevision then
        spatialRemove(self, actorId)
        self._spatialIndex.builtRevision = self.revision
    end
    markProjectionDirty("actor_removed")
    return true
end

function Registry:HardDelete(actorId, spec)
    local allowed, authErr = Lifecycle.RequireServerAuthority(spec)
    if not allowed then return nil, authErr end
    if type(spec) ~= "table"
        or not Lifecycle.VALID_HARD_DELETE_REASONS[spec.reason]
    then
        return nil, "hard_delete_reason_required"
    end
    local removed = self.records[actorId]
    if not removed then
        if self.tombstones and self.tombstones[actorId] then
            return nil, "actor_retired"
        end
        return nil, "actor_not_found"
    end
    local prevRevision = self.revision
    self.records[actorId] = nil
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records[actorId] = removed
        rebuildIdentityIndex(self)
        return nil, indexReason
    end
    self.revision = self.revision + 1
    if self._spatialIndex and self._spatialIndex.builtRevision == prevRevision then
        spatialRemove(self, actorId)
        self._spatialIndex.builtRevision = self.revision
    end
    markProjectionDirty("actor_hard_deleted")
    return true
end

function Registry:Retire(ref, spec)
    local prevRevision = self.revision
    local resolvedBefore = Lifecycle.ResolveRef(self, ref)
    local retiredID = resolvedBefore
        and resolvedBefore.status == Lifecycle.STATUS_LIVE
        and resolvedBefore.recordID or nil
    local result, reason = Lifecycle.Retire(self, ref, spec)
    if not result then return nil, reason end
    if self._spatialIndex and self._spatialIndex.builtRevision == prevRevision then
        if retiredID and self.records[retiredID] == nil then
            spatialRemove(self, retiredID)
            self._spatialIndex.builtRevision = self.revision
        else
            spatialReset(self)
        end
    end
    return result, reason
end

function Registry:GetTombstone(ref)
    local resolved, err = Lifecycle.ResolveRef(self, ref)
    if not resolved then return nil, err end
    if resolved.status == Lifecycle.STATUS_RETIRED and resolved.tombstone then
        return Util.clone(resolved.tombstone)
    end
    return nil, "tombstone_not_found"
end

function Registry:ListTombstones()
    local ids = {}
    for ref in pairs(self.tombstones or {}) do ids[#ids + 1] = ref end
    table.sort(ids)
    local result = {}
    for index = 1, #ids do
        result[index] = Util.clone(self.tombstones[ids[index]])
    end
    return result
end

function Registry:GetLifecycleState(ref)
    return Lifecycle.GetLifecycleState(self, ref)
end

function Registry:ProjectIdentity(ref)
    return Lifecycle.ProjectIdentity(self, ref)
end

function Registry:Get(actorId)
    local actor = self.records[actorId]
    if not actor then return nil, "actor_not_found" end
    return Util.clone(actor)
end

-- Return a read-only internal view without cloning the entire actor graph.
-- Callers must treat the returned table as immutable.
function Registry:Peek(actorId)
    local actor = self.records[actorId]
    if not actor then return nil, "actor_not_found" end
    return actor
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

function Registry:HasActiveActor(actorId)
    if actorId == nil then return false end
    return self.records[tostring(actorId)] ~= nil
end

function Registry:GetExtension(actorId, extensionID)
    if actorId == nil then return nil, "actor_id_required" end
    extensionID = Util.text(extensionID, nil)
    if not extensionID then return nil, "extension_id_required" end
    local actor = self.records[tostring(actorId)]
    if not actor then return nil, "actor_not_found" end
    local ext = type(actor.extensions) == "table"
        and actor.extensions[extensionID] or nil
    if ext == nil then return nil end
    return Util.clone(ext)
end

function Registry:ListWithExtension(extensionID)
    extensionID = Util.text(extensionID, nil)
    if not extensionID then return {} end
    local ids = {}
    for actorId, actor in pairs(self.records) do
        if type(actor.extensions) == "table"
            and actor.extensions[extensionID] ~= nil
        then
            ids[#ids + 1] = actorId
        end
    end
    table.sort(ids)
    local result = {}
    for index = 1, #ids do
        result[index] = Util.clone(self.records[ids[index]])
    end
    return result
end

function Registry:ListMaterialized()
    local ids = {}
    for actorId, actor in pairs(self.records) do
        if type(actor.providerLease) == "table"
            and actor.providerLease.state == "materialized"
        then
            ids[#ids + 1] = actorId
        end
    end
    table.sort(ids)
    local result = {}
    for index = 1, #ids do
        result[index] = Util.clone(self.records[ids[index]])
    end
    return result
end

function Registry:QueryNearPosition(x, y, radius, options)
    x = tonumber(x)
    y = tonumber(y)
    if x == nil or y == nil or x ~= x or y ~= y then return {} end
    radius = math.max(0, tonumber(radius) or 0)
    options = type(options) == "table" and options or {}
    local limit = tonumber(options.limit)
    if limit ~= nil then
        limit = math.max(0, math.floor(limit))
        if limit == 0 then return {} end
    end
    local filterFn = type(options.filter) == "function"
        and options.filter or nil

    local index = spatialEnsureBuilt(self)
    local cellSize = index.cellSize
    local minCX = math.floor((x - radius) / cellSize)
    local maxCX = math.floor((x + radius) / cellSize)
    local minCY = math.floor((y - radius) / cellSize)
    local maxCY = math.floor((y + radius) / cellSize)
    local radiusSq = radius * radius

    local output = {}
    for cx = minCX, maxCX do
        local column = index.cells[cx]
        if column then
            for cy = minCY, maxCY do
                local bucket = column[cy]
                if bucket then
                    for actorId, _ in pairs(bucket) do
                        local actor = self.records[actorId]
                        local mem = index.membership[actorId]
                        if actor and mem then
                            local dx = mem.x - x
                            local dy = mem.y - y
                            local distSq = dx * dx + dy * dy
                            if distSq <= radiusSq
                                and (not filterFn or filterFn(actor) == true)
                            then
                                output[#output + 1] = {
                                    actorId = actorId,
                                    x = mem.x,
                                    y = mem.y,
                                    z = mem.z,
                                    distSq = distSq,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(output, function(left, right)
        if left.distSq == right.distSq then
            return left.actorId < right.actorId
        end
        return left.distSq < right.distSq
    end)

    if limit ~= nil and #output > limit then
        local trimmed = {}
        for i = 1, limit do
            trimmed[i] = output[i]
        end
        return trimmed
    end
    return output
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
    if (self.tombstones and self.tombstones[actor.actorId])
        or (self.tombstoneAliases and self.tombstoneAliases[actor.actorId])
    then
        return nil, "actor_retired"
    end
    local desc = Identity.DescribeActor(copy)
    if desc and self.tombstones and self.tombstones[desc.canonicalActorID] then
        return nil, "actor_retired"
    end
    copy.lifecycleRevision = math.max(1,
        math.floor(tonumber(copy.lifecycleRevision) or 1))
    local prevRevision = self.revision
    self.records[actor.actorId] = copy
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records[actor.actorId] = nil
        rebuildIdentityIndex(self)
        return nil, indexReason
    end
    self.revision = self.revision + 1
    if self._spatialIndex and self._spatialIndex.builtRevision == prevRevision then
        spatialUpsert(self, copy)
        self._spatialIndex.builtRevision = self.revision
    end
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

    if (self.tombstones and self.tombstones[actorID])
        or (self.tombstoneAliases and self.tombstoneAliases[actorID])
    then
        return nil, "actor_retired"
    end
    local existing = self.records[actorID]
    if existing then
        return Util.clone(existing), "existing_actor"
    end

    local createSpec = Util.clone(spec)
    createSpec.actorId = actorID
    return self:Create(createSpec)
end

function Registry:Commit(actorId, patch, expectedRevision, options)
    local current = self.records[actorId]
    if not current then return nil, "actor_not_found" end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= current.revision then
        return nil, "revision_conflict"
    end
    if type(patch) ~= "table" then return nil, "patch_required" end

    -- Top-level shallow copy so untouched large domains (e.g. 100 KB social)
    -- are not deep-cloned or re-normalized on unrelated updates.
    local nextActor = {}
    for key, value in pairs(current) do
        nextActor[key] = value
    end
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
    nextActor.lifecycleRevision = math.max(1,
        math.floor(tonumber(current.lifecycleRevision) or 1))
    local valid, reason
    if patch.social ~= nil or nextActor.social == nil then
        nextActor.social, reason = Social.NewState(nextActor.social)
        if not nextActor.social then return nil, reason end
        valid, reason = Social.Validate(nextActor.social)
        if not valid then return nil, reason end
    end
    if patch.world ~= nil or nextActor.world == nil then
        nextActor.world, reason = World.NewState(nextActor.world, actorId)
        if not nextActor.world then return nil, reason end
        valid, reason = World.Validate(nextActor.world)
        if not valid then return nil, reason end
    end
    if patch.providerLease ~= nil or nextActor.providerLease == nil then
        nextActor.providerLease, reason = Provider.Normalize(
            nextActor.providerLease, actorId)
        if not nextActor.providerLease then return nil, reason end
        valid, reason = Provider.Validate(nextActor.providerLease, actorId)
        if not valid then return nil, reason end
    end
    if patch.persona ~= nil or nextActor.persona == nil then
        nextActor.persona, reason = Persona.NewState(nextActor.persona)
        if not nextActor.persona then return nil, reason end
    end
    if patch.knowledge ~= nil or nextActor.knowledge == nil then
        nextActor.knowledge, reason = Knowledge.NewState(nextActor.knowledge)
        if not nextActor.knowledge then return nil, reason end
    end
    if type(Factory.ValidateActorPatch) == "function" then
        valid, reason = Factory.ValidateActorPatch(nextActor, patch)
    else
        valid, reason = Factory.ValidateActor(nextActor)
    end
    if not valid then return nil, reason end

    local prevRevision = self.revision
    self.records[actorId] = nextActor
    local needIdentityRebuild = identityMetadataChanged(current, nextActor, patch)
        or not self.identityResolver
        or type(self.identityResolver.records) ~= "table"
    if needIdentityRebuild then
        local indexed, indexReason = rebuildIdentityIndex(self)
        if not indexed then
            self.records[actorId] = current
            rebuildIdentityIndex(self)
            return nil, indexReason
        end
    else
        self.identityResolver.records[actorId] = nextActor
    end
    self.revision = self.revision + 1
    if self._spatialIndex and self._spatialIndex.builtRevision == prevRevision then
        spatialUpsert(self, nextActor)
        self._spatialIndex.builtRevision = self.revision
    end
    markProjectionDirty("actor_committed")
    if type(options) == "table" and options.returnClone == false then
        return { actorId = actorId, revision = nextActor.revision }
    end
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
    return Persistence.SerializeRegistry(self:List(), self.revision, {
        lifecycleRevision = self.lifecycleRevision,
        tombstones = self.tombstones,
        gcMeta = self.gcMeta,
    })
end

function Registry:Load(serialized)
    local actors, revision, lifecycleState = Persistence.DecodeRegistry(serialized)
    if not actors then return nil, revision end
    local replacement = {}
    for index = 1, #actors do
        local actor = actors[index]
        if replacement[actor.actorId] then return nil, "duplicate_actor_id" end
        actor.lifecycleRevision = math.max(1,
            math.floor(tonumber(actor.lifecycleRevision) or 1))
        replacement[actor.actorId] = actor
    end

    local nextTombstones = Util.clone(
        (type(lifecycleState) == "table" and lifecycleState.tombstones) or {}
    )
    for _, actor in pairs(replacement) do
        local desc = Identity.DescribeActor(actor)
        local canonicalID = desc and desc.canonicalActorID or actor.actorId
        if nextTombstones[actor.actorId] or nextTombstones[canonicalID] then
            return nil, "live_retired_actor_conflict"
        end
    end
    local nextAliases, nextAmbiguous =
        Lifecycle.RebuildTombstoneIndex(nextTombstones)

    local previousRecords = self.records
    local previousResolver = self.identityResolver
    local previousTombstones = self.tombstones
    local previousAliases = self.tombstoneAliases
    local previousAmbiguous = self.tombstoneAmbiguousAliases
    local previousLifecycleRev = self.lifecycleRevision
    local previousGCMeta = self.gcMeta

    self.records = replacement
    self.tombstones = nextTombstones
    self.tombstoneAliases = nextAliases
    self.tombstoneAmbiguousAliases = nextAmbiguous
    self.identityResolver = Identity.NewResolver()
    local indexed, indexReason = rebuildIdentityIndex(self)
    if not indexed then
        self.records = previousRecords
        self.tombstones = previousTombstones
        self.tombstoneAliases = previousAliases
        self.tombstoneAmbiguousAliases = previousAmbiguous
        self.identityResolver = previousResolver
        self.lifecycleRevision = previousLifecycleRev
        self.gcMeta = previousGCMeta
        return nil, indexReason
    end
    self.revision = revision
    self.lifecycleRevision = math.max(0,
        math.floor(tonumber(type(lifecycleState) == "table"
            and lifecycleState.lifecycleRevision) or 0))
    self.gcMeta = Util.clone(
        (type(lifecycleState) == "table" and lifecycleState.gcMeta)
            or { generation = 0, lastSweepAt = 0 }
    )
    spatialReset(self)
    markProjectionDirty("actors_loaded")
    return true
end

return Registry
