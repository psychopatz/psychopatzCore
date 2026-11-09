local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

PsychopatzCore = { DebugHub = {} }
dofile(CLIENT .. "PsychopatzCore/UI/PsychopatzDebugHubRegistry.lua")

local Hub = PsychopatzCore.DebugHub
local launched = 0

assert(Hub.RegisterTool({
    id = "registry.first",
    source = "Registry",
    order = 20,
    title = "First",
    action = function() launched = launched + 1 end,
}), "valid tool was rejected")
assert(Hub.RegisterTool({
    id = "registry.second",
    source = "Registry",
    order = 10,
    title = "Second",
    action = function() launched = launched + 1 end,
}), "second valid tool was rejected")
assert(Hub.RegisterTool({
    id = "registry.map",
    surface = "map",
    source = "Map Debug",
    order = 5,
    title = "Map Tool",
    action = function() launched = launched + 1 end,
}), "scoped map tool was rejected")
assert(not Hub.RegisterTool({ id = "missing-action", title = "Invalid" }),
    "tool without an action was accepted")

local tools = Hub.GetTools()
assert(#tools == 3 and tools[1].id == "registry.map",
    "registry ordering changed")
assert(tools[1].description == "" and tools[1].available(),
    "registry defaults were not applied")

local mapTools = Hub.GetTools("map")
assert(#mapTools == 1 and mapTools[1].id == "registry.map",
    "surface filtering did not isolate map tools")
local mapGroups = Hub.GetToolGroups({ surface = "map" })
assert(#mapGroups == 1 and mapGroups[1].source == "Map Debug",
    "surface filtering did not isolate map groups")

local groups = Hub.GetToolGroups()
assert(#groups == 2 and groups[1].source == "Map Debug"
    and #groups[1].tools == 1 and groups[2].source == "Registry"
    and #groups[2].tools == 2,
    "registry grouping changed")
assert(groups[1].expanded == true and groups[2].expanded == true,
    "groups were not expanded by default")
Hub.SetGroupExpanded("Registry", false)
assert(Hub.GetToolGroups()[2].expanded == false,
    "group expansion state was not persisted")

Hub.tools["registry.second"].action()
assert(launched == 1, "registered action was not retained")

print("psychopatz_debug_hub_registry_smoke: ok")
