-- Optional shared settings window for command-hub consumers.

require "ISUI/ISLabel"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Components/PsychopatzFormRow"
require "PsychopatzCore/UI/Components/PsychopatzSlider"
require "PsychopatzCore/UI/Components/PsychopatzWidgetWindow"
require "PsychopatzCore/UI/PsychopatzCommandHubOptions"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Options = UI.CommandHubOptions
local Translation = PsychopatzCore.Translation

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function label(parent, text, color, colorName)
    local value = color or Theme.colors.text
    local control = ISLabel:new(0, 0, 22, tostring(text or ""),
        value.r, value.g, value.b, value.a, UIFont.Small, true)
    control:initialise()
    control.psychopatzThemeColorName = colorName
        or (color == Theme.colors.textMuted and "textMuted" or "text")
    parent:addChild(control)
    return control
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

local function liftText(value)
    return "+" .. tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function controlScaleText(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function themeTitle()
    return tr("UI_PsychopatzCore_CommandHub_Settings_Theme", "THEME")
        .. ": " .. Theme.GetPresetLabel()
end

ISPsychopatzCommandHubSettingsWindow = PsychopatzWindow:derive(
    "ISPsychopatzCommandHubSettingsWindow")

local Internal = {
    tr = tr,
    label = label,
    branchTitle = branchTitle,
    opacityText = opacityText,
    liftText = liftText,
    controlScaleText = controlScaleText,
    themeTitle = themeTitle,
}
ISPsychopatzCommandHubSettingsWindow.Internal = Internal

function ISPsychopatzCommandHubSettingsWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self)
end

function ISPsychopatzCommandHubSettingsWindow:createChildren()
    Internal.createChildren(self)
end

function ISPsychopatzCommandHubSettingsWindow:setStatus(value)
    local text = tostring(value or "")
    if self.statusLabel then
        UI.SetLabelText(self.statusLabel, text)
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
    local opacity = Options.GetOpacityPercent()
    self.opacitySlider:setValue(opacity, true)
    if self.opacityValue then
        UI.SetLabelText(self.opacityValue, opacityText(opacity))
    end
    local surfaceLift = Options.GetSurfaceOpacityLift() * 100
    self.surfaceLiftRow.control:setValue(surfaceLift, true)
    UI.SetLabelText(self.surfaceLiftRow.valueLabel, liftText(surfaceLift))
    local detailLift = Options.GetDetailOpacityLift() * 100
    self.detailLiftRow.control:setValue(detailLift, true)
    UI.SetLabelText(self.detailLiftRow.valueLabel, liftText(detailLift))
    local titlebarScale = Options.GetTitlebarControlScale() * 100
    self.titlebarScaleRow.control:setValue(titlebarScale, true)
    UI.SetLabelText(self.titlebarScaleRow.valueLabel,
        controlScaleText(titlebarScale))
    self.branchButton:setTitle(branchTitle())
    self.themeButton:setTitle(themeTitle())
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
    Options.Reset()
    Theme.Reset()
    Options.ApplyRegisteredOpacity(Options.GetOpacity())
    Options.ApplyRegisteredToolbarScale()
    local hub = UI.CommandHub
    if hub and hub.Sync then hub.Sync() end
    self:populate()
    self:setStatus(tr("UI_PsychopatzCore_CommandHub_Settings_Applied",
        "Settings applied."))
end

function ISPsychopatzCommandHubSettingsWindow:onThemeCycle()
    local ids = Theme.GetPresetIDs()
    local current = Theme.GetPresetID()
    local index = 1
    for position, id in ipairs(ids) do
        if id == current then index = position end
    end
    local nextIndex = index + 1
    if nextIndex > #ids then nextIndex = 1 end
    Theme.SetPreset(ids[nextIndex])
    self.themeButton:setTitle(themeTitle())
    self:setStatus(tr("UI_PsychopatzCore_CommandHub_Settings_Applied",
        "Settings applied."))
end

function ISPsychopatzCommandHubSettingsWindow:onApply()
    local host = self:getHost()
    if not host then return false end
    local opacity = math.floor(self.opacitySlider:getValue() + 0.5)
    if not opacity then
        self:setStatus(tr("UI_PsychopatzCore_CommandHub_Settings_Invalid",
            "Enter a valid opacity value."))
        return false
    end
    Options.SetOpacityPercent(opacity)
    Options.SetSurfaceOpacityLift(
        math.floor(self.surfaceLiftRow.control:getValue() + 0.5) / 100)
    Options.SetDetailOpacityLift(
        math.floor(self.detailLiftRow.control:getValue() + 0.5) / 100)
    Options.SetTitlebarControlScale(
        math.floor(self.titlebarScaleRow.control:getValue() + 0.5) / 100)
    Options.ApplyRegisteredOpacity(opacity / 100)
    Options.ApplyRegisteredToolbarScale()
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
    local y = rect.y
    local rowHeight = Layout.Pixels(34, scale)
    local gap = Layout.Pixels(4, scale)

    Layout.SetBounds(self.helpLabel, rect.x, y, rect.width,
        Layout.Pixels(22, scale))
    y = y + Layout.Pixels(28, scale)
    self.opacityRow:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 4,
        controlHeight = 26,
    })
    y = y + rowHeight + gap

    self.surfaceLiftRow:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 4,
        controlHeight = 26,
    })
    y = y + rowHeight + gap
    self.detailLiftRow:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 4,
        controlHeight = 26,
    })
    y = y + rowHeight + gap
    self.titlebarScaleRow:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 4,
        controlHeight = 26,
    })
    y = y + rowHeight + gap
    Layout.SetBounds(self.themeButton, rect.x, y, rect.width, rowHeight - 4)
    y = y + rowHeight + gap

    Layout.SetBounds(self.branchButton, rect.x, y, rect.width, rowHeight - 4)
    y = y + rowHeight + gap
    Layout.SetBounds(self.statusLabel, rect.x, y, rect.width,
        Layout.Pixels(22, scale))

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

require "PsychopatzCore/UI/PsychopatzCommandHubSettingsWindow_Controls"

return ISPsychopatzCommandHubSettingsWindow
