local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local registered = {}
local actions = {}
local requests = 0

local Menu = {
    Register = function(id, definition)
        registered[id] = definition
        return true
    end,
}
package.preload["PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"] =
    function() return Menu end

local Client = {
    Selection = { selectedActorID = "actor:selected", trackedActorID = nil },
}
function Client.RequestDiscovery()
    requests = requests + 1
    return true, "requested"
end
function Client.DiscoveryAction(action, args)
    actions[#actions + 1] = { action = action, args = args }
    return true, "sent"
end
function Client.SetTracked(actorID)
    Client.Selection.trackedActorID = actorID
    return Client.Selection
end
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
] = function() return Client end

PsychopatzCore = {
    Debug = { CanUse = function() return true end },
    DebugHub = { Open = function() return true end },
}
getSpecificPlayer = function() return {} end

local loaded = dofile(
    CLIENT .. "PsychopatzCore/UI/Map/PsychopatzMapDebugTools.lua"
)
assert(loaded == Menu, "Core map debug tools did not return the shared menu")

assert(registered["PsychopatzCore:discovery_refresh"],
    "Core discovery refresh entry was not registered")
assert(registered["PsychopatzCore:discovery_all_signals"],
    "Core signal discovery entry was not registered")
assert(registered["PsychopatzCore:discovery_all"],
    "Core all-discovery entry was not registered")
assert(registered["PsychopatzCore:discovery_all_groups"],
    "Core group discovery entry was not registered")
assert(registered["PsychopatzCore:discovery_all_communities"],
    "Core community discovery entry was not registered")
assert(registered["PsychopatzCore:discovery_reset"],
    "Core discovery reset entry was not registered")
assert(registered["PsychopatzCore:track_selected"],
    "Core actor tracking entry was not registered")
assert(registered["PsychopatzCore:debug_hub"],
    "Core Debug Hub entry was not registered")

registered["PsychopatzCore:discovery_refresh"].onActivate()
registered["PsychopatzCore:discovery_all"].onActivate()
registered["PsychopatzCore:discovery_all_signals"].onActivate()
registered["PsychopatzCore:discovery_all_groups"].onActivate()
registered["PsychopatzCore:discovery_all_communities"].onActivate()
registered["PsychopatzCore:discovery_reset"].onActivate()
assert(requests == 1, "Core discovery refresh did not use Core transport")
assert(#actions == 5, "Core discovery debug actions did not use Core transport")
assert(actions[1].action == "debug_discover_all"
    and actions[1].args.scope == "all",
    "Core all-discovery scope changed")
assert(actions[2].action == "debug_discover_all"
    and actions[2].args.scope == "signals",
    "Core signal discovery scope changed")
assert(actions[3].args.scope == "mobile_groups",
    "Core group discovery scope changed")
assert(actions[4].args.scope == "settlements",
    "Core community discovery scope changed")
assert(actions[5].action == "debug_reset",
    "Core discovery reset action changed")

registered["PsychopatzCore:track_selected"].onActivate()
assert(Client.Selection.trackedActorID == "actor:selected",
    "Core tracking entry did not track selected actor")
assert(registered["PsychopatzCore:track_selected"].title() == "Stop tracking survivor",
    "Core tracking title did not reflect active tracking")
registered["PsychopatzCore:track_selected"].onActivate()
assert(Client.Selection.trackedActorID == nil,
    "Core tracking entry did not clear active tracking")

print("psychopatz_map_debug_tools_smoke: PASS")
