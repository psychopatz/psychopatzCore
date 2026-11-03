local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Generation = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldGeneration"

local Bootstrap = {}

Bootstrap.SCHEMA_VERSION = 1
Bootstrap.DEFAULT_COMMUNITIES = 3
Bootstrap.DEFAULT_GROUPS = 3
Bootstrap.MAX_COMMUNITIES = 8
Bootstrap.MAX_GROUPS = 16
Bootstrap.AFFILIATION_EXTENSION =
    "PsychopatzCore.SurvivorWorld"

local OFFSETS = {
    { x = 0, y = 0 },
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
    { x = 1, y = 1 },
    { x = -1, y = 1 },
    { x = 1, y = -1 },
}

local function integer(value, minimum, maximum, fallback)
    value = math.floor(tonumber(value) or fallback)
    return math.max(minimum, math.min(maximum, value))
end

local function point(value)
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
        z = tonumber(value.z) or 0,
    }
end

local function siteList(spec, worldSeed)
    local supplied = type(spec.sites) == "table"
        and spec.sites or nil
    local output = {}
    if supplied then
        for index = 1, #supplied do
            local item = supplied[index]
            local position = point(
                item and (item.position or item.home or item)
            )
            if position then
                output[#output + 1] = {
                    id = tostring(
                        item.id or item.locationID
                            or item.locationId
                            or ("bootstrap_site_" .. index)
                    ),
                    position = position,
                    kind = tostring(item.kind or "settlement"),
                }
            end
        end
        table.sort(output, function(left, right)
            return left.id < right.id
        end)
        if #output > 0 then return output end
    end

    local anchor = point(spec.anchor)
    if not anchor then
        return nil, "survivor_world_bootstrap_anchor_required"
    end
    local sectorSize = math.max(
        1,
        math.floor(
            tonumber(spec.sectorSize)
                or Generation.DEFAULT_SECTOR_SIZE
        )
    )
    local _, sx, sy = Generation.SectorID(
        anchor.x,
        anchor.y,
        sectorSize
    )
    local count = integer(
        spec.siteCount,
        1,
        #OFFSETS,
        math.max(
            tonumber(spec.communityCount)
                or Bootstrap.DEFAULT_COMMUNITIES,
            tonumber(spec.groupCount)
                or Bootstrap.DEFAULT_GROUPS
        )
    )
    for index = 1, count do
        local offset = OFFSETS[index]
        local sectorID = "psector_"
            .. tostring(sx + offset.x)
            .. "_" .. tostring(sy + offset.y)
        local center = assert(
            Generation.SectorCenter(sectorID, sectorSize)
        )
        local seed = Generation.GenerationSeed(
            worldSeed,
            "BOOTSTRAP_SITE",
            sectorID,
            index,
            "CORE"
        )
        local half = math.max(32, math.floor(sectorSize * 0.25))
        local dx = (seed % (half * 2 + 1)) - half
        local dy = (
            Generation.SeedText(tostring(seed) .. ":Y")
                % (half * 2 + 1)
        ) - half
        output[#output + 1] = {
            id = Generation.EntityID(
                "location",
                worldSeed,
                sectorID,
                index
            ),
            sectorID = sectorID,
            position = {
                x = center.x + dx,
                y = center.y + dy,
                z = anchor.z,
            },
            kind = "settlement",
        }
    end
    return output
end

