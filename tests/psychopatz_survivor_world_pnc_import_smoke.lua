local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal")
            .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"

local source = {
    factions = {
        byID = {
            faction_rose = {
                id = "faction_rose",
                name = "Rose Compact",
                archetypeID = "community",
                status = "active",
                leaderNPCID = "npc_rose_leader",
                memberIDs = {
                    npc_rose_leader = true,
                    npc_rose_guard = true,
                },
                tags = { alignment = "neutral" },
                revision = 4,
            },
        },
    },
    communities = {
        byID = {
            community_rose = {
                id = "community_rose",
                factionID = "faction_rose",
                name = "Rose Camp",
                mode = "settled",
                status = "active",
                home = { x = 4000, y = 5000, z = 0, radius = 30 },
                leaderNPCID = "npc_rose_leader",
                memberIDs = {
                    npc_rose_leader = true,
                    npc_rose_guard = true,
                },
                capacity = { population = 12 },
                revision = 3,
            },
        },
    },
    abstractWorld = {
        revision = 8,
        groupsByID = {
            agroup_rose = {
                id = "agroup_rose",
                factionId = "faction_rose",
                homeCommunityId = "community_rose",
                groupType = "CARAVAN",
                memberIds = {
                    "npc_rose_leader",
                    "npc_rose_guard",
                },
                leaderId = "npc_rose_leader",
                mission = "TRAVEL",
                state = "TRAVELING",
                location = {
                    id = "aloc_rose",
                    type = "SETTLEMENT",
                    x = 4000, y = 5000, z = 0,
                },
                targetLocation = {
                    id = "aloc_trade",
                    type = "TEMPORARY",
                    x = 5000, y = 6000, z = 0,
                },
                revision = 6,
            },
        },
        population = {
            worldSeed = 123456,
            worldSeedString = "pnc-fixture",
            nextGenerationSerial = 11,
            bootstrapCompleted = true,
            starterSettlementId = "community_rose",
            sectors = {
                psector_1_2 = {
                    discovered = true,
                    hadGroups = true,
                    hadSettlements = true,
                    lastReconciledAt = 24,
                },
            },
        },
    },
    discovery = {
        revision = 2,
        players = {
            player_fixture = {
                revision = 1,
                lastRadioScanAt = 12,
                radioScanCount = 2,
                entities = {
                    settlement = {
                        community_rose = {
                            phase = 3,
                            source = "visit",
                            x = 4000, y = 5000, z = 0,
                        },
                    },
                    mobile_group = {
                        agroup_rose = {
                            phase = 2,
                            source = "radio",
                            x = 4500, y = 5500, z = 0,
                        },
                    },
                    signal = {
                        signal_fixture = {
                            phase = 1,
                            source = "radio",
                            x = 4600, y = 5600, z = 0,
                        },
                    },
                },
            },
        },
    },
}

local before = Json.Encode(source)
local snapshot, reason = World.Import.FromPNC(source)
truthy(snapshot, reason)
equal(Json.Encode(source), before, "import is read-only")
equal(snapshot.worldSeed, 123456, "world seed imported")

local faction = snapshot.factions.faction_rose
truthy(faction, "faction imported")
equal(faction.name, "Rose Compact", "faction name")
equal(faction.leaderActorID, "npc_rose_leader", "leader mapped")
equal(#faction.memberActorIDs, 2, "faction members mapped")

local community = snapshot.communities.community_rose
truthy(community, "community imported")
equal(community.factionID, "faction_rose", "community faction")
equal(community.home.x, 4000, "community home")
equal(community.population, 2, "community member population summary")

local group = snapshot.groups.agroup_rose
truthy(group, "group imported")
equal(group.factionID, "faction_rose", "group faction")
equal(group.homeCommunityID, "community_rose", "group home")
equal(group.location.id, "aloc_rose", "group location")
equal(group.targetLocation.id, "aloc_trade", "group target")
equal(#group.memberActorIDs, 2, "group members")

truthy(snapshot.population.sectors.psector_1_2.hadCommunities,
    "PNC settlement sector maps to generic community")
equal(snapshot.population.starterCommunityID,
    "community_rose", "starter community mapped")

local player = snapshot.discovery.players.player_fixture
truthy(player, "player discovery imported")
truthy(player.entities.community.community_rose,
    "settlement discovery mapped to community")
truthy(player.entities.group.agroup_rose,
    "mobile-group discovery mapped to group")
truthy(player.entities.signal.signal_fixture,
    "signal discovery preserved")

-- Hoomans-only policy/runtime fields do not leak into Core generic records.
equal(faction.policy, nil, "faction policy excluded")
equal(community.supplies, nil, "community supplies excluded")
equal(group.combatProfile, nil, "group combat profile excluded")
equal(group.behaviorProfile, nil, "group behavior profile excluded")

local registry = assert(World.NewRegistry({ snapshot = snapshot }))
truthy(registry:Validate(), "imported registry validates")
local saved = assert(registry:Save())
local reloaded = assert(World.NewRegistry({ worldSeed = 0 }))
truthy(reloaded:Load(saved), "imported world round-trip")
equal(Json.Encode(reloaded:Snapshot()),
    Json.Encode(snapshot), "imported world persistence parity")

equal(package.loaded["PNC/Core/Factions/PNC_FactionTypes"], nil,
    "import adapter does not require PNC")
equal(package.loaded["DTCommon/DTCommon_TraderWorld"], nil,
    "import adapter does not require DynamicTrading")

print("psychopatz_survivor_world_pnc_import_smoke: PASS")
