-- Reusable root host for PsychopatzCore command-hub buttons.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/PsychopatzCommandHubRegistry"
require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
require "PsychopatzCore/UI/PsychopatzCommandHubActionsWindow"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Registry = UI.CommandHubRegistry
local Options = UI.CommandHubOptions
local Actions = UI.CommandHubActions

local function trace(event, message)
    local hub = UI.CommandHub
    if hub and hub.Trace then hub.Trace(event, message) end
end

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function titleFor(definition)
    return tr(definition and definition.titleKey,
        definition and definition.titleFallback or "COMMAND")
end

local function tooltipFor(definition)
    return tr(definition and definition.tooltipKey,
        definition and definition.tooltipFallback or titleFor(definition))
end

local function setEnabled(button, enabled)
    if not button then return end
    if button.setEnable then button:setEnable(enabled)
    else button.enable = enabled end
end

ISPsychopatzCommandHubWindow = PsychopatzWindow:derive(
    "ISPsychopatzCommandHubWindow")

function ISPsychopatzCommandHubWindow:initialise()
    PsychopatzWindow.initialise(self)
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
    Options.ApplyOpacity(self)
end

function ISPsychopatzCommandHubWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.categoryButtons = {}
    self.registryRevision = -1
    self:syncButtons()
    self:fitToContent(true)
    self:requestResponsiveLayout(true)
end

function ISPsychopatzCommandHubWindow:syncButtons()
    local active = {}
    for _, category in ipairs(Registry.All()) do
        if Registry.IsVisible(category, self) then
            active[category.id] = true
            local button = self.categoryButtons[category.id]
            if not button then
                button = UI.CreateButton(self, {
                    id = "command-hub-category:" .. tostring(category.id),
                    title = titleFor(category),
                    target = self,
                    onclick = UI.ButtonCallback(function(button)
                        return self:onControl(button)
                    end),
                    variant = "quiet",
                    font = Theme.Font(self.uiScale),
                })
                self.categoryButtons[category.id] = button
            end
            button.commandHubCategory = category.id
            button:setTitle(titleFor(category))
            button.tooltip = tooltipFor(category)
            if button.setFont then button:setFont(Theme.Font(self.uiScale)) end
        end
    end
    for id, button in pairs(self.categoryButtons) do
        if not active[id] then button:setVisible(false) end
    end
    self.registryRevision = Registry.Revision
end

function ISPsychopatzCommandHubWindow:fitToContent(force)
    self:layoutButtons()
    local scale = self.uiScale or Layout.Scale()
    local top = Layout.Pixels(30, scale)
    local bottom = Layout.Pixels(12, scale)
    local gap = Layout.Pixels(6, scale)
    local rowHeight = Layout.Pixels(30, scale)
    local minimumHeight = Layout.Pixels(150, scale)
    local rows = self.layout and self.layout.rowCount or 1
    local requiredHeight = top + bottom + rows * rowHeight
        + math.max(0, rows - 1) * gap
    local _, screenHeight = Layout.ScreenSize()
    local margin = Layout.Pixels(18, scale)
    local maximumHeight = math.max(minimumHeight, screenHeight - margin * 2)
    if force or self:getHeight() < requiredHeight then
        self:setHeight(math.min(maximumHeight,
            math.max(minimumHeight, requiredHeight)))
    end
end

