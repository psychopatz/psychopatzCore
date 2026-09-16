require "ISUI/ISPanel"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationOpacity"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Opacity = Conversation.Opacity
local Text = Conversation.Text

local ROW_DEFINITIONS = {
    {
        role = "surface",
        key = "UI_PsychopatzConversation_OpacitySurface",
        fallback = "PANEL",
    },
    {
        role = "detail",
        key = "UI_PsychopatzConversation_OpacityContent",
        fallback = "CONTENT",
    },
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function resolve(key, fallback)
    if Text and Text.Resolve then
        return Text.Resolve({ key = key, fallback = fallback })
    end
    return fallback
end

local function percent(value)
    return string.format(
        "%d%%",
        math.floor((tonumber(value) or 0) * 100 + 0.5)
    )
end

local Control = ISPanel:derive("PsychopatzConversationOpacityControl")
PsychopatzCore.Conversation.OpacityControl = Control

function Control:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
end

function Control:refresh(force)
    local signature = Opacity.GetSignature()
    if not force and self.signature == signature then return false end
    for _, row in ipairs(self.rows) do
        local minimum, maximum, value = Opacity.GetRange(
            self.partID,
            row.role
        )
        row.minimum = minimum
        row.maximum = maximum
        row.value = value
    end
    self.signature = signature
    return true
end

function Control:trackBounds()
    local left = 66
    local right = math.max(left + 1, self.width - 42)
    return left, right
end

function Control:rowAt(y)
    for index, _ in ipairs(self.rows) do
        local rowY = 20 + (index - 1) * 27
        if y >= rowY - 3 and y <= rowY + 20 then
            return index
        end
    end
    return nil
end

function Control:valueFromMouse(x, row)
    local left, right = self:trackBounds()
    local ratio = clamp(
        (tonumber(x) or left) - left,
        0,
        math.max(1, right - left)
    ) / math.max(1, right - left)
    return row.minimum + ratio * (row.maximum - row.minimum)
end

function Control:relativeMouseX(fallback)
    if getMouseX and self.getAbsoluteX then
        return getMouseX() - self:getAbsoluteX()
    end
    return fallback
end

function Control:updateFromMouse(x, index, save)
    local row = self.rows[index]
    if not row then return end
    local value = clamp(
        self:valueFromMouse(self:relativeMouseX(x), row),
        row.minimum,
        row.maximum
    )
    -- Surface and content are independent effective-opacity channels. Both
    -- are stored as lifts from the shared conversation base.
    Opacity.SetLift(self.partID, row.role, value - Opacity.GetBase(), save)
    self:refresh(true)
end

function Control:onMouseDown(x, y)
    local index = self:rowAt(y)
    if not index then return false end
    self.dragRow = index
    self:bringToTop()
    self:updateFromMouse(x, index, false)
    return true
end

function Control:onMouseMove(dx, dy)
    if not self.dragRow then return false end
    self:updateFromMouse(dx, self.dragRow, false)
    return true
end

function Control:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function Control:finishDrag(x)
    if not self.dragRow then return false end
    self:updateFromMouse(x, self.dragRow, true)
    self.dragRow = nil
    return true
end

function Control:onMouseUp(x, y)
    return self:finishDrag(x)
end

function Control:onMouseUpOutside(x, y)
    return self:finishDrag(x)
end

function Control:render()
    self:refresh()
    ISPanel.render(self)
    local part = self.owner
    local accent = part and part:getAccentColor()
        or { r = 0.28, g = 0.76, b = 0.62 }
    self:drawRect(
        0, 0, self.width, self.height,
        1.0, 0.005, 0.008, 0.008
    )
    self:drawRectBorder(
        0, 0, self.width, self.height,
        1.0, accent.r, accent.g, accent.b
    )
    self:drawTextCentre(
        resolve("UI_PsychopatzConversation_Opacity", "OPACITY"),
        self.width / 2,
        3,
        0.94, 0.98, 0.98, 1, UIFont.Small
    )
    local left, right = self:trackBounds()
    for index, row in ipairs(self.rows) do
        local rowY = 20 + (index - 1) * 27
        local value = row.value or row.minimum or 0
        local ratio = (value - row.minimum)
            / math.max(0.0001, row.maximum - row.minimum)
        local trackWidth = right - left
        self:drawText(
            resolve(row.key, row.fallback),
            8, rowY - 3,
            0.86, 0.92, 0.92, 1, UIFont.Small
        )
        self:drawTextRight(
            percent(value), self.width - 8, rowY - 3,
            0.94, 0.98, 0.98, 1, UIFont.Small
        )
        self:drawRect(
            left, rowY + 5, trackWidth, 5,
            1.0, 0.08, 0.10, 0.10
        )
        self:drawRect(
            left, rowY + 5,
            math.floor(trackWidth * ratio + 0.5),
            5,
            0.95, accent.r, accent.g, accent.b
        )
        local knobX = math.floor(left + trackWidth * ratio - 3)
        self:drawRect(
            knobX, rowY, 6, 15,
            1, accent.r, accent.g, accent.b
        )
    end
end

function Control:new(x, y, width, height, options)
    options = options or {}
    local object = ISPanel.new(self, x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.owner = options.owner
    object.partID = options.partID or "history"
    object.signature = nil
    object.dragRow = nil
    object.rows = {}
    for index, definition in ipairs(ROW_DEFINITIONS) do
        object.rows[index] = {
            role = definition.role,
            key = definition.key,
            fallback = definition.fallback,
        }
    end
    return object
end

return Control
