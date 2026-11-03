local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Types = {
    Internal = {},
}

Types.SCHEMA_VERSION = 1
Types.MAX_FACTIONS = 256
Types.MAX_COMMUNITIES = 512
Types.MAX_GROUPS = 1024
Types.MAX_LOCATIONS = 4096
Types.MAX_SECTORS = 4096
Types.MAX_DISCOVERY_PLAYERS = 256
Types.MAX_DISCOVERY_ENTITIES_PER_PLAYER = 4096
Types.MAX_FACTION_MEMBERS = 4096
Types.MAX_COMMUNITY_MEMBERS = 1024
Types.MAX_GROUP_MEMBERS = 128
Types.MAX_RELATIONS = 128
Types.MAX_TAGS = 64
Types.MAX_PROVENANCE = 4096
Types.MAX_COMMITTED_GENERATIONS = 2048
Types.MAX_SITE_HISTORY = 4096
Types.MAX_ID_LENGTH = 192
Types.ID_MAX_LENGTH = Types.MAX_ID_LENGTH
Types.MAX_DISCOVERY_ENTRIES = Types.MAX_DISCOVERY_ENTITIES_PER_PLAYER
Types.MAX_NAME_LENGTH = 128
Types.MAX_ARCHETYPE_LENGTH = 128
Types.MAX_KIND_LENGTH = 64
Types.MAX_SOURCE_LENGTH = 96
Types.MAX_WORLD_SEED_STRING = 128

local I = Types.Internal

function I.Finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

function I.Integer(value, minimum, maximum, fallback)
    local normalized = math.floor(I.Finite(value, fallback))
    if minimum ~= nil then normalized = math.max(minimum, normalized) end
    if maximum ~= nil then normalized = math.min(maximum, normalized) end
    return normalized
end

function I.BoundedText(value, maximum, fallback)
    local normalized = Util.text(value, nil)
    if not normalized then return fallback end
    maximum = tonumber(maximum) or Types.MAX_NAME_LENGTH
    if #normalized > maximum then
        normalized = string.sub(normalized, 1, maximum)
    end
    return normalized
end

function I.SafeID(value)
    local normalized = I.BoundedText(value, Types.MAX_ID_LENGTH, nil)
    if not normalized or string.find(normalized, "%c")
        or string.match(normalized, "^[%w_%-%.:]+$") == nil
    then
        return nil
    end
    return normalized
end

function I.StableSeed(worldSeed, kind, id, value)
    local supplied = tonumber(value)
    if supplied and supplied == supplied
        and supplied ~= math.huge and supplied ~= -math.huge
    then
        return math.abs(math.floor(supplied)) % 2147483647
    end
    return Util.hash(
        tostring(worldSeed or 0) .. ":"
            .. tostring(kind or "entity") .. ":" .. tostring(id or "")
    )
end

function I.BoundedIDs(value, maximum)
    local seen = {}
    local candidates = {}
    local output = {}
    maximum = math.max(0, math.floor(tonumber(maximum) or 0))
    if type(value) ~= "table" or maximum == 0 then return output end

    local function add(candidate)
        local id = I.SafeID(candidate)
        if id and not seen[id] then
            seen[id] = true
            candidates[#candidates + 1] = id
        end
    end

    for key, item in pairs(value) do
        if type(key) == "number" then
            add(item)
        elseif item == true then
            add(key)
        end
    end
    table.sort(candidates)
    for index = 1, math.min(#candidates, maximum) do
        output[index] = candidates[index]
    end
    return output
end

function I.BoundedTags(value)
    local output = {}
    local keys = {}
    for key in pairs(type(value) == "table" and value or {}) do
        if type(key) == "string" then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for index = 1, math.min(#keys, Types.MAX_TAGS) do
        local key = I.BoundedText(keys[index], 64, nil)
        local item = value[keys[index]]
        if key then
            if type(item) == "boolean" then
                output[key] = item
            elseif type(item) == "string" then
                output[key] = I.BoundedText(item, 128, nil)
            elseif type(item) == "number"
                and item == item and item ~= math.huge
                and item ~= -math.huge
            then
                output[key] = item
            end
        end
    end
    return output
end

function I.NormalizeResources(value)
    value = type(value) == "table" and value or {}
    return {
        food = math.max(0, I.Finite(value.food, 0)),
        water = math.max(0, I.Finite(value.water, 0)),
        ammo = math.max(0, I.Finite(value.ammo, 0)),
        medical = math.max(
            0,
            I.Finite(value.medical or value.medicine, 0)
        ),
        materials = math.max(0, I.Finite(value.materials, 0)),
        weapons = math.max(0, I.Finite(value.weapons, 0)),
    }
end

function I.NormalizePoint(value)
    value = type(value) == "table" and value or {}
    local x = tonumber(value.x)
    local y = tonumber(value.y)
    if x == nil or y == nil
        or x ~= x or y ~= y
        or x == math.huge or x == -math.huge
        or y == math.huge or y == -math.huge
    then
        return nil
    end
    return {
        x = x,
        y = y,
        z = I.Finite(value.z, 0),
    }
end

function I.NormalizeLocation(value)
    value = type(value) == "table" and value or {}
    local point = I.NormalizePoint(value.position or value)
    if not point then return nil end
    local id = I.SafeID(value.id or value.locationID or value.locationId)
    local kind = I.BoundedText(
        value.kind or value.type,
        Types.MAX_KIND_LENGTH,
        "world"
    )
    return {
        id = id,
        kind = kind,
        x = point.x,
        y = point.y,
        z = point.z,
    }
end

function I.NormalizeGeneration(value)
    if type(value) ~= "table" then return nil end
    local generationID = I.SafeID(
        value.generationID or value.generationId or value.id
    )
    if not generationID then return nil end
    return {
        source = I.BoundedText(
            value.source,
            Types.MAX_SOURCE_LENGTH,
            "world"
        ),
        generationID = generationID,
        sectorID = I.SafeID(value.sectorID or value.sectorId),
        createdAt = math.max(0, I.Finite(value.createdAt, 0)),
        seed = I.StableSeed(
            0,
            "generation",
            generationID,
            value.seed
        ),
    }
end

function I.CountMap(value)
    local count = 0
    for _ in pairs(type(value) == "table" and value or {}) do
        count = count + 1
    end
    return count
end

function I.MemberInput(value)
    value = type(value) == "table" and value or {}
    return value.memberActorIDs
        or value.memberActorIds
        or value.memberIDs
        or value.memberIds
        or {}
end

Types.SafeID = I.SafeID
Types.StableSeed = I.StableSeed
Types.NormalizePoint = I.NormalizePoint
Types.NormalizeLocation = I.NormalizeLocation
Types.NormalizeResources = I.NormalizeResources
Types.CountMap = I.CountMap
Types.MemberInput = I.MemberInput

return Types
