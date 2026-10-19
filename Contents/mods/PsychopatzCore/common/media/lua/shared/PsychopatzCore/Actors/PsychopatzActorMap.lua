local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Presentation = require "PsychopatzCore/Actors/PsychopatzActorPresentation"
local Journey = require "PsychopatzCore/Actors/PsychopatzActorJourney"

local Map = {}
Map.SCHEMA_VERSION = 1
Map.MAX_ENTRIES = 256

local function number(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then return fallback end
    return value
end

local function distance(left, right)
    local dx = left.x - right.x
    local dy = left.y - right.y
    local dz = left.z - right.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function knownSet(value)
    local output = {}
    if type(value) == "string" and value ~= "" then output[value] = true end
    if type(value) == "table" then
        for key, item in pairs(value) do
            if type(key) == "number" and type(item) == "string" then
                output[item] = true
            elseif type(key) == "string" and item == true then
                output[key] = true
            end
        end
    end
    return output
end

local function buildEntry(actor, spec)
    spec = type(spec) == "table" and spec or {}
    if type(actor) ~= "table" or not Util.text(actor.actorId, nil) then
        return nil, "actor_required"
    end
    local world = actor.world or {}
    local location = world.location or {}
    local point = location.position or { x = 0, y = 0, z = 0 }
    local portrait, reason = Presentation.BuildPortrait(actor)
    if not portrait then return nil, reason end
    local journey = world.journey
    local entry = {
        schemaVersion = Map.SCHEMA_VERSION,
        actorID = actor.actorId,
        provider = Util.text(spec.provider or actor.ownerMod, "PsychopatzCore"),
        position = {
            x = number(point.x, 0), y = number(point.y, 0),
            z = number(point.z, 0),
        },
        visibility = Util.text(spec.visibility, "known"),
        knownTo = knownSet(spec.knownTo),
        markerID = Util.text(spec.markerID, "npc"),
        label = Util.text(spec.label or actor.identity.displayName,
            actor.actorId),
        capabilities = Util.clone(spec.capabilities or {
            talk = true,
            inspect = true,
        }),
        portrait = portrait,
        journey = journey and {
            journeyID = journey.journeyID,
            state = journey.state,
            progress = journey.progress,
            destination = Util.clone(journey.destination),
        } or nil,
        revision = math.max(0, math.floor(tonumber(spec.revision) or 0)),
    }
    return entry
end

local Registry = {}
Registry.__index = Registry

function Map.NewRegistry()
    return setmetatable({ entries = {}, revision = 0 }, Registry)
end

function Registry:Register(entry)
    if type(entry) ~= "table" or not Util.text(entry.actorID, nil) then
        return nil, "map_entry_invalid"
    end
    if self.entries[entry.actorID] then return nil, "duplicate_map_actor" end
    local copy = Util.clone(entry)
    if copy.visibility ~= "public" and copy.visibility ~= "known"
        and copy.visibility ~= "nearby"
    then return nil, "map_visibility_invalid" end
    local valid, reason = Presentation.ValidatePortrait(copy.portrait)
    if not valid then return nil, reason end
    self.entries[copy.actorID] = copy
    self.revision = self.revision + 1
    return Util.clone(copy)
end

function Registry:ProjectActor(actor, spec)
    local entry, reason = buildEntry(actor, spec)
    if not entry then return nil, reason end
    if self.entries[entry.actorID] then
        self.entries[entry.actorID] = nil
    end
    return self:Register(entry)
end

function Registry:Update(actor, spec)
    local entry, reason = buildEntry(actor, spec)
    if not entry then return nil, reason end
    self.entries[entry.actorID] = nil
    return self:Register(entry)
end

function Registry:Remove(actorID)
    if not self.entries[actorID] then return nil, "map_actor_not_found" end
    self.entries[actorID] = nil
    self.revision = self.revision + 1
    return true
end

function Registry:Get(actorID)
    local entry = self.entries[actorID]
    return entry and Util.clone(entry) or nil, entry and nil
        or "map_actor_not_found"
end

function Registry:Count()
    local count = 0
    for _ in pairs(self.entries) do count = count + 1 end
    return count
end

local function canSee(entry, viewerKey)
    if entry.visibility == "public" then return true end
    if entry.visibility == "nearby" then return true end
    return viewerKey ~= nil and entry.knownTo[viewerKey] == true
end

function Registry:ListFor(viewerKey)
    local output = {}
    for _, entry in pairs(self.entries) do
        if canSee(entry, viewerKey) then output[#output + 1] = entry end
    end
    table.sort(output, function(left, right)
        return left.actorID < right.actorID
    end)
    return Util.clone(output)
end

function Registry:MarkKnown(actorID, viewerKey)
    local entry = self.entries[actorID]
    viewerKey = Util.text(viewerKey, nil)
    if not entry then return nil, "map_actor_not_found" end
    if not viewerKey then return nil, "viewer_key_required" end
    entry.knownTo[viewerKey] = true
    entry.revision = entry.revision + 1
    self.revision = self.revision + 1
    return Util.clone(entry)
end

function Registry:QueryNearby(point, radius, viewerKey)
    point = type(point) == "table" and point or {}
    point = { x = number(point.x, 0), y = number(point.y, 0),
        z = number(point.z, 0) }
    radius = math.max(0, number(radius, 0))
    local output = {}
    for _, entry in pairs(self.entries) do
        if canSee(entry, viewerKey)
            and distance(point, entry.position) <= radius
        then
            local copy = Util.clone(entry)
            copy.distance = distance(point, entry.position)
            output[#output + 1] = copy
        end
    end
    table.sort(output, function(left, right)
        if left.distance ~= right.distance then
            return left.distance < right.distance
        end
        return left.actorID < right.actorID
    end)
    return output
end

function Registry:Save()
    local entries = {}
    for _, entry in pairs(self.entries) do entries[#entries + 1] = entry end
    table.sort(entries, function(left, right) return left.actorID < right.actorID end)
    return {
        schema = "PsychopatzCore.NPC.Map",
        schemaVersion = Map.SCHEMA_VERSION,
        revision = self.revision,
        entries = Util.clone(entries),
    }
end

function Registry:Load(payload)
    if type(payload) ~= "table"
        or payload.schema ~= "PsychopatzCore.NPC.Map"
        or tonumber(payload.schemaVersion) ~= Map.SCHEMA_VERSION
        or type(payload.entries) ~= "table"
    then return nil, "map_schema_mismatch" end
    local replacement = {}
    for index = 1, #payload.entries do
        local entry = Util.clone(payload.entries[index])
        if type(entry) ~= "table" or not Util.text(entry.actorID, nil)
            or replacement[entry.actorID]
        then return nil, "map_entry_invalid" end
        local valid, reason = Presentation.ValidatePortrait(entry.portrait)
        if not valid then return nil, reason end
        replacement[entry.actorID] = entry
    end
    self.entries = replacement
    self.revision = math.max(0, math.floor(tonumber(payload.revision) or 0))
    return true
end

return Map
