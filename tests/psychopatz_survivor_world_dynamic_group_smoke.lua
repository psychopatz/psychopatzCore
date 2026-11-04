local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

local SurvivorWorld = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"

local registry = SurvivorWorld.NewRegistry({
    worldSeed = 424242,
})
local actorRegistry = Actors.NewRegistry()

local faction = assert(registry:UpsertFaction({
    id = "faction:dynamic:test",
    seed = 7,
    name = "Road Traders",
    archetypeID = "trader",
    status = "active",
}))
local community = assert(registry:UpsertCommunity({
    id = "community:dynamic:test",
    seed = 8,
    factionID = faction.id,
    name = "Road Camp",
    mode = "settled",
    status = "active",
    home = {
        x = 100,
        y = 200,
        z = 0,
        radius = 24,
    },
    memberActorIDs = {},
    population = 0,
}))

local plan, reason =
    SurvivorWorld.Generation.BuildGroupPlan({
        worldSeed = registry:WorldSeed(),
        sectorID = "psector_1_1",
        serial = 100001,
        source = "TEST_DYNAMIC_GROUP",
        locationID = "location_dynamic_test",
        location = { x = 333, y = 444, z = 0 },
        locationKind = "temporary",
        factionID = faction.id,
        factionName = faction.name,
        factionArchetypeID = faction.archetypeID,
        groupType = "CARAVAN",
        initialMission = "TRADE",
        memberCount = 3,
    })
assert(plan, reason)
plan.homeCommunityID = community.id

local group
group, reason = SurvivorWorld.Bootstrap.CommitGroupPlan(
    registry,
    plan,
    actorRegistry
)
assert(group, reason)
assert(group.id == plan.groupID,
    "committed group identity changed")
assert(group.homeCommunityID == community.id,
    "committed group lost canonical home community")
assert(group.location.x == 333 and group.location.y == 444,
    "committed group lost requested canonical location")
assert(#group.memberActorIDs == 3,
    "committed group member count changed")
assert(actorRegistry:Count() == 3,
    "generated group did not create canonical actors")
assert(actorRegistry:Get(group.leaderActorID),
    "generated leader actor missing")
assert(registry:GetLocation("location_dynamic_test"),
    "generated group location was not committed")

local leader = actorRegistry:Get(group.leaderActorID)
local affiliation = leader.extensions
    and leader.extensions[
        SurvivorWorld.Bootstrap.AFFILIATION_EXTENSION
    ] or nil
assert(affiliation and affiliation.groupID == group.id,
    "generated actor lost canonical group affiliation")
assert(affiliation.communityID == nil,
    "mobile-group actor unexpectedly became a resident-community member")

print("psychopatz_survivor_world_dynamic_group_smoke: PASS")
