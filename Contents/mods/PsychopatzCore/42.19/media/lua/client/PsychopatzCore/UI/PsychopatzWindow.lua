require "ISUI/ISCollapsableWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Components/PsychopatzWindowToolbar"
require "PsychopatzCore/UI/Components/PsychopatzLayoutHost"
require "PsychopatzCore/Settings/PsychopatzSettings"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local LayoutHost = UI.LayoutHost
local Toolbar = UI.WindowToolbar
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
        return GeometryStore:SetWindowState(key, state.x, state.y, state.w, state.h, true, {
            pin = state.pin,
            collapsed = state.collapsed,
            widgetDetached = state.widgetDetached,
        })
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
    -- ISUIElement geometry getters instantiate the control when javaObject is
    -- absent.  A base constructor must not instantiate a derived window before
    -- the derived constructor has initialized its own fields.
    if window.javaObject == nil then
        return table.concat({
            math.floor(tonumber(window.x) or 0),
            math.floor(tonumber(window.y) or 0),
            math.floor(tonumber(window.width) or 0),
            math.floor(tonumber(window.height) or 0),
            tostring(window.pin == true),
            tostring(window.isCollapsed == true),
        }, ":")
    end
    return table.concat({
        math.floor(tonumber(window:getX()) or 0),
        math.floor(tonumber(window:getY()) or 0),
        math.floor(tonumber(window:getWidth()) or 0),
        math.floor(tonumber(window:getHeight()) or 0),
        tostring(window.pin == true),
        tostring(window.isCollapsed == true),
    }, ":")
end

local function nowMillis()
    return getTimeInMillis and getTimeInMillis() or 0
end

local function traceGeometry(window, event)
    if not window or window.geometryTrace ~= true then return end
    local hub = UI.CommandHub
    if not hub or type(hub.Trace) ~= "function" then return end
    hub.Trace("window_geometry_" .. tostring(event),
        "key=" .. tostring(window.persistenceKey)
        .. " x=" .. tostring(window:getX())
        .. " y=" .. tostring(window:getY())
        .. " w=" .. tostring(window:getWidth())
        .. " h=" .. tostring(window:getHeight()))
end

PsychopatzWindow = ISCollapsableWindow:derive("PsychopatzWindow")
UI.Window = PsychopatzWindow

function PsychopatzWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self.clearStentil = true
    self.uiScale = Layout.Scale()
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
    self.lastScreenWidth, self.lastScreenHeight = Layout.ScreenSize()
    self:installRenderClip()
end

local function syncNativeTitlebarButton(window, button)
    if not window or not button then return end
    local windowWidth = window.getWidth and window:getWidth()
        or window.width or 0
    local buttonWidth = button.getWidth and button:getWidth()
        or button.width or 16
    local x = math.max(0, math.floor(windowWidth - buttonWidth - 1))
    if button.setX then button:setX(x) end
    if button.setY then button:setY(1) end
    -- Keep the native control anchored as well as explicitly positioned. The
    -- explicit x fixes stale positions during resize; the anchor lets the
    -- vanilla UI continue tracking later parent geometry changes.
    button.anchorLeft = false
    button.anchorRight = true
    button.anchorTop = true
    button.anchorBottom = false
end

function PsychopatzWindow:installRenderClip()
    if self.psychopatzRenderClipInstalled then return end
    local render = self.render
    if not render or render == PsychopatzWindow.render then return end

    self.psychopatzRenderClipInstalled = true
    self.psychopatzOriginalRender = render
    self.render = function(window, ...)
        window.psychopatzCustomRenderActive = true
        local ok, result = pcall(render, window, ...)
        window.psychopatzCustomRenderActive = false
        if window.psychopatzStencilActive then
            window:clearStencilRect()
            window.psychopatzStencilActive = false
        end
        if not ok then error(result) end
        return result
    end
end

