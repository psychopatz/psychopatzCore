local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"
local GroupJourney = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
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

local function hasFinitePoint(value)
    if type(value) ~= "table" then return false end
    local x = tonumber(value.x)
    local y = tonumber(value.y)
    return x ~= nil and y ~= nil
        and x == x and y == y
        and x ~= math.huge and x ~= -math.huge
        and y ~= math.huge and y ~= -math.huge
end

function Types.ValidateSnapshot(value)
    if type(value) ~= "table"
        or tonumber(value.schemaVersion) ~= Types.SCHEMA_VERSION
    then
        return false, "survivor_world_schema_mismatch"
    end

    local bounded, reason = Types.ValidateInputBounds(value)
    if not bounded then return false, reason end

    local factions = type(value.factions) == "table"
        and value.factions or {}
    local communities = type(value.communities) == "table"
        and value.communities or {}

    for id, faction in pairs(factions) do
        if type(faction) ~= "table"
            or not I.SafeID(id or faction.id or faction.factionID)
            or not I.BoundedText(faction.name, Types.MAX_NAME_LENGTH, nil)
        then
            return false, "survivor_world_faction_invalid"
        end
    end

    for id, community in pairs(communities) do
        if type(community) ~= "table" then
            return false, "survivor_world_community_invalid"
        end
        local factionID = I.SafeID(
            community.factionID or community.factionId
        )
        local home = community.home or community.position
        if not I.SafeID(id or community.id or community.communityID)
            or not factionID
            or not I.BoundedText(community.name, Types.MAX_NAME_LENGTH, nil)
            or not hasFinitePoint(home)
        then
            return false, "survivor_world_community_invalid"
        end
        if not factions[factionID] then
            return false, "survivor_world_community_faction_missing"
        end
    end

    for id, location in pairs(value.locations or {}) do
        if type(location) ~= "table"
            or not I.SafeID(id or location.id or location.locationID)
            or not hasFinitePoint(location.position or location)
        then
            return false, "survivor_world_location_invalid"
        end
    end

    for id, group in pairs(value.groups or {}) do
        if type(group) ~= "table" then
            return false, "survivor_world_group_invalid"
        end
        local factionID = I.SafeID(group.factionID or group.factionId)
        local loc = group.location
        if not I.SafeID(id or group.id or group.groupID)
            or not factionID
            or type(loc) ~= "table"
            or not hasFinitePoint(loc.position or loc)
        then
            return false, "survivor_world_group_invalid"
        end
        local rawJourney = group.journey or group.groupJourney
        if rawJourney ~= nil then
            local journeyValid = GroupJourney.Validate(rawJourney)
            if not journeyValid then
                return false, "survivor_world_group_invalid"
            end
        end
        if not factions[factionID] then
            return false, "survivor_world_group_faction_missing"
        end
        local homeCommunityID = I.SafeID(
            group.homeCommunityID or group.homeCommunityId
        )
        if homeCommunityID and not communities[homeCommunityID] then
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
