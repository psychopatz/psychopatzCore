local Core = PsychopatzCore
local UI = Core.UI
local Layout = UI.Layout
local Geometry = require "PsychopatzCore/UI/PsychopatzWindow_Geometry"
local Window = PsychopatzWindow

function Window:restoreGeometry()
    if not self.persistGeometry or not self.persistenceKey then return false end
    local adapter = self.geometryAdapter
    local state = adapter and adapter.load and adapter.load(self.persistenceKey, self) or nil
    if type(state) == "table" then
        if self.collapsible ~= false then
            if state.pin ~= nil then self.pin = state.pin == true end
            if state.collapsed ~= nil then
                self.isCollapsed = state.collapsed == true
            end
        end
        if state.widgetDetached ~= nil then
            self.psychopatzWidgetDetached = state.widgetDetached == true
        end
    end
    if self.collapsible == false then
        self.pin = true
        self.isCollapsed = false
    end
    local bounds = Layout.ResolveSavedWindow(state, self.responsiveSpec)
    if not bounds then return false end
    self:setX(bounds.x)
    self:setY(bounds.y)
    self:setWidth(bounds.width)
    self:setHeight(bounds.height)
    self.uiScale = bounds.scale
    self.geometrySignature = Geometry.Signature(self)
    self.psychopatzGeometryRestored = true
    -- Responsive panels must not replace a restored user size with their
    -- first auto-fit measurement on the first open after a restart.
    self.psychopatzUserResized = true
    Geometry.Trace(self, "loaded")
    return true
end

function Window:saveGeometry(force)
    if not self.persistGeometry or not self.persistenceKey then return false end
    local signature = Geometry.Signature(self)
    if force ~= true and signature == self.savedGeometrySignature then return false end
    local adapter = self.geometryAdapter
    if not adapter or not adapter.save then return false end
    local widgetDetached
    if self.psychopatzWidgetEnabled == true then
        widgetDetached = self.psychopatzWidgetDetached == true
    end
    local saved = adapter.save(self.persistenceKey, {
        x = self:getX(), y = self:getY(), w = self:getWidth(), h = self:getHeight(),
        pin = self.pin == true,
        collapsed = self.isCollapsed == true,
        widgetDetached = widgetDetached,
    }, self)
    if saved == false then return false end
    self.savedGeometrySignature = signature
    self.geometrySignature = signature
    self.geometryChangedAt = nil
    Geometry.Trace(self, "saved")
    return true
end

function Window:clearSavedGeometry()
    local adapter = self.geometryAdapter
    if adapter and adapter.clear and self.persistenceKey then adapter.clear(self.persistenceKey, self) end
    self.savedGeometrySignature = nil
end

function Window:trackGeometry()
    if not self.persistGeometry then return end
    local signature = Geometry.Signature(self)
    if self.geometrySignature ~= signature then
        self.geometrySignature = signature
        self.geometryChangedAt = Geometry.NowMillis()
    elseif self.geometryChangedAt
        and Geometry.NowMillis() - self.geometryChangedAt >= 400
    then
        self:saveGeometry(false)
    end
end

function Window:close()
    self:saveGeometry(true)
    ISCollapsableWindow.close(self)
end

function Window:removeFromUIManager()
    self:saveGeometry(true)
    ISCollapsableWindow.removeFromUIManager(self)
end

function Window:new(x, y, width, height, options)
    options = options or {}
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.responsiveSpec = Geometry.CopySpec(options, width, height)
    o.autoFitScreen = options.autoFitScreen ~= false
    o.resizable = options.resizable ~= false
    o.bottomResize = options.bottomResize ~= false
    o.collapsible = options.collapsible ~= false
    o.pin = options.pin == true
    o.title = tostring(options.title or Geometry.CoreText(
        "UI_PsychopatzCore_Window_DefaultTitle", "Psychopatz"))
    o.backgroundColor = UI.Theme.Color("window")
    o.borderColor = UI.Theme.Color("borderStrong")
    o.psychopatzThemeBackgroundName = "window"
    o.psychopatzThemeBorderName = "borderStrong"
    o.persistGeometry = options.persistGeometry ~= false and options.persistenceKey ~= false
    o.geometryAdapter = options.geometryAdapter or Geometry.DefaultAdapter
    o.geometryTrace = options.geometryTrace == true
    o.psychopatzLayoutDebug = options.layoutDebug == true
    UI.LayoutHost.Install(o, { debug = o.psychopatzLayoutDebug })
    local persistenceKey = options.persistenceKey or self.Type or options.title or "PsychopatzWindow"
    if options.persistenceNamespace and options.persistenceNamespace ~= "" then
        persistenceKey = tostring(options.persistenceNamespace) .. ":" .. tostring(persistenceKey)
    end
    o.persistenceKey = o.persistGeometry and tostring(persistenceKey) or nil
    local bounds = Layout.ResolveWindow(o.responsiveSpec)
    o.minimumWidth = bounds.minWidth
    o.minimumHeight = bounds.minHeight
    -- An omitted responsive maximum means "up to the usable screen", which
    -- matches the native resize widget. An explicit maximum remains honored.
    o.maximumWidth = o.responsiveSpec.maxWidth ~= nil
        and bounds.maxWidth or bounds.screenWidth - bounds.margin * 2
    o.maximumHeight = o.responsiveSpec.maxHeight ~= nil
        and bounds.maxHeight or bounds.screenHeight - bounds.margin * 2
    if o.collapsible == false then
        o.pin = true
        o.isCollapsed = false
    end
    if not o:restoreGeometry() then
        o.geometrySignature = Geometry.Signature(o)
    end
    return o
end

function UI.NewWindow(windowClass, options)
    options = options or {}
    local class = windowClass or Window
    if options.persistenceKey == nil then
        local copied = {}
        for key, value in pairs(options) do copied[key] = value end
        copied.persistenceKey = class.Type or copied.title or "PsychopatzWindow"
        options = copied
    end
    local spec = Geometry.CopySpec(options, options.width or 900, options.height or 620)
    local bounds = Layout.ResolveWindow(spec)
    local window = class:new(bounds.x, bounds.y, bounds.width, bounds.height, options)
    window.uiScale = bounds.scale
    return window
end

return Window
