local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"

local Generation = {
    Internal = {},
}

Generation.SCHEMA_VERSION = 1
Generation.DEFAULT_SECTOR_SIZE = 1000
Generation.MAX_POLICIES = 16
Generation.MAX_PROFILE_NAME = 96
Generation.MAX_PLAN_MEMBERS = Types.MAX_GROUP_MEMBERS

local I = Generation.Internal

function Generation.SeedText(value)
    local hash = 5381
    local source = tostring(value or "")
    for index = 1, #source do
        hash = (
            hash * 33 + string.byte(source, index)
        ) % 2147483647
    end
    return hash
end

function Generation.ResolveWorldSeed(value)
    local source = type(value) == "table" and value or { seed = value }
    local numeric = tonumber(source.seed or source.worldSeed)
    if numeric and numeric == numeric
        and numeric ~= math.huge and numeric ~= -math.huge
        and numeric ~= 0
    then
        return math.max(
            1,
            math.min(2147483647, math.abs(math.floor(numeric)))
        )
    end

    local seedString = source.seedString or source.worldSeedString
    if seedString ~= nil and tostring(seedString) ~= "" then
        return math.max(
            1,
            Generation.SeedText("PZ_WORLD:" .. tostring(seedString))
        )
    end

    return math.max(
        1,
        Generation.SeedText("PSYCHOPATZ_SURVIVOR_WORLD")
    )
end

function Generation.SectorID(x, y, sectorSize)
    sectorSize = math.max(
        1,
        math.floor(tonumber(sectorSize)
            or Generation.DEFAULT_SECTOR_SIZE)
    )
    local sx = math.floor((tonumber(x) or 0) / sectorSize)
    local sy = math.floor((tonumber(y) or 0) / sectorSize)
    return "psector_" .. tostring(sx) .. "_" .. tostring(sy),
        sx, sy
end

function Generation.ParseSectorID(id)
    local sx, sy = string.match(
        tostring(id or ""),
        "^psector_([%-]?%d+)_([%-]?%d+)$"
    )
    return tonumber(sx), tonumber(sy)
end

function Generation.SectorCenter(id, sectorSize)
    local sx, sy = Generation.ParseSectorID(id)
    if sx == nil then return nil, "invalid_sector_id" end
    sectorSize = math.max(
        1,
        math.floor(tonumber(sectorSize)
            or Generation.DEFAULT_SECTOR_SIZE)
    )
    return {
        x = (sx + 0.5) * sectorSize,
        y = (sy + 0.5) * sectorSize,
        z = 0,
    }
end

function Generation.GenerationID(kind, serial)
    kind = string.upper(tostring(kind or "ENTITY"))
    kind = string.gsub(kind, "[^A-Z0-9_]", "_")
    serial = math.max(1, math.floor(tonumber(serial) or 1))
    return "POP_" .. kind .. "_" .. string.format("%07d", serial)
end

function Generation.GenerationSeed(
    worldSeed,
    kind,
    sectorID,
    serial,
    qualifier
)
    worldSeed = Generation.ResolveWorldSeed(worldSeed)
    return Generation.SeedText(table.concat({
        tostring(worldSeed),
        tostring(kind or "ENTITY"),
        tostring(sectorID or ""),
        tostring(serial or 0),
        tostring(qualifier or ""),
    }, ":"))
end

function Generation.WeightedChoice(weights, seed)
    local keys = {}
    local total = 0
    for key, value in pairs(
        type(weights) == "table" and weights or {}
    ) do
        value = math.max(0, tonumber(value) or 0)
        if value > 0 then
            keys[#keys + 1] = tostring(key)
            total = total + value
        end
    end
    if total <= 0 then return nil end

    table.sort(keys)
    local roll = (
        Generation.SeedText(tostring(seed) .. ":WEIGHTED_ROLL")
        % 1000000
    ) / 1000000 * total

    for _, key in ipairs(keys) do
        roll = roll - math.max(0, tonumber(weights[key]) or 0)
        if roll <= 0 then return key end
    end
    return keys[#keys]
end

function Generation.EntityID(kind, worldSeed, sectorID, serial)
    worldSeed = Generation.ResolveWorldSeed(worldSeed)
    local generationSeed = Generation.GenerationSeed(
        worldSeed,
        kind,
        sectorID,
        serial,
        "ENTITY_ID"
    )
    local normalizedKind = tostring(kind or "entity")
    local prefix = ({
        faction = "faction_",
        community = "community_",
        group = "agroup_",
        location = "aloc_",
        actor = "npc_",
    })[normalizedKind] or (normalizedKind .. "_")
    return prefix .. tostring(generationSeed)
end

function I.Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local output = {}
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = I.Copy(item, seen)
        end
    end
    seen[value] = nil
    return output
end

return Generation
