-- Generic child-button panel used by Core command-hub hosts.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/PsychopatzAttachedWindow"
require "PsychopatzCore/UI/PsychopatzCommandHubRegistry"
require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Tooltip = require "PsychopatzCore/UI/PsychopatzCommandHubTooltip"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Registry = UI.CommandHubRegistry
local Options = UI.CommandHubOptions
local AttachedWindow = UI.AttachedWindow or PsychopatzAttachedWindow

local function trace(event, message)
    local hub = UI.CommandHub
    if hub and hub.Trace then hub.Trace(event, message) end
end

local Actions = UI.CommandHubActions or {}
UI.CommandHubActions = Actions
ISPsychopatzCommandHubActionsWindow = AttachedWindow:derive(
    "ISPsychopatzCommandHubActionsWindow")
Actions.Window = ISPsychopatzCommandHubActionsWindow

local titleFor = Tooltip.TitleFor
local tooltipFor = Tooltip.For

local function setEnabled(button, enabled)
    if not button then return end
    if button.setEnable then button:setEnable(enabled)
    else button.enable = enabled end
end

function ISPsychopatzCommandHubActionsWindow:initialise()
    AttachedWindow.initialise(self)
    self.backgroundColor = Theme.Color("surface")
    self.borderColor = Theme.Color("borderStrong")
    self.psychopatzThemeBackgroundName = "surface"
    self.psychopatzThemeBorderName = "borderStrong"
    Options.ApplySurfaceOpacity(self)
end

function ISPsychopatzCommandHubActionsWindow:createChildren()
    AttachedWindow.createChildren(self)
    self.actionButtons = {}
    self.backButton = UI.CreateButton(self, {
        id = "command-hub-back",
        title = getText and getText("UI_PsychopatzCore_CommandHub_Back")
            or "Back",
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return self:onControl(button)
        end),
        variant = "quiet",
        font = Theme.Font(self.uiScale),
    })
    self.backButton.commandHubBack = true
    self:syncButtons()
end

function ISPsychopatzCommandHubActionsWindow:syncButtons()
    local active = {}
    local actions = Registry.GetChildren(self.parentID)
    for _, action in ipairs(actions) do
        if Registry.IsVisible(action, self.owner) then
            active[action.id] = true
            local button = self.actionButtons[action.id]
            if not button then
                button = UI.CreateButton(self, {
                    id = "command-hub-action:" .. tostring(action.id),
                    title = titleFor(action),
                    target = self,
                    onclick = UI.ButtonCallback(function(button)
                        return self:onControl(button)
                    end),
                    variant = "primary",
                    font = Theme.Font(self.uiScale),
                })
                self.actionButtons[action.id] = button
            end
            button.commandHubAction = action.id
            button:setTitle(titleFor(action))
            button.tooltip = tooltipFor(action, self.owner, true)
            if button.setFont then button:setFont(Theme.Font(self.uiScale)) end
        end
    end
    for id, button in pairs(self.actionButtons) do
        if not active[id] then button:setVisible(false) end
    end

    self.backButton:setVisible(self.parentID ~= nil
        and Registry.Get(self.parentID)
        and Registry.Get(self.parentID).parentID ~= nil)
    local parent = Registry.Get(self.parentID)
    self.title = titleFor(parent)
end

function ISPsychopatzCommandHubActionsWindow:syncButtonStates()
    local actions = Registry.GetChildren(self.parentID)
    for _, action in ipairs(actions) do
        local button = self.actionButtons[action.id]
        if button and button:getIsVisible() then
            local enabled = Registry.IsEnabled(action, self.owner)
            button.tooltip = tooltipFor(action, self.owner, enabled)
            setEnabled(button, enabled)
            local selected = enabled and Registry.IsSelected(action, self.owner)
            UI.StyleButton(button, selected and "selected"
                or (enabled and "default" or "quiet"))
        end
    end
end

function ISPsychopatzCommandHubActionsWindow:layoutButtons()
    self:syncButtons()
    self:syncButtonStates()
    local actions = Registry.GetChildren(self.parentID)
    local scale = self.uiScale or Layout.Scale()
    local gap = Layout.Pixels(6, scale)
    local padding = Layout.Pixels(8, scale)
    local rowHeight = Layout.Pixels(30, scale)
    local columns = #actions >= 4 and 2 or 1
    local rect = self:getContentRect({ padding = 8 })
    local availableWidth = rect.width
    local buttonWidth = columns == 1
        and math.max(Layout.Pixels(180, scale), availableWidth)
        or math.max(Layout.Pixels(120, scale), math.floor(
            (availableWidth - gap) / columns))
    local row, column = 0, 0
    local top = rect.y

    if self.backButton:getIsVisible() then
        Layout.SetBounds(self.backButton, rect.x, top, buttonWidth, rowHeight)
        top = top + rowHeight + gap
    end

    for _, action in ipairs(actions) do
        local button = self.actionButtons[action.id]
        if button and button:getIsVisible() then
            local x = rect.x + column * (buttonWidth + gap)
            local y = top + row * (rowHeight + gap)
            Layout.SetBounds(button, x, y, buttonWidth, rowHeight)
            column = column + 1
            if column >= columns then
                column = 0
                row = row + 1
            end
        end
    end

    local rows = row + (column > 0 and 1 or 0)
    if #actions == 0 then rows = 0 end
    local resizeHeight = self:footerHeight()
    local height = top + rows * rowHeight + math.max(0, rows - 1) * gap
        + padding + resizeHeight
    local desiredWidth = math.max(Layout.Pixels(190, scale), padding * 2
        + columns * buttonWidth + math.max(0, columns - 1) * gap)
    local desiredHeight = math.max(Layout.Pixels(70, scale), height)
    if self.psychopatzUserResized ~= true then
        self:setWidth(desiredWidth)
        self:setHeight(desiredHeight)
    else
        self:setWidth(math.max(self:getWidth(), Layout.Pixels(190, scale)))
        self:setHeight(math.max(self:getHeight(), desiredHeight,
            Layout.Pixels(70, scale)))
    end
    self:syncResizeWidgets()
    self.layoutRevision = Registry.Revision
    self.layoutScale = scale
    self.layoutParentID = self.parentID
