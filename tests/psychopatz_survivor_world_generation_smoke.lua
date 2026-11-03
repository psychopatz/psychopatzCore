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
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
local Generation = World.Generation

local seedA = Generation.ResolveWorldSeed({
    seedString = "survivor-world-fixture",
})
local seedB = Generation.ResolveWorldSeed({
    seedString = "survivor-world-fixture",
})
equal(seedA, seedB, "world seed deterministic")
truthy(seedA > 0, "world seed positive")

-- Lock generic deterministic outputs to the current serialization-safe PNC
-- generation behavior that is being migrated into Core.
equal(Generation.GenerationSeed(
    123, "GROUP", "psector_1_2", 7, "fixture"),
    1945112353, "PNC-compatible generation seed")
equal(Generation.Profiles.FactionName("settler", 12345),
    "Clearwater Enclave", "settler faction-name parity")
equal(Generation.Profiles.FactionName("looter", 12345),
    "The Broken Fangs", "looter faction-name parity")
equal(Generation.Profiles.FactionName("trader", 12345),
    "Riverside Exchange Caravan", "trader faction-name parity")
equal(Generation.Profiles.FactionName("refugee", 12345),
    "Hope Collective", "refugee faction-name parity")
equal(Generation.Profiles.CommunityName(
    "looter", "The Broken Fangs", 12345),
    "Broken Fangs Hold", "community-name parity")

local sectorID, sx, sy = Generation.SectorID(2450, -150, 1000)
equal(sectorID, "psector_2_-1", "sector id")
equal(sx, 2, "sector x")
equal(sy, -1, "sector y")
local center = assert(Generation.SectorCenter(sectorID, 1000))
equal(center.x, 2500, "sector center x")
equal(center.y, -500, "sector center y")

local communityRequest = {
    worldSeed = seedA,
    sectorID = sectorID,
    serial = 7,
    source = "fixture",
    locationID = "aloc_generation_community",
    location = { x = 2400, y = -100, z = 0 },
}
local communityA = assert(
    Generation.BuildCommunityPlan(communityRequest))
local communityB = assert(
    Generation.BuildCommunityPlan(communityRequest))
equal(Json.Encode(communityA), Json.Encode(communityB),
    "community plan deterministic")
truthy(communityA.factionID:match("^faction_"),
    "community faction id prefix")
truthy(communityA.communityID:match("^community_"),
    "community id prefix")
equal(#communityA.memberActorIDs,
    communityA.initialPopulation, "community actor plan count")
equal(communityA.leaderActorID,
    communityA.memberActorIDs[1], "community leader actor")

local groupRequest = {
    worldSeed = seedA,
    sectorID = sectorID,
    serial = 11,
    source = "fixture",
    locationID = "aloc_generation_group",
    location = { x = 2600, y = -300, z = 0 },
}
local groupA = assert(Generation.BuildGroupPlan(groupRequest))
local groupB = assert(Generation.BuildGroupPlan(groupRequest))
equal(Json.Encode(groupA), Json.Encode(groupB),
    "group plan deterministic")
truthy(groupA.groupID:match("^agroup_"),
    "group id prefix")
equal(#groupA.memberActorIDs, groupA.memberCount,
    "group actor plan count")
equal(groupA.leaderActorID, groupA.memberActorIDs[1],
    "group leader actor")
for _, actorID in ipairs(groupA.memberActorIDs) do
    truthy(actorID:match("^npc_"), "actor id prefix")
end

local canonicalBefore = Json.Encode(groupA)
truthy(Generation.Policies.Register("fixture.policy", {
    BuildExtension = function(plan)
        return {
            equipmentProfile = "physical-only",
            observedGroupID = plan.groupID,
        }
    end,
}), "register generation policy")
local extensions = Generation.BuildPolicyExtensions(
    groupA,
    { provider = "Hoomans" })
equal(extensions["fixture.policy"].equipmentProfile,
    "physical-only", "policy extension value")
equal(extensions["fixture.policy"].observedGroupID,
    groupA.groupID, "policy receives canonical plan")
equal(Json.Encode(groupA), canonicalBefore,
    "policy cannot mutate canonical plan")
local groupAfterPolicy = assert(
    Generation.BuildGroupPlan(groupRequest))
equal(Json.Encode(groupAfterPolicy), canonicalBefore,
    "registered adopter policy does not change canonical plan")
truthy(Generation.Policies.Unregister("fixture.policy"),
    "unregister generation policy")

for index = 1, Generation.MAX_POLICIES do
    truthy(Generation.Policies.Register(
        "capacity.policy." .. tostring(index),
        { BuildExtension = function() return { ok = true } end }
    ), "register bounded policy " .. tostring(index))
end
local policyOverflow, policyOverflowReason =
    Generation.Policies.Register("capacity.policy.overflow", {
        BuildExtension = function() return { ok = true } end,
    })
equal(policyOverflow, false, "policy capacity rejects overflow")
equal(policyOverflowReason, "generation_policy_capacity",
    "policy capacity reason")
for index = 1, Generation.MAX_POLICIES do
    Generation.Policies.Unregister(
        "capacity.policy." .. tostring(index))
end

for _, forbidden in ipairs({
    "equipment", "facilities", "jobs", "combatProfile",
    "behaviorProfile", "body", "ai", "needs",
}) do
    equal(groupA[forbidden], nil,
        "group plan excludes " .. forbidden)
    equal(communityA[forbidden], nil,
        "community plan excludes " .. forbidden)
end

equal(package.loaded["PNC/Core/Factions/PNC_FactionNameGenerator"], nil,
    "generation does not import PNC")
equal(package.loaded["DTCommon/DTCommon_TraderWorld"], nil,
    "generation does not import DynamicTrading")

print("psychopatz_survivor_world_generation_smoke: PASS")
