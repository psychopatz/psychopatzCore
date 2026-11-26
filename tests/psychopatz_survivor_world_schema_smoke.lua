local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.layerRoot("common_shared")
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

PNC = nil

local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Types = World.Types

equal(World.Import, nil, "retired SurvivorWorld.Import must be absent")

local seedA = Types.StableSeed(77, "faction", "faction_fixture")
local seedB = Types.StableSeed(77, "faction", "faction_fixture")
local seedC = Types.StableSeed(78, "faction", "faction_fixture")
equal(seedA, seedB, "deterministic seed parity")
truthy(seedA ~= seedC, "world seed changes derived entity seed")

local registry = assert(World.NewRegistry({ worldSeed = 12345 }))

local faction = assert(registry:UpsertFaction({
    id = "faction_fixture",
    name = "Fixture Survivors",
    archetypeID = "survivor",
    status = "active",
    leaderActorID = "npc_leader",
    memberActorIDs = { "npc_leader", "npc_guard", "npc_trader" },
    tags = { trader = true, region = "south" },
    relations = {
        faction_rival = {
            targetFactionID = "faction_rival",
            standing = -45,
            trust = -20,
            fear = 15,
            grievance = 32,
            state = "hostile",
            atWar = false,
            allied = false,
        },
    },
}))
truthy(faction, "canonical faction created")
equal(faction.leaderActorID, "npc_leader", "faction leader")
equal(#faction.memberActorIDs, 3, "faction members")
equal(faction.relations.faction_rival.standing, -45, "relation standing retained")
equal(faction.relations.faction_rival.trust, -20, "relation trust retained")

assert(registry:UpsertFaction({
    id = "faction_rival",
    name = "Fixture Rivals",
    archetypeID = "looter",
}))

local community = assert(registry:UpsertCommunity({
    id = "community_fixture",
    factionID = "faction_fixture",
    name = "Fixture Haven",
    mode = "settled",
    status = "active",
    home = { x = 100, y = 200, z = 0, radius = 22 },
    siteID = "community_site_fixture",
    leaderActorID = "npc_leader",
    memberActorIDs = { "npc_leader", "npc_guard", "npc_trader" },
    security = 42,
    morale = 0.7,
    resources = {
        food = 30,
        water = 40,
        ammo = 12,
        medical = 8,
        materials = 20,
        weapons = 4,
    },
}))
truthy(community, "canonical community created")
equal(community.home.x, 100, "community X")
equal(community.population, 3, "community member population summary")
equal(community.security, 42, "generic community security retained")
equal(community.resources.food, 30, "generic community resources retained")
equal(community.resources.ammo, 12, "generic ammo retained")
equal(community.resources.medical, 8, "generic medical retained")

local location = assert(registry:UpsertLocation({
    id = "aloc_fixture",
    kind = "SETTLEMENT",
    x = 100,
    y = 200,
    z = 0,
    tags = { settlement = true },
    resources = {
        food = 10,
        water = 10,
        ammo = 3,
        medical = 2,
        materials = 5,
        weapons = 1,
    },
    scavengedLevel = 4,
    danger = 8,
}))
truthy(location, "canonical abstract location created")
equal(location.resources.food, 10, "location resource potential retained")
equal(location.danger, 8, "location danger retained")

local group = assert(registry:UpsertGroup({
    id = "agroup_fixture",
    factionID = "faction_fixture",
    homeCommunityID = "community_fixture",
    groupType = "TRADER",
    memberActorIDs = { "npc_trader", "npc_guard" },
    leaderActorID = "npc_trader",
    mission = "TRADE",
    state = "TRAVELING",
    location = {
        id = "aloc_fixture",
        kind = "SETTLEMENT",
        x = 100,
        y = 200,
        z = 0,
    },
    targetLocation = {
        id = "aloc_target",
        kind = "SETTLEMENT",
        x = 500,
        y = 700,
        z = 0,
    },
    resources = {
        food = 2,
        water = 3,
        ammo = 4,
        medical = 1,
        materials = 0,
        weapons = 2,
    },
    morale = 0.8,
    generation = {
        source = "WORLD_POPULATION_DIRECTOR",
        generationID = "generation_fixture",
        sectorID = "psector_fixture",
        createdAt = 9,
        seed = 12345,
    },
}))
truthy(group, "canonical group created")
equal(#group.memberActorIDs, 2, "group members")
equal(group.resources.ammo, 4, "generic group resources retained")
equal(group.morale, 0.8, "generic group morale retained")
equal(group.generation.generationID, "generation_fixture",
    "generation provenance retained")

assert(registry:SetDiscovery({
    revision = 3,
    players = {
        ["player:fixture"] = {
            revision = 2,
            entities = {
                community = {
                    community_fixture = {
                        entityID = "community_fixture",
                        kind = "community",
                        phase = 3,
                        source = "radio",
                        discoveredAt = 20,
                        updatedAt = 30,
                        x = 100,
                        y = 200,
                        z = 0,
                        arrivalState = "contacted",
                        presenceStatus = "present",
                        factionKnown = true,
                        factionID = "faction_fixture",
                        factionName = "Fixture Survivors",
                    },
                },
                group = {
                    agroup_fixture = {
                        entityID = "agroup_fixture",
                        kind = "group",
                        phase = 2,
                        source = "visual",
                        discoveredAt = 22,
                        updatedAt = 24,
                        x = 120,
                        y = 220,
                        z = 0,
                        arrivalState = "unchecked",
                        presenceStatus = "present",
                        factionKnown = false,
                    },
                },
                signal = {
                    signal_fixture = {
                        entityID = "signal_fixture",
                        kind = "signal",
                        phase = 1,
                        source = "radio",
                        x = 150,
                        y = 250,
                        z = 0,
                    },
                },
            },
        },
    },
}))

local saved, saveReason = registry:Save()
truthy(saved, saveReason)
local fresh = assert(World.NewRegistry({ worldSeed = 1 }))
truthy(fresh:Load(saved), "survivor world reload")
equal(fresh:WorldSeed(), 12345, "world seed reload")
equal(fresh:GetFaction("faction_fixture").name,
    "Fixture Survivors", "faction reload")
equal(fresh:GetFaction("faction_fixture").leaderActorID,
    "npc_leader", "faction leader reload")
equal(fresh:GetCommunity("community_fixture").resources.food,
    30, "community resources reload")
equal(fresh:GetLocation("aloc_fixture").danger,
    8, "location danger reload")
local reloadedGroup = assert(fresh:GetGroup("agroup_fixture"))
equal(reloadedGroup.targetLocation.x, 500, "group target reload")
equal(reloadedGroup.resources.ammo, 4, "group resources reload")
equal(reloadedGroup.generation.generationID, "generation_fixture",
    "group generation provenance reload")

local reloadedDiscovery = fresh:GetDiscovery().players["player:fixture"]
truthy(reloadedDiscovery, "discovery reload")
equal(reloadedDiscovery.entities.community.community_fixture.phase, 3,
    "community discovery reload")
equal(reloadedDiscovery.entities.group.agroup_fixture.phase, 2,
    "group discovery reload")
equal(reloadedDiscovery.entities.signal.signal_fixture.phase, 1,
    "signal discovery reload")

print("psychopatz_survivor_world_schema_smoke: PASS bytes=" .. #saved)
