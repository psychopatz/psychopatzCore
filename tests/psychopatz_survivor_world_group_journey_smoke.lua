local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal")
            .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function near(actual, expected, tolerance, label)
    if math.abs(actual - expected) > tolerance then
        error((label or "near")
            .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local ActorWorld = require "PsychopatzCore/Actors/PsychopatzActorWorld"
local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"

local registry = assert(World.NewRegistry({ worldSeed = 5150 }))
assert(registry:AddFaction({
    factionID = "faction_journey",
    name = "Journey Fixture",
    archetypeID = "survivor",
}))

local members = {}
for index = 1, 25 do
    members[index] = "actor_group_" .. string.format("%02d", index)
end

assert(registry:AddGroup({
    groupID = "agroup_journey",
    factionID = "faction_journey",
    groupType = "CARAVAN",
    memberActorIDs = members,
    leaderActorID = members[1],
    location = {
        id = "aloc_origin",
        kind = "SETTLEMENT",
        x = 0, y = 0, z = 0,
    },
}))

local started = assert(registry:StartGroupJourney(
    "agroup_journey",
    {
        destination = {
            id = "aloc_destination",
            kind = "SETTLEMENT",
            x = 200, y = 0, z = 0,
        },
        route = {
            { x = 0, y = 0, z = 0 },
            { x = 100, y = 0, z = 0, waitHours = 2 },
            { x = 200, y = 0, z = 0 },
        },
        speed = 10,
        startAt = 0,
    },
    0
))
truthy(started.journey, "group owns journey")
equal(started.journey.groupID, "agroup_journey", "journey group")
equal(#started.journey.route.points, 3, "shared route points")
equal(started.memberActorIDs[25], members[25], "members preserved")

local sharedPosition, sharedSource =
    registry:ProjectGroupMemberPosition(
        "agroup_journey",
        members[2],
        nil,
        5
    )
equal(sharedSource, "group", "normal member uses group route")
near(sharedPosition.x, 50, 0.001, "shared projection X")
near(sharedPosition.y, 0, 0.001, "shared projection Y")

local waitingPosition = assert(
    registry:ProjectGroupPosition("agroup_journey", 11)
)
near(waitingPosition.x, 100, 0.001, "wait holds at waypoint")

local afterWait = assert(
    registry:ProjectGroupPosition("agroup_journey", 13)
)
near(afterWait.x, 110, 0.001, "travel resumes after wait")

local actorWorld = assert(ActorWorld.NewState({
    position = { x = 0, y = 0, z = 0 },
}, members[3], 0))
actorWorld = assert(ActorWorld.StartJourney(
    actorWorld,
    members[3],
    {
        origin = { x = 0, y = 0, z = 0 },
        destination = { x = 0, y = 100, z = 0 },
        speed = 10,
        startAt = 0,
    },
    0
))
local overridePosition, overrideSource =
    registry:ProjectGroupMemberPosition(
        "agroup_journey",
        members[3],
        actorWorld,
        5
    )
equal(overrideSource, "actor_override",
    "separated actor uses actor route")
near(overridePosition.x, 0, 0.001, "override X")
near(overridePosition.y, 50, 0.001, "override Y")

local committed = assert(
    registry:AdvanceGroupJourney("agroup_journey", 13)
)
near(committed.location.x, 110, 0.001, "committed group X")
equal(committed.state, "TRAVELING", "group traveling state")

local saved = assert(registry:Save())
local loaded = assert(World.NewRegistry({ worldSeed = 1 }))
truthy(loaded:Load(saved), "shared journey save/reload")
local loadedGroup = assert(loaded:GetGroup("agroup_journey"))
equal(loadedGroup.journey.journeyID,
    committed.journey.journeyID, "journey ID reload")
near(loadedGroup.location.x, 110, 0.001, "location reload")

local rebased = assert(loaded:RebaseGroupJourney(
    "agroup_journey",
    { x = 111, y = 1, z = 0 },
    13
))
near(rebased.journey.origin.x, 111, 0.001, "rebase origin X")
near(rebased.journey.origin.y, 1, 0.001, "rebase origin Y")
equal(rebased.journey.journeyID,
    committed.journey.journeyID, "rebase keeps journey identity")

local arrived = assert(
    loaded:AdvanceGroupJourney("agroup_journey", 100)
)
equal(arrived.state, "ARRIVED", "arrival group state")
equal(arrived.journey.state, "arrived", "arrival journey state")
near(arrived.location.x, 200, 0.001, "arrival X")
near(arrived.location.y, 0, 0.001, "arrival Y")
equal(arrived.targetLocation, nil, "arrival retires target")

local function footprint(memberCount)
    local ids = {}
    for index = 1, memberCount do
        ids[index] = "actor_size_" .. string.format("%02d", index)
    end
    local journey = assert(World.Traversal.GroupJourney.New(
        "agroup_size",
        {
            origin = { x = 0, y = 0, z = 0 },
            destination = { x = 300, y = 100, z = 0 },
            route = {
                { x = 0, y = 0, z = 0 },
                { x = 100, y = 20, z = 0 },
                { x = 200, y = 70, z = 0 },
                { x = 300, y = 100, z = 0 },
            },
            speed = 12,
        },
        0
    ))
    local group = assert(World.Types.NormalizeGroup({
        id = "agroup_size",
        factionID = "faction_journey",
        groupType = "CARAVAN",
        memberActorIDs = ids,
        location = {
            id = "aloc_size",
            kind = "TEMPORARY",
            x = 0, y = 0, z = 0,
        },
        journey = journey,
    }, 5150, "agroup_size"))
    return #Json.Encode(group), #Json.Encode(group.journey)
end

local sizes = {}
local sharedJourneyBytes
for _, count in ipairs({ 1, 5, 10, 25 }) do
    local bytes, journeyBytes = footprint(count)
    sizes[count] = bytes
    if sharedJourneyBytes == nil then
        sharedJourneyBytes = journeyBytes
    else
        equal(journeyBytes, sharedJourneyBytes,
            "journey bytes independent of member count")
    end
end
truthy(sizes[25] - sizes[1] < 800,
    "25-member growth is member IDs, not route copies")

local plannedJourney = assert(
    World.Traversal.GroupJourney.New(
        "agroup_planned",
        {
            origin = { x = 0, y = 0, z = 0 },
            destination = { x = 100, y = 0, z = 0 },
            speed = 10,
            startAt = 10,
        },
        0
    )
)
local beforeDeparture, plannedAtFive =
    World.Traversal.GroupJourney.ProjectPosition(
        plannedJourney,
        5
    )
near(beforeDeparture.x, 0, 0.001,
    "planned journey does not move before departure")
local afterDeparture = assert(
    World.Traversal.GroupJourney.ProjectPosition(
        plannedAtFive,
        12
    )
)
near(afterDeparture.x, 20, 0.001,
    "planned journey counts only post-departure time")

local tooManyPoints = {}
for index = 1, World.Types.MAX_GROUP_ROUTE_POINTS + 1 do
    tooManyPoints[index] = { x = index, y = 0, z = 0 }
end
local mutationRejected, mutationReason = registry:AddGroup({
    groupID = "agroup_mutation_oversized",
    factionID = "faction_journey",
    memberActorIDs = { members[1] },
    location = { x = 0, y = 0, z = 0 },
    journey = {
        route = { points = tooManyPoints },
    },
})
equal(mutationRejected, nil,
    "mutation rejects oversized route")
equal(mutationReason, "survivor_world_group_route_capacity",
    "mutation oversized route reason")

local oversized = registry:Snapshot()
oversized.groups.agroup_oversized_route = {
    id = "agroup_oversized_route",
    factionID = "faction_journey",
    memberActorIDs = { members[1] },
    location = { x = 0, y = 0, z = 0 },
    journey = {
        route = { points = tooManyPoints },
    },
}
local bounded, boundReason =
    World.Types.ValidateInputBounds(oversized)
equal(bounded, false, "oversized group route rejected")
equal(boundReason, "survivor_world_group_route_capacity",
    "oversized group route reason")

print(string.format(
    "psychopatz_survivor_world_group_journey_smoke: PASS bytes=1:%d 5:%d 10:%d 25:%d journey:%d",
    sizes[1], sizes[5], sizes[10], sizes[25],
    sharedJourneyBytes
))
