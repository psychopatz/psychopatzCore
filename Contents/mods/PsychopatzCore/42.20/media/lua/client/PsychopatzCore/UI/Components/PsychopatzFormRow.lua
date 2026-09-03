-- Reusable transparent form row for Core and external mod panels.

require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "PsychopatzCore/UI/Core/PsychopatzUITheme"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function createLabel(parent, text, color)
    local value = color or Theme.colors.text
    local labelText = tostring(text or "")
    local label = ISLabel:new(0, 0, 22, labelText,
        value.r, value.g, value.b, value.a, UIFont.Small, true)
    label:initialise()
    -- Keep the source text separately. ISLabel:setName() can change its
    -- measured width, so responsive layout must measure the source text rather
    -- than the last display value.
    label.psychopatzFormText = labelText
    label.psychopatzThemeColorName = color == nil and "text" or nil
    parent:addChild(label)
    return label
end

local FormRow = ISPanel:derive("PsychopatzFormRow")
UI.FormRow = FormRow

function FormRow:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.drawBorder = false
    self.backgroundColor = Theme.Color("transparent")
    self.borderColor = Theme.Color("transparent")
end

function FormRow:setLabelText(value)
    if self.label then self.label.psychopatzFormText = tostring(value or "") end
    UI.SetLabelText(self.label, value)
end

function FormRow:setValueText(value)
    UI.SetLabelText(self.valueLabel, value)
end

function FormRow:layout(options)
    options = options or {}
    local scale = self.uiScale or Layout.Scale()
    local width = self:getWidth()
    local height = self:getHeight()
    local gap = Layout.Pixels(options.gap or self.gap or 8, scale)
    local preferredLabelWidth = Layout.Pixels(
        options.labelWidth or self.labelWidth or 110, scale)
    local valueWidth = self.valueLabel and Layout.Pixels(
        options.valueWidth or self.valueWidth or 48, scale) or 0
    local minimumControlWidth = Layout.Pixels(
        options.minimumControlWidth or self.minimumControlWidth or 96, scale)
    local controlHeight = Layout.Pixels(
        options.controlHeight or self.controlHeight or 26, scale)
    -- A fixed label column is not enough for translated settings labels. Give
    -- the label the space it needs, while retaining a minimum usable control
    -- width. If the row is too narrow for both, the display text is safely
    -- ellipsized below instead of drawing across the control.
    local labelWidth = preferredLabelWidth
    local labelFont = self.label and self.label.font
        or (Theme.Font and Theme.Font(scale) or UIFont.Small)
    local labelText = self.label and (self.label.psychopatzFormText
        or self.label.name) or ""
    if options.autoLabelWidth ~= false and self.autoLabelWidth ~= false
        and self.label and Theme.TextWidth
    then
        labelWidth = math.max(labelWidth,
            Theme.TextWidth(labelFont, labelText) + Layout.Pixels(6, scale))
    end
    local minimumLabelWidth = Layout.Pixels(
        options.minimumLabelWidth or self.minimumLabelWidth or 1, scale)
    local availableLabelWidth = math.max(minimumLabelWidth,
        width - gap * 2 - valueWidth - (self.control and minimumControlWidth or 0))
    labelWidth = math.min(labelWidth, availableLabelWidth)
    local controlX = labelWidth + gap
    local controlWidth = math.max(1, width - controlX - gap - valueWidth)
    local controlY = math.max(0, math.floor((height - controlHeight) / 2))

    if self.label then
        self.label.uiScale = scale
        Layout.SetBounds(self.label, 0, 0, labelWidth, height)
        local displayText = labelText
        if Layout.Ellipsize and Theme.TextWidth then
            displayText = Layout.Ellipsize(labelText, labelFont,
                math.max(1, labelWidth - Layout.Pixels(4, scale)))
        end
        if displayText ~= self.label.name then
            if self.label.setNameWithoutMoving then
                self.label:setNameWithoutMoving(displayText)
            elseif self.label.setName then
                self.label:setName(displayText)
            else
                self.label.name = displayText
            end
        end
    end
    if self.control then
        if self.control.setUIScale then self.control:setUIScale(scale)
        else self.control.uiScale = scale end
        Layout.SetBounds(self.control, controlX, controlY, controlWidth,
            math.min(height, controlHeight))
    end
    if self.valueLabel then
        self.valueLabel.uiScale = scale
        Layout.SetBounds(self.valueLabel,
            math.max(controlX + controlWidth + gap, width - valueWidth),
            0, valueWidth, height)
    end
    self.lastLayout = {
        labelWidth = labelWidth, controlX = controlX,
        controlWidth = controlWidth, valueWidth = valueWidth,
        labelText = labelText,
    }
end

function FormRow:place(x, y, width, height, options)
    options = options or {}
    local scale = options.scale or self.uiScale or Layout.Scale()
    self.uiScale = scale
    Layout.SetBounds(self, x, y, width, height)
    self:layout(options)
end

function FormRow:new(x, y, width, height, definition)
    local object = ISPanel.new(self, x, y, width, height)
    definition = type(definition) == "table" and definition or {}
    setmetatable(object, self)
    self.__index = self
    object.labelWidth = definition.labelWidth
    object.valueWidth = definition.valueWidth
    object.controlHeight = definition.controlHeight
    object.minimumControlWidth = definition.minimumControlWidth
    object.minimumLabelWidth = definition.minimumLabelWidth
    object.autoLabelWidth = definition.autoLabelWidth
    object.gap = definition.gap
    object.definition = definition
    return object
end

function UI.CreateFormRow(parent, definition)
    definition = type(definition) == "table" and definition or {}
    local row = FormRow:new(0, 0, 1, 1, definition)
    row:initialise()
    row:instantiate()
    row.label = createLabel(row, definition.label or definition.title,
        definition.labelColor)
    if definition.labelColorName then
        row.label.psychopatzThemeColorName = definition.labelColorName
    end
    if type(definition.createControl) == "function" then
        row.control = definition.createControl(row)
    else
        row.control = definition.control
        if row.control then row:addChild(row.control) end
    end
    if definition.valueLabel == true or definition.valueText ~= nil then
        row.valueLabel = createLabel(row, definition.valueText or "",
            definition.valueColor or Theme.colors.textMuted)
        if not definition.valueColor then
            row.valueLabel.psychopatzThemeColorName = "textMuted"
        elseif definition.valueColorName then
            row.valueLabel.psychopatzThemeColorName = definition.valueColorName
        end
    end
    if parent then parent:addChild(row) end
    local host = UI.LayoutHost
    if parent and host and host.Track and definition.id then
        host.Track(parent, definition.id, row)
    end
    row:layout(definition)
    return row
end

return UI
