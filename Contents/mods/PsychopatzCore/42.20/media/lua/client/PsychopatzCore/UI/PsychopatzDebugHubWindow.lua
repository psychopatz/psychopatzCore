require "PsychopatzCore/UI/PsychopatzDebugHubRegistry"
require "PsychopatzCore/UI/PsychopatzUI"

local Hub = PsychopatzCore.DebugHub
local Renderer = require "PsychopatzCore/UI/PsychopatzDebugHubWindow_Renderer"
local Cards = require "PsychopatzCore/UI/PsychopatzDebugHubWindow_Cards"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local tr = Renderer.Translate

PsychopatzDebugHubWindow = PsychopatzWindow:derive("PsychopatzDebugHubWindow")
Hub.Window = PsychopatzDebugHubWindow

require "PsychopatzCore/UI/PsychopatzDebugHubWindow_Interaction"

function PsychopatzDebugHubWindow:rebuildCards()
    Cards.Rebuild(self)
end

function PsychopatzDebugHubWindow:refreshAvailability()
    Cards.RefreshAvailability(self)
end

function PsychopatzDebugHubWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function PsychopatzDebugHubWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.toolList = UI.CreateList(self, { itemHeight = Layout.Pixels(58, self.uiScale), doDrawItem = Renderer.DrawItem })
    self.toolList.onMouseDown = function(list, x, y)
        return self:onToolListMouseDown(list, x, y)
    end
    self.toolList.onMouseDoubleClick = function(list, x, y)
        return self:onToolListMouseDoubleClick(list, x, y)
    end
    self.launchButton = UI.CreateButton(self, {
        id = "launch",
        title = tr("UI_PsychopatzDebugHub_Launch", "Launch selected tool"),
        target = self,
        onclick = PsychopatzDebugHubWindow.onLaunchSelected,
        variant = "primary",
    })
    self.hubCloseButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PsychopatzDebugHub_Close", "Close"),
        target = self,
        onclick = PsychopatzDebugHubWindow.onCloseClick,
        variant = "quiet",
    })
    self:rebuildCards()
    self:requestResponsiveLayout(true)
end

function PsychopatzDebugHubWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 55, bottom = 48 })
    Layout.SetBounds(self.toolList, rect.x, rect.y, rect.width, rect.height)
    local buttons = { self.launchButton, self.hubCloseButton }
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
    UI.DrawSectionTitle(self, tr("UI_PsychopatzDebugHub_Section",
        "Development tools"), rect.x, rect.y - Layout.Pixels(22, self.uiScale),
        rect.width, tostring(#(self.definitions or {})))
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
        title = tr("UI_PsychopatzDebugHub_Title", "Psychopatz Debug Hub"),
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
