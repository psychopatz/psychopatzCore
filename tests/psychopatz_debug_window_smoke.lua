local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local created = 0
local commands = {}
local now = 0
local downKey = 0
local tickCallbacks = {}

PsychopatzCore = {
    COMMAND_MODULE = "PsychopatzCore",
    Debug = {
        COMMAND = "SetDebugAccess",
        IsLocalOverrideEnabled = function() return false end,
        SetLocalOverride = function() end,
    },
    DebugHub = { Open = function() end },
    IsOwner = function() return true end,
}
PsychopatzCore.UI = {
    CreateToggleButton = function(parent, definition)
        local button = {
            parent = parent,
            state = definition.value == true,
        }
        function button:setX(value) self.x = value end
        function button:setY(value) self.y = value end
        function button:setWidth(value) self.width = value end
        function button:setHeight(value) self.height = value end
        function button:getToggleState() return self.state end
        function button:setToggleState(value) self.state = value == true end
        function button:toggle()
            self.state = not self.state
            return self.state
        end
        return button
    end,
}

package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISLabel"] = function() return true end
package.preload["ISUI/ISTextEntryBox"] = function() return true end
package.preload["ISUI/ISTickBox"] = function() return true end
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] = function()
    return PsychopatzCore.DebugHub
end
package.preload["PsychopatzCore/Debug/PsychopatzDebugContextMenu"] = function() return true end
package.preload["PsychopatzCore/UI/Inventory/PsychopatzItemTypeLedgerWindow"] = function()
    return true
end

ISCollapsableWindow = {
    derive = function(self)
        local child = {}
        child.__index = child
        setmetatable(child, { __index = self })
        return child
    end,
    new = function(self, x, y, width, height)
        created = created + 1
        return setmetatable({
            x = x,
            y = y,
            width = width,
            height = height,
            visible = true,
        }, { __index = self })
    end,
    initialise = function(self)
        self.visible = true
    end,
    setResizable = function() end,
    setVisible = function(self, visible)
        self.visible = visible
    end,
    getIsVisible = function(self)
        return self.visible == true
    end,
    removeFromUIManager = function(self)
        self.removed = true
    end,
    addToUIManager = function(self)
        self.added = true
    end,
    bringToTop = function(self)
        self.broughtToTop = (self.broughtToTop or 0) + 1
    end,
    setX = function(self, x)
        self.x = x
    end,
    setY = function(self, y)
        self.y = y
    end,
    getWidth = function(self)
        return self.width
    end,
    getHeight = function(self)
        return self.height
    end,
}
package.preload["ISUI/ISCollapsableWindow"] = function()
    return ISCollapsableWindow
end

local savedGeometry = {}
PsychopatzWindow = ISCollapsableWindow:derive("PsychopatzWindow")
PsychopatzWindow.derive = function(self, name)
    local child = {}
    child.Type = name
    child.__index = child
    setmetatable(child, { __index = self })
    return child
end
PsychopatzWindow.new = function(self, x, y, width, height, options)
    created = created + 1
    options = options or {}
    local persistenceKey = tostring(options.persistenceNamespace or "")
        .. ":" .. tostring(options.persistenceKey or "")
    local state = savedGeometry[persistenceKey]
    local object = setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        visible = true,
        persistenceKey = persistenceKey,
        psychopatzGeometryRestored = state ~= nil,
    }, self)
    if state then
        object.x = state.x
        object.y = state.y
    end
    return object
end
PsychopatzWindow.initialise = function(self)
    self.visible = true
end
PsychopatzWindow.createChildren = function() end
PsychopatzWindow.saveGeometry = function(self)
    savedGeometry[self.persistenceKey] = { x = self.x, y = self.y }
    return true
end
PsychopatzWindow.removeFromUIManager = function(self)
    self:saveGeometry(true)
    self.removed = true
end
package.preload["PsychopatzCore/UI/PsychopatzWindow"] = function()
    return PsychopatzWindow
