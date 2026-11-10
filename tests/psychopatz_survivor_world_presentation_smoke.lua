local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"

local plan = assert(World.Bootstrap.BuildPlan({
    seedString = "presentation-fixture",
    anchor = { x = 1000, y = 2000, z = 0 },
    communityCount = 3,
    groupCount = 3,
    traderGroupCount = 2,
}))
local registry = assert(World.NewRegistry({
    worldSeed = plan.worldSeed,
}))
local actors = Actors.NewRegistry()
assert(World.Bootstrap.Commit(registry, plan, actors))

local groupID = plan.groups[1].groupID
local group = assert(registry:GetGroup(groupID))
local origin = group.location
local updated = assert(registry:StartGroupJourney(
    groupID,
    {
        origin = origin,
        destination = {
            x = origin.x + 100,
            y = origin.y + 100,
            z = origin.z,
        },
        route = {
            { x = origin.x, y = origin.y, z = origin.z },
            { x = origin.x, y = origin.y + 100, z = origin.z },
            { x = origin.x + 100, y = origin.y + 100, z = origin.z },
        },
        speed = 20,
        startAt = 10,
    },
    10
))
assert(updated.journey, "group journey missing")

local entries = World.Presentation.BuildActorEntries(
    registry,
    actors,
    12.5
)
assert(#entries == actors:Count(),
    "every canonical SurvivorWorld actor must project")

local byID = {}
for _, entry in ipairs(entries) do
    byID[entry.actorID] = entry
end

for _, actorID in ipairs(group.memberActorIDs) do
    local entry = assert(byID[actorID],
        "group member projection missing " .. actorID)
    assert(entry.groupID == groupID, "group context")
    assert(entry.factionID == group.factionID, "faction context")
    assert(entry.communityID == group.homeCommunityID,
        "community context")
    assert(entry.role ~= nil, "role context")
    assert(entry.positionSource == "group",
        "abstract group member must use shared group projection")
    assert(entry.journey
        and entry.journey.groupID == groupID,
        "group journey missing from actor projection")
    assert(entry.journey.route
        and #entry.journey.route.points == 3,
        "route points missing from actor projection")
    assert(entry.portrait
        and entry.portrait.actorID == actorID,
        "portrait contract missing")
    assert(entry.portrait.appearance,
        "portrait appearance contract missing")
    assert(entry.portrait.equipment
        and entry.portrait.equipment.worn
        and entry.portrait.equipment.worn.Torso_Upper
            == "Base.Tshirt_DefaultTEXTURE_TINT"
        and entry.portrait.equipment.worn.Legs == "Base.Trousers_Denim"
        and entry.portrait.equipment.worn.Shoes == "Base.Shoes_Random",
        "portrait must project canonical Core worn clothing")
end

local first = byID[group.memberActorIDs[1]]
assert(first.providerState == "abstract"
    or first.providerState == "materialized",
    "canonical map actors must have a Core presence state")

local released = assert(actors:Create({
    actorId = "npc:presentation:released",
    identitySeed = "presentation-released",
    world = { position = { x = origin.x, y = origin.y, z = 0 } },
}))
assert(actors:AttachExtension(
    released.actorId,
    "PsychopatzCore.SurvivorWorld",
    { factionID = group.factionID }
))
local afterReleased = World.Presentation.BuildActorEntries(
    registry,
    actors,
    12.5
)
local releasedEntry
for _, entry in ipairs(afterReleased) do
    if entry.actorID == released.actorId then
        releasedEntry = entry
        break
    end
end
assert(releasedEntry == nil,
    "released Core actors must not become map ghosts")
assert(math.abs(first.position.x - origin.x) < 0.001,
    "route first leg X")
assert(math.abs(first.position.y - (origin.y + 50)) < 0.001,
    "route first leg Y")

local spread = World.Presentation.SpreadOverlaps(entries, {
    radius = 4,
})
local spreadByID = {}
for _, entry in ipairs(spread) do
    spreadByID[entry.actorID] = entry
end
for _, actorID in ipairs(group.memberActorIDs) do
    local entry = assert(spreadByID[actorID])
    assert(entry.canonicalPosition,
        "canonical position must survive overlap spreading")
    assert(entry.overlapCount >= #group.memberActorIDs,
        "group co-location should be detected")
end
local spreadAgain = World.Presentation.SpreadOverlaps(entries, {
    radius = 4,
})
for index = 1, #spread do
    assert(spread[index].actorID == spreadAgain[index].actorID,
        "spread ordering must be deterministic")
    assert(math.abs(
        spread[index].position.x
            - spreadAgain[index].position.x
    ) < 0.0001, "spread X deterministic")
    assert(math.abs(
        spread[index].position.y
            - spreadAgain[index].position.y
    ) < 0.0001, "spread Y deterministic")
end

local route = World.Presentation.JourneyPoints(first)
assert(#route == 3, "presentation route helper")

local state = World.Presentation.NewSelection()
state = World.Presentation.SelectActor(
    state,
    group.memberActorIDs[1]
)
state = World.Presentation.HighlightActor(
    state,
    group.memberActorIDs[2]
)
state = World.Presentation.TrackActor(
    state,
    group.memberActorIDs[1]
)
assert(state.selectedActorID == group.memberActorIDs[1],
    "selection state")
assert(state.highlightedActorID == group.memberActorIDs[2],
    "highlight state")
assert(World.Presentation.ResolveTracked(entries, state).actorID
    == group.memberActorIDs[1], "tracking resolution")

print("psychopatz_survivor_world_presentation_smoke: PASS")