function PsychopatzWindow:syncWindowControls()
    local collapseButton = self.psychopatzTitlebarCollapseButton or self.collapseButton
    local pinButton = self.psychopatzTitlebarPinButton or self.pinButton

    syncNativeTitlebarButton(self, collapseButton)
    syncNativeTitlebarButton(self, pinButton)

    if self.collapsible == false then
        -- Fixed windows still use the native window frame and resize widgets,
        -- but they must never enter the pin/collapse state machine.  Keeping
        -- pin=true is important because ISCollapsableWindow collapses an
        -- unpinned window when the mouse leaves it.
        self.pin = true
        self.isCollapsed = false
        self.collapseCounter = 0
        if self.clearMaxDrawHeight then self:clearMaxDrawHeight() end
        if collapseButton then collapseButton:setVisible(false) end
        if pinButton then pinButton:setVisible(false) end
        self.psychopatzPinState = "disabled"
        if Toolbar then Toolbar.Sync(self) end
        return
    end

    if not collapseButton or not pinButton then
        if Toolbar then Toolbar.Sync(self) end
        return
    end

    local pinned = self.pin == true
    if self.psychopatzPinState == pinned then
        if Toolbar then Toolbar.Sync(self) end
        return
    end

    collapseButton:setVisible(pinned)
    pinButton:setVisible(not pinned)
    local activeButton = pinned and collapseButton or pinButton
    if activeButton then activeButton:bringToTop() end
    self.psychopatzPinState = pinned
    if Toolbar then Toolbar.Sync(self) end
end

function PsychopatzWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    -- Derived windows may use names such as "collapseButton" for their own
    -- toolbar controls. Keep stable references to the native title-bar
    -- controls so that pinning cannot hide the wrong button.
    self.psychopatzTitlebarPinButton = self.pinButton
    self.psychopatzTitlebarCollapseButton = self.collapseButton
    -- The vanilla constructor starts pinned and createChildren initially shows
    -- the collapse control. Core windows may explicitly start unpinned.
    if self.psychopatzTitlebarCollapseButton and self.psychopatzTitlebarPinButton then
        self.psychopatzTitlebarPinButton.onclick = function(target)
            target.pin = true
            target:syncWindowControls()
            target:saveGeometry(true)
        end
        self.psychopatzTitlebarCollapseButton.onclick = function(target)
            target.pin = false
            target:syncWindowControls()
            target:saveGeometry(true)
        end
        self.psychopatzPinState = nil
        self:syncWindowControls()
    end
    self:syncResizeWidgets()
end

function PsychopatzWindow:requestResponsiveLayout(force)
    local width = self:getWidth()
    local height = self:getHeight()
    if not force and self.layoutWidth == width and self.layoutHeight == height
        and not LayoutHost.IsDirty(self)
    then
        return
    end
    self.layoutWidth = width
    self.layoutHeight = height
    return LayoutHost.Perform(self, force)
end

function PsychopatzWindow:invalidateLayout(reason)
    return LayoutHost.Invalidate(self, reason)
end

function PsychopatzWindow:performLayout(force)
    return LayoutHost.Perform(self, force)
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
    self:syncResizeWidgets()
    return bounds
end

function PsychopatzWindow:applyResize(width, height)
    local nextWidth = Layout.Clamp(math.floor(tonumber(width) or self:getWidth()),
        self.minimumWidth or 1, self.maximumWidth or math.huge)
    local nextHeight = Layout.Clamp(math.floor(tonumber(height) or self:getHeight()),
        self.minimumHeight or 1, self.maximumHeight or math.huge)
    self:setWidth(nextWidth)
    self:setHeight(nextHeight)
    self.psychopatzUserResized = true
    Layout.KeepOnScreen(self)
    self:syncResizeWidgets()
    self:requestResponsiveLayout(true)
end

