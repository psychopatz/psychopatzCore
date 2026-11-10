local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

local Bootstrap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldBootstrap"
local Registry = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRegistry"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"

local function same(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not same(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local request = {
    seedString = "bootstrap-fixture",
    anchor = { x = 8000, y = 9000, z = 0 },
    communityCount = 3,
    groupCount = 3,
    source = "WORLD_POPULATION_BOOTSTRAP",
}

local abstractPlan = assert(Bootstrap.BuildPlan(request))
local hoomansPlan = assert(Bootstrap.BuildPlan({
    seedString = request.seedString,
    anchor = request.anchor,
    communityCount = request.communityCount,
    groupCount = request.groupCount,
    source = request.source,
    adopter = "ProjectHoomans",
}))
assert(same(abstractPlan, hoomansPlan),
    "adopter presence must not change canonical bootstrap plan")

assert(#abstractPlan.communities == 3, "community count")
assert(#abstractPlan.groups == 3, "group count")
assert(abstractPlan.communities[1].factionArchetypeID == "settler",
    "Core bootstrap uses its provider-neutral default archetype")
assert(abstractPlan.groups[1].groupType ~= "CARAVAN",
    "Core bootstrap does not invent a Dynamic Trading caravan")

local traderPlan = assert(Bootstrap.BuildPlan({
    seedString = request.seedString,
    anchor = request.anchor,
    communityCount = request.communityCount,
    groupCount = request.groupCount,
    source = request.source,
    primaryArchetypeID = "DT.trader",
    primaryGroupCount = 2,
    primaryGroupType = "CARAVAN",
    primaryMission = "TRADE",
}))
assert(traderPlan.communities[1].factionArchetypeID == "DT.trader",
    "an adopter may opt into its canonical trader profile")
assert(traderPlan.groups[1].groupType == "CARAVAN"
    and traderPlan.groups[2].groupType == "CARAVAN",
    "an adopter controls its primary caravan groups")
assert(traderPlan.groups[1].factionID
    == traderPlan.communities[1].factionID,
    "adopter caravan shares its requested primary faction")

local world = assert(Registry.new({
    worldSeed = abstractPlan.worldSeed,
}))
local actorRegistry = Actors.NewRegistry()
local result, reason = Bootstrap.Commit(
    world,
    abstractPlan,
    actorRegistry
)
assert(result, reason)
local counts = world:Counts()
assert(counts.communities == 3, "committed communities")
assert(counts.groups == 3, "committed groups")
assert(counts.locations >= 3, "committed locations")
assert(counts.factions >= 3, "committed factions")

local primary = abstractPlan.groups[1]
local group = assert(world:GetGroup(primary.groupID))
assert(group.homeCommunityID
    == abstractPlan.communities[1].communityID,
    "group home community")
assert(#group.memberActorIDs == #primary.memberActorIDs,
    "group membership")

for _, actorID in ipairs(primary.memberActorIDs) do
    local actor = assert(actorRegistry:Get(actorID),
        "bootstrap actor missing " .. actorID)
    assert(actor.personalInventory
        and actor.personalInventory.mode == "SEED_ONLY",
        "untouched abstract actor must remain SEED_ONLY")
    local affiliation = actor.extensions
        and actor.extensions[Bootstrap.AFFILIATION_EXTENSION]
    assert(affiliation and affiliation.groupID == primary.groupID,
        "actor group affiliation extension")
end

local population = world:GetPopulation()
assert(population.bootstrapCompleted == true,
    "bootstrap completion flag")
assert(population.starterCommunityID
    == abstractPlan.communities[1].communityID,
    "starter community")

local replay = assert(Registry.new({
    worldSeed = abstractPlan.worldSeed,
}))
local replayActors = Actors.NewRegistry()
assert(Bootstrap.Commit(replay, hoomansPlan, replayActors))
assert(same(world:Snapshot(), replay:Snapshot()),
    "same plan must commit byte-equivalent canonical world")

local incremental = assert(Registry.new({
    worldSeed = abstractPlan.worldSeed,
}))
local incrementalActors = Actors.NewRegistry()
local incrementalCommunity = assert(Bootstrap.CommitCommunityPlan(
    incremental,
    assert(abstractPlan.communities[1]),
    incrementalActors
))
assert(incrementalCommunity.id == abstractPlan.communities[1].communityID,
    "incremental community commit identity")
assert(incremental:Counts().communities == 1,
    "incremental community commit count")
assert(incrementalActors:Get(abstractPlan.communities[1].leaderActorID),
    "incremental community actor")

print("psychopatz_survivor_world_bootstrap_smoke: PASS")
