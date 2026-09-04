local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/"
package.path = ROOT .. "?.lua;" .. package.path

local Base = {}
Base.__index = Base
function Base:derive()
    local child = {}
    child.__index = child
    setmetatable(child, { __index = self })
    return child
end
function Base:new(x, y, width, height)
    return setmetatable({
        x = x, y = y, width = width, height = height,
    }, { __index = self })
end
function Base:initialise() end
function Base:instantiate() end
function Base:addChild(child) self.child = child end
function Base:getAbsoluteX() return self.x end
function Base:bringToTop() end
function Base:setX(value) self.x = value end
function Base:setY(value) self.y = value end
function Base:setWidth(value) self.width = value end
function Base:setHeight(value) self.height = value end
function Base:drawRect() end
function Base:drawRectBorder() end

ISPanel = Base
PsychopatzCore = { UI = {} }
UIFont = { Small = 1 }
PsychopatzCore.UI.Theme = {
    colors = {
        transparent = { r = 0, g = 0, b = 0, a = 0 },
        surfaceRaised = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
        border = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        borderStrong = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        accent = { r = 0, g = 1, b = 1, a = 1 },
        textMuted = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
    },
    Color = function(_, name)
        return PsychopatzCore.UI.Theme.colors[name]
    end,
}
PsychopatzCore.UI.Layout = {
    Scale = function() return 1 end,
    Pixels = function(value) return math.floor(value + 0.5) end,
}

package.preload["ISUI/ISPanel"] = function() return Base end
package.preload["PsychopatzCore/UI/Core/PsychopatzUITheme"] =
    function() return PsychopatzCore.UI.Theme end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] =
    function() return PsychopatzCore.UI.Layout end

local UI = PsychopatzCore.UI
local changedValue
local parent = { addChild = function(self, child) self.child = child end }
dofile(ROOT .. "Components/PsychopatzSlider.lua")
local slider = UI.CreateSlider(parent, {
    min = 20, max = 100, step = 1, value = 30,
    onChange = function(_, value) changedValue = value end,
})

assert(slider:getValue() == 30, "slider initial value")
assert(slider:setValue(110) == 100, "slider maximum clamp")
assert(changedValue == 100, "slider change callback")
assert(slider:setValue(20) == 20, "slider minimum clamp")
assert(slider:valueFromMouse(-10) == 20, "slider mouse minimum clamp")
assert(slider:valueFromMouse(1000) == 100, "slider mouse maximum clamp")
slider:setValue(55, true)
assert(changedValue == 20, "silent slider update fired callback")
assert(parent.child == slider, "slider parent attachment")

print("psychopatz_slider_smoke: ok")
