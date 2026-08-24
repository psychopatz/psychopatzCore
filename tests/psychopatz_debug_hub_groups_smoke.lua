local CLIENT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

PsychopatzCore = {
    UI = {
        Theme = { colors = {} },
        Layout = {},
    },
    DebugHub = {},
}

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end

PsychopatzWindow = {
    derive = function(self)
        local child = {}
        child.__index = child
        setmetatable(child, { __index = self })
        return child
    end,
}

dofile(CLIENT .. "PsychopatzCore/UI/PsychopatzDebugHubWindow.lua")
local Hub = PsychopatzCore.DebugHub

Hub.RegisterTool({
    id = "core.one",
    source = "PsychopatzCore",
    order = 10,
    title = "Core One",
    action = function() end,
})
Hub.RegisterTool({
    id = "hoomans.one",
    source = "Project Hoomans",
    order = 20,
    title = "Hoomans One",
    action = function() end,
})
Hub.RegisterTool({
    id = "hoomans.two",
    source = "Project Hoomans",
    order = 30,
    title = "Hoomans Two",
    action = function() end,
})

local groups = Hub.GetToolGroups()
assert(#groups == 2, "debug tools were not grouped by source")
assert(groups[1].source == "PsychopatzCore", "core group order was incorrect")
assert(groups[2].source == "Project Hoomans", "Hoomans group was missing")
assert(groups[1].expanded == true, "core group was not expanded by default")
assert(groups[2].expanded == true, "Hoomans group was not expanded by default")
assert(#groups[2].tools == 2, "Hoomans tools were split into multiple groups")

Hub.SetGroupExpanded("Project Hoomans", false)
groups = Hub.GetToolGroups()
assert(groups[2].expanded == false, "Hoomans group did not collapse")
assert(groups[1].expanded == true, "collapsing Hoomans changed the core group")

Hub.SetGroupExpanded("Project Hoomans", true)
assert(Hub.GetToolGroups()[2].expanded == true,
    "Hoomans group did not expand again")

local list = { items = {}, selected = 0 }
function list:clear()
    self.items = {}
    self.selected = 0
end
function list:addItem(label, item)
    self.items[#self.items + 1] = {
        text = label,
        item = item,
        index = #self.items + 1,
    }
end
function list:getItem()
    return self.items[self.selected]
end
ISScrollingListBox = {
    onMouseDown = function(target)
        target.selected = target.clickedRow
    end,
}
local window = {
    toolList = list,
    launchButton = { setEnable = function(self, enabled) self.enabled = enabled end },
    rebuildCards = Hub.Window.rebuildCards,
    refreshAvailability = Hub.Window.refreshAvailability,
    onToolListMouseDown = Hub.Window.onToolListMouseDown,
}
Hub.Window.instance = window
Hub.Window.rebuildCards(window)
assert(#list.items == 5, "expanded group rows were not rendered")
list.clickedRow = 3
window:onToolListMouseDown(list, 0, 0)
assert(#list.items == 3, "collapsed group tools remained visible")
assert(list.items[3].item.kind == "group"
    and list.items[3].item.source == "Project Hoomans",
    "collapsed group header was not retained")
assert(Hub.IsGroupExpanded("Project Hoomans") == false,
    "clicking a group header did not collapse the group")
list.clickedRow = 3
window:onToolListMouseDown(list, 0, 0)
assert(#list.items == 5, "collapsed group tools did not return on second click")
assert(Hub.IsGroupExpanded("Project Hoomans") == true,
    "clicking a collapsed group header did not expand the group")
Hub.Window.instance = nil

print("psychopatz_debug_hub_groups_smoke: ok")
