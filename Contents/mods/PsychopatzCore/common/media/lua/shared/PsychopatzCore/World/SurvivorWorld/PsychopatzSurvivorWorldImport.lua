local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"

local Import = {}

local function mapByID(value)
    if type(value) ~= "table" then return {} end
    if type(value.byID) == "table" then return value.byID end
    return value
end

local function factionSpec(id, source)
    source = type(source) == "table" and source or {}
    return {
        id = id,
        seed = source.seed,
        name = source.name,
        archetypeID = source.archetypeID,
        status = source.status,
        leaderActorID = source.leaderActorID
            or source.leaderNPCID,
        memberActorIDs = source.memberActorIDs
            or source.memberIDs,
        relations = source.relations,
        tags = source.tags,
        createdAt = source.createdAt,
        archivedAt = source.archivedAt,
        revision = source.revision,
        generation = source.generation,
    }
end

local function communitySpec(id, source)
    source = type(source) == "table" and source or {}
    return {
        id = id,
        seed = source.seed,
        factionID = source.factionID or source.factionId,
        name = source.name,
        mode = source.mode,
        status = source.status,
        home = source.home,
        siteID = source.siteID or source.siteId,
        leaderActorID = source.leaderActorID
            or source.leaderNPCID,
        memberActorIDs = source.memberActorIDs
            or source.memberIDs,
        population = source.population
            or source.currentPopulation,
        security = source.security,
        morale = source.morale,
        resources = source.resources or source.supplies,
        tags = source.tags,
        createdAt = source.createdAt,
        archivedAt = source.archivedAt,
        destroyedAt = source.destroyedAt,
        revision = source.revision,
        generation = source.generation,
    }
end

local function groupSpec(id, source)
    source = type(source) == "table" and source or {}
    return {
        id = id,
        seed = source.seed,
        factionID = source.factionID or source.factionId,
        homeCommunityID = source.homeCommunityID
            or source.homeCommunityId,
        groupType = source.groupType,
        memberActorIDs = source.memberActorIDs
            or source.memberIDs
            or source.memberIds,
        leaderActorID = source.leaderActorID
            or source.leaderID
            or source.leaderId,
        mission = source.mission,
        state = source.state,
        location = source.location,
        targetLocation = source.targetLocation,
        stateStartedAt = source.stateStartedAt,
        stateEndsAt = source.stateEndsAt,
        missionStartedAt = source.missionStartedAt,
        resources = source.resources or source.supplies,
        morale = source.morale,
        tags = source.tags,
        revision = source.revision,
        generation = source.generation,
    }
end

