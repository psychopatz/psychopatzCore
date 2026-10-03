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
assert(not Hub.RegisterTool({ id = "missing-action", title = "Invalid" }),
    "tool without an action was accepted")

local tools = Hub.GetTools()
assert(#tools == 2 and tools[1].id == "registry.second",
    "registry ordering changed")
assert(tools[1].description == "" and tools[1].available(),
    "registry defaults were not applied")

local groups = Hub.GetToolGroups()
assert(#groups == 1 and #groups[1].tools == 2,
    "registry grouping changed")
assert(groups[1].expanded == true, "groups were not expanded by default")
Hub.SetGroupExpanded("Registry", false)
assert(Hub.GetToolGroups()[1].expanded == false,
    "group expansion state was not persisted")

Hub.tools["registry.second"].action()
assert(launched == 1, "registered action was not retained")

print("psychopatz_debug_hub_registry_smoke: ok")
