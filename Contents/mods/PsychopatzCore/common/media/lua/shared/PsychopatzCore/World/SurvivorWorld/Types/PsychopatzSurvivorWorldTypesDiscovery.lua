local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"
local I = Types.Internal

local VALID_KINDS = {
    community = true,
    group = true,
    signal = true,
}

local function discoveryKind(value)
    value = tostring(value or "")
    if value == "settlement" then return "community" end
    if value == "mobile_group" then return "group" end
    if VALID_KINDS[value] then return value end
    return nil
end

local function normalizeEntry(kind, id, value)
    kind = discoveryKind(kind)
    id = I.SafeID(id)
    value = type(value) == "table" and value or {}
    if not kind or not id then return nil end
    local point = I.NormalizePoint(value)
    return {
        entityID = id,
        kind = kind,
        phase = I.Integer(value.phase, 0, 3, 0),
        source = I.BoundedText(
            value.source,
            Types.MAX_SOURCE_LENGTH,
            "unknown"
        ),
        discoveredAt = math.max(
            0,
            I.Finite(value.discoveredAt, 0)
        ),
        updatedAt = math.max(
            0,
            I.Finite(value.updatedAt, 0)
        ),
        x = point and point.x or nil,
        y = point and point.y or nil,
        z = point and point.z or nil,
        arrivalState = I.BoundedText(
            value.arrivalState,
            32,
            "unchecked"
        ),
        searchedAt = math.max(
            0,
            I.Finite(value.searchedAt, 0)
        ),
        contactedAt = math.max(
            0,
            I.Finite(value.contactedAt, 0)
        ),
        presenceStatus = I.BoundedText(
            value.presenceStatus,
            32,
            "unknown"
        ),
        factionKnown = value.factionKnown == true,
        factionID = I.SafeID(
            value.factionID or value.factionId
        ),
        factionName = I.BoundedText(
            value.factionName,
            Types.MAX_NAME_LENGTH,
            nil
        ),
    }
end

local function normalizePlayer(value)
    value = type(value) == "table" and value or {}
    local output = {
        revision = I.Integer(value.revision, 0, 2147483647, 0),
        lastRadioScanAt = math.max(
            0,
            I.Finite(value.lastRadioScanAt, 0)
        ),
        radioScanCount = I.Integer(
            value.radioScanCount,
            0,
            2147483647,
            0
        ),
        entities = {
            community = {},
            group = {},
            signal = {},
        },
    }

    local count = 0
    for sourceKind, entries in pairs(
        type(value.entities) == "table"
            and value.entities or {}
    ) do
        local kind = discoveryKind(sourceKind)
        if kind and type(entries) == "table" then
            local ids = {}
            for id in pairs(entries) do
                if I.SafeID(id) then ids[#ids + 1] = id end
            end
            table.sort(ids)
            for _, id in ipairs(ids) do
                if count >= Types.MAX_DISCOVERY_ENTITIES_PER_PLAYER then
                    break
                end
                local entry =
                    normalizeEntry(kind, id, entries[id])
                if entry then
                    output.entities[kind][id] = entry
                    count = count + 1
                end
            end
        end
        if count >= Types.MAX_DISCOVERY_ENTITIES_PER_PLAYER then
            break
        end
    end
    return output
end

function Types.NormalizeDiscovery(value)
    value = type(value) == "table" and value or {}
    local output = {
        schemaVersion = Types.SCHEMA_VERSION,
        revision = I.Integer(value.revision, 0, 2147483647, 0),
        players = {},
    }

    local ids = {}
    for id in pairs(
        type(value.players) == "table" and value.players or {}
    ) do
        if I.SafeID(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)

    for index = 1, math.min(
        #ids,
        Types.MAX_DISCOVERY_PLAYERS
    ) do
        output.players[ids[index]] =
            normalizePlayer(value.players[ids[index]])
    end
    return output
end

return Types
