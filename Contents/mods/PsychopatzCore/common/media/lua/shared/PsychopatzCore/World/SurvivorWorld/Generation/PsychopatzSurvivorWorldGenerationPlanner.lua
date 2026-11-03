local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"
local Generation = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationCore"
local Profiles = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationProfiles"
local I = Generation.Internal

local Planner = {}

local function boundedCount(range, seed)
    local minimum = math.max(1, math.floor(range.minimum or 1))
    local maximum = math.max(minimum, math.floor(range.maximum or minimum))
    local width = maximum - minimum + 1
    return minimum + (seed % width)
end

local function actorIDs(
    worldSeed,
    sectorID,
    serial,
    count,
    scope
)
    local output = {}
    for index = 1, count do
        output[index] = Generation.EntityID(
            "actor",
            worldSeed,
            tostring(sectorID) .. ":" .. tostring(scope)
                .. ":" .. tostring(serial),
            index
        )
    end
    return output
end

local function generationMetadata(
    generationID,
    sectorID,
    source,
    seed,
    createdAt
)
    return {
        source = tostring(source or "CORE_SURVIVOR_WORLD"),
        generationID = generationID,
        sectorID = sectorID,
        createdAt = math.max(0, tonumber(createdAt) or 0),
        seed = seed,
    }
end

local function normalizeProfile(value)
    return Profiles.Normalize(value)
end

function Planner.BuildCommunityPlan(request)
    request = type(request) == "table" and request or {}
    local profile = normalizeProfile(request.profile)
    local worldSeed = Generation.ResolveWorldSeed(
        request.worldSeed or {
            seed = request.seed,
            seedString = request.seedString,
        }
    )
    local sectorID = Types.SafeID(request.sectorID)
    local locationID = Types.SafeID(request.locationID)
    local location = type(request.location) == "table"
        and Types.NormalizePoint(request.location) or nil
    local serial = math.max(1, math.floor(tonumber(request.serial) or 1))
    if not sectorID or not locationID or not location then
        return nil, "community_plan_location_required"
    end

    local seed = Generation.GenerationSeed(
        worldSeed,
        "COMMUNITY",
        sectorID,
        serial,
        request.source
    )
    local archetype = tostring(
        request.factionArchetypeID
            or Generation.WeightedChoice(
                profile.communityFactionWeights,
                tostring(seed) .. ":FACTION_ARCHETYPE"
            )
            or "settler"
    )

    local factionID = Types.SafeID(request.factionID)
    local factionName = request.factionName
    local factionPlan
    if not factionID then
        factionID = Generation.EntityID(
            "faction",
            worldSeed,
            sectorID,
            serial
        )
        factionName = factionName
            or Profiles.FactionName(archetype, seed)
        factionPlan = {
            id = factionID,
            seed = Generation.GenerationSeed(
                worldSeed,
                "FACTION",
                sectorID,
                serial,
                archetype
            ),
            name = factionName,
            archetypeID = archetype,
            status = "active",
            generation = generationMetadata(
                Generation.GenerationID("FACTION", serial),
                sectorID,
                request.source,
                seed,
                request.createdAt
            ),
        }
    elseif not factionName then
        factionName = tostring(request.factionName or factionID)
    end

    local communityID = Types.SafeID(request.communityID)
        or Generation.EntityID(
            "community",
            worldSeed,
            sectorID,
            serial
        )
    local communityName = request.communityName
        or Profiles.CommunityName(archetype, factionName, seed)
    local population = math.max(
        1,
        math.min(
            Types.MAX_COMMUNITY_MEMBERS,
            math.floor(
                tonumber(request.initialPopulation)
                    or boundedCount(profile.communitySize, seed)
            )
        )
    )
    local members = actorIDs(
        worldSeed,
        sectorID,
        serial,
        population,
        "community"
    )

    local plan = {
        schemaVersion = Generation.SCHEMA_VERSION,
        kind = "community",
        worldSeed = worldSeed,
        sectorID = sectorID,
        serial = serial,
        generationID = Generation.GenerationID(
            "COMMUNITY",
            serial
        ),
        seed = seed,
        source = tostring(
            request.source or "CORE_SURVIVOR_WORLD"
        ),
        factionID = factionID,
        factionArchetypeID = archetype,
        factionPlan = factionPlan,
        locationID = locationID,
        location = {
            id = locationID,
            kind = tostring(request.locationKind or "settlement"),
            x = location.x,
            y = location.y,
            z = location.z,
        },
        communityID = communityID,
        communityName = communityName,
        initialPopulation = population,
        memberActorIDs = members,
        leaderActorID = members[1],
        profileID = profile.id,
    }
    return plan
