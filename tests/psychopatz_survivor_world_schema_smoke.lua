local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
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

local seedA = Types.StableSeed(77, "faction", "faction_fixture")
local seedB = Types.StableSeed(77, "faction", "faction_fixture")
local seedC = Types.StableSeed(78, "faction", "faction_fixture")
equal(seedA, seedB, "deterministic seed parity")
truthy(seedA ~= seedC, "world seed changes derived entity seed")

local pncFixture = {
    factions = {
        byID = {
            faction_fixture = {
                id = "faction_fixture",
                name = "Fixture Survivors",
                archetypeID = "survivor",
                status = "active",
                leaderNPCID = "npc_leader",
                memberIDs = {
                    npc_leader = true,
                    npc_guard = true,
                    npc_trader = true,
                },
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
                        incidents = {
                            { id = "incident_should_not_migrate" },
                        },
                    },
                },
                policy = { aggression = 0.7 },
                provision = { mode = "rich_hydration" },
                needs = { food = 0.3 },
                excursion = { id = "excursion_human_policy" },
                mobile = { combatProfile = { power = 999 } },
            },
        },
    },
    communities = {
        byID = {
            community_fixture = {
                id = "community_fixture",
                factionID = "faction_fixture",
                name = "Fixture Haven",
                mode = "settled",
                status = "active",
                home = { x = 100, y = 200, z = 0, radius = 22 },
                siteID = "community_site_fixture",
                leaderNPCID = "npc_leader",
                memberIDs = {
                    npc_leader = true,
                    npc_guard = true,
                    npc_trader = true,
                },
                capacity = { population = 12, beds = 10, storage = 250 },
                security = 42,
                morale = 0.7,
                supplies = {
                    food = 30, water = 40, ammo = 12,
                    medical = 8, materials = 20, weapons = 4,
                },
                facilities = { workshop = true },
                jobs = { guard = "npc_guard" },
            },
        },
    },
    abstractWorld = {
        revision = 7,
        locationsByID = {
            aloc_fixture = {
                id = "aloc_fixture",
                type = "SETTLEMENT",
                x = 100,
                y = 200,
                z = 0,
                tags = { settlement = true },
                resourcePotential = {
                    food = 10, water = 10, ammo = 3,
                    medical = 2, materials = 5, weapons = 1,
                },
                scavengedLevel = 4,
                danger = 8,
                diagnostics = { ignored = true },
            },
        },
        groupsByID = {
            agroup_fixture = {
                id = "agroup_fixture",
                factionId = "faction_fixture",
                homeCommunityId = "community_fixture",
                groupType = "TRADER",
                memberIds = { "npc_trader", "npc_guard" },
                leaderId = "npc_trader",
                mission = "TRADE",
                state = "TRAVELING",
                location = {
                    id = "aloc_fixture", type = "SETTLEMENT",
                    x = 100, y = 200, z = 0,
                },
                targetLocation = {
                    id = "aloc_target", type = "SETTLEMENT",
                    x = 500, y = 700, z = 0,
                },
                stateStartedAt = 12,
                stateEndsAt = 14,
                missionStartedAt = 11,
                resources = {
                    food = 2, water = 3, ammo = 4,
                    medical = 1, materials = 0, weapons = 2,
                },
                morale = 0.8,
                behaviorProfile = { curiosity = 99 },
                combatProfile = { power = 999 },
                mobileAmbient = true,
                diagnostics = { ignored = true },
                generation = {
                    source = "WORLD_POPULATION_DIRECTOR",
                    generationId = "generation_fixture",
                    sectorId = "psector_fixture",
                    createdAt = 9,
                    seed = 12345,
                },
            },
        },
        population = {
            worldSeed = 12345,
            worldSeedString = "fixture-world",
            nextGenerationSerial = 8,
            bootstrapCompleted = true,
            bootstrapCompletedAt = 5,
            starterSettlementId = "community_fixture",
            sectors = {
                psector_fixture = {
                    id = "psector_fixture",
                    discovered = true,
                    hadGroups = true,
                    hadSettlements = true,
                    groupGenerationCooldownUntil = 40,
                    settlementGenerationCooldownUntil = 50,
                    lastReconciledAt = 6,
                },
            },
        },
    },
    discovery = {
        revision = 3,
        players = {
            ["player:fixture"] = {
                revision = 2,
                entities = {
                    settlement = {
                        community_fixture = {
                            entityID = "community_fixture",
                            kind = "settlement",
                            phase = 3,
                            source = "radio",
                            discoveredAt = 20,
                            updatedAt = 30,
                            x = 100, y = 200, z = 0,
                            arrivalState = "contacted",
                            presenceStatus = "present",
                            factionKnown = true,
                            factionID = "faction_fixture",
                            factionName = "Fixture Survivors",
                        },
                    },
                    mobile_group = {
                        agroup_fixture = {
                            entityID = "agroup_fixture",
                            kind = "mobile_group",
                            phase = 2,
                            source = "visual",
                            discoveredAt = 22,
                            updatedAt = 24,
                            x = 120, y = 220, z = 0,
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
                            x = 150, y = 250, z = 0,
                        },
                    },
                },
            },
        },
    },
}

