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
        visible = true, children = {}, events = {} }, self)
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
function Base:drawSubTexture(texture, sx, sy, sw, sh, ...)
    self.draws = (self.draws or 0) + 1
    self.events[#self.events + 1] = {
        kind = "sprite", path = texture and texture.path,
        x = sx, y = sy, w = sw, h = sh,
    }
end
function Base:drawText(...)
    self.textDraws = (self.textDraws or 0) + 1
    self.events[#self.events + 1] = { kind = "text" }
end
function Base:drawRect(...)
    self.events[#self.events + 1] = { kind = "matte" }
end
function Base:drawRectBorder(...)
    self.events[#self.events + 1] = { kind = "border" }
end
function Base:setStencilRect(...)
    self.stenciled = true
    self.events[#self.events + 1] = { kind = "stencil_on" }
end
function Base:clearStencilRect()
    self.stenciled = false
    self.events[#self.events + 1] = { kind = "stencil_off" }
end
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
local viewportWidth, viewportHeight = 1280, 900
getTextManager = function()
    return {
        MeasureStringX = function(_, _, value) return #tostring(value) * 6 end,
        MeasureStringY = function() return 10 end,
    }
end
getCore = function()
    return {
        getScreenWidth = function() return viewportWidth end,
        getScreenHeight = function() return viewportHeight end,
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
local pagedCalls = {}
truthy(OS.RegisterContactProvider({
    id = "mock:paged",
    ownerModID = "MockPlugin",
    list = function(_, page)
        pagedCalls[#pagedCalls + 1] = page.offset
        if page.offset == 0 then
            return {
                contacts = {
                    { id = "paged-1", title = "Yankee", status = "known",
                        actions = {} },
                },
                nextOffset = 1,
            }
        end
        return {
            contacts = {
                { id = "paged-2", title = "Zulu", status = "unknown",
                    actions = {} },
            },
        }
    end,
}), "paged window provider")

local window = assert(OS.Open(0, device, { scale = 1 }))
equal(window.page, "home", "initial page")
window:prerender()
window:render()
truthy((window.draws or 0) >= 5, "atlas rendering")
truthy((window.textDraws or 0) >= 1, "screen text rendering")
truthy(window._spriteDefinitions["icon_contacts"],
    "home icon atlas sprite is rendered")
truthy(window._spriteDefinitions["btn_sq_green_idle"],
    "physical button atlas state is rendered")
local function firstEvent(kind, start)
    for index = start or 1, #window.events do
        if window.events[index].kind == kind then return index end
    end
    return nil
end
equal(window.events[1].kind, "matte", "opaque LCD matte is first")
local stencilOn = firstEvent("stencil_on")
local stencilOff = firstEvent("stencil_off")
truthy(stencilOn and stencilOff and stencilOn < stencilOff,
    "screen stencil is reset")
truthy(window:lcdBackdropRect().w >= window:screenRect().w,
    "LCD aperture contains content viewport")
truthy(window:lcdBackdropRect().h >= window:screenRect().h,
    "LCD aperture height contains content viewport")
local shellEvent
for index = stencilOff + 1, #window.events do
    local event = window.events[index]
    if event.kind == "sprite"
        and event.path
        and string.find(event.path, "DTA_Walkie_Shells", 1, true)
    then
        shellEvent = index
        break
    end
end
truthy(shellEvent and shellEvent > stencilOff,
    "shell is composited after clipped content")
local integerScreen = window:screenRect()
truthy(integerScreen.x == math.floor(integerScreen.x)
    and integerScreen.y == math.floor(integerScreen.y)
    and integerScreen.w == math.floor(integerScreen.w)
    and integerScreen.h == math.floor(integerScreen.h),
    "screen transform is pixel snapped")

local Geometry = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSGeometry"
local minimum720, maximum720 = Geometry.GetScaleLimits(1280, 720)
local minimum1080, maximum1080 = Geometry.GetScaleLimits(1920, 1080)
local minimum1440, maximum1440 = Geometry.GetScaleLimits(2560, 1440)
local minimum4K, maximum4K = Geometry.GetScaleLimits(3840, 2160)
truthy(minimum720 <= maximum720 and maximum720 < maximum1080
    and maximum1080 < maximum1440 and maximum1440 < maximum4K,
    "scale limits follow available viewport")

local settingsIndex
for index, app in ipairs(OS.ListApps(window.context)) do
    if app.id == "psychopatzcore:settings" then
        settingsIndex = index
        break
    end
end
truthy(settingsIndex, "settings app is discoverable")
window.homeIndex = settingsIndex
truthy(window:openSelectedApp(), "settings app opens")
equal(window.page, "settings", "settings page")
local settingsScale = window.scale
window.settingsIndex = 1
truthy(window:select(), "zoom in action")
truthy(window.scale > settingsScale, "zoom in changes scale")
window.settingsIndex = 2
truthy(window:select(), "zoom out action")
near(window.scale, settingsScale, 0.001, "zoom out restores scale")
window.settingsIndex = 4
truthy(window:select(), "fit action")
equal(window.scale, window.maxScale, "fit uses viewport maximum")
window.settingsIndex = 3
truthy(window:select(), "reset action")
near(window.scale, Geometry.GetPreferredScale(), 0.001,
    "reset uses responsive default")
window:back()
equal(window.page, "home", "settings back navigation")
window.homeIndex = 1
OS.SetCompositorDebug(true)
window:prerender()
window:render()
truthy(window.debugCompositor, "debug compositor can be enabled")
OS.SetCompositorDebug(false)
viewportWidth, viewportHeight = 1280, 720
window:prerender()
equal(window.maxScale, maximum720, "resolution change updates max scale")
truthy(window:getX() + window:getWidth() <= viewportWidth
    and window:getY() + window:getHeight() <= viewportHeight,
    "resolution change clamps radio into viewport")
viewportWidth, viewportHeight = 1920, 1080
window:prerender()
equal(window.maxScale, maximum1080, "larger resolution restores scale ceiling")

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

local callsBeforeRefresh = #pagedCalls
window:ensureContacts(true)
equal(#pagedCalls - callsBeforeRefresh, 2,
    "contact provider pagination is bounded and followed")
truthy(window.contacts[1] and window.contacts[2]
    and window.contacts[3], "paged contacts are collected")
equal(window.selectedContact and window.selectedContact.id, "npc-1",
    "selected contact survives provider refresh")

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

local otherDevice = {}
for key, value in pairs(device) do otherDevice[key] = value end
otherDevice.fullType = "Base.WalkieTalkie1"
local otherWindow = assert(OS.Open(0, otherDevice, { scale = 0.9 }))
otherWindow:moveBy(17, 0)
otherWindow:close()
local firstSkinAgain = assert(OS.Open(0, device))
equal(firstSkinAgain:getX(), savedX,
    "radio geometry is scoped by device skin")
equal(firstSkinAgain.scale, savedScale,
    "radio scale is scoped by device skin")
firstSkinAgain:close()

local host = { visible = true }
function host:setVisible(value) self.visible = value end
function host:bringToTop() self.broughtToTop = true end
local hosted = assert(OS.Open(0, device, { scale = 1, hostWindow = host }))
equal(host.visible, false, "native host is hidden while OS is open")
hosted:close()
equal(host.visible, true, "native host is restored on close")

OS.UnregisterContactProvider("mock:contacts")
OS.UnregisterContactProvider("mock:paged")

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
customWindow.page = "custom"
customWindow.drawScreenContent = function()
    error("intentional compositor smoke failure")
end
customWindow:drawScreen()
truthy(customWindow.stenciled == false,
    "stencil resets after screen render failure")
customWindow:back()
equal(customWindow.page, "home", "custom app back navigation")
customWindow:close()
OS.UnregisterApp("mock:custom")

print("psychopatz_radio_os_window_smoke: ok")
