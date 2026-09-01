-- Optional shared settings window for command-hub consumers.

require "ISUI/ISLabel"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Components/PsychopatzSlider"
require "PsychopatzCore/UI/Components/PsychopatzTextEntry"
require "PsychopatzCore/UI/Components/PsychopatzWidgetWindow"
require "PsychopatzCore/UI/PsychopatzCommandHubOptions"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Options = UI.CommandHubOptions

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function label(parent, text, color)
    local value = color or Theme.colors.text
    local control = ISLabel:new(0, 0, 22, tostring(text or ""),
        value.r, value.g, value.b, value.a, UIFont.Small, true)
    control:initialise()
    parent:addChild(control)
    return control
end

local function readInteger(entry, minimum, maximum)
    local value = tonumber(entry and entry:getText() or nil)
    if not value then return nil end
    value = math.floor(value + 0.5)
    if minimum and value < minimum then return nil end
    if maximum and value > maximum then return nil end
    return value
end

local function setEntry(entry, value)
    if entry then entry:setText(tostring(math.floor(value or 0))) end
end

local function branchTitle()
    local key = Options.GetBranch() == "left"
        and "UI_PsychopatzCore_CommandHub_Settings_BranchLeft"
        or "UI_PsychopatzCore_CommandHub_Settings_BranchRight"
    local fallback = Options.GetBranch() == "left"
        and "ACTION PANEL: LEFT" or "ACTION PANEL: RIGHT"
    return tr(key, fallback)
end

local function opacityText(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

ISPsychopatzCommandHubSettingsWindow = PsychopatzWindow:derive(
    "ISPsychopatzCommandHubSettingsWindow")

function ISPsychopatzCommandHubSettingsWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self)
end

function ISPsychopatzCommandHubSettingsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.fields = {}
    local definitions = {
        { id = "x", key = "UI_PsychopatzCore_CommandHub_Settings_X" },
        { id = "y", key = "UI_PsychopatzCore_CommandHub_Settings_Y" },
        { id = "width", key = "UI_PsychopatzCore_CommandHub_Settings_Width" },
        { id = "height", key = "UI_PsychopatzCore_CommandHub_Settings_Height" },
    }
    for _, definition in ipairs(definitions) do
        self.fields[definition.id] = {
            label = label(self, tr(definition.key, definition.id)),
            entry = UI.CreateTextEntry(self, {
                onlyNumbers = true, maxTextLength = 5,
            }),
        }
    end

    self.opacityLabel = label(self,
        tr("UI_PsychopatzCore_CommandHub_Settings_Opacity", "Opacity"))
    self.opacitySlider = UI.CreateSlider(self, {
        id = "psychopatz-command-hub-opacity",
        target = self,
        min = 10,
        max = 100,
        step = 1,
        value = Options.GetOpacityPercent(),
        onChange = function(_, value)
            if self.opacityValue then self.opacityValue:setName(opacityText(value)) end
        end,
    })
    self.opacityValue = label(self, opacityText(
        Options.GetOpacityPercent()), Theme.colors.textMuted)
    self.helpLabel = label(self,
        tr("UI_PsychopatzCore_CommandHub_Settings_Help",
            "Edit the hub position, dimensions, and opacity."),
        Theme.colors.textMuted)
    self.branchButton = UI.CreateButton(self, {
        id = "branch", title = branchTitle(), target = self,
        onclick = function() return self:onBranchToggle() end,
        variant = "quiet",
    })
    self.statusLabel = label(self, "", Theme.colors.textMuted)
    self.resetButton = UI.CreateButton(self, {
        id = "reset",
        title = getText and getText(
            "UI_PsychopatzCore_CommandHub_Settings_Reset") or "RESET",
        target = self, onclick = function() return self:onReset() end,
        variant = "quiet",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = getText and getText(
            "UI_PsychopatzCore_CommandHub_Settings_Close") or "CLOSE",
        target = self, onclick = function() return self:close() end,
        variant = "quiet",
    })
    self.applyButton = UI.CreateButton(self, {
        id = "apply",
        title = getText and getText(
            "UI_PsychopatzCore_CommandHub_Settings_Apply") or "APPLY",
        target = self, onclick = function() return self:onApply() end,
        variant = "primary",
    })

    self:populate()
    self:requestResponsiveLayout(true)
    UI.WidgetWindow.Install(self, {
        id = "psychopatzcore-command-hub-settings-widget",
        onDetachedChanged = function()
            local hub = UI.CommandHub
            if hub and hub.Sync then hub.Sync() end
        end,
    })
end

function ISPsychopatzCommandHubSettingsWindow:setStatus(value)
    local text = tostring(value or "")
    if self.statusLabel then
        self.statusLabel:setName(text)
        self.statusLabel:setVisible(text ~= "")
    end
end

function ISPsychopatzCommandHubSettingsWindow:getHost()
    local hub = UI.CommandHub
    if self.owner and self.owner.getIsVisible
        and self.owner:getIsVisible()
    then
        return self.owner
    end
    return hub and hub.instance or nil
end

