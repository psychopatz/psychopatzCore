local CLIENT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local created = 0
local keyHandler
local commands = {}

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

package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISLabel"] = function() return true end
package.preload["ISUI/ISTextEntryBox"] = function() return true end
package.preload["ISUI/ISTickBox"] = function() return true end
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
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
    setY = function(self, y)
        self.y = y
    end,
    getHeight = function(self)
        return self.height
    end,
}
package.preload["ISUI/ISCollapsableWindow"] = function()
    return ISCollapsableWindow
end

Events = {
    OnKeyPressed = {
        Add = function(handler) keyHandler = handler end,
    },
    OnTick = {
        Add = function() end,
    },
}
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

assert(keyHandler, "debug key handler was not registered")
assert(PsychopatzDebugWindow.instance == nil, "debug window existed before opening")

keyHandler(82)
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

keyHandler(82)
assert(created == 1, "pressing Numpad 0 on an open window created a duplicate")
assert(PsychopatzDebugWindow.instance == first, "executing closed the singleton instance")
assert(first.visible == true, "executing hid the debug window")
assert(#commands == 2 and commands[2].command == "GrantPowers",
    "Numpad 0 did not invoke the execute action")
assert(commands[2].args.itemID == "Base.Katana" and commands[2].args.doSpawn == true,
    "execute action did not use the selected controls")

first:close()
assert(PsychopatzDebugWindow.instance == nil, "manual close left a stale singleton instance")

keyHandler(82)
local second = PsychopatzDebugWindow.instance
assert(second ~= nil and second ~= first, "closed debug window was not replaceable")
assert(created == 2, "reopening the debug window created the wrong number of instances")

second:close()
assert(PsychopatzDebugWindow.instance == nil, "manual close left a stale singleton instance")

print("psychopatz_debug_window_smoke: ok")
