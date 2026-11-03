-- Bounded authority-to-client actor presentation projection.
-- Contains only the generic world/provider fields needed by map/debug/nearby
-- consumers; private actor state and adopter gameplay data stay server-owned.

local World = require "PsychopatzCore/Actors/PsychopatzActorWorld"
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

local function cloneJourney(journey)
    if type(journey) ~= "table" then return nil end
    local output = {
        journeyID = boundedText(journey.journeyID, 160),
        state = boundedText(journey.state, 32),
        origin = point(journey.origin),
        destination = point(journey.destination),
        startAt = finite(journey.startAt or journey.startedAt),
        eta = finite(journey.eta),
        speed = finite(journey.speed),
        distanceTotal = finite(journey.distanceTotal),
        lastAdvancedAt = finite(journey.lastAdvancedAt),
        progress = finite(journey.progress) or 0,
    }
    if output.progress < 0 then output.progress = 0 end
    if output.progress > 1 then output.progress = 1 end
    return output
end

function Projection.ProjectActor(actor, now, spec)
    if type(actor) ~= "table" then return nil, "actor_required" end
    local actorID = boundedText(actor.actorId or actor.actorID, 192)
    if not actorID then return nil, "actor_id_required" end

    local world = actor.world
    if type(world) ~= "table" then return nil, "actor_world_required" end

    local position = World.ProjectPosition(world, now)
    position = point(position)
    if not position then return nil, "actor_position_required" end

    spec = type(spec) == "table" and spec or {}
    local lease = actor.providerLease or {}
    local journey = cloneJourney(world.journey)

    local entry = {
        actorID = actorID,
        revision = math.max(0, math.floor(tonumber(actor.revision) or 0)),
        provider = boundedText(
            spec.provider or lease.provider or "PsychopatzCore", 64),
        providerState = boundedText(
            spec.providerState or lease.state or "released", 32),
        bodyID = boundedText(spec.bodyID or lease.bodyID, 192),
        position = position,
        journey = journey,
        updatedAt = finite(now),
    }

    if spec.sourceID then
        entry.sourceID = boundedText(spec.sourceID, 96)
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
    local actorID = boundedText(entry.actorID, 192)
    if not actorID then return nil, "actor_id_required" end
    local position = point(entry.position)
    if not position then return nil, "position_required" end

    return {
        actorID = actorID,
        revision = math.max(0, math.floor(tonumber(entry.revision) or 0)),
        provider = boundedText(entry.provider, 64),
        providerState = boundedText(entry.providerState, 32),
        bodyID = boundedText(entry.bodyID, 192),
        position = position,
        journey = cloneJourney(entry.journey),
        sourceID = boundedText(entry.sourceID, 96),
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
    }, Store)
end

function Store:Get(actorID)
    return self.entries[tostring(actorID or "")]
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
    return true
end

Projection.Store = Store
Projection.ClientStore = Projection.ClientStore or Projection.NewStore()

return Projection