local function communityPlans(spec, sites, worldSeed)
    local count = integer(
        spec.communityCount,
        1,
        math.min(Bootstrap.MAX_COMMUNITIES, #sites),
        math.min(Bootstrap.DEFAULT_COMMUNITIES, #sites)
    )
    local output = {}
    for index = 1, count do
        local site = sites[index]
        local sectorID = site.sectorID
            or Generation.SectorID(
                site.position.x,
                site.position.y,
                spec.sectorSize
            )
        local request = {
            worldSeed = worldSeed,
            sectorID = sectorID,
            serial = index,
            source = tostring(
                spec.source or "CORE_SURVIVOR_WORLD_BOOTSTRAP"
            ),
            locationID = site.id,
            location = site.position,
            locationKind = site.kind,
            initialPopulation = spec.communityPopulation,
            createdAt = spec.createdAt,
        }
        -- Guarantee one deterministic trader home without making every
        -- survivor settlement trader-owned.
        if index == 1 then
            request.factionArchetypeID =
                tostring(spec.primaryArchetypeID or "trader")
        end
        local plan, reason =
            Generation.BuildCommunityPlan(request)
        if not plan then return nil, reason end
        output[#output + 1] = plan
    end
    return output
end

local function groupPlans(spec, sites, communities, worldSeed)
    local count = integer(
        spec.groupCount,
        1,
        Bootstrap.MAX_GROUPS,
        Bootstrap.DEFAULT_GROUPS
    )
    local output = {}
    for index = 1, count do
        local site = sites[((index - 1) % #sites) + 1]
        local home =
            communities[((index - 1) % #communities) + 1]
        local sectorID = site.sectorID
            or Generation.SectorID(
                site.position.x,
                site.position.y,
                spec.sectorSize
            )
        local request = {
            worldSeed = worldSeed,
            sectorID = sectorID,
            serial = 1000 + index,
            source = tostring(
                spec.source or "CORE_SURVIVOR_WORLD_BOOTSTRAP"
            ),
            locationID = site.id,
            location = site.position,
            locationKind = site.kind,
            factionID = home.factionID,
            factionName = home.factionPlan
                and home.factionPlan.name or home.factionID,
            factionArchetypeID =
                home.factionArchetypeID,
            memberCount = spec.groupSize,
            createdAt = spec.createdAt,
        }
        if index == 1 then
            request.groupType =
                tostring(spec.primaryGroupType or "CARAVAN")
            request.factionArchetypeID = "trader"
            request.factionID = communities[1].factionID
            request.factionName = communities[1].factionPlan
                and communities[1].factionPlan.name
                or communities[1].factionID
            request.initialMission = "TRADE"
        end
        local plan, reason =
            Generation.BuildGroupPlan(request)
        if not plan then return nil, reason end
        plan.homeCommunityID = home.communityID
        output[#output + 1] = plan
    end
    return output
end

function Bootstrap.BuildPlan(spec)
    spec = type(spec) == "table" and spec or {}
    local worldSeed = Generation.ResolveWorldSeed(
        spec.worldSeed or {
            seed = spec.seed,
            seedString = spec.seedString,
        }
    )
    local sites, reason = siteList(spec, worldSeed)
    if not sites then return nil, reason end

    local communities
    communities, reason =
        communityPlans(spec, sites, worldSeed)
    if not communities then return nil, reason end

    local groups
    groups, reason =
        groupPlans(spec, sites, communities, worldSeed)
    if not groups then return nil, reason end

    return {
        schemaVersion = Bootstrap.SCHEMA_VERSION,
        worldSeed = worldSeed,
        source = tostring(
            spec.source or "CORE_SURVIVOR_WORLD_BOOTSTRAP"
        ),
        sites = sites,
        communities = communities,
        groups = groups,
    }
end

local function actorExtension(
    factionID,
    communityID,
    groupID,
    role
)
    return {
        [Bootstrap.AFFILIATION_EXTENSION] = {
            factionID = factionID,
            communityID = communityID,
            groupID = groupID,
            role = role,
        },
    }
end

local function ensureActor(
    actorRegistry,
    actorID,
    seed,
    archetypeID,
    position,
    extension
)
    if not actorRegistry then return true end
    local existing = actorRegistry:Get(actorID)
    if existing then return existing end
    return actorRegistry:Create({
        actorId = actorID,
        identitySeed = seed,
        archetypeID = archetypeID or "core.survivor",
        ownerMod = "PsychopatzCore",
        world = { position = Util.clone(position) },
        extensions = extension,
    })
end

function Bootstrap.Commit(registry, plan, actorRegistry)
    if type(registry) ~= "table"
        or type(registry.UpsertFaction) ~= "function"
    then
        return nil, "survivor_world_registry_required"
    end
    if type(plan) ~= "table"
        or tonumber(plan.schemaVersion)
            ~= Bootstrap.SCHEMA_VERSION
    then
        return nil, "survivor_world_bootstrap_plan_invalid"
    end

    local firstCommunityID
    for _, item in ipairs(plan.communities or {}) do
        if item.factionPlan then
            local faction, reason =
                registry:UpsertFaction(item.factionPlan)
            if not faction then return nil, reason end
        end
        local location, reason = registry:UpsertLocation({
            id = item.location.id,
            kind = item.location.kind,
            x = item.location.x,
            y = item.location.y,
            z = item.location.z,
            generation = {
                source = item.source,
                generationID = item.generationID,
                sectorID = item.sectorID,
                seed = item.seed,
            },
        })
        if not location then return nil, reason end
        local community
        community, reason = registry:UpsertCommunity({
            id = item.communityID,
            seed = item.seed,
            factionID = item.factionID,
            name = item.communityName,
            mode = "settled",
            status = "active",
            home = {
                x = item.location.x,
                y = item.location.y,
                z = item.location.z,
                radius = 24,
            },
            siteID = item.location.id,
            leaderActorID = item.leaderActorID,
            memberActorIDs = item.memberActorIDs,
            population = item.initialPopulation,
            generation = {
                source = item.source,
                generationID = item.generationID,
                sectorID = item.sectorID,
                seed = item.seed,
            },
        })
        if not community then return nil, reason end
        firstCommunityID =
            firstCommunityID or community.id

        for index, actorID in ipairs(
            item.memberActorIDs or {}
        ) do
            local actor
            actor, reason = ensureActor(
                actorRegistry,
                actorID,
                tostring(item.seed) .. ":" .. actorID,
                item.factionArchetypeID,
                item.location,
                actorExtension(
                    item.factionID,
                    item.communityID,
                    nil,
                    index == 1 and "leader" or "resident"
                )
            )
            if not actor then return nil, reason end
        end
    end

    for _, item in ipairs(plan.groups or {}) do
        local group, reason = registry:UpsertGroup({
            id = item.groupID,
            seed = item.seed,
            factionID = item.factionID,
            homeCommunityID = item.homeCommunityID,
            groupType = item.groupType,
            leaderActorID = item.leaderActorID,
            memberActorIDs = item.memberActorIDs,
            mission = item.initialMission,
            state = "IDLE",
            location = item.location,
            resources = {
                food = 50,
                water = 50,
                ammo = item.factionArchetypeID == "looter"
                    and 50 or 15,
                medical = 10,
                materials = 0,
            },
            generation = {
                source = item.source,
                generationID = item.generationID,
                sectorID = item.sectorID,
                seed = item.seed,
            },
        })
        if not group then return nil, reason end
        for index, actorID in ipairs(
            item.memberActorIDs or {}
        ) do
            local actor
            actor, reason = ensureActor(
                actorRegistry,
                actorID,
                tostring(item.seed) .. ":" .. actorID,
                item.factionArchetypeID,
                item.location,
                actorExtension(
                    item.factionID,
                    nil,
                    item.groupID,
                    index == 1 and "leader" or "member"
                )
            )
            if not actor then return nil, reason end
        end
    end

    local population = registry:GetPopulation()
    population.bootstrapCompleted = true
    population.bootstrapCompletedAt =
        math.max(0, tonumber(plan.createdAt) or 0)
    population.starterCommunityID = firstCommunityID
    population.worldSeed = registry:WorldSeed()
    registry:SetPopulation(population)

    return {
        communities = #plan.communities,
        groups = #plan.groups,
        starterCommunityID = firstCommunityID,
    }
end

function Bootstrap.EnsureRuntime(spec)
    spec = type(spec) == "table" and spec or {}
    local World = require
        "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
    local registry, reason = World.ActivateRuntime({
        worldSeed = Generation.ResolveWorldSeed(
            spec.worldSeed or {
                seed = spec.seed,
                seedString = spec.seedString,
            }
        ),
    })
    if not registry then return nil, reason end

    local counts = registry:Counts()
    local population = registry:GetPopulation()
    if counts.communities > 0
        or counts.groups > 0
        or population.bootstrapCompleted == true
    then
        return registry, "existing"
    end

    local plan
    plan, reason = Bootstrap.BuildPlan(spec)
    if not plan then return nil, reason end

    local Actors = require
        "PsychopatzCore/Actors/PsychopatzActors"
    local result
    result, reason = Bootstrap.Commit(
        registry,
        plan,
        spec.actorRegistry or Actors.DefaultRegistry
    )
    if not result then return nil, reason end

    World.RuntimeStore.MarkDirty("survivor_world_bootstrap")
    local saved
    saved, reason = World.RuntimeStore.Save()
    if not saved and reason ~= "not_dirty" then
        return nil, reason
    end
    return registry, "bootstrapped", result
end

Bootstrap.Generation = Generation

return Bootstrap
