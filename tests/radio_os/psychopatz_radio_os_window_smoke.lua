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

UIFont = { Small = 1 }
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
truthy(OS.RegisterApp({
    id = "mock:custom",
    ownerModID = "MockPlugin",
    label = "Custom",
    order = 30,
    open = function() return "custom" end,
    onMove = function(_, _, delta) customMoves = customMoves + delta end,
    onSelect = function() customSelected = true; return true end,
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

local center = window:controlRect("center")
window:onMouseDown(center.x + 1, center.y + 1)
equal(window.page, "contacts", "contacts navigation")
window:prerender()
window:onMouseDown(center.x + 1, center.y + 1)
equal(window.page, "contact_detail", "contact navigation")
window:onMouseDown(center.x + 1, center.y + 1)
equal(requested, 1, "provider action dispatch")
window:onMouseDown(window:controlRect("left").x + 1,
    window:controlRect("left").y + 1)
equal(window.page, "contacts", "detail back navigation")
window:back()
equal(window.page, "home", "home back navigation")
window:close()
equal(OS.GetOpenWindow(0), nil, "window cleanup")
OS.UnregisterContactProvider("mock:contacts")

local customWindow = assert(OS.Open(0, device, { scale = 1 }))
customWindow:pressControl("right")
customWindow:pressControl("center")
equal(customWindow.page, "custom", "custom app navigation")
customWindow:pressControl("right")
equal(customMoves, 1, "custom app movement")
customWindow:pressControl("center")
truthy(customSelected, "custom app selection")
customWindow:back()
equal(customWindow.page, "home", "custom app back navigation")
customWindow:close()
OS.UnregisterApp("mock:custom")

print("psychopatz_radio_os_window_smoke: ok")
