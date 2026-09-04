local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function buttonMethod(name, fn)
    return function(self, ...)
        if fn then return fn(self, ...) end
    end
end

local Button = {}
Button.__index = Button
function Button:new(x, y, width, height, title, target, onclick)
    return setmetatable({
        Type = "ISButton", x = x, y = y, width = width, height = height,
        title = title, target = target, onclick = onclick, enable = true,
        visible = true,
    }, self)
end
Button.initialise = buttonMethod("initialise")
Button.instantiate = buttonMethod("instantiate")
Button.setDisplayBackground = buttonMethod("setDisplayBackground")
Button.setImage = buttonMethod("setImage")
Button.setTitle = function(self, value) self.title = value end
Button.setVisible = function(self, value) self.visible = value end
Button.getIsVisible = function(self) return self.visible end
Button.setX = function(self, value) self.x = value end
Button.setY = function(self, value) self.y = value end
Button.setWidth = function(self, value) self.width = value end
Button.setHeight = function(self, value) self.height = value end
Button.getX = function(self) return self.x end
Button.getY = function(self) return self.y end
Button.getWidth = function(self) return self.width end
Button.getHeight = function(self) return self.height end
Button.getBottom = function(self) return self.y + self.height end

ISButton = Button
package.preload["ISUI/ISButton"] = function() return Button end
PsychopatzCore = { UI = {
    StyleButton = function(button, variant)
        button.variant = variant
        return button
    end,
} }
Events = { OnTick = { Add = function() end } }
getTimestampMs = function() return 1000 end

local function makeChild(typeName, y, height)
    return {
        Type = typeName, x = 0, y = y, width = 48, height = height,
        visible = true,
        getBottom = function(self) return self.y + self.height end,
        getWidth = function(self) return self.width end,
        getHeight = function(self) return self.height end,
        getIsVisible = function(self) return self.visible end,
    }
end

local host = {
    chr = { getPlayerNum = function() return 0 end },
    children = {}, mouseOverList = {}, width = 48, height = 60,
    offHand = makeChild("ISImage", 0, 36),
    getChildren = function(self) return self.children end,
    addChild = function(self, child)
        child.parent = self
        self.children[#self.children + 1] = child
    end,
    addMouseOverToolTipItem = function(self, object, text)
        self.mouseOverList[#self.mouseOverList + 1] = {
            object = object, displayString = text,
        }
    end,
    getHeight = function(self) return self.height end,
    setHeight = function(self, value) self.height = value end,
    getWidth = function(self) return self.width end,
    getIsVisible = function() return true end,
}
host.addChild(host, host.offHand)
host.addChild(host, makeChild("ISButton", 51, 36))

ISEquippedItem = {
    initialise = function(self) ISEquippedItem.instance = self end,
    prerender = function() end,
}

dofile(ROOT .. "PsychopatzSidebar.lua")
local Sidebar = PsychopatzCore.UI.Sidebar
Sidebar.Register({ id = "mod.first", order = 20, title = "First" })
Sidebar.Register({ id = "mod.early", order = 10, title = "Early" })
ISEquippedItem.initialise(host)

local early = host.psychopatzSidebarEntries["mod.early"]
local first = host.psychopatzSidebarEntries["mod.first"]
equal(early.parent, host, "registered control is a sidebar child")
equal(early:getY(), 102, "first registered control follows native controls")
equal(first:getY(), 153, "registered controls use stable ordered spacing")
equal(host.mouseOverList[1].object, early,
    "registered control uses the sidebar tooltip group")

print("psychopatz_sidebar_smoke: ok")