function ISPsychopatzCommandHubWindow:layoutButtons()
    self:syncButtons()
    local scale = self.uiScale or Layout.Scale()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local gap = Layout.Pixels(6, scale)
    local rowHeight = Layout.Pixels(30, scale)
    local columns = rect.width >= Layout.Pixels(260, scale) and 2 or 1
    local cellWidth = math.max(1, math.floor(
        (rect.width - gap * (columns - 1)) / columns))
    local row, column = 0, 0
    for _, category in ipairs(Registry.All()) do
        local button = self.categoryButtons[category.id]
        if button and button:getIsVisible() then
            local x = rect.x + column * (cellWidth + gap)
            local y = rect.y + row * (rowHeight + gap)
            Layout.SetBounds(button, x, y, cellWidth, rowHeight)
            local enabled = Registry.IsEnabled(category, self)
            setEnabled(button, enabled)
            local selected = Registry.IsSelected(category, self)
            if not selected and #Registry.GetChildren(category.id) > 0
                and Actions.instance and Actions.instance.parentID == category.id
            then
                selected = true
            end
            UI.StyleButton(button, not enabled and "quiet"
                or selected and "selected" or "default")
            column = column + 1
            if column >= columns then
                column = 0
                row = row + 1
            end
        end
    end
    self.layout = {
        rowCount = row + (column > 0 and 1 or 0),
        rect = rect,
        rowHeight = rowHeight,
        gap = gap,
    }
end

function ISPsychopatzCommandHubWindow:onResponsiveLayout()
    self:layoutButtons()
end

function ISPsychopatzCommandHubWindow:onControl(button)
    local id = button and button.commandHubCategory or nil
    trace("root_control", "button_id=" .. tostring(button and button.internal)
        .. " category=" .. tostring(id))
    local category = Registry.Get(id)
    if not category then
        trace("root_control_rejected", "reason=missing_category")
        return false
    end
    if not Registry.IsEnabled(category, self) then
        trace("root_control_rejected", "category=" .. tostring(id)
            .. " reason=disabled")
        return false
    end

    local children = Registry.GetChildren(id)
    if #children > 0 and category.useChildren ~= false then
        trace("root_actions_toggle", "category=" .. tostring(id)
            .. " child_count=" .. tostring(#children)
            .. " currently_open=" .. tostring(Actions.instance ~= nil
                and Actions.instance.owner == self
                and Actions.instance.parentID == id))
        if Actions.instance and Actions.instance.owner == self
            and Actions.instance.parentID == id
        then
            Actions.Close()
        else
            Actions.Open(id, self)
        end
        self:layoutButtons()
        return true
    end

    if type(category.onClick) ~= "function" then
        trace("root_control_rejected", "category=" .. tostring(id)
            .. " reason=missing_callback")
        return false
    end
    trace("category_callback_start", "category=" .. tostring(id))
    local ok, result = pcall(category.onClick, category, self)
    if not ok then
        trace("category_callback_error", "category=" .. tostring(id)
            .. " error=" .. tostring(result))
        print("[PsychopatzCore][CommandHub] button failed: " .. tostring(result))
        return false
    end
    trace("category_callback_result", "category=" .. tostring(id)
        .. " result=" .. tostring(result))
    if result ~= false and category.closeHub == true then self:close() end
    self:layoutButtons()
    return result ~= false
end

function ISPsychopatzCommandHubWindow:prerender()
    local scale = Layout.Scale()
    if self.uiScale ~= scale then
        self.uiScale = scale
        self:fitToContent(false)
        self:requestResponsiveLayout(true)
    end
    if self.registryRevision ~= Registry.Revision then
        self:syncButtons()
        self:fitToContent(false)
        self:requestResponsiveLayout(true)
    end
    PsychopatzWindow.prerender(self)
    Options.ApplyOpacity(self)
    if Actions.instance and Actions.instance.owner == self then
        Actions.SyncPosition(self)
    end
    local hub = UI.CommandHub
    if hub and hub.Notify then hub.Notify("prerender", self) end
end

function ISPsychopatzCommandHubWindow:close()
    Actions.Close()
    local hub = UI.CommandHub
    if hub and hub.Settings and hub.Settings.instance
        and hub.Settings.instance.owner == self
    then
        hub.Settings.instance:close()
    end
    Options.UnregisterTarget("PsychopatzCore.CommandHub.Host")
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    hub = UI.CommandHub
    if hub and hub.instance == self then hub.instance = nil end
    if hub and hub.Notify then hub.Notify("closed", self) end
end

return ISPsychopatzCommandHubWindow
