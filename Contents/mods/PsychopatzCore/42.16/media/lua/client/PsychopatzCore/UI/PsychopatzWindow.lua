require "ISUI/ISCollapsableWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/Settings/PsychopatzSettings"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local GeometryStore = PsychopatzCore.Settings.Open("UI", {
    fileName = "PsychopatzCore_UI.txt",
    defaults = {},
})

local DefaultGeometryAdapter = {
    load = function(key)
        if not GeometryStore.loaded then GeometryStore:Load() end
        return GeometryStore:GetWindowState(key)
    end,
    save = function(key, state)
        return GeometryStore:SetWindowState(key, state.x, state.y, state.w, state.h, true)
    end,
    clear = function(key)
        return GeometryStore:ClearWindowState(key, true)
    end,
}

local function copySpec(options, width, height)
    local source = options.responsiveSpec or {}
    local spec = {}
    for key, value in pairs(source) do spec[key] = value end
    spec.width = spec.width or width
    spec.height = spec.height or height
    spec.minWidth = spec.minWidth or math.min(width, 520)
    spec.minHeight = spec.minHeight or math.min(height, 360)
    if options.anchor ~= nil then spec.anchor = options.anchor end
    if options.offsetX ~= nil then spec.offsetX = options.offsetX end
    if options.offsetY ~= nil then spec.offsetY = options.offsetY end
    return spec
end

local function geometrySignature(window)
    return table.concat({
        math.floor(tonumber(window:getX()) or 0),
        math.floor(tonumber(window:getY()) or 0),
        math.floor(tonumber(window:getWidth()) or 0),
        math.floor(tonumber(window:getHeight()) or 0),
    }, ":")
end

local function nowMillis()
    return getTimeInMillis and getTimeInMillis() or 0
end

PsychopatzWindow = ISCollapsableWindow:derive("PsychopatzWindow")
UI.Window = PsychopatzWindow

function PsychopatzWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self.uiScale = Layout.Scale()
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
    self.lastScreenWidth, self.lastScreenHeight = Layout.ScreenSize()
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

function PsychopatzWindow:restoreGeometry()
    if not self.persistGeometry or not self.persistenceKey then return false end
    local adapter = self.geometryAdapter
    local state = adapter and adapter.load and adapter.load(self.persistenceKey, self) or nil
    local bounds = Layout.ResolveSavedWindow(state, self.responsiveSpec)
    if not bounds then return false end
    self:setX(bounds.x)
    self:setY(bounds.y)
    self:setWidth(bounds.width)
    self:setHeight(bounds.height)
    self.uiScale = bounds.scale
    self.geometrySignature = geometrySignature(self)
    return true
end

function PsychopatzWindow:saveGeometry(force)
    if not self.persistGeometry or not self.persistenceKey then return false end
    local signature = geometrySignature(self)
    if force ~= true and signature == self.savedGeometrySignature then return false end
    local adapter = self.geometryAdapter
    if not adapter or not adapter.save then return false end
    local saved = adapter.save(self.persistenceKey, {
        x = self:getX(), y = self:getY(), w = self:getWidth(), h = self:getHeight(),
    }, self)
    if saved == false then return false end
    self.savedGeometrySignature = signature
    self.geometrySignature = signature
    self.geometryChangedAt = nil
    return true
end

function PsychopatzWindow:clearSavedGeometry()
    local adapter = self.geometryAdapter
    if adapter and adapter.clear and self.persistenceKey then adapter.clear(self.persistenceKey, self) end
    self.savedGeometrySignature = nil
end

function PsychopatzWindow:trackGeometry()
    if not self.persistGeometry then return end
    local signature = geometrySignature(self)
    if self.geometrySignature ~= signature then
        self.geometrySignature = signature
        self.geometryChangedAt = nowMillis()
    elseif self.geometryChangedAt and nowMillis() - self.geometryChangedAt >= 400 then
        self:saveGeometry(false)
    end
end

function PsychopatzWindow:getContentRect(options)
    return Layout.ContentRect(self, options)
end

function PsychopatzWindow:prerender()
    local screenWidth, screenHeight = Layout.ScreenSize()
    if self.lastScreenWidth ~= screenWidth or self.lastScreenHeight ~= screenHeight then
        self.lastScreenWidth = screenWidth
        self.lastScreenHeight = screenHeight
        if self.autoFitScreen ~= false then
            if self.persistGeometry then
                Layout.KeepOnScreen(self)
                self:requestResponsiveLayout(true)
            else
                self:applyResponsiveBounds(false)
            end
        end
    end
    self:requestResponsiveLayout(false)
    self:trackGeometry()
    ISCollapsableWindow.prerender(self)
    local accent = Theme.colors.accent
    self:drawRect(0, self:titleBarHeight(), self:getWidth(), 2, 0.75, accent.r, accent.g, accent.b)
end

function PsychopatzWindow:onMouseUp(x, y)
    ISCollapsableWindow.onMouseUp(self, x, y)
    self:saveGeometry(false)
end

function PsychopatzWindow:onMouseUpOutside(x, y)
    ISCollapsableWindow.onMouseUpOutside(self, x, y)
    self:saveGeometry(false)
end

function PsychopatzWindow:close()
    self:saveGeometry(true)
    ISCollapsableWindow.close(self)
end

function PsychopatzWindow:removeFromUIManager()
    self:saveGeometry(true)
    ISCollapsableWindow.removeFromUIManager(self)
end

function PsychopatzWindow:new(x, y, width, height, options)
    options = options or {}
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.responsiveSpec = copySpec(options, width, height)
    o.autoFitScreen = options.autoFitScreen ~= false
    o.resizable = options.resizable ~= false
    o.pin = options.pin == true
    o.title = tostring(options.title or "Psychopatz")
    o.backgroundColor = Theme.Color("window")
    o.borderColor = Theme.Color("borderStrong")
    o.persistGeometry = options.persistGeometry ~= false and options.persistenceKey ~= false
    o.geometryAdapter = options.geometryAdapter or DefaultGeometryAdapter
    local persistenceKey = options.persistenceKey or self.Type or options.title or "PsychopatzWindow"
    if options.persistenceNamespace and options.persistenceNamespace ~= "" then
        persistenceKey = tostring(options.persistenceNamespace) .. ":" .. tostring(persistenceKey)
    end
    o.persistenceKey = o.persistGeometry and tostring(persistenceKey) or nil
    if not o:restoreGeometry() then
        o.geometrySignature = geometrySignature(o)
    end
    return o
end

function UI.NewWindow(windowClass, options)
    options = options or {}
    local class = windowClass or PsychopatzWindow
    if options.persistenceKey == nil then
        local copied = {}
        for key, value in pairs(options) do copied[key] = value end
        copied.persistenceKey = class.Type or copied.title or "PsychopatzWindow"
        options = copied
    end
    local spec = copySpec(options, options.width or 900, options.height or 620)
    local bounds = Layout.ResolveWindow(spec)
    local window = class:new(bounds.x, bounds.y, bounds.width, bounds.height, options)
    window.uiScale = bounds.scale
    return window
end

return PsychopatzWindow
