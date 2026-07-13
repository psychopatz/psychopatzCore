require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISLabel"
require "ISUI/ISPanel"
require "PsychopatzCore/00_PsychopatzCore_Init"

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

local function splitWrappedLines(font, value, maxWidth)
    local lines = {}
    local current = ""
    for word in string.gmatch(tostring(value or ""), "%S+") do
        local candidate = current == "" and word or (current .. " " .. word)
        if current ~= "" and getTextManager():MeasureStringX(font, candidate) > maxWidth then
            lines[#lines + 1] = current
            current = word
        else
            current = candidate
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    return lines
end

local PsychopatzDebugHubCard = ISPanel:derive("PsychopatzDebugHubCard")

function PsychopatzDebugHubCard:initialise()
    ISPanel.initialise(self)
end

function PsychopatzDebugHubCard:createChildren()
    self.button = ISButton:new(10, 10, self.width - 20, 26, self.definition.title, self, PsychopatzDebugHubCard.onLaunch)
    self.button:initialise()
    self:addChild(self.button)
end

function PsychopatzDebugHubCard:onLaunch()
    self.parentWindow:onLauncherClick(self.definition.id)
end

function PsychopatzDebugHubCard:setAvailability(available)
    self.available = available == true
    self.button:setEnable(self.available)
    self.button.backgroundColor = self.available
        and { r = 0.2, g = 0.34, b = 0.22, a = 1 }
        or { r = 0.16, g = 0.16, b = 0.16, a = 1 }
end

function PsychopatzDebugHubCard:prerender()
    ISPanel.prerender(self)
    self:drawRect(0, 0, self.width, self.height, 0.12, 0.02, 0.02, 0.02)
    self:drawRectBorder(0, 0, self.width, self.height, 0.8, 0.35, 0.35, 0.38)
end

function PsychopatzDebugHubCard:render()
    ISPanel.render(self)
    local y = 44
    for _, line in ipairs(splitWrappedLines(UIFont.Small, self.definition.description, self.width - 20)) do
        self:drawText(line, 10, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        y = y + 14
    end
    local text = self.available and "Available" or "Unavailable in current session"
    local r, g, b = self.available and 0.5 or 0.78, self.available and 0.92 or 0.58, self.available and 0.5 or 0.58
    self:drawText(text, 10, self.height - 20, r, g, b, 1, UIFont.Small)
end

function PsychopatzDebugHubCard:new(x, y, width, height, definition, parentWindow)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.definition = definition
    o.parentWindow = parentWindow
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

PsychopatzDebugHubWindow = ISCollapsableWindow:derive("PsychopatzDebugHubWindow")
Hub.Window = PsychopatzDebugHubWindow

function PsychopatzDebugHubWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self.title = "Psychopatz Debug Hub"
    self:setResizable(false)
end

function PsychopatzDebugHubWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    self:rebuildCards()
end

function PsychopatzDebugHubWindow:rebuildCards()
    if self.cards then
        for _, card in pairs(self.cards) do
            self:removeChild(card)
        end
    end
    if self.introLabel then self:removeChild(self.introLabel) end
    if self.closeButton then self:removeChild(self.closeButton) end

    self.cards = {}
    self.definitions = Hub.GetTools()
    local padX, topY, columns, columnGap, rowHeight = 14, self:titleBarHeight() + 10, 2, 14, 112
    local columnWidth = math.floor((self:getWidth() - (padX * 2) - columnGap) / columns)

    self.introLabel = ISLabel:new(padX, topY, 20, "Central launcher for Psychopatz mod development tools.", 0.9, 0.9, 0.9, 1, UIFont.Small, true)
    self.introLabel:initialise()
    self:addChild(self.introLabel)

    for index, definition in ipairs(self.definitions) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local card = PsychopatzDebugHubCard:new(
            padX + (columnWidth + columnGap) * column,
            topY + 24 + rowHeight * row,
            columnWidth,
            rowHeight - 12,
            definition,
            self
        )
        card:initialise()
        card:createChildren()
        self:addChild(card)
        self.cards[definition.id] = card
    end

    local rows = math.max(1, math.ceil(#self.definitions / columns))
    local closeY = topY + 24 + rowHeight * rows + 4
    self.closeButton = ISButton:new(self:getWidth() - 124, closeY, 110, 25, "Close", self, PsychopatzDebugHubWindow.onCloseClick)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    self:setHeight(closeY + 38)
    self:refreshAvailability()
end

function PsychopatzDebugHubWindow:refreshAvailability()
    for _, definition in ipairs(self.definitions or {}) do
        local card = self.cards[definition.id]
        if card then card:setAvailability(launcherIsAvailable(definition)) end
    end
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

function PsychopatzDebugHubWindow:onCloseClick()
    self:close()
end

function PsychopatzDebugHubWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    PsychopatzDebugHubWindow.instance = nil
end

function PsychopatzDebugHubWindow.Open()
    if PsychopatzDebugHubWindow.instance then
        PsychopatzDebugHubWindow.instance:setVisible(true)
        PsychopatzDebugHubWindow.instance:bringToTop()
        PsychopatzDebugHubWindow.instance:rebuildCards()
        return PsychopatzDebugHubWindow.instance
    end

    local width, height = 520, 360
    local window = PsychopatzDebugHubWindow:new(
        math.floor((getCore():getScreenWidth() - width) / 2),
        math.floor((getCore():getScreenHeight() - height) / 2),
        width,
        height
    )
    window:initialise()
    window:addToUIManager()
    PsychopatzDebugHubWindow.instance = window
    return window
end

function PsychopatzDebugHubWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.03, g = 0.03, b = 0.03, a = 0.92 }
    o.borderColor = { r = 0.85, g = 0.85, b = 0.85, a = 0.85 }
    o.resizable = false
    return o
end

function Hub.Open()
    return PsychopatzDebugHubWindow.Open()
end

return Hub
