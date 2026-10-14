local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy", 2) end
end

local function near(actual, expected, tolerance, label)
    if math.abs(actual - expected) > (tolerance or 0.01) then
        error((label or "near") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local Base = {}
Base.__index = Base
function Base:derive(name)
    local class = setmetatable({ __name = name }, { __index = self })
    class.__index = class
    return class
end
function Base:new(x, y, width, height)
    return setmetatable({ x = x, y = y, width = width, height = height,
        visible = true, children = {} }, self)
end
function Base:initialise() end
function Base:createChildren() end
function Base:instantiate() self:createChildren() end
function Base:addChild(child)
    self.children[#self.children + 1] = child
    child.parent = self
end
function Base:setVisible(value) self.visible = value end
function Base:getIsVisible() return self.visible end
function Base:addToUIManager() self.added = true end
function Base:removeFromUIManager() self.added = false end
function Base:bringToTop() self.broughtToTop = true end
function Base:setX(value) self.x = value end
function Base:setY(value) self.y = value end
function Base:setWidth(value) self.width = value end
function Base:setHeight(value) self.height = value end
function Base:getX() return self.x end
function Base:getY() return self.y end
function Base:getWidth() return self.width end
function Base:getHeight() return self.height end
function Base:setCapture(value) self.captured = value end
function Base:drawSubTexture(...) self.draws = (self.draws or 0) + 1 end
function Base:drawText(...) self.textDraws = (self.textDraws or 0) + 1 end
function Base:drawRect(...) end
function Base:drawRectBorder(...) end
function Base:setStencilRect(...) self.stenciled = true end
function Base:clearStencilRect() self.stenciled = false end
function Base:prerender() end
function Base:render() end

package.preload["ISUI/ISPanel"] = function()
    _G.ISPanel = Base
    return Base
end
package.preload["ISUI/ISUI3DModel"] = function()
    error("portrait engine intentionally unavailable in this UI mock")
end
package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISContextMenu"] = function() return true end
package.preload["RadioCom/ISRadioWindow"] = function() return true end

UIFont = { Tiny = 1, Small = 2 }
getTextManager = function()
    return {
        MeasureStringX = function(_, _, value) return #tostring(value) * 6 end,
        MeasureStringY = function() return 10 end,
    }
end
getCore = function()
    return {
        getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 900 end,
    }
end
getTexture = function(path) return { path = path } end

PsychopatzCore = {}
dofile(COMMON .. "PsychopatzCore/Radio/PC_RadioDeviceState.lua")
local player = {}
getSpecificPlayer = function() return player end
local device = {
    fullType = "Base.WalkieTalkie5",
    getFullType = function(self) return self.fullType end,
    getIsPortable = function() return true end,
    getIsTwoWay = function() return true end,
    getIsTelevision = function() return false end,
    getIsTurnedOn = function() return true end,
    getPower = function() return 1 end,
    getDeviceVolume = function() return 1 end,
    getMicIsMuted = function() return false end,
}

local OS = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS.lua")
local customMoves = 0
local customSelected = false
local customScreenSelected = false
truthy(OS.RegisterApp({
    id = "mock:custom",
    ownerModID = "MockPlugin",
    label = "Custom",
    order = 30,
    open = function() return "custom" end,
    onMove = function(_, _, delta) customMoves = customMoves + delta end,
    onSelect = function() customSelected = true; return true end,
    hitTest = function() return { row = 1 } end,
    onScreenClick = function(_, _, value)
        customScreenSelected = value and value.row == 1
        return customScreenSelected
    end,
}), "custom app registration")
local requested = 0
truthy(OS.RegisterContactProvider({
    id = "mock:contacts",
    ownerModID = "MockPlugin",
    list = function()
        return { contacts = {
            { id = "npc-1", title = "Riley", status = "known",
                actions = { "mock:call" } },
        } }
    end,
    invoke = function()
        requested = requested + 1
        return true
    end,
}), "window provider")

local window = assert(OS.Open(0, device, { scale = 1 }))
equal(window.page, "home", "initial page")
window:prerender()
window:render()
truthy((window.draws or 0) >= 5, "atlas rendering")
truthy((window.textDraws or 0) >= 1, "screen text rendering")

local homeLayout = window:screenListLayout(#OS.ListApps(window.context), 3,
    window.homeIndex, window:headerLayout(window:statusLine()))
local homeRow = window:screenRowRect(homeLayout, 0)
truthy(window:homeRowAt(homeRow.x + 1, homeRow.y + 1),
    "home row hit-test")
window:onMouseDown(homeRow.x + 1, homeRow.y + 1)
equal(window.page, "contacts", "home row navigation")

local contactRow = window:screenRowRect(
    window:screenListLayout(#window.contacts, 2, window.contactIndex,
        window:headerLayout(window.contactStatus or window:statusLine())), 0)
truthy(window:contactRowAt(contactRow.x + 1, contactRow.y + 1),
    "contact row hit-test")
window:onMouseDown(contactRow.x + 1, contactRow.y + 1)
equal(window.page, "contact_detail", "contact row navigation")
window:onMouseDown(window:screenRect().x + 2, window:screenRect().y + 40)
equal(requested, 1, "direct contact action dispatch")

local center = window:controlRect("center")
window:onMouseDown(window:controlRect("left").x + 1,
    window:controlRect("left").y + 1)
equal(window.page, "contacts", "detail back navigation")
window:back()
equal(window.page, "home", "home back navigation")

local beforeX, beforeY = window:getX(), window:getY()
window:onMouseDown(10, 200)
window:onMouseMove(24, 13)
window:onMouseUp()
truthy(window:getX() ~= beforeX or window:getY() ~= beforeY,
    "shell drag moves the window")

local beforeScale = window.scale
window:onMouseDown(window:getWidth() - 2, window:getHeight() - 2)
window:onMouseMove(24, 24)
window:onMouseUp()
truthy(window.scale > beforeScale, "resize grip changes uniform scale")
near(window:getWidth() / window:getHeight(), 256 / 432, 0.01,
    "resize preserves shell aspect ratio")
local savedX, savedY, savedScale = window:getX(), window:getY(), window.scale
window:close()
equal(OS.GetOpenWindow(0), nil, "window cleanup")

local restored = assert(OS.Open(0, device))
equal(restored:getX(), savedX, "player-local position x persists")
equal(restored:getY(), savedY, "player-local position y persists")
equal(restored.scale, savedScale, "player-local scale persists")
restored:close()

local host = { visible = true }
function host:setVisible(value) self.visible = value end
function host:bringToTop() self.broughtToTop = true end
local hosted = assert(OS.Open(0, device, { scale = 1, hostWindow = host }))
equal(host.visible, false, "native host is hidden while OS is open")
hosted:close()
equal(host.visible, true, "native host is restored on close")

OS.UnregisterContactProvider("mock:contacts")

local customWindow = assert(OS.Open(0, device, { scale = 1 }))
customWindow:pressControl("right")
customWindow:pressControl("center")
equal(customWindow.page, "custom", "custom app navigation")
customWindow:pressControl("right")
equal(customMoves, 1, "custom app movement")
customWindow:pressControl("center")
truthy(customSelected, "custom app selection")
local customScreen = customWindow:screenRect()
customWindow:onMouseDown(customScreen.x + 4, customScreen.y + 30)
truthy(customScreenSelected, "custom app screen click")
customWindow:back()
equal(customWindow.page, "home", "custom app back navigation")
customWindow:close()
OS.UnregisterApp("mock:custom")

print("psychopatz_radio_os_window_smoke: ok")