end

Events = {
    OnTick = {
        Add = function(handler)
            tickCallbacks[#tickCallbacks + 1] = handler
            Events.tick = function()
                for _, callback in ipairs(tickCallbacks) do callback() end
            end
        end,
    },
}
getTimeInMillis = function() return now end
local pressedKey = 0
Keyboard = {
    KEY_NUMPAD0 = 82,
    isKeyDown = function(key) return key == downKey end,
    isKeyPressed = function(key) return key == pressedKey end,
}
isKeyDown = function(key) return Keyboard.isKeyDown(key) end
isKeyPressed = function(key) return Keyboard.isKeyPressed(key) end
getPlayer = function() return { steamID = "76561198137190990" } end
getCore = function()
    return {
        getScreenWidth = function() return 1920 end,
        getScreenHeight = function() return 1080 end,
    }
end
sendClientCommand = function(_, module, command, args)
    commands[#commands + 1] = { module = module, command = command, args = args }
end

dofile(CLIENT .. "PsychopatzCore/Debug/PsychopatzDebugClient.lua")

assert(Events.tick, "debug keybind tick handler was not registered")
assert(PsychopatzDebugWindow.instance == nil, "debug window existed before opening")

local function triggerDebugKey(startTime)
    downKey = 0
    pressedKey = 0
    now = startTime
    Events.tick()
    downKey = 82
    now = startTime + 1
    Events.tick()
    now = startTime + 601
    Events.tick()
    downKey = 0
    pressedKey = 0
    now = startTime + 602
    Events.tick()
end

triggerDebugKey(0)
local first = PsychopatzDebugWindow.instance
assert(first ~= nil, "Numpad 0 did not open the debug window")
assert(created == 1, "opening the debug window created the wrong number of instances")
assert(first.added == true, "debug window was not added to the UI manager")

local function selected(value)
    return { isSelected = function() return value end }
end
local function text(value)
    return { getText = function() return value end }
end
first.chkDebugAccess = selected(false)
first.chkSpawn = selected(true)
first.chkHeal = selected(true)
first.chkStats = selected(true)
first.chkMoney = selected(false)
first.chkWalkie = selected(false)
first.chkNight = selected(false)
first.qtyMoney = text("100")
first.qtyWalkie = text("1")
first.itemEntry = text("Base.Katana")
first.qtyEntry = text("1")

triggerDebugKey(1000)
assert(created == 1, "pressing Numpad 0 on an open window created a duplicate")
assert(PsychopatzDebugWindow.instance == first,
    "executing unexpectedly replaced the singleton")
assert(first.visible == true and first.removed ~= true,
    "executing unexpectedly closed and removed the debug window")
assert(#commands == 2 and commands[2].command == "GrantPowers",
    "Numpad 0 did not invoke the execute action")
assert(commands[2].args.itemID == "Base.Katana" and commands[2].args.doSpawn == true,
    "execute action did not use the selected controls")

triggerDebugKey(2000)
assert(PsychopatzDebugWindow.instance == first,
    "repeated access did not preserve the debug window")
assert(#commands == 4 and commands[4].command == "GrantPowers",
    "repeated access did not trigger the command again")
assert(commands[4].args.itemID == "Base.Katana",
    "repeated access did not preserve the form data")

first:setX(321)
first:setY(456)
first:close()
assert(PsychopatzDebugWindow.instance == nil,
    "manual close left a stale singleton instance")

triggerDebugKey(3000)
local second = PsychopatzDebugWindow.instance
assert(second ~= nil and second ~= first, "closed debug window was not replaceable")
assert(created == 2, "reopening the debug window created the wrong number of instances")
assert(second.x == 321 and second.y == 456,
    "reopening the debug window did not restore its saved position")

second:close()
assert(PsychopatzDebugWindow.instance == nil, "manual close left a stale singleton instance")

print("psychopatz_debug_window_smoke: ok")
