local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.layerRoot("common_shared")
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

local registry = assert(World.NewRegistry({ worldSeed = 424242 }))
equal(registry:WorldSeed(), 424242, "world seed")

local faction = assert(registry:UpsertFaction({
    id = "faction_alpha",
    name = "Alpha Cooperative",
    archetypeID = "community",
    leaderActorID = "actor_alex",
    memberActorIDs = {
        "actor_alex", "actor_ben", "actor_alex",
    },
}))
equal(#faction.memberActorIDs, 2, "faction member dedupe")
truthy(faction.seed > 0, "deterministic faction seed")

local sameSeedRegistry = assert(World.NewRegistry({ worldSeed = 424242 }))
local sameFaction = assert(sameSeedRegistry:UpsertFaction({
    id = "faction_alpha",
    name = "Alpha Cooperative",
    archetypeID = "community",
}))
equal(sameFaction.seed, faction.seed, "same world deterministic seed")

local statusRegistry = assert(World.NewRegistry({ worldSeed = 424242 }))
local inactiveFaction = assert(statusRegistry:UpsertFaction({
    id = "faction_inactive",
    name = "Inactive Faction",
    archetypeID = "community",
    status = "inactive",
}))
equal(inactiveFaction.status, "inactive",
    "inactive faction status must survive Core normalization")

local community = assert(registry:UpsertCommunity({
    id = "community_alpha",
    factionID = "faction_alpha",
    name = "Cedar Haven",
    mode = "settled",
    status = "active",
    home = { x = 1200, y = 2400, z = 0, radius = 42 },
    leaderActorID = "actor_alex",
    memberActorIDs = { "actor_alex", "actor_ben" },
}))
equal(community.home.radius, 42, "community home radius")
equal(community.population, 2, "community population default")

local group = assert(registry:UpsertGroup({
    id = "agroup_alpha",
    factionID = "faction_alpha",
    homeCommunityID = "community_alpha",
    groupType = "CARAVAN",
    memberActorIDs = { "actor_alex", "actor_ben" },
    leaderActorID = "actor_alex",
    mission = "TRADE",
    state = "TRAVELING",
    location = {
        id = "aloc_origin", type = "SETTLEMENT",
        x = 1200, y = 2400, z = 0,
    },
    targetLocation = {
        id = "aloc_target", type = "SETTLEMENT",
        x = 3600, y = 4100, z = 0,
    },
}))
equal(group.targetLocation.id, "aloc_target", "group target")
equal(#group.memberActorIDs, 2, "group member count")

local tooManyMembers = {}
for index = 1, World.Types.MAX_GROUP_MEMBERS + 1 do
    tooManyMembers[index] = "actor_overflow_" .. tostring(index)
end
local oversizedGroup, oversizedReason = registry:UpsertGroup({
    id = "agroup_oversized",
    factionID = "faction_alpha",
    groupType = "CARAVAN",
    memberActorIDs = tooManyMembers,
    location = { x = 1, y = 1, z = 0 },
})
equal(oversizedGroup, nil, "oversized group rejected")
equal(oversizedReason, "survivor_world_group_member_capacity",
    "oversized group reason")

local missingCommunity, missingReason = registry:UpsertCommunity({
    id = "community_orphan",
    factionID = "faction_missing",
    name = "Orphan",
    home = { x = 1, y = 2, z = 0 },
})
equal(missingCommunity, nil, "missing-faction community rejected")
equal(missingReason, "survivor_world_community_faction_missing",
    "missing-faction community reason")

local population = registry:SetPopulation({
    worldSeed = 999999,
    worldSeedString = "fixture-world",
    nextGenerationSerial = 8,
    bootstrapCompleted = true,
    starterSettlementId = "community_alpha",
    sectors = {
        psector_0_0 = {
            discovered = true,
            hadGroups = true,
            hadSettlements = true,
            groupGenerationCooldownUntil = 12,
            settlementGenerationCooldownUntil = 24,
            lastReconciledAt = 6,
        },
    },
})
equal(population.worldSeed, 424242, "registry world seed authority")
truthy(population.sectors.psector_0_0.hadCommunities,
    "settlement sector maps to community")

registry:SetDiscovery({
    revision = 3,
    players = {
        player_fixture = {
            revision = 2,
            entities = {
                community = {
                    community_alpha = {
                        phase = 3,
                        source = "visit",
                        x = 1200, y = 2400, z = 0,
                    },
                },
                group = {
                    agroup_alpha = {
                        phase = 2,
                        source = "radio",
                        x = 1800, y = 2800, z = 0,
                    },
                },
                signal = {
                    signal_event_1 = {
                        phase = 1,
                        source = "radio",
                        x = 2000, y = 3000, z = 0,
                    },
                },
            },
        },
    },
})
local discovery = registry:GetDiscovery()
equal(discovery.players.player_fixture.entities.signal
    .signal_event_1.kind, "signal", "signal discovery kind")

local counts = registry:Counts()
equal(counts.factions, 1, "faction count")
equal(counts.communities, 1, "community count")
equal(counts.groups, 1, "group count")
equal(counts.sectors, 1, "sector count")
equal(counts.discoveryPlayers, 1, "discovery player count")

-- O(1) actor-to-group reverse index
equal(registry:GetGroupIDForActor("actor_alex"), "agroup_alpha",
    "actor_alex group ID lookup")
equal(registry:GetGroupIDForActor("actor_ben"), "agroup_alpha",
    "actor_ben group ID lookup")
equal(registry:GetGroupIDForActor("actor_missing"), nil,
    "missing actor group ID lookup")
local alexGroup = assert(registry:GetGroupForActor("actor_alex"))
equal(alexGroup.id, "agroup_alpha", "GetGroupForActor returns group")

-- Active group journey round-trip + compact persistence verification
assert(registry:StartGroupJourney("agroup_alpha", {
    origin = { x = 1200, y = 2400, z = 0 },
    destination = { x = 3600, y = 4100, z = 0 },
    route = {
        { x = 1200, y = 2400, z = 0 },
        { x = 2400, y = 3200, z = 0, waitHours = 1.5, tag = "rest" },
        { x = 3600, y = 4100, z = 0 },
    },
    speed = 12,
    startAt = 10,
}, 10))
assert(registry:AdvanceGroupJourney("agroup_alpha", 15))

local expandedBytes = #Json.Encode(registry:Snapshot())
local saved = assert(registry:Save())
truthy(#saved > 100, "serialized survivor world")
truthy(#saved < expandedBytes,
    "compact persistence must be smaller than expanded snapshot ("
        .. tostring(#saved) .. " vs " .. tostring(expandedBytes) .. ")")
local reloaded = assert(World.NewRegistry({ worldSeed = 1 }))
truthy(reloaded:Load(saved), "survivor world reload")
equal(Json.Encode(reloaded:Snapshot()),
    Json.Encode(World.Types.NormalizeSnapshot(registry:Snapshot())),
    "save/load parity")
equal(reloaded:Save(), saved, "compact save idempotence")
equal(reloaded:GetGroupIDForActor("actor_ben"), "agroup_alpha",
    "reloaded actor-group index")

-- Removing a group updates O(1) counts and actor-group index
assert(registry:RemoveGroup("agroup_alpha"))
equal(registry:Counts().groups, 0, "group count after removal")
equal(registry:GetGroupIDForActor("actor_alex"), nil,
    "actor-group index cleared after group removal")

truthy(registry:Validate(), "registry validation")
equal(package.loaded["PNC/Core/Director/PNC_AbstractWorldTypes"], nil,
    "Core world does not import Hoomans abstract world")
equal(package.loaded["DTCommon/DTCommon_TraderWorld"], nil,
    "Core world does not import DynamicTrading")

print("psychopatz_survivor_world_registry_smoke: PASS compact="
    .. tostring(#saved) .. " expanded=" .. tostring(expandedBytes))