end

function Planner.BuildGroupPlan(request)
    request = type(request) == "table" and request or {}
    local profile = normalizeProfile(request.profile)
    local worldSeed = Generation.ResolveWorldSeed(
        request.worldSeed or {
            seed = request.seed,
            seedString = request.seedString,
        }
    )
    local sectorID = Types.SafeID(request.sectorID)
    local locationID = Types.SafeID(request.locationID)
    local location = type(request.location) == "table"
        and Types.NormalizePoint(request.location) or nil
    local serial = math.max(1, math.floor(tonumber(request.serial) or 1))
    if not sectorID or not locationID or not location then
        return nil, "group_plan_location_required"
    end

    local seed = Generation.GenerationSeed(
        worldSeed,
        "GROUP",
        sectorID,
        serial,
        request.source
    )
    local groupType = tostring(
        request.groupType
            or Generation.WeightedChoice(
                profile.groupTypeWeights,
                tostring(seed) .. ":GROUP_TYPE"
            )
            or "WANDERER"
    )
    local archetype = tostring(
        request.factionArchetypeID
            or profile.groupFactionArchetypes[groupType]
            or "refugee"
    )

    local factionID = Types.SafeID(request.factionID)
    local factionName = request.factionName
    local factionPlan
    if not factionID then
        factionID = Generation.EntityID(
            "faction",
            worldSeed,
            tostring(sectorID) .. ":group",
            serial
        )
        factionName = factionName
            or Profiles.FactionName(archetype, seed)
        factionPlan = {
            id = factionID,
            seed = Generation.GenerationSeed(
                worldSeed,
                "FACTION",
                sectorID,
                serial,
                groupType
            ),
            name = factionName,
            archetypeID = archetype,
            status = "active",
            generation = generationMetadata(
                Generation.GenerationID("FACTION", serial),
                sectorID,
                request.source,
                seed,
                request.createdAt
            ),
        }
    end

    local count = math.max(
        1,
        math.min(
            Generation.MAX_PLAN_MEMBERS,
            math.floor(
                tonumber(request.memberCount)
                    or boundedCount(profile.groupSize, seed)
            )
        )
    )
    local members = actorIDs(
        worldSeed,
        sectorID,
        serial,
        count,
        "group"
    )

    return {
        schemaVersion = Generation.SCHEMA_VERSION,
        kind = "group",
        worldSeed = worldSeed,
        sectorID = sectorID,
        serial = serial,
        generationID = Generation.GenerationID("GROUP", serial),
        seed = seed,
        source = tostring(
            request.source or "CORE_SURVIVOR_WORLD"
        ),
        factionID = factionID,
        factionArchetypeID = archetype,
        factionPlan = factionPlan,
        groupID = Types.SafeID(request.groupID)
            or Generation.EntityID(
                "group",
                worldSeed,
                sectorID,
                serial
            ),
        groupType = groupType,
        initialMission = tostring(
            request.initialMission or "SCAVENGE"
        ),
        locationID = locationID,
        location = {
            id = locationID,
            kind = tostring(request.locationKind or "temporary"),
            x = location.x,
            y = location.y,
            z = location.z,
        },
        memberCount = count,
        memberActorIDs = members,
        leaderActorID = members[1],
        profileID = profile.id,
    }
end

Generation.Planner = Planner

return Planner
