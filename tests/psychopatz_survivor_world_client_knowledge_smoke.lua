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
local listCalls = 0
local discovery

package.preload[
    "PsychopatzCore/Actors/PsychopatzActorProjectionClient"
] = function()
    return {
        Get = function() return projection end,
        List = function() listCalls = listCalls + 1 return { projection } end,
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

local undiscovered = assert(Client.GetActorKnowledge(projection.actorID))
assert(undiscovered.state == "unknown" and not undiscovered.nameKnown,
    "missing discovery disclosed an unknown group member")
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

Client.RegisterActorKnowledgeProvider("Unavailable", { get = function() return nil end })
assert(Client.GetActorKnowledge(projection.actorID, { provider = "Unavailable" }) == nil,
    "unavailable knowledge adapter fell back to a raw name")
local before = listCalls
assert(Client.GetTracked() == nil, "untracked map resolved an actor")
Client.Selection.trackedActorID = projection.actorID
for frame = 1, 120 do
    assert(Client.GetTracked() == projection, "tracked actor lookup changed")
end
assert(listCalls == before, "tracking sorted the full population per frame")
projection.sourceID = "OtherProvider"
assert(Client.GetTracked() == nil, "tracking admitted a different projection source")
local authorized = false
PsychopatzCore.Debug = { CanUse = function() return authorized end }
assert(Client.SetDebugPresentationEnabled(true) == false, "unauthorized debug enabled")
authorized = true
assert(Client.SetDebugPresentationEnabled(true))
assert(Client.IsDebugPresentationEnabled(), "authorized shared debug did not enable")
authorized = false
assert(not Client.IsDebugPresentationEnabled(), "revoked permission retained debug")
assert(Client.SetDebugPresentationEnabled(false), "debug could not disable after revoke")
print("psychopatz_survivor_world_client_knowledge_smoke: PASS")
