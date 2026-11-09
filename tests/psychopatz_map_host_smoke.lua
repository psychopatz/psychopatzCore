local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local calls = {}

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
function ISButton:setX(v) self.x = v end
function ISButton:setY(v) self.y = v end
function ISButton:setHeight(v) self.height = v end
function ISButton:setVisible(v) self.visible = v end
function ISButton:setEnable(v) self.enable = v end
function ISButton:setTitle(v) self.title = v end

ISContextMenu = {}
function ISContextMenu.get()
    local context = { options = {} }
    function context:addOption(title)
        self.options[#self.options + 1] = title
    end
    return context
end

ISWorldMap = {
    createChildren = function(self)
        calls[#calls + 1] = "vanilla_create"
        self.buttonPanel = { x = 300, y = 400, height = 32 }
    end,
    prerender = function() calls[#calls + 1] = "vanilla_pre" end,
    render = function() calls[#calls + 1] = "vanilla_render" end,
    onRightMouseUp = function(self, x, y)
        local context = ISContextMenu.get(self.playerNum or 0, x, y)
        context:addOption("vanilla")
        self.lastContext = context
        return false
    end,
    close = function() calls[#calls + 1] = "vanilla_close" return "closed" end,
}

package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end
package.preload["ISUI/ISButton"] = function() return ISButton end
package.preload["ISUI/ISContextMenu"] = function() return ISContextMenu end

PsychopatzCore = {}
local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

assert(ISWorldMap._psychopatzCoreMapHostPatched == true,
    "Core map host did not install")
local patchedRender = ISWorldMap.render

assert(Host.Overlays.Register("late", {
    order = 20,
    render = function() calls[#calls + 1] = "late" end,
}))
assert(Host.Overlays.Register("early", {
    order = 10,
    render = function() calls[#calls + 1] = "early" end,
}))
assert(Host.Overlays.Register("broken", {
    order = 15,
    render = function() error("fixture") end,
}))

local contextAugmented = 0
assert(Host.Contexts.Register("context", {
    order = 10,
    available = function() return true end,
    augment = function(_, context)
        context:addOption("extension")
        contextAugmented = contextAugmented + 1
        return true
    end,
}))

local activated = 0
assert(Host.Tools.Register("tool", {
    order = 10,
    field = "testToolButton",
    title = "Tool",
    width = 80,
    onActivate = function() activated = activated + 1 return true end,
}))

local map = {
    children = {},
    playerNum = 0,
    addChild = function(self, child) self.children[#self.children + 1] = child end,
    getAbsoluteX = function() return 0 end,
    getAbsoluteY = function() return 0 end,
}
setmetatable(map, { __index = ISWorldMap })

map:createChildren()
assert(map.testToolButton, "registered Core map tool was not attached")
map.testToolButton.onclick()
assert(activated == 1, "map tool action was not called")
map:render()
map:onRightMouseUp(20, 30)
assert(contextAugmented == 1, "map context provider did not run")
assert(map.lastContext and #map.lastContext.options == 2,
    "vanilla and Core context options did not coexist")
assert(map.lastContext.options[1] == "vanilla"
    and map.lastContext.options[2] == "extension",
    "map context extension order changed")

local captured = 0
assert(Host.Input.Register("test.capture", {
    order = 1000,
    onMouseDown = function(_, x, y)
        captured = x + y
        return true
    end,
}), "map input capture registration failed")
assert(map:onMouseDown(20, 30) == true,
    "active map input capture did not consume world input")
assert(captured == 50, "map input capture did not receive world coordinates")
assert(Host.Input.Unregister("test.capture"),
    "map input capture unregistration failed")
assert(map:onMouseDown(20, 30) == false,
    "map input capture leaked after unregistration")

local renderIndex = {}
for i, value in ipairs(calls) do renderIndex[value] = i end
assert(renderIndex.vanilla_render
    and renderIndex.early > renderIndex.vanilla_render
    and renderIndex.late > renderIndex.early,
    "Core overlays did not render after vanilla in stable order")

-- Reloading must not stack a second map patch.
package.loaded["PsychopatzCore/UI/Map/PsychopatzMapHost"] = nil
local reloaded = require "PsychopatzCore/UI/Map/PsychopatzMapHost"
assert(reloaded.Overlays == Host.Overlays, "registry identity changed on reload")
assert(ISWorldMap.render == patchedRender, "Core map host patched twice")

assert(Host.Overlays.Unregister("broken"), "overlay unregister failed")
assert(Host.Tools.Unregister("tool"), "tool unregister failed")
assert(Host.Contexts.Unregister("context"), "context unregister failed")

print("psychopatz_map_host_smoke: PASS")
