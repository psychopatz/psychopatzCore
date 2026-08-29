local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local files = {}
Events = {
    OnGameBoot = { Add = function(callback) Events.boot = callback end },
}
getFileWriter = function(name)
    local chunks = {}
    return {
        write = function(_, value) chunks[#chunks + 1] = value end,
        close = function() files[name] = table.concat(chunks) end,
    }
end
getFileReader = function(name)
    local content = files[name]
    if not content then return nil end
    local lines = {}
    for line in string.gmatch(content, "([^\r\n]+)") do lines[#lines + 1] = line end
    local index = 0
    return {
        readLine = function()
            index = index + 1
            return lines[index]
        end,
        close = function() end,
    }
end

PsychopatzCore = {}
dofile(ROOT .. "Settings/PsychopatzSettings.lua")
local store = PsychopatzCore.Settings.Open("Smoke", {
    fileName = "Smoke.txt",
    defaults = { enabled = true, volume = 0.5, label = "default" },
    autoLoad = false,
})
local stableValues = store.values
store:Set("enabled", false, false)
store:Set("volume", 0.75, false)
store:Set("label", "saved", false)
store:SetWindowState("Main", 40, 50, 640, 480, false)
assertEqual(store:Save(), true, "settings save")
store:Set("enabled", true, false)
store:ClearWindowState("Main", false)
assertEqual(store:Load(), true, "settings load")
assertEqual(store.values, stableValues, "settings table identity")
assertEqual(store:Get("enabled"), false, "boolean round trip")
assertEqual(store:Get("volume"), 0.75, "number round trip")
assertEqual(store:Get("label"), "saved", "string round trip")
assertEqual(store:GetWindowState("Main").w, 640, "window state round trip")
local reopened = PsychopatzCore.Settings.Open("Smoke", {
    defaults = { enabled = true, newSetting = "added" },
    autoLoad = false,
})
assertEqual(reopened, store, "settings store reused")
assertEqual(reopened:Get("enabled"), false, "existing value preserved on reopen")
assertEqual(reopened:Get("newSetting"), "added", "new default merged on reopen")

package.preload["PsychopatzCore/UI/Core/PsychopatzUITheme"] = function() return true end
PsychopatzCore.UI = {
    Theme = {
        metrics = {
            baselineWidth = 1920,
            baselineHeight = 1080,
            minimumScale = 1,
            maximumScale = 1,
            screenMargin = 10,
            padding = 10,
            spacing = 6,
            controlHeight = 24,
            compactBreakpoint = 700,
        },
        colors = { accent = { r = 1, g = 1, b = 1 } },
        Color = function() return {} end,
        TextWidth = function(_, value) return #tostring(value or "") end,
    },
}
getCore = function()
    return { getScreenWidth = function() return 1000 end, getScreenHeight = function() return 800 end }
end
dofile(ROOT .. "UI/Core/PsychopatzUILayout.lua")
local Layout = PsychopatzCore.UI.Layout
UIFont = { Small = 1, Medium = 2 }
assertEqual(Layout.Ellipsize("abcdefgh", UIFont.Small, 6), "abc...",
    "ellipsize keeps text within width")
assertEqual(Layout.Ellipsize("abcdefgh", UIFont.Small, 2), "",
    "ellipsize avoids an overflowing suffix")
assertEqual(Layout.Ellipsize("abc", UIFont.Small, 3), "abc",
    "ellipsize preserves short text")
local x, y = Layout.ResolveAnchor("center", 200, 100, { margin = 10 })
assertEqual(x, 400, "center anchor x")
assertEqual(y, 350, "center anchor y")
x, y = Layout.ResolveAnchor("top-left", 200, 100, { margin = 10 })
assertEqual(x, 10, "top-left anchor x")
assertEqual(y, 10, "top-left anchor y")
x, y = Layout.ResolveAnchor("bottom right", 200, 100, { margin = 10 })
assertEqual(x, 790, "bottom-right anchor x")
assertEqual(y, 690, "bottom-right anchor y")
local scrollbar = { x = -1, y = -1, width = 13, height = -1 }
function scrollbar:getWidth() return self.width end
function scrollbar:setX(value) self.x = value end
function scrollbar:setY(value) self.y = value end
function scrollbar:setHeight(value) self.height = value end
local scrollingControl = { x = 0, y = 0, width = 1, height = 1,
    vscroll = scrollbar, javaObject = {} }
function scrollingControl:getWidth() return self.width end
function scrollingControl:getHeight() return self.height end
function scrollingControl:setX(value) self.x = value end
function scrollingControl:setY(value) self.y = value end
function scrollingControl:setWidth(value) self.width = value end
function scrollingControl:setHeight(value) self.height = value end
function scrollingControl:updateScrollbars()
    self.scrollbarRefreshes = (self.scrollbarRefreshes or 0) + 1
end
Layout.SetBounds(scrollingControl, 5, 6, 240, 180)
assertEqual(scrollbar.x, 227, "responsive vertical scrollbar x")
assertEqual(scrollbar.y, 0, "responsive vertical scrollbar y")
assertEqual(scrollbar.height, 180, "responsive vertical scrollbar height")
assertEqual(scrollingControl.scrollbarRefreshes, 1,
    "responsive bounds refresh native scrollbar state")

package.preload["ISUI/ISCollapsableWindow"] = function() return true end
package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] = function() return true end
package.preload["PsychopatzCore/Settings/PsychopatzSettings"] = function() return PsychopatzCore.Settings end
local BaseWindow = {}
BaseWindow.__index = BaseWindow
function BaseWindow:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function BaseWindow:new(x0, y0, width, height)
    return setmetatable({ x = x0, y = y0, width = width, height = height,
        pin = true, clearStentil = false, isCollapsed = false }, self)
end
function BaseWindow:initialise() end
function BaseWindow:createChildren()
    local function button()
        return {
            visible = false,
            setVisible = function(self, value) self.visible = value end,
            bringToTop = function(self) self.onTop = true end,
        }
    end
    self.collapseButton = button()
    self.pinButton = button()
    self.collapseButton:setVisible(true)
end
function BaseWindow:instantiate()
    if self.javaObject ~= nil then return end
    self.javaObject = {}
    self:createChildren()
end
function BaseWindow:prerender()
    if self.clearStentil then
        self:setStencilRect(0, 0, self.width,
            self.isCollapsed and self:titleBarHeight() or self.height)
    end
end
function BaseWindow:render()
    if self.clearStentil then self:clearStencilRect() end
end
function BaseWindow:setStencilRect(x0, y0, width, height)
    self.stencilRect = { x = x0, y = y0, width = width, height = height }
    self.stencilSetCount = (self.stencilSetCount or 0) + 1
end
function BaseWindow:clearStencilRect()
    self.stencilClearCount = (self.stencilClearCount or 0) + 1
end
function BaseWindow:titleBarHeight() return 18 end
function BaseWindow:drawRect() end
function BaseWindow:close() self.visible = false end
function BaseWindow:removeFromUIManager() self.removed = true end
function BaseWindow:onMouseUp() end
function BaseWindow:onMouseUpOutside() end
function BaseWindow:getX() self:instantiate() return self.x end
function BaseWindow:getY() self:instantiate() return self.y end
function BaseWindow:getWidth() self:instantiate() return self.width end
function BaseWindow:getHeight() self:instantiate() return self.height end
function BaseWindow:setX(value) self.x = value end
function BaseWindow:setY(value) self.y = value end
function BaseWindow:setWidth(value) self.width = value end
function BaseWindow:setHeight(value) self.height = value end
ISCollapsableWindow = BaseWindow
getTimeInMillis = function() return 1000 end
dofile(ROOT .. "UI/PsychopatzWindow.lua")

local TestWindow = PsychopatzWindow:derive("SmokeWindow")
local defaultUnpinned = PsychopatzWindow:new(0, 0, 200, 100, {
    persistGeometry = false,
})
defaultUnpinned:instantiate()
assertEqual(defaultUnpinned.pin, false, "window keeps reusable unpinned default")
assertEqual(defaultUnpinned.collapseButton.visible, false,
    "unpinned window initially hides collapse control")
assertEqual(defaultUnpinned.pinButton.visible, true,
    "unpinned window initially shows pin control")
defaultUnpinned.pin = true
defaultUnpinned:prerender()
assertEqual(defaultUnpinned.collapseButton.visible, true,
    "pin state restores collapse control")
assertEqual(defaultUnpinned.pinButton.visible, false,
    "pin state hides pin control")
defaultUnpinned.pin = false
defaultUnpinned:prerender()
assertEqual(defaultUnpinned.collapseButton.visible, false,
    "unpin state restores pin control")
assertEqual(defaultUnpinned.pinButton.visible, true,
    "unpin state shows pin control")
defaultUnpinned:prerender()
assertEqual(defaultUnpinned.clearStentil, true,
    "window enables child clipping")
assertEqual(defaultUnpinned.stencilRect.height, 100,
    "expanded window clips to its full bounds")
defaultUnpinned:render()
assertEqual(defaultUnpinned.stencilClearCount, 1,
    "expanded window clears its child clip")
local initialPinned = PsychopatzWindow:new(0, 0, 200, 100, {
    persistGeometry = false, pin = true,
})
initialPinned:instantiate()
assertEqual(initialPinned.pin, true, "explicit pinned state retained")
assertEqual(initialPinned.collapseButton.visible, true,
    "pinned window initially shows collapse control")
assertEqual(initialPinned.pinButton.visible, false,
    "pinned window initially hides pin control")

local CollidingWindow = PsychopatzWindow:derive("CollidingWindow")
function CollidingWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    -- Simulate a derived window's toolbar using the old reserved field name.
    self.collapseButton = {
        visible = true,
        setVisible = function(button, value) button.visible = value end,
        bringToTop = function(button) button.onTop = true end,
    }
end
local colliding = CollidingWindow:new(0, 0, 200, 100, {
    persistGeometry = false,
})
colliding:instantiate()
colliding.pin = true
colliding:prerender()
assertEqual(colliding.psychopatzTitlebarCollapseButton.visible, true,
    "pinning survives a derived collapseButton name collision")
assertEqual(colliding.psychopatzTitlebarPinButton.visible, false,
    "pinning hides only the native title-bar pin control")
assertEqual(colliding.collapseButton.visible, true,
    "derived toolbar collapse control is not mutated by pin sync")

local CustomRenderWindow = PsychopatzWindow:derive("CustomRenderWindow")
function CustomRenderWindow:initialise()
    PsychopatzWindow.initialise(self)
end
function CustomRenderWindow:createChildren()
    PsychopatzWindow.createChildren(self)
end
function CustomRenderWindow:render()
    PsychopatzWindow.render(self)
    self.customContentRendered = true
end
local custom = CustomRenderWindow:new(0, 0, 200, 100, {
    persistGeometry = false,
})
custom:initialise()
custom:instantiate()
custom.isCollapsed = true
custom:prerender()
assertEqual(custom.stencilRect.height, 18,
    "collapsed window clips to its title bar")
custom:render()
assertEqual(custom.customContentRendered, true,
    "custom render still runs")
assertEqual(custom.stencilClearCount, 1,
    "custom render clears its child clip after subclass drawing")

local LifecycleWindow = PsychopatzWindow:derive("LifecycleWindow")
function LifecycleWindow:createChildren()
    assertEqual(self.requiredState, "ready",
        "derived state initialized before createChildren")
end
function LifecycleWindow:new(x0, y0, width, height, options)
    local window = PsychopatzWindow.new(self, x0, y0, width, height, options)
    window.requiredState = "ready"
    return window
end
local lifecycle = PsychopatzCore.UI.NewWindow(LifecycleWindow, {
    persistGeometry = false,
    responsiveSpec = { width = 200, height = 100, minWidth = 100, minHeight = 80 },
})
assertEqual(lifecycle.javaObject, nil, "constructor does not instantiate derived window")
assertEqual(lifecycle:getX(), 400, "derived window instantiates after construction")
local derivedKey
PsychopatzCore.UI.NewWindow(TestWindow, {
    geometryAdapter = {
        load = function(key) derivedKey = key return nil end,
        save = function() return true end,
    },
    responsiveSpec = { width = 200, height = 100, minWidth = 100, minHeight = 80 },
})
assertEqual(derivedKey, "SmokeWindow", "derived default persistence key")
local disabledLoads = 0
local disabledSaves = 0
local disabled = PsychopatzCore.UI.NewWindow(TestWindow, {
    persistGeometry = false,
    geometryAdapter = {
        load = function() disabledLoads = disabledLoads + 1 end,
        save = function() disabledSaves = disabledSaves + 1 end,
    },
    anchor = "top_right",
    responsiveSpec = { width = 200, height = 100, minWidth = 100, minHeight = 80 },
})
assertEqual(disabled:getX(), 790, "window anchor x")
assertEqual(disabled:getY(), 10, "window anchor y")
disabled:close()
assertEqual(disabledLoads, 0, "disabled persistence does not load")
assertEqual(disabledSaves, 0, "disabled persistence does not save")

local saved
local adapter = {
    load = function(key)
        assertEqual(key, "Smoke:Main", "custom adapter key")
        return { x = 45, y = 55, w = 420, h = 310 }
    end,
    save = function(_, state) saved = state return true end,
}
local persistent = PsychopatzCore.UI.NewWindow(TestWindow, {
    persistenceNamespace = "Smoke",
    persistenceKey = "Main",
    geometryAdapter = adapter,
    responsiveSpec = { width = 500, height = 400, minWidth = 300, minHeight = 200, maxWidth = 700, maxHeight = 600 },
})
assertEqual(persistent:getX(), 45, "restored x")
assertEqual(persistent:getY(), 55, "restored y")
assertEqual(persistent:getWidth(), 420, "restored width")
assertEqual(persistent:getHeight(), 310, "restored height")
persistent:close()
assertEqual(saved.w, 420, "saved width")
assertEqual(saved.h, 310, "saved height")

local saveAttempts = 0
local retryWindow = PsychopatzCore.UI.NewWindow(TestWindow, {
    persistenceKey = "Retry",
    geometryAdapter = {
        load = function() return nil end,
        save = function()
            saveAttempts = saveAttempts + 1
            return saveAttempts > 1
        end,
    },
    responsiveSpec = { width = 200, height = 100, minWidth = 100, minHeight = 80 },
})
assertEqual(retryWindow:saveGeometry(false), false, "failed geometry save reported")
assertEqual(retryWindow:saveGeometry(false), true, "failed geometry save retried")
assertEqual(saveAttempts, 2, "geometry save retry count")

print("psychopatz_core_smoke: ok")
