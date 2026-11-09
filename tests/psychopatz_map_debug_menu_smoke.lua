local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

PsychopatzCore = {
    Translation = {
        GetKey = function(key, fallback) return fallback or key end,
    },
}

ISPanel = {}
function ISPanel:derive()
    local child = {}
    setmetatable(child, { __index = self })
    child.__index = child
    return child
end
function ISPanel:new(x, y, width, height)
    local panel = {
        x = x, y = y, width = width, height = height,
        children = {}, visible = true,
    }
    setmetatable(panel, { __index = self })
    return panel
end
function ISPanel:initialise() end
function ISPanel:createChildren() end
function ISPanel:instantiate() self:createChildren() end
function ISPanel:addChild(child) self.children[#self.children + 1] = child end
function ISPanel:addToUIManager() end
function ISPanel:removeFromUIManager() end
function ISPanel:bringToTop() end
function ISPanel:setAlwaysOnTop() end
function ISPanel:setCapture() end
function ISPanel:setVisible(value) self.visible = value end
function ISPanel:setHeight(value) self.height = value end

ISButton = {}
function ISButton:new(x, y, width, height, title, target, onclick)
    local button = {
        x = x, y = y, width = width, height = height,
        title = title, target = target, onclick = onclick,
        visible = true, enable = true,
    }
    setmetatable(button, { __index = self })
    return button
end
function ISButton:initialise() end
function ISButton:instantiate() end
function ISButton:setY(value) self.y = value end
function ISButton:setTitle(value) self.title = value end
function ISButton:setEnable(value) self.enable = value end
function ISButton:setVisible(value) self.visible = value end

package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISButton"] = function() return ISButton end

getCore = function()
    return {
        getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 720 end,
    }
end

local Hub = require "PsychopatzCore/UI/PsychopatzDebugHubRegistry"
local enabled = false
Hub.RegisterTool({
    id = "map.toggle",
    surface = "map",
    source = "Map Debug",
    title = "Toggle",
    menuTitle = function()
        return enabled and "TEST DEBUG: ON" or "TEST DEBUG: OFF"
    end,
    description = "Toggle test state.",
    action = function()
        enabled = not enabled
        return true
    end,
})
Hub.RegisterTool({
    id = "global.tool",
    title = "Global Tool",
    action = function() return true end,
})

local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapDebugMenu"
local modal = Menu.Open()
local toggle = assert(modal.entryButtons["map.toggle"],
    "map toggle was not rendered")
assert(not modal.entryButtons["global.tool"],
    "global Debug Hub tool leaked into the map debug menu")
assert(toggle.title == "TEST DEBUG: OFF",
    "map toggle did not render its OFF state")
assert(modal:onButton(toggle), "map toggle did not activate")
assert(enabled and toggle.title == "TEST DEBUG: ON",
    "map toggle did not refresh its ON state")
Menu.Close()
assert(Menu.instance == nil, "map debug menu did not close")
assert(PsychopatzMapDebugWindow.instance == nil,
    "map debug window singleton survived close")
local reopened = Menu.Open()
assert(reopened ~= modal, "map debug menu reused a closed window")
Menu.Close()
assert(PsychopatzMapDebugWindow.instance == nil,
    "reopened map debug window did not close")

print("psychopatz_map_debug_menu_smoke: PASS")
