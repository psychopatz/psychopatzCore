local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local toolbar = {}
local debugTools = {}
local actions = {}
local requests = 0
local inspection = false
local authorized = true
local debugMenuOpens = 0
local debugMenuMap = nil
local mapMenuEntries = {}
local mapMenuCloses = 0

local Host = {
    Tools = {
        Register = function(id, definition)
            toolbar[id] = definition
            return true
        end,
    },
}
package.preload["PsychopatzCore/UI/Map/PsychopatzMapHost"] =
    function() return Host end

local MapMenu = {
    Register = function(id, definition)
        mapMenuEntries[id] = definition
        return true
    end,
    Close = function()
        mapMenuCloses = mapMenuCloses + 1
    end,
}
package.preload["PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"] =
    function() return MapMenu end

local DebugMenu = {
    Open = function(map)
        debugMenuOpens = debugMenuOpens + 1
        debugMenuMap = map
        return true
    end,
    Close = function() end,
}
package.preload["PsychopatzCore/UI/Map/PsychopatzMapDebugMenu"] =
    function() return DebugMenu end

local Hub = {
    RegisterTool = function(definition)
        debugTools[definition.id] = definition
        return true
    end,
}
package.preload["PsychopatzCore/UI/PsychopatzDebugHubRegistry"] =
    function() return Hub end

local Client = {
    IsDebugPresentationEnabled = function() return inspection end,
    SetDebugPresentationEnabled = function(value)
        inspection = value
        return true
    end,
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
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresence"
] = function()
    return { IsOverrideEnabled = function() return false end }
end

PsychopatzCore = {
    Debug = { CanUse = function() return authorized end },
    DebugHub = {},
}
getSpecificPlayer = function() return {} end

local loaded = dofile(
    CLIENT .. "PsychopatzCore/UI/Map/PsychopatzMapDebugTools.lua"
)
assert(loaded == Hub, "Core map debug tools did not return the Debug Hub")

local function debug(id)
    return assert(debugTools["psychopatz.map." .. id],
        "missing Debug Hub tool: " .. id)
end

debug("discovery_refresh")
debug("discovery_all_signals")
debug("discovery_all")
debug("discovery_all_groups")
debug("discovery_all_communities")
debug("discovery_reset")
debug("actor_debug_presentation")
local presenceOverride = debug("actor_presence_override")
assert(not presenceOverride.available(),
    "presence override must stay gated when its Core setting is disabled")
debug("marker_diagnostics")
assert(toolbar["PsychopatzCore:track_selected"],
    "Core actor tracking was not registered as a toolbar tool")
assert(not toolbar["PsychopatzCore:debug"],
    "Core Debug button still leaked into the map toolbar")
local debugMenu = assert(mapMenuEntries["PsychopatzCore:map_debug"],
    "Core Debug entry was not registered inside Map Tools")
assert(debugMenu.visible() and debugMenu.enabled(),
    "authorized map Debug entry was not available")

debug("discovery_refresh").action()
debug("discovery_all").action()
debug("discovery_all_signals").action()
debug("discovery_all_groups").action()
debug("discovery_all_communities").action()
debug("discovery_reset").action()
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

local tracking = toolbar["PsychopatzCore:track_selected"]
tracking.onActivate()
assert(Client.Selection.trackedActorID == "actor:selected",
    "Core tracking button did not track selected actor")
assert(tracking.title() == "Stop tracking survivor",
    "Core tracking title did not reflect active tracking")
tracking.onActivate()
assert(Client.Selection.trackedActorID == nil,
    "Core tracking button did not clear active tracking")

local inspectionTool = debug("actor_debug_presentation")
assert(inspectionTool.available(), "authorized Debug Hub tool hidden")
assert(inspectionTool.menuTitle() == "SURVIVOR DEBUG: OFF",
    "map debug toggle did not expose its OFF state")
assert(inspectionTool.action() and inspection,
    "Debug Hub inspection tool did not enable inspection")
assert(inspectionTool.menuTitle() == "SURVIVOR DEBUG: ON",
    "map debug toggle did not expose its ON state")
assert(inspectionTool.action() and not inspection,
    "Debug Hub inspection tool did not disable inspection")

authorized = false
assert(not inspectionTool.available(),
    "Debug Hub tool remained available without permission")
assert(debugMenu.visible() == false and debugMenu.enabled() == false,
    "map Debug entry remained available without permission")
authorized = true
assert(debugMenu.onActivate(),
    "Map Tools Debug entry did not open the map debug menu")
assert(debugMenuOpens == 1, "map Debug opened the wrong surface")
assert(debugMenuMap == nil,
    "map Debug passed an unexpected map object in the isolated smoke")
assert(mapMenuCloses == 0,
    "map Debug used the broad menu close lifecycle instead of closing its window")
print("psychopatz_map_debug_tools_smoke: PASS")
