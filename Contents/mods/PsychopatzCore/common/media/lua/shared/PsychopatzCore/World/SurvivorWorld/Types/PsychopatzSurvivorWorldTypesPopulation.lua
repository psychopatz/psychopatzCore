local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"
local I = Types.Internal

local function normalizeSector(id, value)
    id = I.SafeID(id)
    value = type(value) == "table" and value or {}
    if not id then return nil end

    return {
        id = id,
        discovered = value.discovered == true,
        hadGroups = value.hadGroups == true,
        hadCommunities = value.hadCommunities == true
            or value.hadSettlements == true,
        groupGenerationCooldownUntil = math.max(
            0,
            I.Finite(value.groupGenerationCooldownUntil, 0)
        ),
        communityGenerationCooldownUntil = math.max(
            0,
            I.Finite(
                value.communityGenerationCooldownUntil
                    or value.settlementGenerationCooldownUntil,
                0
            )
        ),
        lastReconciledAt = math.max(
            0,
            I.Finite(value.lastReconciledAt, 0)
        ),
    }
end

local function normalizeSectors(value)
    local output = {}
    local ids = {}
    for id in pairs(type(value) == "table" and value or {}) do
        if I.SafeID(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for index = 1, math.min(#ids, Types.MAX_SECTORS) do
        local sector =
            normalizeSector(ids[index], value[ids[index]])
        if sector then output[sector.id] = sector end
    end
    return output
end

local function normalizeSiteHistory(value)
    local output = {}
    local ids = {}
    for id in pairs(type(value) == "table" and value or {}) do
        if I.SafeID(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)

    for index = 1, math.min(#ids, Types.MAX_SITE_HISTORY) do
        local id = ids[index]
        local source =
            type(value[id]) == "table" and value[id] or {}
        output[id] = {
            formerCommunity = source.formerCommunity == true
                or source.formerSettlement == true,
            destroyedAt = math.max(
                0,
                I.Finite(source.destroyedAt, 0)
            ),
            regenerationBlockedUntil = math.max(
                0,
                I.Finite(
                    source.regenerationBlockedUntil,
                    0
                )
            ),
        }
    end
    return output
end

local function normalizeProvenance(value)
    local output = {}
    local ids = {}
    for id in pairs(type(value) == "table" and value or {}) do
        if I.SafeID(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)

    for index = 1, math.min(#ids, Types.MAX_PROVENANCE) do
        local generation =
            I.NormalizeGeneration(value[ids[index]])
        if generation then output[ids[index]] = generation end
    end
    return output
end

function Types.NormalizePopulation(value, worldSeed)
    value = type(value) == "table" and value or {}
    local committed = I.BoundedIDs(
        value.committedOrder,
        Types.MAX_COMMITTED_GENERATIONS
    )

    return {
        schemaVersion = Types.SCHEMA_VERSION,
        worldSeed = I.StableSeed(
            0,
            "world",
            "root",
            value.worldSeed or worldSeed
        ),
        worldSeedString = I.BoundedText(
            value.worldSeedString,
            Types.MAX_WORLD_SEED_STRING,
            nil
        ),
        nextGenerationSerial = I.Integer(
            value.nextGenerationSerial,
            1,
            2147483647,
            1
        ),
        bootstrapCompleted = value.bootstrapCompleted == true,
        bootstrapCompletedAt = math.max(
            0,
            I.Finite(value.bootstrapCompletedAt, 0)
        ),
        starterCommunityID = I.SafeID(
            value.starterCommunityID
                or value.starterCommunityId
                or value.starterSettlementId
        ),
        starterAttempts = I.Integer(
            value.starterAttempts,
            0,
            2147483647,
            0
        ),
        sectors = normalizeSectors(value.sectors),
        siteHistory = normalizeSiteHistory(value.siteHistory),
        provenance = normalizeProvenance(value.provenance),
        committedOrder = committed,
    }
end

return Types
