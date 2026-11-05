local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local activated = 0

ISButton = {}
function ISButton:new(x, y, width, height, title, target, onclick)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        title = title,
        target = target,
        onclick = onclick,
        visible = true,
        enable = true,
    }, { __index = self })
end
function ISButton:initialise() end
function ISButton:instantiate() end
function ISButton:setX(value) self.x = value end
function ISButton:setY(value) self.y = value end
function ISButton:setHeight(value) self.height = value end
function ISButton:setVisible(value) self.visible = value end
function ISButton:setEnable(value) self.enable = value end
function ISButton:setTitle(value) self.title = value end

ISPanel = {}
function ISPanel:derive()
    local child = {}
    setmetatable(child, { __index = self })
    child.__index = child
    return child
end
function ISPanel:new(x, y, width, height)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        children = {},
        visible = true,
    }, { __index = self })
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
function ISPanel:drawRect() end
function ISPanel:drawRectBorder() end
function ISPanel:drawTextCentre() end

ISContextMenu = {}
function ISContextMenu.get()
    return { addOption = function() end }
end

ISWorldMap = {
    createChildren = function(self)
        self.buttonPanel = { x = 300, y = 400, height = 32 }
    end,
    prerender = function() end,
    render = function() end,
    close = function(self) self.closed = true end,
    onMouseDown = function() end,
    onMouseMove = function() end,
    onMouseMoveOutside = function() end,
    onMouseUp = function() end,
    onMouseUpOutside = function() end,
    onRightMouseDown = function() end,
    onRightMouseUp = function() end,
}

package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end
package.preload["ISUI/ISButton"] = function() return ISButton end
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISContextMenu"] = function() return ISContextMenu end

getTexture = function(path) return path end
getText = function(key) return key end
getCore = function()
    return {
        getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 720 end,
    }
end

PsychopatzCore = {
    Translation = { GetKey = function(_, key, fallback) return fallback or key end },
    Debug = { CanUse = function() return true end },
}

local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"
local entryID = "test.map_tools_entry"
Menu.Unregister(entryID)
assert(Menu.Register(entryID, {
    order = 10,
    title = "Test tool",
    tooltip = "Test tooltip",
    onActivate = function()
        activated = activated + 1
        return true
    end,
}), "Core map menu rejected a valid entry")

local map = { children = {}, addChild = ISPanel.addChild }
setmetatable(map, { __index = ISWorldMap })
map:createChildren()

assert(map.psychopatzMapToolsButton, "Core map tools button was not attached")
assert(map.psychopatzMapToolsButton.title == "Map Tools",
    "Core map tools button has the wrong title")
assert(map.psychopatzMapToolsButton.onclick() == true,
    "Core map tools button did not open the shared menu")

local modal = Menu.instance
assert(modal and modal.entryButtons[entryID],
    "registered Core map entry did not appear in shared menu")
assert(modal:onButton(modal.entryButtons[entryID]) == true,
    "shared map entry did not activate")
assert(activated == 1, "shared map entry callback was not called")

Menu.Unregister(entryID)
map:close()
assert(Menu.instance == nil, "map close did not close the shared map menu")

print("psychopatz_map_tools_menu_smoke: PASS")
