require "PsychopatzCore/00_PsychopatzCore_Init"

local SurvivorWorld = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Sync = require
    "PsychopatzCore/Actors/PsychopatzActorProjectionServer"

PsychopatzCore.SurvivorWorldProjectionServer =
    PsychopatzCore.SurvivorWorldProjectionServer or {}

local Server = PsychopatzCore.SurvivorWorldProjectionServer
Server.SOURCE_ID = "SurvivorWorld"

local function worldHour()
    local time = getGameTime and getGameTime() or nil
    return time and type(time.getWorldAgeHours) == "function"
        and math.max(
            0,
            tonumber(time:getWorldAgeHours()) or 0
        )
        or 0
end

function Server.BuildEntries()
    local registry =
        SurvivorWorld.GetRuntimeRegistry()
    if not registry then return {} end
    local actorRegistry = Actors.DefaultRegistry
    if not actorRegistry then return {} end
    return SurvivorWorld.Presentation.BuildActorEntries(
        registry,
        actorRegistry,
        worldHour(),
        {
            sourceID = Server.SOURCE_ID,
            includeUnscoped = true,
        }
    )
end

function Server.Publish()
    if not SurvivorWorld.GetRuntimeRegistry() then
        return 0
    end
    return Sync.Broadcast(Server.SOURCE_ID)
end

function Server.Send(player)
    if not SurvivorWorld.GetRuntimeRegistry() then
        return false, "survivor_world_inactive"
    end
    return Sync.Send(
        player,
        Server.SOURCE_ID,
        false
    )
end

Sync.RegisterProvider(Server.SOURCE_ID, {
    BuildEntries = Server.BuildEntries,
})

return Server