function PsychopatzWindow:syncResizeWidgets()
    local resizable = self.resizable ~= false
    local bottomResize = self.bottomResize ~= false
    local handleHeight = self.resizeWidgetHeight
        and self:resizeWidgetHeight() or 12
    local windowWidth = self:getWidth()
    local windowHeight = self:getHeight()
    if not self.psychopatzResizeFunction then
        self.psychopatzResizeFunction = function(target, width, height)
            if target and target.applyResize then
                target:applyResize(width, height)
            end
        end
    end
    local resizeFunction = self.psychopatzResizeFunction
    local corner = self.resizeWidget
    if corner then
        corner.resizeFunction = resizeFunction
        corner.target = self
        corner.yonly = false
        corner:setX(math.max(0, windowWidth - handleHeight))
        corner:setY(math.max(0, windowHeight - handleHeight))
        corner:setWidth(handleHeight)
        corner:setHeight(handleHeight)
        corner:setVisible(resizable)
        self.psychopatzResizeCornerBounds = {
            x = corner:getX(), y = corner:getY(),
            width = corner:getWidth(), height = corner:getHeight(),
        }
    end
    local bottom = self.resizeWidget2
    if bottom then
        bottom.resizeFunction = resizeFunction
        bottom.target = self
        bottom.yonly = true
        bottom:setVisible(resizable and bottomResize)
        bottom:setX(0)
        bottom:setY(math.max(0, windowHeight - handleHeight))
        bottom:setWidth(math.max(1, windowWidth - handleHeight))
        bottom:setHeight(handleHeight)
        self.psychopatzResizeBottomBounds = {
            x = bottom:getX(), y = bottom:getY(),
            width = bottom:getWidth(), height = bottom:getHeight(),
        }
    end

    -- Content controls are added after the native resize widgets. Keep both
    -- hit targets above those controls; ISResizeWidget intentionally has no
    -- visual render pass, so the panel renderer and its hitbox must stay in
    -- lockstep.
    local bottomVisible = bottom and (not bottom.getIsVisible
        or bottom:getIsVisible())
    local cornerVisible = corner and (not corner.getIsVisible
        or corner:getIsVisible())
    if bottomVisible and bottom.bringToTop then
        bottom:bringToTop()
    end
    if cornerVisible and corner.bringToTop then
        corner:bringToTop()
    end
end

function PsychopatzWindow:restoreGeometry()
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
    self.geometrySignature = geometrySignature(self)
    self.psychopatzGeometryRestored = true
    -- Responsive panels must not replace a restored user size with their
    -- first auto-fit measurement on the first open after a restart.
    self.psychopatzUserResized = true
    traceGeometry(self, "loaded")
    return true
end

function PsychopatzWindow:saveGeometry(force)
    if not self.persistGeometry or not self.persistenceKey then return false end
    local signature = geometrySignature(self)
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
    traceGeometry(self, "saved")
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
    self:installRenderClip()
    self:syncWindowControls()
    -- ISCollapsableWindow uses this flag to stencil the current window bounds
    -- before its children render.  Keep it enabled even when a derived window
    -- has changed the flag, otherwise collapsed children can bleed through.
    self.clearStentil = true
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
    self:syncResizeWidgets()
    self:requestResponsiveLayout(false)
    self:trackGeometry()
    ISCollapsableWindow.prerender(self)
    -- The native title-bar controls can be repositioned by the base window
    -- during its prerender. Re-run the shared control sync after that pass so
    -- both native and injected toolbar controls reflect the same bounds.
    self:syncWindowControls()
    self.psychopatzStencilActive = true
    if self.drawFrame ~= false then
        local accent = Theme.colors.accent
        self:drawRect(0, self:titleBarHeight(), self:getWidth(), 2, 0.75,
            accent.r, accent.g, accent.b)
    end
end

function PsychopatzWindow:render()
    if self.psychopatzCustomRenderActive then
        -- Derived windows commonly call this method first and then draw their
        -- own content.  Let the derived draw pass finish before the stencil is
        -- cleared by the wrapper installed above.
        local clearStentil = self.clearStentil
        self.clearStentil = false
        ISCollapsableWindow.render(self)
        self.clearStentil = clearStentil
        return
    end

    ISCollapsableWindow.render(self)
    self.psychopatzStencilActive = false
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
    o.bottomResize = options.bottomResize ~= false
    o.collapsible = options.collapsible ~= false
    o.pin = options.pin == true
    o.title = tostring(options.title or "Psychopatz")
    o.backgroundColor = Theme.Color("window")
    o.borderColor = Theme.Color("borderStrong")
    o.persistGeometry = options.persistGeometry ~= false and options.persistenceKey ~= false
    o.geometryAdapter = options.geometryAdapter or DefaultGeometryAdapter
    o.geometryTrace = options.geometryTrace == true
    o.psychopatzLayoutDebug = options.layoutDebug == true
    LayoutHost.Install(o, { debug = o.psychopatzLayoutDebug })
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
