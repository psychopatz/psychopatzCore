local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path
local Journey = require "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
local Projection = require "PsychopatzCore/Actors/PsychopatzActorProjection"
local Presentation = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresentation"
local journey = assert(Journey.New("group:test", {
    origin = {x=0,y=0,z=0}, destination = {x=100,y=0,z=0}, speed=10,
}, 0))
for _, provider in ipairs({"ProjectHoomans", "DTAbstract", "DTHoomans"}) do
    local entry = assert(Projection.ValidateEntry({actorID="npc:"..provider,
        provider=provider, providerState="abstract", sourceID="SurvivorWorld",
        positionSource="group", groupID="group:test", position={x=3,y=2,z=0},
        updatedAt=0, journey=journey}))
    assert(entry.positionSource == "group", "transport discarded position authority")
    local position = Presentation.ProjectActorPosition(entry, 1)
    assert(position.x == 13 and position.y == 2, "providers disagree on abstract movement/offset")
    assert(entry.position.x == 3 and entry.journey.distanceTravelled == 0, "display mutated authority")
    entry.providerState = "materialized"
    assert(Presentation.ProjectActorPosition(entry, 1).x == 3, "live actor extrapolated with group")
    entry.providerState = "abstract"
    entry.positionSource = "actor_override"
    assert(Presentation.ProjectActorPosition(entry, 1).x == 3, "provider position overridden")
    entry.positionSource = "group"
    entry.journey.state = "paused"
    assert(Presentation.ProjectActorPosition(entry, 1).x == 3, "paused journey moved")
    entry.journey.state = "waiting"
    entry.journey.waitRemainingHours = 2
    entry = assert(Projection.ValidateEntry(entry))
    assert(entry.journey.waitRemainingHours == 2, "transport dropped remaining wait")
    assert(Presentation.ProjectActorPosition(entry, 1).x == 3, "waiting journey moved early")
    assert(Presentation.ProjectActorPosition(entry, 3).x == 13, "wait did not resume correctly")
    assert(Presentation.ProjectActorPosition(entry, -1).x == 3, "clock rollback moved actor")
    entry.journey.distanceTotal = 500
    assert(Presentation.ProjectActorPosition(entry, 3).x == 3, "truncated route extrapolated")
end
-- Exercise the client entry point used by both Hoomans and DTAbstract.
package.path = "Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua;"
    .. "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;" .. package.path
local entry = assert(Projection.ValidateEntry({actorID="npc:shared", sourceID="SurvivorWorld",
    provider="DTAbstract", providerState="abstract", positionSource="group", groupID="group:test",
    position={x=3,y=2,z=0}, updatedAt=0, journey=journey}))
package.preload["PsychopatzCore/Actors/PsychopatzActorProjectionClient"] = function()
    return { List = function() return {entry} end, Get = function() return entry end }
end
getGameTime = function() return {getWorldAgeHours = function() return 1 end} end
local Client = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
assert(Client.ListActors(false)[1].position.x == 13, "shared client did not project moving actor")
assert(Client.ListActors(true)[1].position.x == 3, "raw authority projection was mutated")
print("psychopatz_actor_map_journey_parity_smoke: PASS")
