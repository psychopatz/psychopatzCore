-- Bounded authority-to-client actor presentation projection.
-- Contains only the generic world/provider fields needed by map/debug/nearby
-- consumers; private actor state and adopter gameplay data stay server-owned.

local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"
local Presentation = require
    "PsychopatzCore/Actors/PsychopatzActorPresentation"
local FactionPresentation = require
    "PsychopatzCore/Actors/PsychopatzActorFactionPresentation"
local Identity = require "PsychopatzCore/Actors/PsychopatzActorIdentity"
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local Projection = {}

Projection.SCHEMA = "PsychopatzCore.ActorProjection"
Projection.SCHEMA_VERSION = 1
Projection.MAX_ENTRIES = 256
Projection.MAX_SNAPSHOT_BYTES = 256 * 1024

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function point(value)
    if type(value) ~= "table" then return nil end
    local x, y = finite(value.x), finite(value.y)
    if not x or not y then return nil end
    return { x = x, y = y, z = finite(value.z) or 0 }
end

local function boundedText(value, limit)
    value = tostring(value or "")
    if value == "" then return nil end
    limit = tonumber(limit) or 128
    if #value > limit then value = string.sub(value, 1, limit) end
    return value
end

local function boundedAliases(value, canonical, sourceID)
    local output = {}
    local seen = {}
    local function add(alias)
        alias = boundedText(alias, 192)
        if not alias or alias == canonical or seen[alias]
            or #output >= Identity.MAX_ALIASES
        then
            return
        end
        seen[alias] = true
        output[#output + 1] = alias
    end
    if type(value) == "table" then
        for index = 1, #value do add(value[index]) end
    elseif value ~= nil then
        add(value)
    end
    add(sourceID)
    return output
end

local function cloneRoute(route)
    route = type(route) == "table" and route or {}
    local source = type(route.points) == "table"
        and route.points or route
    local points = {}
    for index = 1, math.min(#source, 32) do
        local value = source[index]
        local projected = point(value)
        if projected then
            projected.waitHours = math.max(
                0,
                finite(value and value.waitHours) or 0
            )
            points[#points + 1] = projected
        end
    end
    return #points >= 2 and { points = points } or nil
end

local function cloneJourney(journey)
    if type(journey) ~= "table" then return nil end
    local output = {
        journeyID = boundedText(journey.journeyID, 160),
        groupID = boundedText(journey.groupID, 192),
        ownerMod = boundedText(journey.ownerMod, 96),
        ownerRef = boundedText(journey.ownerRef, 192),
        state = boundedText(journey.state, 32),
        mode = boundedText(journey.mode, 32),
        origin = point(journey.origin),
        destination = point(journey.destination),
        originAnchorID = boundedText(journey.originAnchorID, 192),
        destinationAnchorID = boundedText(
            journey.destinationAnchorID,
            192
        ),
        route = cloneRoute(journey.route),
        startAt = finite(journey.startAt or journey.startedAt),
        eta = finite(journey.eta),
        speed = finite(journey.speed),
        distanceTotal = finite(journey.distanceTotal),
        distanceTravelled = finite(journey.distanceTravelled),
        lastAdvancedAt = finite(journey.lastAdvancedAt),
        waitRemainingHours = finite(journey.waitRemainingHours),
        arrivalRadius = finite(journey.arrivalRadius),
        progress = finite(journey.progress) or 0,
    }
    if output.progress < 0 then output.progress = 0 end
    if output.progress > 1 then output.progress = 1 end
    return output
end

function Projection.ProjectActor(actor, now, spec)
    if type(actor) ~= "table" then return nil, "actor_required" end
    local identity, identityReason = Identity.DescribeActor(actor, spec)
    if not identity then return nil, identityReason end
    local actorID = boundedText(identity.canonicalActorID, 192)
    if not actorID then return nil, "actor_id_required" end

    local world = actor.world
    if type(world) ~= "table" then return nil, "actor_world_required" end

    spec = type(spec) == "table" and spec or {}
    local position = point(spec.position)
        or point(World.ProjectPosition(world, now))
    if not position then return nil, "actor_position_required" end
    local lease = actor.providerLease or {}
    local journey = cloneJourney(world.journey)

    local entry = {
        actorID = actorID,
        canonicalActorID = actorID,
        aliases = Util.clone(identity.aliases),
        revision = math.max(0, math.floor(tonumber(actor.revision) or 0)),
        provider = boundedText(
            spec.provider or identity.providerID or lease.provider
                or "PsychopatzCore", 64),
        providerState = boundedText(
            spec.providerState or identity.presenceState or lease.state
                or "released", 32),
        presenceState = boundedText(
            spec.presenceState or identity.presenceState or lease.state
                or "released", 32),
        bodyID = boundedText(spec.bodyID or identity.bodyID or lease.bodyID, 192),
        position = position,
        journey = journey,
        updatedAt = finite(now),
    }

    if spec.sourceID then
        entry.sourceID = boundedText(spec.sourceID, 96)
    end
    entry.groupID = boundedText(spec.groupID, 192)
    entry.communityID = boundedText(spec.communityID, 192)
    entry.factionID = boundedText(spec.factionID, 192)
    entry.factionName = boundedText(spec.factionName, 128)
    entry.factionArchetypeID = boundedText(
        spec.factionArchetypeID or spec.factionArchetypeId,
        96
    )
    local factionPresentation = FactionPresentation.Build({
        factionID = entry.factionID,
        factionName = entry.factionName,
        factionArchetypeID = entry.factionArchetypeID,
        factionPresentation = spec.factionPresentation,
    })
    if factionPresentation then
        entry.factionPresentation = factionPresentation
    end
    entry.role = boundedText(spec.role, 64)
    entry.markerID = boundedText(spec.markerID, 64)
    entry.label = boundedText(
        spec.label
            or actor.identity and actor.identity.displayName
            or actorID,
        192
    )
    if type(identity.capabilities) == "table" then
        entry.capabilities = Util.clone(identity.capabilities)
    end
    if type(spec.portrait) == "table" then
        local valid = Presentation.ValidatePortrait(spec.portrait)
        if valid then entry.portrait = Util.clone(spec.portrait) end
    end
    if type(spec.journey) == "table" then
        entry.journey = cloneJourney(spec.journey)
    end
    return entry
end

function Projection.MeasureSnapshotBytes(payload)
    local ok, encoded = pcall(Json.Encode, payload)
    if not ok or type(encoded) ~= "string" then
        return nil, "projection_encode_failed"
    end
    return #encoded
end

function Projection.ValidateEntry(entry)
    if type(entry) ~= "table" then return nil, "entry_required" end
    local sourceActorID = boundedText(entry.actorID, 192)
    local actorID = boundedText(
        entry.canonicalActorID or entry.actorID,
        192
    )
    if not actorID or not sourceActorID then
        return nil, "actor_id_required"
    end
    local position = point(entry.position)
    if not position then return nil, "position_required" end
    local portrait
    if entry.portrait ~= nil then
        local valid, reason =
            Presentation.ValidatePortrait(entry.portrait)
        if not valid then return nil, reason end
        portrait = Util.clone(entry.portrait)
    end
    local factionPresentation
    if entry.factionPresentation ~= nil then
        local valid, factionReason = FactionPresentation.Validate(
            entry.factionPresentation
        )
        if not valid then return nil, factionReason end
        factionPresentation = Util.clone(entry.factionPresentation)
    end
    local capabilities
    if entry.capabilities ~= nil then
        if type(entry.capabilities) ~= "table"
            or not Util.isSerializable(entry.capabilities)
        then
            return nil, "projection_capabilities_invalid"
        end
        capabilities = Util.clone(entry.capabilities)
    end

    return {
        actorID = actorID,
        canonicalActorID = actorID,
        sourceActorID = sourceActorID ~= actorID and sourceActorID or nil,
        aliases = boundedAliases(entry.aliases, actorID, sourceActorID),
        revision = math.max(0, math.floor(tonumber(entry.revision) or 0)),
        provider = boundedText(entry.provider, 64),
        providerState = boundedText(entry.providerState, 32),
        presenceState = boundedText(
            entry.presenceState or entry.providerState,
            32
        ),
        bodyID = boundedText(entry.bodyID, 192),
        position = position,
        positionSource = boundedText(entry.positionSource, 96),
        journey = cloneJourney(entry.journey),
        sourceID = boundedText(entry.sourceID, 96),
        groupID = boundedText(entry.groupID, 192),
        communityID = boundedText(entry.communityID, 192),
        factionID = boundedText(entry.factionID, 192),
        factionName = boundedText(entry.factionName, 128),
        factionArchetypeID = boundedText(
            entry.factionArchetypeID or entry.factionArchetypeId,
            96
        ),
        factionPresentation = factionPresentation,
        role = boundedText(entry.role, 64),
        markerID = boundedText(entry.markerID, 64),
        label = boundedText(entry.label, 192),
        capabilities = capabilities,
        portrait = portrait,
        updatedAt = finite(entry.updatedAt),
    }
end

local Store = {}
Store.__index = Store

function Projection.NewStore()
    return setmetatable({
        entries = {},
        sourceActors = {},
        sourceRevisions = {},
        aliasActors = {},
        ambiguousAliases = {},
    }, Store)
end

function Store:RebuildReferenceIndex()
    local aliases = {}
    local ambiguous = {}
    for actorID, entry in pairs(self.entries) do
        for _, alias in ipairs(entry.aliases or {}) do
            alias = tostring(alias or "")
            if alias ~= "" and alias ~= actorID then
                local previous = aliases[alias]
                if previous and previous ~= actorID then
                    ambiguous[alias] = true
                    aliases[alias] = nil
                elseif not ambiguous[alias] then
                    aliases[alias] = actorID
                end
            end
        end
    end
    self.aliasActors = aliases
    self.ambiguousAliases = ambiguous
    return true
end

function Store:Resolve(reference)
    local value = Identity.ReferenceValue(reference)
    if not value then return nil, "actor_reference_required" end
    local direct = self.entries[value]
    if direct then
        return direct, {
            canonicalActorID = direct.actorID,
            aliasKind = "canonical",
            sourceReference = value,
        }
    end
    if self.ambiguousAliases[value] then
        return nil, "actor_reference_ambiguous"
    end
    local actorID = self.aliasActors[value]
    local entry = actorID and self.entries[actorID] or nil
    if not entry then return nil, "actor_not_found" end
    return entry, {
        canonicalActorID = entry.actorID,
        aliasKind = "alias",
        sourceReference = value,
    }
end

function Store:Get(actorID)
    local entry = self:Resolve(actorID)
    return entry
end

function Store:List(sourceID)
    local output = {}
    sourceID = sourceID and tostring(sourceID) or nil
    if sourceID then
        local members = self.sourceActors[sourceID] or {}
        for actorID in pairs(members) do
            local entry = self.entries[actorID]
            if entry then output[#output + 1] = entry end
        end
    else
        for _, entry in pairs(self.entries) do
            output[#output + 1] = entry
        end
    end
    table.sort(output, function(left, right)
        return left.actorID < right.actorID
    end)
    return output
end

function Store:ClearSource(sourceID)
    sourceID = tostring(sourceID or "")
    local members = self.sourceActors[sourceID]
    if members then
        for actorID in pairs(members) do self.entries[actorID] = nil end
    end
    self.sourceActors[sourceID] = {}
    self:RebuildReferenceIndex()
    return true
end

function Store:ApplySnapshot(payload)
    local bytes, byteReason = Projection.MeasureSnapshotBytes(payload)
    if not bytes then return false, byteReason end
    if bytes > Projection.MAX_SNAPSHOT_BYTES then
        return false, "projection_payload_too_large"
    end

    if type(payload) ~= "table"
        or payload.schema ~= Projection.SCHEMA
        or tonumber(payload.schemaVersion) ~= Projection.SCHEMA_VERSION
    then
        return false, "projection_schema_mismatch"
    end

    local sourceID = boundedText(payload.sourceID, 96)
    if not sourceID then return false, "source_id_required" end
    local revision = math.max(0,
        math.floor(tonumber(payload.snapshotRevision) or 0))
    local current = tonumber(self.sourceRevisions[sourceID]) or -1
    if revision < current then return false, "stale_snapshot" end

    local rawEntries = type(payload.entries) == "table" and payload.entries or {}
    if #rawEntries > Projection.MAX_ENTRIES then
        return false, "projection_capacity_exceeded"
    end

    local validated = {}
    local nextMembers = {}
    for index = 1, #rawEntries do
        local entry, reason = Projection.ValidateEntry(rawEntries[index])
        if not entry then return false, reason end
        entry.sourceID = sourceID
        validated[#validated + 1] = entry
        nextMembers[entry.actorID] = true
    end

    self:ClearSource(sourceID)
    for index = 1, #validated do
        local entry = validated[index]
        local existing = self.entries[entry.actorID]
        if not existing or entry.revision >= (tonumber(existing.revision) or 0) then
            self.entries[entry.actorID] = entry
        end
    end
    self.sourceActors[sourceID] = nextMembers
    self.sourceRevisions[sourceID] = revision
    self:RebuildReferenceIndex()
    return true
end

Projection.Store = Store
Projection.ClientStore = Projection.ClientStore or Projection.NewStore()

return Projection