end

function ISPsychopatzCommandHubActionsWindow:ensureLayout()
    local scale = self.owner and self.owner.uiScale or Layout.Scale()
    if self.layoutRevision ~= Registry.Revision
        or self.layoutScale ~= scale
        or self.layoutParentID ~= self.parentID
    then
        self.uiScale = scale
        self:layoutButtons()
    end
    self:syncButtonStates()
end

function ISPsychopatzCommandHubActionsWindow:onResponsiveLayout()
    self.layoutRevision = nil
    self:layoutButtons()
end

function ISPsychopatzCommandHubActionsWindow:onControl(button)
    trace("actions_control", "button_id=" .. tostring(button and button.internal)
        .. " action=" .. tostring(button and button.commandHubAction)
        .. " back=" .. tostring(button and button.commandHubBack == true))
    if button and button.commandHubBack then
        local parent = Registry.Get(self.parentID)
        self.parentID = parent and parent.parentID or nil
        self:layoutButtons()
        return true
    end

    local actionID = button and button.commandHubAction or nil
    local action = Registry.GetAction(self.parentID, actionID)
    if not action then
        trace("actions_control_rejected", "parent=" .. tostring(self.parentID)
            .. " reason=missing_action")
        return false
    end
    if not Registry.IsEnabled(action, self.owner) then
        trace("actions_control_rejected", "action=" .. tostring(actionID)
            .. " reason=disabled")
        return false
    end

    local children = Registry.GetChildren(action.id)
    if #children > 0 and action.useChildren ~= false then
        self.parentID = action.id
        self:layoutButtons()
        return true
    end

    if type(action.onClick) ~= "function" then
        trace("actions_control_rejected", "action=" .. tostring(actionID)
            .. " reason=missing_callback")
        return false
    end
    trace("action_callback_start", "action=" .. tostring(actionID))
    local ok, result = pcall(action.onClick, action, self.owner or self)
    if not ok then
        trace("action_callback_error", "action=" .. tostring(actionID)
            .. " error=" .. tostring(result))
        print("[PsychopatzCore][CommandHub] action failed: " .. tostring(result))
        return false
    end
    trace("action_callback_result", "action=" .. tostring(actionID)
        .. " result=" .. tostring(result))
    self:syncButtonStates()
    if result ~= false and action.closePanel == true then self:close() end
    return result ~= false
end

function ISPsychopatzCommandHubActionsWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    self:ensureLayout()
    AttachedWindow.prerender(self)
    Options.ApplySurfaceOpacity(self)
end

function ISPsychopatzCommandHubActionsWindow:close()
    Options.UnregisterTarget(self.commandHubTargetID)
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if Actions.instance == self then Actions.instance = nil end
end

function Actions.Open(parentID, owner)
    local children = Registry.GetChildren(parentID)
    if #children == 0 then return false end
    local window = Actions.instance
    if not window then
        window = UI.NewWindow(ISPsychopatzCommandHubActionsWindow, {
            title = titleFor(Registry.Get(parentID)),
            width = 220,
            height = 180,
            resizable = true,
            persistGeometry = true,
            persistenceKey = "PsychopatzCore.CommandHub.Actions",
            geometryTrace = true,
            responsiveSpec = { width = 220, height = 180,
                minWidth = 180, minHeight = 70,
                maxWidth = 520, maxHeight = 820 },
        })
        window:initialise()
        window:instantiate()
        Actions.instance = window
    end
    window.owner = owner
    window.parentID = tostring(parentID)
    window.uiScale = owner and owner.uiScale or Layout.Scale()
    window.commandHubTargetID = "PsychopatzCore.CommandHub.Actions"
    Options.RegisterTarget(window.commandHubTargetID, window)
    window:ensureLayout()
    Actions.SyncPosition(owner)
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    return window
end

function Actions.SyncPosition(owner)
    local window = Actions.instance
    local host = owner or (window and window.owner)
    if not window or not host then return false end
    if not host.getIsVisible or not host:getIsVisible() then
        window:close()
        return false
    end
    window.owner = host
    Options.PlaceAttached(window, host)
    return true
end

function Actions.Close()
    if Actions.instance then Actions.instance:close() end
end

return Actions