function ISPsychopatzCommandHubSettingsWindow:populate()
    local host = self:getHost()
    if not host then return end
    setEntry(self.fields.x.entry, host:getX())
    setEntry(self.fields.y.entry, host:getY())
    setEntry(self.fields.width.entry, host:getWidth())
    setEntry(self.fields.height.entry, host:getHeight())
    local opacity = Options.GetOpacityPercent()
    self.opacitySlider:setValue(opacity, true)
    if self.opacityValue then self.opacityValue:setName(opacityText(opacity)) end
    self.branchButton:setTitle(branchTitle())
end

function ISPsychopatzCommandHubSettingsWindow:onBranchToggle()
    local branch = Options.GetBranch() == "right" and "left" or "right"
    Options.SetBranch(branch)
    self.branchButton:setTitle(branchTitle())
    local hub = UI.CommandHub
    if hub and hub.Sync then hub.Sync() end
    self:setStatus(tr("UI_PsychopatzCore_CommandHub_Settings_Applied",
        "Settings applied."))
end

function ISPsychopatzCommandHubSettingsWindow:onReset()
    local host = self:getHost()
    if host then Options.ResetGeometry(host) end
    Options.ApplyRegisteredOpacity(Options.GetOpacity())
    local hub = UI.CommandHub
    if hub and hub.Sync then hub.Sync() end
    self:populate()
    self:setStatus(tr("UI_PsychopatzCore_CommandHub_Settings_Applied",
        "Settings applied."))
end

function ISPsychopatzCommandHubSettingsWindow:onApply()
    local host = self:getHost()
    if not host then return false end
    local x = readInteger(self.fields.x.entry, 0)
    local y = readInteger(self.fields.y.entry, 0)
    local width = readInteger(self.fields.width.entry, 1)
    local height = readInteger(self.fields.height.entry, 1)
    local opacity = math.floor(self.opacitySlider:getValue() + 0.5)
    if not x or not y or not width or not height or not opacity then
        self:setStatus(tr("UI_PsychopatzCore_CommandHub_Settings_Invalid",
            "Enter valid numeric values."))
        return false
    end
    Options.ApplyGeometry(host, x, y, width, height)
    Options.SetOpacityPercent(opacity)
    Options.ApplyRegisteredOpacity(opacity / 100)
    local hub = UI.CommandHub
    if hub and hub.Sync then hub.Sync() end
    self:populate()
    self:setStatus(tr("UI_PsychopatzCore_CommandHub_Settings_Applied",
        "Settings applied."))
    return true
end

function ISPsychopatzCommandHubSettingsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 34, bottom = 12 })
    local scale = self.uiScale or Layout.Scale()
    local labelWidth = Layout.Pixels(110, scale)
    local fieldX = rect.x + labelWidth
    local fieldWidth = math.max(Layout.Pixels(150, scale),
        rect.width - labelWidth)
    local y = rect.y
    local rowHeight = Layout.Pixels(30, scale)
    local gap = Layout.Pixels(4, scale)

    for _, id in ipairs({ "x", "y", "width", "height" }) do
        local field = self.fields[id]
        field.label:setX(rect.x)
        field.label:setY(y + 4)
        Layout.SetBounds(field.entry, fieldX, y, fieldWidth, rowHeight - 4)
        y = y + rowHeight + gap
    end
    self.opacityLabel:setX(rect.x)
    self.opacityLabel:setY(y + 4)
    Layout.SetBounds(self.opacitySlider, fieldX, y, fieldWidth - 48,
        rowHeight - 4)
    self.opacityValue:setX(rect.x + rect.width - 42)
    self.opacityValue:setY(y + 4)
    y = y + rowHeight + gap

    self.branchButton:setX(rect.x)
    self.branchButton:setY(y)
    self.branchButton:setWidth(rect.width)
    self.branchButton:setHeight(rowHeight - 4)
    y = y + rowHeight + gap
    self.helpLabel:setX(rect.x)
    self.helpLabel:setY(y)
    self.helpLabel:setWidth(rect.width)
    y = y + Layout.Pixels(28, scale)
    self.statusLabel:setX(rect.x)
    self.statusLabel:setY(y)
    self.statusLabel:setWidth(rect.width)

    local footerY = rect.y + rect.height - rowHeight
    Layout.SetBounds(self.resetButton, rect.x, footerY,
        Layout.Pixels(92, scale), rowHeight - 4)
    Layout.SetBounds(self.closeButton, rect.x + rect.width
        - Layout.Pixels(92, scale) * 2 - gap, footerY,
        Layout.Pixels(92, scale), rowHeight - 4)
    Layout.SetBounds(self.applyButton, rect.x + rect.width
        - Layout.Pixels(92, scale), footerY,
        Layout.Pixels(92, scale), rowHeight - 4)
end

function ISPsychopatzCommandHubSettingsWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    PsychopatzWindow.prerender(self)
    Options.ApplyOpacity(self)
end

function ISPsychopatzCommandHubSettingsWindow:close()
    Options.UnregisterTarget("PsychopatzCore.CommandHub.Settings")
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    local hub = UI.CommandHub
    if hub and hub.Settings then hub.Settings.instance = nil end
end

function ISPsychopatzCommandHubSettingsWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

return ISPsychopatzCommandHubSettingsWindow