local function importMap(
    source,
    maximum,
    worldSeed,
    mapper,
    normalizer
)
    local output = {}
    local ids = {}
    for id in pairs(type(source) == "table" and source or {}) do
        if Types.SafeID(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for index = 1, math.min(#ids, maximum) do
        local id = ids[index]
        local normalized = normalizer(
            mapper(id, source[id]),
            worldSeed,
            id
        )
        if normalized then output[id] = normalized end
    end
    return output
end

local function memberCount(value)
    value = type(value) == "table" and value or {}
    return Types.CountMap(
        value.memberActorIDs
            or value.memberActorIds
            or value.memberIDs
            or value.memberIds
            or {}
    )
end

local function validatePNCBounds(source, abstractWorld)
    local factions = mapByID(source.factions)
    local communities = mapByID(source.communities)
    local locations = type(abstractWorld.locationsByID) == "table"
        and abstractWorld.locationsByID
        or type(source.locations) == "table" and source.locations
        or {}
    local groups = type(abstractWorld.groupsByID) == "table"
        and abstractWorld.groupsByID
        or type(source.groups) == "table" and source.groups
        or {}
    if Types.CountMap(factions) > Types.MAX_FACTIONS then
        return false, "survivor_world_faction_capacity"
    end
    if Types.CountMap(communities) > Types.MAX_COMMUNITIES then
        return false, "survivor_world_community_capacity"
    end
    if Types.CountMap(locations) > Types.MAX_LOCATIONS then
        return false, "survivor_world_location_capacity"
    end
    if Types.CountMap(groups) > Types.MAX_GROUPS then
        return false, "survivor_world_group_capacity"
    end
    for _, faction in pairs(factions) do
        if memberCount(faction) > Types.MAX_FACTION_MEMBERS then
            return false, "survivor_world_faction_member_capacity"
        end
    end
    for _, community in pairs(communities) do
        if memberCount(community) > Types.MAX_COMMUNITY_MEMBERS then
            return false, "survivor_world_community_member_capacity"
        end
    end
    for _, group in pairs(groups) do
        if memberCount(group) > Types.MAX_GROUP_MEMBERS then
            return false, "survivor_world_group_member_capacity"
        end
    end

    local population = type(abstractWorld.population) == "table"
        and abstractWorld.population or {}
    if Types.CountMap(population.sectors) > Types.MAX_SECTORS then
        return false, "survivor_world_sector_capacity"
    end
    if Types.CountMap(population.provenance) > Types.MAX_PROVENANCE then
        return false, "survivor_world_provenance_capacity"
    end
    if Types.CountMap(population.siteHistory)
        > Types.MAX_SITE_HISTORY
    then
        return false, "survivor_world_site_history_capacity"
    end

    local discovery = source.discovery or source.worldDiscovery
    discovery = type(discovery) == "table" and discovery or {}
    if Types.CountMap(discovery.players)
        > Types.MAX_DISCOVERY_PLAYERS
    then
        return false, "survivor_world_discovery_player_capacity"
    end
    for _, player in pairs(discovery.players or {}) do
        local total = 0
        for _, entries in pairs(
            type(player.entities) == "table"
                and player.entities or {}
        ) do
            total = total + Types.CountMap(entries)
        end
        if total > Types.MAX_DISCOVERY_ENTITIES_PER_PLAYER then
            return false, "survivor_world_discovery_entity_capacity"
        end
    end
    return true
end

local function discoveryFromPNC(value)
    value = type(value) == "table" and value or {}
    local sourcePlayers = type(value.players) == "table"
        and value.players or {}
    local players = {}
    for playerID, source in pairs(sourcePlayers) do
        if Types.SafeID(playerID) and type(source) == "table" then
            local entities = {
                community = {},
                group = {},
                signal = {},
            }
            local rawEntities = type(source.entities) == "table"
                and source.entities or {}
            for id, entry in pairs(
                type(rawEntities.settlement) == "table"
                    and rawEntities.settlement or {}
            ) do
                entities.community[id] = Util.clone(entry)
            end
            for id, entry in pairs(
                type(rawEntities.mobile_group) == "table"
                    and rawEntities.mobile_group or {}
            ) do
                entities.group[id] = Util.clone(entry)
            end
            for id, entry in pairs(
                type(rawEntities.signal) == "table"
                    and rawEntities.signal or {}
            ) do
                entities.signal[id] = Util.clone(entry)
            end
            players[playerID] = {
                revision = source.revision,
                lastRadioScanAt = source.lastRadioScanAt,
                radioScanCount = source.radioScanCount,
                entities = entities,
            }
        end
    end
    return {
        revision = value.revision,
        players = players,
    }
end

function Import.FromPNC(source, options)
    source = type(source) == "table" and source or {}
    options = type(options) == "table" and options or {}

    local abstractWorld = type(source.abstractWorld) == "table"
        and source.abstractWorld
        or type(source.world) == "table" and source.world
        or {}
    local population = type(abstractWorld.population) == "table"
        and abstractWorld.population or {}
    local bounded, boundReason =
        validatePNCBounds(source, abstractWorld)
    if not bounded then return nil, boundReason end
    local worldSeed = options.worldSeed
        or population.worldSeed
        or source.worldSeed
        or 0

    local snapshot = Types.NewSnapshot(worldSeed)
    snapshot.revision = math.max(
        0,
        math.floor(tonumber(
            source.revision or abstractWorld.revision
        ) or 0)
    )
    snapshot.factions = importMap(
        mapByID(source.factions),
        Types.MAX_FACTIONS,
        snapshot.worldSeed,
        factionSpec,
        Types.NormalizeFaction
    )
    snapshot.communities = importMap(
        mapByID(source.communities),
        Types.MAX_COMMUNITIES,
        snapshot.worldSeed,
        communitySpec,
        Types.NormalizeCommunity
    )
    snapshot.locations = importMap(
        type(abstractWorld.locationsByID) == "table"
            and abstractWorld.locationsByID
            or type(source.locations) == "table" and source.locations
            or {},
        Types.MAX_LOCATIONS,
        snapshot.worldSeed,
        function(id, raw)
            local copy = Util.clone(raw or {})
            copy.id = id
            return copy
        end,
        Types.NormalizeAbstractLocation
    )
    snapshot.groups = importMap(
        type(abstractWorld.groupsByID) == "table"
            and abstractWorld.groupsByID
            or type(source.groups) == "table" and source.groups
            or {},
        Types.MAX_GROUPS,
        snapshot.worldSeed,
        groupSpec,
        Types.NormalizeGroup
    )
    snapshot.population = Types.NormalizePopulation(
        population,
        snapshot.worldSeed
    )
    snapshot.population.worldSeed = snapshot.worldSeed
    snapshot.discovery = Types.NormalizeDiscovery(
        discoveryFromPNC(
            source.discovery
                or source.worldDiscovery
        )
    )

    local valid, reason = Types.ValidateSnapshot(snapshot)
    if not valid then return nil, reason end
    return snapshot
end

return Import
