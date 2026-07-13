require "ISUI/ISCollapsableWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

PsychopatzWindow = ISCollapsableWindow:derive("PsychopatzWindow")
UI.Window = PsychopatzWindow

function PsychopatzWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self.uiScale = Layout.Scale()
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
end

function PsychopatzWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
end

function PsychopatzWindow:requestResponsiveLayout(force)
    local width = self:getWidth()
    local height = self:getHeight()
    if not force and self.layoutWidth == width and self.layoutHeight == height then return end
    self.layoutWidth = width
    self.layoutHeight = height
    if self.onResponsiveLayout then self:onResponsiveLayout() end
end

function PsychopatzWindow:applyResponsiveBounds(center)
    local bounds = Layout.ResolveWindow(self.responsiveSpec)
    self.uiScale = bounds.scale
    self:setWidth(bounds.width)
    self:setHeight(bounds.height)
    if center ~= false then
        self:setX(bounds.x)
        self:setY(bounds.y)
    else
        Layout.KeepOnScreen(self)
    end
    self:requestResponsiveLayout(true)
    return bounds
end

function PsychopatzWindow:getContentRect(options)
    return Layout.ContentRect(self, options)
end

function PsychopatzWindow:prerender()
    local screenWidth, screenHeight = Layout.ScreenSize()
    if self.lastScreenWidth ~= screenWidth or self.lastScreenHeight ~= screenHeight then
        self.lastScreenWidth = screenWidth
        self.lastScreenHeight = screenHeight
        if self.autoFitScreen ~= false then self:applyResponsiveBounds(false) end
    end
    self:requestResponsiveLayout(false)
    ISCollapsableWindow.prerender(self)
    local accent = Theme.colors.accent
    self:drawRect(0, self:titleBarHeight(), self:getWidth(), 2, 0.75, accent.r, accent.g, accent.b)
end

function PsychopatzWindow:new(x, y, width, height, options)
    options = options or {}
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.responsiveSpec = options.responsiveSpec or {
        width = width,
        height = height,
        minWidth = math.min(width, 520),
        minHeight = math.min(height, 360),
    }
    o.autoFitScreen = options.autoFitScreen ~= false
    o.resizable = options.resizable ~= false
    o.pin = options.pin == true
    o.title = tostring(options.title or "Psychopatz")
    o.backgroundColor = Theme.Color("window")
    o.borderColor = Theme.Color("borderStrong")
    return o
end

function UI.NewWindow(windowClass, options)
    options = options or {}
    local bounds = Layout.ResolveWindow(options.responsiveSpec or options)
    local class = windowClass or PsychopatzWindow
    local window = class:new(bounds.x, bounds.y, bounds.width, bounds.height, options)
    window.uiScale = bounds.scale
    return window
end

return PsychopatzWindow
