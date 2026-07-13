require "PsychopatzCore/UI/PsychopatzUI"

PsychopatzCore.DebugHub = PsychopatzCore.DebugHub or {}

local Hub = PsychopatzCore.DebugHub
Hub.tools = Hub.tools or {}

function Hub.RegisterTool(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string" or definition.id == "" then
        return false
    end
    if type(definition.title) ~= "string" or type(definition.action) ~= "function" then
        return false
    end

    definition.description = tostring(definition.description or "")
    definition.order = tonumber(definition.order) or 1000
    definition.available = type(definition.available) == "function" and definition.available or function() return true end
    Hub.tools[definition.id] = definition

    if Hub.Window and Hub.Window.instance then
        Hub.Window.instance:rebuildCards()
    end
    return true
end

function Hub.UnregisterTool(id)
    Hub.tools[tostring(id or "")] = nil
    if Hub.Window and Hub.Window.instance then
        Hub.Window.instance:rebuildCards()
    end
end

function Hub.GetTools()
    local result = {}
    for _, definition in pairs(Hub.tools) do
        result[#result + 1] = definition
    end
    table.sort(result, function(left, right)
        if left.order == right.order then
            return left.title < right.title
        end
        return left.order < right.order
    end)
    return result
end

local function launcherIsAvailable(definition)
    local ok, available = pcall(definition.available)
    return ok and not not available
end

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function drawToolItem(list, y, entry, alternate)
    local item = entry.item
    local selected = list.selected == entry.index
    local height = list.itemheight
    UI.DrawListSelection(list, y, height, selected, alternate)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    local statusColor = item.available and "success" or "danger"
    list:drawText(item.title, 12, y + 7, text.r, text.g, text.b, text.a, UIFont.Medium)
    UI.DrawBadge(list, item.available and "Available" or "Unavailable", list:getWidth() - 12, y + 7, statusColor)
    local availableWidth = math.max(40, list:getWidth() - 30)
    local description = Layout.Ellipsize(item.description, UIFont.Small, availableWidth)
    list:drawText(description, 12, y + 31, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + height
end

PsychopatzDebugHubWindow = PsychopatzWindow:derive("PsychopatzDebugHubWindow")
Hub.Window = PsychopatzDebugHubWindow

function PsychopatzDebugHubWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function PsychopatzDebugHubWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.toolList = UI.CreateList(self, { itemHeight = Layout.Pixels(58, self.uiScale), doDrawItem = drawToolItem })
    self.launchButton = UI.CreateButton(self, {
        id = "launch",
        title = "Launch selected tool",
        target = self,
        onclick = PsychopatzDebugHubWindow.onLaunchSelected,
        variant = "primary",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = "Close",
        target = self,
        onclick = PsychopatzDebugHubWindow.onCloseClick,
        variant = "quiet",
    })
    self:rebuildCards()
    self:requestResponsiveLayout(true)
end

function PsychopatzDebugHubWindow:rebuildCards()
    if not self.toolList then return end
    local selected = self.toolList:getItem()
    local selectedId = selected and selected.item and selected.item.id or nil
    self.definitions = Hub.GetTools()
    self.toolList:clear()
    for _, definition in ipairs(self.definitions) do
        local item = {
            id = definition.id,
            title = definition.title,
            description = definition.description,
            available = launcherIsAvailable(definition),
        }
        self.toolList:addItem(definition.title, item)
        if selectedId == definition.id then self.toolList.selected = #self.toolList.items end
    end
    self:refreshAvailability()
end

function PsychopatzDebugHubWindow:refreshAvailability()
    for index, entry in ipairs(self.toolList and self.toolList.items or {}) do
        local definition = Hub.tools[entry.item.id]
        entry.item.available = definition and launcherIsAvailable(definition) or false
    end
    local selected = self.toolList and self.toolList:getItem() or nil
    self.launchButton:setEnable(selected and selected.item.available or false)
end

function PsychopatzDebugHubWindow:onLauncherClick(id)
    local definition = Hub.tools[id]
    if not definition or not launcherIsAvailable(definition) then
        local player = getPlayer and getPlayer() or nil
        if player and definition then player:Say(definition.title .. " unavailable in this session.") end
        return
    end

    local ok, err = pcall(definition.action)
    if not ok then
        local player = getPlayer and getPlayer() or nil
        if player then player:Say(definition.title .. " failed to open.") end
        print("[PsychopatzCore.DebugHub] " .. tostring(err))
    end
end

function PsychopatzDebugHubWindow:onLaunchSelected()
    local selected = self.toolList and self.toolList:getItem() or nil
    if selected and selected.item then self:onLauncherClick(selected.item.id) end
end

function PsychopatzDebugHubWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 55, bottom = 48 })
    Layout.SetBounds(self.toolList, rect.x, rect.y, rect.width, rect.height)
    local buttons = { self.launchButton, self.closeButton }
    local buttonWidth = math.min(Layout.Pixels(180, self.uiScale), math.floor((rect.width - Layout.Pixels(8, self.uiScale)) / 2))
    for _, button in ipairs(buttons) do button.psychopatzPreferredWidth = buttonWidth end
    Layout.Flow(buttons, { x = rect.x, y = rect.y + rect.height + Layout.Pixels(8, self.uiScale), width = rect.width }, { scale = self.uiScale })
end

function PsychopatzDebugHubWindow:onCloseClick()
    self:close()
end

function PsychopatzDebugHubWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    PsychopatzDebugHubWindow.instance = nil
end

function PsychopatzDebugHubWindow:render()
    PsychopatzWindow.render(self)
    local rect = self:getContentRect({ top = 55, bottom = 48 })
    UI.DrawSectionTitle(self, "Development tools", rect.x, rect.y - Layout.Pixels(22, self.uiScale), rect.width, tostring(#(self.definitions or {})))
end

function PsychopatzDebugHubWindow:prerender()
    PsychopatzWindow.prerender(self)
    self:refreshAvailability()
end

function PsychopatzDebugHubWindow.Open()
    if PsychopatzDebugHubWindow.instance then
        PsychopatzDebugHubWindow.instance:setVisible(true)
        PsychopatzDebugHubWindow.instance:bringToTop()
        PsychopatzDebugHubWindow.instance:rebuildCards()
        return PsychopatzDebugHubWindow.instance
    end

    local window = UI.NewWindow(PsychopatzDebugHubWindow, {
        title = "Psychopatz Debug Hub",
        resizable = true,
        responsiveSpec = {
            width = 720,
            height = 520,
            minWidth = 460,
            minHeight = 350,
            maxWidth = 920,
            maxHeight = 760,
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    PsychopatzDebugHubWindow.instance = window
    return window
end

function PsychopatzDebugHubWindow:new(x, y, width, height, options)
    local o = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(o, self)
    self.__index = self
    return o
end

function Hub.Open()
    return PsychopatzDebugHubWindow.Open()
end

return Hub
