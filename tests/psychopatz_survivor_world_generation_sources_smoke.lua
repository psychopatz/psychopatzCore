local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

local SurvivorWorld = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Generation = SurvivorWorld.Generation
local Sources = Generation.Sources

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

Sources.ResetForTests()
truthy(Sources.Register("fixture:trader", {
    generationKind = "group",
    maxCommitted = 1,
    cooldownHours = 4,
    defaults = {
        groupType = "CARAVAN",
        initialMission = "TRADE",
        sectorID = "psector_0_0",
        locationID = "location_fixture_trader",
        location = { x = 333, y = 444, z = 0 },
        memberCount = 2,
    },
}), "register group source")

local registry = SurvivorWorld.NewRegistry({
    worldSeed = 424242,
})
local actorRegistry = Actors.NewRegistry()

local group, status, plan = Generation.GenerateGroup(
    registry,
    actorRegistry,
    "fixture:trader",
    {
        idempotencyKey = "caravan:first",
        createdAt = 10,
        factionArchetypeID = "trader",
        memberSpecs = {
            { presetID = "fixture.leader", role = "leader" },
            { presetID = "fixture.member", role = "guard" },
        },
    }
)
assert(group, status)
equal(status, "committed", "first source request commits")
equal(plan.source, "fixture:trader", "source is canonicalized")
equal(plan.requestKey, "caravan:first", "request key persisted in plan")
equal(#group.memberActorIDs, 2, "source default member count")
equal(actorRegistry:Count(), 2, "canonical actors created once")

local repeated, repeatedStatus = Generation.GenerateGroup(
    registry,
    actorRegistry,
    "fixture:trader",
    {
        idempotencyKey = "caravan:first",
        createdAt = 10,
        factionArchetypeID = "trader",
        memberSpecs = {
            { presetID = "fixture.leader", role = "leader" },
            { presetID = "fixture.member", role = "guard" },
        },
    }
)
truthy(repeated, "repeated source request returns canonical group")
equal(repeated.id, group.id, "repeated request keeps group identity")
equal(repeatedStatus, "already_committed",
    "repeated request is idempotent")
equal(actorRegistry:Count(), 2,
    "repeated request does not create actors")

local conflicting, conflictingReason = Generation.GenerateGroup(
    registry,
    actorRegistry,
    "fixture:trader",
    {
        idempotencyKey = "caravan:first",
        createdAt = 10,
        memberCount = 3,
    }
)
equal(conflicting, nil, "idempotency key cannot change payload")
equal(conflictingReason, "generation_request_key_conflict",
    "idempotency conflict reason")

truthy(Sources.Register("fixture:cooldown", {
    generationKind = "group",
    cooldownHours = 4,
    defaults = {
        sectorID = "psector_0_0",
        locationID = "location_fixture_cooldown",
        location = { x = 10, y = 20, z = 0 },
        memberCount = 1,
    },
}), "register cooldown source")
local cooldownGroup = assert(Generation.GenerateGroup(
    registry,
    actorRegistry,
    "fixture:cooldown",
    { idempotencyKey = "cooldown:first", createdAt = 30 }
))
truthy(cooldownGroup, "cooldown source first request commits")
local throttled, throttledReason = Generation.GenerateGroup(
    registry,
    actorRegistry,
    "fixture:cooldown",
    { idempotencyKey = "cooldown:second", createdAt = 32 }
)
equal(throttled, nil, "source cooldown rejects early request")
equal(throttledReason, "generation_source_cooldown",
    "source cooldown reason")

local capped, cappedReason = Generation.GenerateGroup(
    registry,
    actorRegistry,
    "fixture:trader",
    {
        idempotencyKey = "caravan:second",
        createdAt = 15,
    }
)
equal(capped, nil, "source cap rejects second group")
equal(cappedReason, "generation_source_cap_reached",
    "source cap reason")

truthy(Sources.Register("fixture:disabled", {
    generationKind = "group",
    enabled = false,
    defaults = {
        locationID = "location_fixture_disabled",
        location = { x = 1, y = 2, z = 0 },
    },
}), "register disabled source")
local disabled, disabledReason = Generation.GenerateGroup(
    registry,
    actorRegistry,
    "fixture:disabled",
    { idempotencyKey = "disabled:first" }
)
equal(disabled, nil, "disabled source does not generate")
equal(disabledReason, "generation_source_disabled",
    "disabled source reason")

truthy(Sources.Register("fixture:community", {
    generationKind = "community",
    defaults = {
        sectorID = "psector_0_0",
        locationID = "location_fixture_community",
        location = { x = 555, y = 666, z = 0 },
        factionArchetypeID = "settler",
        initialPopulation = 2,
    },
}), "register community source")
local community, communityStatus = Generation.GenerateCommunity(
    registry,
    actorRegistry,
    "fixture:community",
    { idempotencyKey = "community:first", createdAt = 20 }
)
assert(community, communityStatus)
equal(communityStatus, "committed", "community source commits")
equal(actorRegistry:Count(), 5,
    "community source creates canonical actors")

truthy(Sources.SetEnabled("fixture:disabled", true),
    "source activation toggles centrally")
truthy(Sources.SetEnabled("fixture:disabled", false),
    "source can be disabled again")
truthy(Sources.Unregister("fixture:disabled"),
    "source unregisters without touching canonical data")
truthy(registry:GetGroup(group.id),
    "unregister does not remove canonical group")
truthy(registry:GetCommunity(community.id),
    "unregister does not remove canonical community")

Sources.ResetForTests()
print("psychopatz_survivor_world_generation_sources_smoke: PASS")
