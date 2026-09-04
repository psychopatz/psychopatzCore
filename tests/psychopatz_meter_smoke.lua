local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = ROOT .. "?.lua;" .. package.path

UIFont = { Small = 1 }

local Base = {}
function Base:derive()
    local child = {}
    child.__index = child
    setmetatable(child, { __index = self })
    return child
end
function Base:new(x, y, width, height)
    return setmetatable({ x = x, y = y, width = width, height = height }, {
        __index = self,
    })
end
function Base:initialise() end
ISUIElement = Base

package.preload["ISUI/ISUIElement"] = function() return Base end
package.preload["PsychopatzCore/UI/Core/PsychopatzUITheme"] = function()
    return PsychopatzCore.UI.Theme
end

PsychopatzCore = { UI = { Theme = {
    colors = {
        surfaceRaised = { r = 0, g = 0, b = 0, a = 1 },
        borderStrong = { r = 1, g = 1, b = 1, a = 1 },
        text = { r = 1, g = 1, b = 1, a = 1 },
        accent = { r = 0, g = 1, b = 1, a = 1 },
        danger = { r = 1, g = 0, b = 0, a = 1 },
        success = { r = 0, g = 1, b = 0, a = 1 },
    },
    FontHeight = function() return 10 end,
    TextWidth = function(_, value) return #tostring(value or "") end,
} } }

local Meter = dofile(ROOT
    .. "PsychopatzCore/UI/Components/PsychopatzMeter.lua")

local ratio, value = Meter.Normalize(125, 0, 100)
assert(ratio == 1 and value == 100, "meter maximum clamp")
ratio, value = Meter.Normalize(-5, 0, 100)
assert(ratio == 0 and value == 0, "meter minimum clamp")

local color = Meter.ResolveColor({ thresholds = {
    { maximum = 0.25, color = "danger" },
    { maximum = 1, color = "success" },
} }, 0.2, 20)
assert(color == PsychopatzCore.UI.Theme.colors.danger,
    "threshold color selection")

local draws = {}
local canvas = {
    drawRect = function(_, x, y, width, height)
        draws[#draws + 1] = { x = x, y = y, width = width, height = height }
    end,
    drawRectBorder = function() end,
    drawTextCentre = function(_, text) draws.text = text end,
}
ratio, value = Meter.Draw(canvas, {
    width = 102, height = 18, value = 35, maximum = 100,
    colorName = "accent", decimals = 1,
})
assert(ratio == 0.35 and value == 35, "meter render value")
assert(draws[2].width == 35, "meter proportional fill")
assert(draws.text == "35.0 / 100.0", "meter actual amount text")

local widget = PsychopatzMeter:new(0, 0, 120, 20, { value = 10 })
widget:setValue(45)
widget:setStyle({ colorName = "success", showMaximum = false })
assert(widget.spec.value == 45, "standalone meter value update")
assert(widget.spec.colorName == "success", "standalone meter style update")

print("psychopatz_meter_smoke: ok")
