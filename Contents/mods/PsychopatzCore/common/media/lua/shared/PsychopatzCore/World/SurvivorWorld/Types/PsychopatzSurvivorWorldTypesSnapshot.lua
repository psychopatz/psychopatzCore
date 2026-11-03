local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"
local I = Types.Internal

local function normalizedMap(source, maximum, normalizer, worldSeed)
    local output = {}
    local ids = {}
    for id in pairs(type(source) == "table" and source or {}) do
        if I.SafeID(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for index = 1, math.min(#ids, maximum) do
        local record =
            normalizer(source[ids[index]], worldSeed, ids[index])
        if record then output[ids[index]] = record end
    end
    return output
end

function Types.NewSnapshot(worldSeed)
    local seed = I.StableSeed(0, "world", "root", worldSeed)
    return {
        schemaVersion = Types.SCHEMA_VERSION,
        revision = 0,
        worldSeed = seed,
        factions = {},
        communities = {},
        locations = {},
        groups = {},
        population = Types.NormalizePopulation(
            { worldSeed = seed },
            seed
        ),
        discovery = Types.NormalizeDiscovery(nil),
    }
end

function Types.NormalizeSnapshot(value)
    value = type(value) == "table" and value or {}
    local seed = I.StableSeed(
        0,
        "world",
        "root",
        value.worldSeed
            or (type(value.population) == "table"
                and value.population.worldSeed)
    )
    local output = Types.NewSnapshot(seed)
    output.revision = I.Integer(
        value.revision,
        0,
        2147483647,
        0
    )
    output.factions = normalizedMap(
        value.factions,
        Types.MAX_FACTIONS,
        Types.NormalizeFaction,
        seed
    )
    output.communities = normalizedMap(
        value.communities,
        Types.MAX_COMMUNITIES,
        Types.NormalizeCommunity,
        seed
    )
    output.locations = normalizedMap(
        value.locations,
        Types.MAX_LOCATIONS,
        Types.NormalizeAbstractLocation,
        seed
    )
    output.groups = normalizedMap(
        value.groups,
        Types.MAX_GROUPS,
        Types.NormalizeGroup,
        seed
    )
    output.population = Types.NormalizePopulation(
        value.population,
        seed
    )
    output.population.worldSeed = seed
    output.discovery = Types.NormalizeDiscovery(value.discovery)
    return output
end

function Types.ValidateInputBounds(value)
    value = type(value) == "table" and value or {}
    if I.CountMap(value.factions) > Types.MAX_FACTIONS then
        return false, "survivor_world_faction_capacity"
    end
    if I.CountMap(value.communities) > Types.MAX_COMMUNITIES then
        return false, "survivor_world_community_capacity"
    end
    if I.CountMap(value.locations) > Types.MAX_LOCATIONS then
        return false, "survivor_world_location_capacity"
    end
    if I.CountMap(value.groups) > Types.MAX_GROUPS then
        return false, "survivor_world_group_capacity"
    end

    for _, faction in pairs(value.factions or {}) do
        if I.CountMap(I.MemberInput(faction))
            > Types.MAX_FACTION_MEMBERS
        then
            return false, "survivor_world_faction_member_capacity"
        end
    end
    for _, community in pairs(value.communities or {}) do
        if I.CountMap(I.MemberInput(community))
            > Types.MAX_COMMUNITY_MEMBERS
        then
            return false, "survivor_world_community_member_capacity"
        end
    end
    for _, group in pairs(value.groups or {}) do
        if I.CountMap(I.MemberInput(group))
            > Types.MAX_GROUP_MEMBERS
        then
            return false, "survivor_world_group_member_capacity"
        end
        local journey = type(group) == "table"
            and (group.journey or group.groupJourney) or nil
        local route = type(journey) == "table"
            and journey.route or nil
        local points = type(route) == "table"
            and (route.points or route) or nil
        if type(points) == "table"
            and #points > Types.MAX_GROUP_ROUTE_POINTS
        then
            return false, "survivor_world_group_route_capacity"
        end
    end

    local population =
        type(value.population) == "table" and value.population or {}
    if I.CountMap(population.sectors) > Types.MAX_SECTORS then
        return false, "survivor_world_sector_capacity"
    end
    if I.CountMap(population.provenance) > Types.MAX_PROVENANCE then
        return false, "survivor_world_provenance_capacity"
    end
    if I.CountMap(population.siteHistory)
        > Types.MAX_SITE_HISTORY
    then
        return false, "survivor_world_site_history_capacity"
    end
    if I.CountMap(population.committedOrder)
        > Types.MAX_COMMITTED_GENERATIONS
    then
        return false, "survivor_world_generation_history_capacity"
    end

    local discovery =
        type(value.discovery) == "table" and value.discovery or {}
    if I.CountMap(discovery.players)
        > Types.MAX_DISCOVERY_PLAYERS
    then
        return false, "survivor_world_discovery_player_capacity"
    end
    for _, player in pairs(discovery.players or {}) do
        local total = 0
        local entities =
            type(player.entities) == "table" and player.entities or {}
        for _, entries in pairs(entities) do
            total = total + I.CountMap(entries)
        end
        if total > Types.MAX_DISCOVERY_ENTITIES_PER_PLAYER then
            return false, "survivor_world_discovery_entity_capacity"
        end
    end
    return true
end

function Types.ValidateSnapshot(value)
    if type(value) ~= "table"
        or tonumber(value.schemaVersion) ~= Types.SCHEMA_VERSION
    then
        return false, "survivor_world_schema_mismatch"
    end

    local bounded, reason = Types.ValidateInputBounds(value)
    if not bounded then return false, reason end

    for id, faction in pairs(value.factions or {}) do
        local normalized = Types.NormalizeFaction(
            faction,
            value.worldSeed,
            id
        )
        if not normalized then
            return false, "survivor_world_faction_invalid"
        end
    end

    for id, community in pairs(value.communities or {}) do
        local normalized = Types.NormalizeCommunity(
            community,
            value.worldSeed,
            id
        )
        if not normalized then
            return false, "survivor_world_community_invalid"
        end
        if not value.factions[normalized.factionID] then
            return false, "survivor_world_community_faction_missing"
        end
    end

    for id, location in pairs(value.locations or {}) do
        local normalized = Types.NormalizeAbstractLocation(
            location,
            value.worldSeed,
            id
        )
        if not normalized then
            return false, "survivor_world_location_invalid"
        end
    end

    for id, group in pairs(value.groups or {}) do
        local normalized = Types.NormalizeGroup(
            group,
            value.worldSeed,
            id
        )
        if not normalized then
            return false, "survivor_world_group_invalid"
        end
        if not value.factions[normalized.factionID] then
            return false, "survivor_world_group_faction_missing"
        end
        if normalized.homeCommunityID
            and not value.communities[normalized.homeCommunityID]
        then
            return false, "survivor_world_group_home_missing"
        end
    end

    if not Util.isSerializable(value) then
        return false, "survivor_world_not_serializable"
    end
    return true
end

local ID_PREFIXES = {
    faction = "faction_",
    community = "community_",
    group = "agroup_",
    location = "aloc_",
    sector = "psector_",
    signal = "signal_",
}

function Types.DeterministicID(kind, worldSeed, scope, serial)
    kind = tostring(kind or "entity")
    local prefix = ID_PREFIXES[kind] or (kind .. "_")
    local hash = Util.hash(
        tostring(worldSeed or 0) .. ":"
            .. tostring(scope or "world") .. ":"
            .. tostring(serial or 0) .. ":"
            .. kind
    )
    return string.sub(
        prefix .. tostring(hash),
        1,
        Types.ID_MAX_LENGTH
    )
end

return Types
