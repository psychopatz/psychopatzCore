local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local RUNTIME_SHARED =
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. RUNTIME_SHARED .. "?.lua;"
    .. COMMON .. "?.lua;" .. package.path

PsychopatzCore = {}
local projection = {
    actorID = "actor:knowledge:one",
    groupID = "group:knowledge:one",
    displayName = "Roaming Trader",
    factionID = "faction:knowledge:one",
}
local discovery

package.preload[
    "PsychopatzCore/Actors/PsychopatzActorProjectionClient"
] = function()
    return {
        Get = function() return projection end,
        List = function() return { projection } end,
        Request = function() return true end,
    }
end
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresentation"
] = function()
    return {
        NewSelection = function() return {} end,
        SpreadOverlaps = function(entries) return entries end,
        SelectActor = function(selection, actorID)
            selection.selectedActorID = actorID
            return selection
        end,
        HighlightActor = function(selection, actorID)
            selection.highlightedActorID = actorID
            return selection
        end,
        TrackActor = function(selection, actorID)
            selection.trackedActorID = actorID
            return selection
        end,
        ResolveTracked = function() return projection end,
    }
end

local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
Client.FindDiscovery = function(kind, entityID)
    if kind == "group" and entityID == projection.groupID then
        return discovery
    end
    return nil
end

discovery = { phase = 2 }
local unknown = assert(Client.GetActorKnowledge(projection.actorID))
assert(unknown.state == "unknown" and unknown.nameKnown == false,
    "uncontacted Core actor projection was exposed as known")
assert(unknown.knownName == nil and unknown.factionID == nil,
    "uncontacted Core actor leaked identity/faction details")

discovery.phase = 3
local known = assert(Client.GetActorKnowledge(projection.actorID))
assert(known.state == "known" and known.nameKnown == true,
    "contacted Core actor projection did not reveal identity")
assert(known.knownName == projection.displayName
    and known.factionID == projection.factionID,
    "contacted Core actor lost canonical identity/faction data")

print("psychopatz_survivor_world_client_knowledge_smoke: PASS")