local before = require("PsychopatzCore/Serialization/PsychopatzJson")
    .Encode(pncFixture)
local snapshot, reason = World.Import.FromPNC(pncFixture)
truthy(snapshot, reason)
equal(require("PsychopatzCore/Serialization/PsychopatzJson")
    .Encode(pncFixture), before, "PNC import is read-only")

local faction = snapshot.factions.faction_fixture
truthy(faction, "faction imported")
equal(faction.leaderActorID, "npc_leader", "faction leader")
equal(#faction.memberActorIDs, 3, "faction members")
equal(faction.policy, nil, "Hoomans policy excluded")
equal(faction.provision, nil, "Hoomans provision excluded")
equal(faction.needs, nil, "Hoomans needs excluded")
equal(faction.excursion, nil, "Hoomans excursion excluded")
equal(faction.relations.faction_rival.incidents, nil,
    "relation incidents excluded")
equal(faction.relations.faction_rival.standing, -45,
    "generic relation standing retained")
equal(faction.relations.faction_rival.trust, -20,
    "generic relation trust retained")

local community = snapshot.communities.community_fixture
truthy(community, "community imported")
equal(community.home.x, 100, "community X")
equal(community.population, 3, "community member population summary")
equal(community.security, 42, "generic community security retained")
equal(community.morale, 0.7, "generic community morale retained")
equal(community.resources.food, 30, "generic community supplies retained")
equal(community.facilities, nil, "Hoomans facilities excluded")
equal(community.jobs, nil, "Hoomans jobs excluded")

local location = snapshot.locations and snapshot.locations.aloc_fixture
truthy(location, "generic abstract location imported")
equal(location.resources.food, 10, "location resource potential retained")
equal(location.danger, 8, "location danger retained")
equal(location.diagnostics, nil, "location diagnostics excluded")

local group = snapshot.groups.agroup_fixture
truthy(group, "group imported")
equal(#group.memberActorIDs, 2, "group members")
equal(group.resources.ammo, 4, "generic group resources retained")
equal(group.morale, 0.8, "generic group morale retained")
equal(group.behaviorProfile, nil, "behavior profile excluded")
equal(group.combatProfile, nil, "combat profile excluded")
equal(group.mobileAmbient, nil, "ambient AI excluded")
equal(group.diagnostics, nil, "diagnostics excluded")
equal(group.generation.generationID, "generation_fixture",
    "generation provenance retained")

local player = snapshot.discovery.players["player:fixture"]
truthy(player, "discovery imported")
equal(player.entities.community.community_fixture.phase, 3,
    "community discovery retained")
equal(player.entities.group.agroup_fixture.phase, 2,
    "group discovery retained")
equal(player.entities.signal.signal_fixture.phase, 1,
    "signal discovery retained")

local registry = assert(World.NewRegistry({ snapshot = snapshot }))
local saved, saveReason = registry:Save()
truthy(saved, saveReason)
local fresh = assert(World.NewRegistry({ worldSeed = 1 }))
truthy(fresh:Load(saved), "survivor world reload")
equal(fresh:GetFaction("faction_fixture").name,
    "Fixture Survivors", "faction reload")
equal(fresh:GetGroup("agroup_fixture").targetLocation.x,
    500, "group target reload")

equal(pncFixture.abstractWorld.groupsByID.agroup_fixture
        .combatProfile.power,
    999, "source fixture remains unchanged")

print("psychopatz_survivor_world_schema_smoke: PASS bytes=" .. #saved)
