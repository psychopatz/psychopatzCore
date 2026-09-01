require "ISUI/ISPanel"
require "PsychopatzCore/UI/Core/PsychopatzUITheme"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function normaliseRange(minimum, maximum)
    minimum = tonumber(minimum) or 0
    maximum = tonumber(maximum) or 1
    if maximum < minimum then minimum, maximum = maximum, minimum end
    if maximum == minimum then maximum = minimum + 1 end
    return minimum, maximum
end

local function snap(value, minimum, maximum, step)
    value = clamp(value, minimum, maximum)
    step = tonumber(step) or 0
    if step > 0 then
        value = minimum + math.floor(((value - minimum) / step) + 0.5) * step
        value = clamp(value, minimum, maximum)
    end
    return value
end

local Slider = ISPanel:derive("PsychopatzSlider")
PsychopatzCore.UI.Slider = Slider

function Slider:initialise()
    ISPanel.initialise(self)
    self.backgroundColor = Theme.Color("transparent")
    self.borderColor = Theme.Color("transparent")
    self.drawBorder = false
end

function Slider:getRatio()
    return (self.value - self.minimum) / (self.maximum - self.minimum)
end

function Slider:getValue()
    return self.value
end

function Slider:getPercent()
    return self:getRatio() * 100
end

function Slider:getValueText()
    if type(self.formatValue) == "function" then
        return tostring(self.formatValue(self.value, self))
    end
    return tostring(self.value)
end

function Slider:setRange(minimum, maximum, step, silent)
    self.minimum, self.maximum = normaliseRange(minimum, maximum)
    self.step = tonumber(step) or self.step or 0
    return self:setValue(self.value, silent)
end

function Slider:setValue(value, silent)
    local nextValue = snap(tonumber(value) or self.minimum,
        self.minimum, self.maximum, self.step)
    local changed = self.value ~= nextValue
    self.value = nextValue
    if changed and silent ~= true and type(self.onChange) == "function" then
        self.onChange(self.target or self, nextValue, self)
    end
    return nextValue
end

function Slider:setEnabled(value)
    self.enabled = value ~= false
    return self.enabled
end

function Slider:setEnable(value)
    return self:setEnabled(value)
end

-- Form rows and external Core consumers can update this without reaching into
-- the implementation field. The next render then uses the same scale for the
-- track, fill, and knob.
function Slider:setUIScale(value)
    self.uiScale = tonumber(value) or Layout.Scale()
    return self.uiScale
end

function Slider:syncUIScale()
    local parentScale = self.parent and self.parent.uiScale
    if parentScale ~= nil then self:setUIScale(parentScale) end
    return self.uiScale
end

function Slider:isEnabled()
    return self.enabled ~= false
end

function Slider:trackBounds()
    local scale = self:syncUIScale() or Layout.Scale()
    local padding = Layout.Pixels(8, scale)
    local left = padding
    local width = self.getWidth and self:getWidth() or self.width or 0
    local right = math.max(left + 1, width - padding)
    return left, right, scale
end

function Slider:valueFromMouse(relativeX)
    local left, right = self:trackBounds()
    local ratio = clamp((tonumber(relativeX) or left) - left,
        0, math.max(1, right - left)) / math.max(1, right - left)
    return self.minimum + ratio * (self.maximum - self.minimum)
end

function Slider:relativeMouseX(fallback)
    if getMouseX and self.getAbsoluteX then
        return getMouseX() - self:getAbsoluteX()
    end
    return fallback
end

function Slider:updateFromMouse(relativeX)
    return self:setValue(self:valueFromMouse(
        self:relativeMouseX(relativeX)))
end

function Slider:onMouseDown(x, y)
    if not self:isEnabled() then return true end
    self.dragging = true
    self:bringToTop()
    self:updateFromMouse(x)
    return true
end

function Slider:onMouseMove(dx, dy)
    if self.dragging and self:isEnabled() then
        self:updateFromMouse(dx)
    end
end

function Slider:onMouseMoveOutside(dx, dy)
    if self.dragging and self:isEnabled() then
        self:updateFromMouse(dx)
    end
end

function Slider:finishDrag(x)
    if not self.dragging then return end
    self:updateFromMouse(x)
    self.dragging = false
    if type(self.onRelease) == "function" then
        return self.onRelease(self.target or self, self.value, self)
    end
end

function Slider:onMouseUp(x, y)
    self:finishDrag(x)
end

function Slider:onMouseUpOutside(x, y)
    self:finishDrag(x)
end

function Slider:render()
    local scale = self:syncUIScale() or Layout.Scale()
    local left, right = self:trackBounds()
    local trackHeight = Layout.Pixels(6, scale)
    local height = self.getHeight and self:getHeight() or self.height or 0
    local trackY = math.floor((height - trackHeight) / 2)
    local trackWidth = math.max(1, right - left)
    local ratio = self:getRatio()
    local background = Theme.colors.surfaceRaised
    local border = Theme.colors.border
    local fill = self:isEnabled() and Theme.colors.accent
        or Theme.colors.textMuted
    self:drawRect(left, trackY, trackWidth, trackHeight,
        background.a, background.r, background.g, background.b)
    local fillWidth = math.floor(trackWidth * ratio + 0.5)
    if fillWidth > 0 then
        self:drawRect(left, trackY, fillWidth, trackHeight,
            fill.a, fill.r, fill.g, fill.b)
    end
    self:drawRectBorder(left, trackY, trackWidth, trackHeight,
        border.a, border.r, border.g, border.b)
    local knobWidth = Layout.Pixels(5, scale)
    local knobHeight = Layout.Pixels(18, scale)
    local knobX = math.floor(left + trackWidth * ratio - knobWidth / 2)
    local knobY = math.floor((height - knobHeight) / 2)
    self:drawRect(knobX, knobY, knobWidth, knobHeight,
        fill.a, fill.r, fill.g, fill.b)
    self:drawRectBorder(knobX, knobY, knobWidth, knobHeight,
        Theme.colors.borderStrong.a, Theme.colors.borderStrong.r,
        Theme.colors.borderStrong.g, Theme.colors.borderStrong.b)
end

function Slider:prerender()
    self:syncUIScale()
    if ISPanel.prerender then ISPanel.prerender(self) end
end

function Slider:new(x, y, width, height, definition)
    local object = ISPanel:new(x, y, width, height)
    definition = type(definition) == "table" and definition or {}
    setmetatable(object, self)
    self.__index = self
    object.minimum, object.maximum = normaliseRange(
        definition.min or definition.minimum,
        definition.max or definition.maximum)
    object.step = tonumber(definition.step) or 0
    object.value = snap(tonumber(definition.value) or object.minimum,
        object.minimum, object.maximum, object.step)
    object.target = definition.target
    object.onChange = definition.onChange
    object.onRelease = definition.onRelease
    object.formatValue = definition.formatValue
    object.internal = definition.id
    object.psychopatzPreferredWidth = definition.preferredWidth
        or definition.width
    object.uiScale = definition.scale or Layout.Scale()
    object.enabled = definition.enabled ~= false
    return object
end

function UI.CreateSlider(parent, definition)
    definition = type(definition) == "table" and definition or {}
    local slider = Slider:new(
        tonumber(definition.x) or 0,
        tonumber(definition.y) or 0,
        tonumber(definition.width) or 180,
        tonumber(definition.height) or Layout.Pixels(24),
        definition
    )
    slider:initialise()
    if slider.instantiate then slider:instantiate() end
    if parent then parent:addChild(slider) end
    return slider
end

return UI
