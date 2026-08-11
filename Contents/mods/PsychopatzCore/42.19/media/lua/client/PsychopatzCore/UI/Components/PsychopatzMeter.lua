require "ISUI/ISUIElement"
require "PsychopatzCore/UI/Core/PsychopatzUITheme"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Meter = UI.Meter or {}
UI.Meter = Meter

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function Meter.Normalize(value, minimum, maximum)
    minimum = tonumber(minimum) or 0
    maximum = tonumber(maximum) or 100
    if maximum <= minimum then maximum = minimum + 1 end
    value = clamp(tonumber(value) or minimum, minimum, maximum)
    return (value - minimum) / (maximum - minimum), value,
        minimum, maximum
end

function Meter.ResolveColor(spec, ratio, value)
    if type(spec.colorResolver) == "function" then
        local resolved = spec.colorResolver(value, ratio, spec)
        if type(resolved) == "table" then return resolved end
        if resolved then return Theme.colors[resolved] or Theme.colors.accent end
    end
    for _, threshold in ipairs(spec.thresholds or {}) do
        if ratio <= (tonumber(threshold.maximum) or 1) then
            return type(threshold.color) == "table" and threshold.color
                or Theme.colors[threshold.color] or Theme.colors.accent
        end
    end
    return type(spec.color) == "table" and spec.color
        or Theme.colors[spec.colorName or spec.color or "accent"]
        or Theme.colors.accent
end

function Meter.FormatValue(spec, value, minimum, maximum)
    if type(spec.formatValue) == "function" then
        return tostring(spec.formatValue(value, minimum, maximum, spec))
    end
    local decimals = math.max(0, math.floor(tonumber(spec.decimals) or 0))
    local format = "%0." .. tostring(decimals) .. "f"
    local current = string.format(format, value)
    if spec.showMaximum == false then return current end
    return current .. " / " .. string.format(format, maximum)
end

function Meter.Draw(element, spec)
    spec = type(spec) == "table" and spec or {}
    local x = tonumber(spec.x) or 0
    local y = tonumber(spec.y) or 0
    local width = math.max(1, tonumber(spec.width) or 100)
    local height = math.max(4, tonumber(spec.height) or 16)
    local ratio, value, minimum, maximum = Meter.Normalize(
        spec.value, spec.minimum, spec.maximum
    )
    local background = type(spec.background) == "table" and spec.background
        or Theme.colors[spec.backgroundName or "surfaceRaised"]
        or Theme.colors.surfaceRaised
    local border = type(spec.border) == "table" and spec.border
        or Theme.colors[spec.borderName or "borderStrong"]
        or Theme.colors.borderStrong
    local fill = Meter.ResolveColor(spec, ratio, value)
    element:drawRect(x, y, width, height,
        background.a or 1, background.r, background.g, background.b)
    local innerWidth = math.max(0, math.floor((width - 2) * ratio + 0.5))
    if innerWidth > 0 then
        element:drawRect(x + 1, y + 1, innerWidth, height - 2,
            fill.a or 1, fill.r, fill.g, fill.b)
    end
    element:drawRectBorder(x, y, width, height,
        border.a or 1, border.r, border.g, border.b)
    if spec.showValue ~= false then
        local font = spec.font or UIFont.Small
        local valueText = Meter.FormatValue(spec, value, minimum, maximum)
        local textColor = type(spec.textColor) == "table" and spec.textColor
            or Theme.colors[spec.textColorName or "text"] or Theme.colors.text
        local textY = y + math.floor((height - Theme.FontHeight(font)) / 2)
        if element.drawTextCentre then
            element:drawTextCentre(valueText, x + width / 2, textY,
                textColor.r, textColor.g, textColor.b,
                textColor.a or 1, font)
        end
    end
    return ratio, value
end

PsychopatzMeter = ISUIElement:derive("PsychopatzMeter")

function PsychopatzMeter:initialise()
    ISUIElement.initialise(self)
end

function PsychopatzMeter:setValue(value)
    self.spec.value = tonumber(value) or self.spec.minimum or 0
end

function PsychopatzMeter:setStyle(values)
    for key, value in pairs(type(values) == "table" and values or {}) do
        self.spec[key] = value
    end
end

function PsychopatzMeter:render()
    Meter.Draw(self, {
        x = 0, y = 0, width = self.width, height = self.height,
        value = self.spec.value,
        minimum = self.spec.minimum,
        maximum = self.spec.maximum,
        color = self.spec.color,
        colorName = self.spec.colorName,
        colorResolver = self.spec.colorResolver,
        thresholds = self.spec.thresholds,
        background = self.spec.background,
        backgroundName = self.spec.backgroundName,
        border = self.spec.border,
        borderName = self.spec.borderName,
        textColor = self.spec.textColor,
        textColorName = self.spec.textColorName,
        showValue = self.spec.showValue,
        showMaximum = self.spec.showMaximum,
        decimals = self.spec.decimals,
        formatValue = self.spec.formatValue,
        font = self.spec.font,
    })
end

function PsychopatzMeter:new(x, y, width, height, spec)
    local object = ISUIElement:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.spec = type(spec) == "table" and spec or {}
    return object
end

function UI.CreateMeter(parent, spec)
    spec = type(spec) == "table" and spec or {}
    local meter = PsychopatzMeter:new(
        spec.x or 0, spec.y or 0,
        spec.width or 100, spec.height or 16, spec
    )
    meter:initialise()
    if meter.instantiate then meter:instantiate() end
    if parent then parent:addChild(meter) end
    return meter
end

return Meter
