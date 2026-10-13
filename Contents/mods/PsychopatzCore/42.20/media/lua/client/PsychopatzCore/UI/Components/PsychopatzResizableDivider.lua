require "ISUI/ISResizeableButton"
require "PsychopatzCore/UI/Core/PsychopatzUITheme"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Theme = UI.Theme

local function clamp(value, minimum, maximum)
    minimum = tonumber(minimum) or 0
    maximum = tonumber(maximum) or minimum
    if maximum < minimum then maximum = minimum end
    return math.max(minimum, math.min(maximum, value))
end

-- This follows the same mouse contract as the base game's
-- ISResizableButton: hover state is tracked separately from the normal
-- button state, capture owns the drag, and movement continues outside the
-- original hit box until mouse-up.
local Divider = ISResizableButton:derive("PsychopatzResizableDivider")
UI.ResizableDivider = Divider

function Divider:initialise()
    ISButton.initialise(self)
    if self.setWantMouseEvents then self:setWantMouseEvents(true) end
    self.backgroundColor = Theme.Color("transparent")
    self.backgroundColorMouseOver = Theme.Color("transparent")
    self.borderColor = Theme.Color("transparent")
    self.drawBorder = false
    self.displayBackground = false
end

function Divider:setRange(minimum, maximum)
    self.minimum = tonumber(minimum) or self.minimum or 0
    self.maximum = tonumber(maximum) or self.maximum or self.minimum
    if self.maximum < self.minimum then
        self.maximum = self.minimum
    end
    self:setValue(self.value, true)
    return self.minimum, self.maximum
end

function Divider:setValue(value, silent)
    local nextValue = clamp(tonumber(value) or self.minimum or 0,
        self.minimum or 0, self.maximum or self.minimum or 0)
    local changed = self.value ~= nextValue
    self.value = nextValue
    if changed and silent ~= true and type(self.onChange) == "function" then
        self.onChange(nextValue, self)
    end
    return nextValue
end

function Divider:getValue()
    return self.value
end

function Divider:setEnabled(value)
    local enabled = value ~= false
    -- `enable` is the flag consumed by ISButton.  Keep the descriptive alias
    -- as well because the divider is also used by Core callers that inspect
    -- it directly.
    self.enable = enabled
    self.enabled = enabled
    return enabled
end

function Divider:setEnable(value)
    return self:setEnabled(value)
end

function Divider:onMouseDown(x, y)
    if self.enable == false or self.enabled == false then return true end
    if not self:isMouseOver() then return true end
    self.dragging = true
    self.resizing = true
    self.mouseOverResize = true
    self.mouseOver = false
    self:setCapture(true)
    self:bringToTop()
    return true
end

function Divider:onMouseMove(dx, dy)
    if self.dragging or self.resizing then
        if self.enable == false or self.enabled == false then return true end
        self:setValue((self.value or 0) + (tonumber(dx) or 0))
        return true
    end
    -- ISResizableButton owns the standard hover/capture contract.  The
    -- Workshop uses a wider hit target than the base game's four-pixel edge,
    -- so the whole child is the resize zone.
    ISButton.onMouseMove(self, dx, dy)
    self.mouseOverResize = self:isMouseOver()
    self.mouseOver = false
    return true
end

function Divider:onMouseMoveOutside(dx, dy)
    if self.dragging or self.resizing then
        if self.enable == false or self.enabled == false then return true end
        self:setValue((self.value or 0) + (tonumber(dx) or 0))
        return true
    end
    ISButton.onMouseMoveOutside(self, dx, dy)
    self.mouseOverResize = false
    return true
end

function Divider:finishDrag()
    if not self.dragging and not self.resizing then return end
    self.dragging = false
    self.resizing = false
    self.mouseOverResize = false
    self:setCapture(false)
    if type(self.onRelease) == "function" then
        return self.onRelease(self.value, self)
    end
end

function Divider:onMouseUp(x, y)
    self:finishDrag()
    return true
end

function Divider:onMouseUpOutside(x, y)
    self:finishDrag()
    return true
end

function Divider:render()
    if self.drawIndicator == false then return end
    local color = Theme.colors.borderStrong or Theme.colors.border
    local alpha = 0.9
    if self.mouseOverResize or self.dragging then
        color = Theme.colors.accent
        alpha = self.dragging and 1 or 0.9
    end
    local width = self:getWidth()
    local lineWidth = math.min(2, math.max(1, width))
    local lineX = math.floor((width - lineWidth) / 2)
    self:drawRectStatic(lineX, 0, lineWidth, self:getHeight(), alpha,
        color.r, color.g, color.b)
end

function Divider:new(x, y, width, height, definition)
    definition = type(definition) == "table" and definition or {}
    local object = ISResizableButton.new(self, x, y, width, height,
        "", nil, nil)
    object.value = tonumber(definition.value) or 0
    object.minimum = tonumber(definition.minimum or definition.min) or 0
    object.maximum = tonumber(definition.maximum or definition.max)
        or object.value
    object.onChange = definition.onChange
    object.onRelease = definition.onRelease
    object.target = definition.target
    object.enable = definition.enabled ~= false
    object.enabled = object.enable
    object.resizing = false
    object.drawIndicator = definition.drawIndicator ~= false
    object.mouseOver = false
    object.mouseOverResize = false
    object.dragging = false
    return object
end

function UI.CreateResizableDivider(parent, definition)
    definition = type(definition) == "table" and definition or {}
    local divider = Divider:new(0, 0,
        tonumber(definition.width) or 8,
        tonumber(definition.height) or 100,
        definition)
    divider:initialise()
    divider:instantiate()
    -- Set this again after Java construction so the native child consumes
    -- the gap even when a parent created it with a different default.
    divider:setWantMouseEvents(true)
    if parent then parent:addChild(divider) end
    return divider
end

return UI
