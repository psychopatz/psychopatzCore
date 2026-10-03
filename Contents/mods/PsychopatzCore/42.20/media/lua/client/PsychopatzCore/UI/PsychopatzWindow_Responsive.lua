local Core = PsychopatzCore
local UI = Core.UI
local Theme = UI.Theme
local Layout = UI.Layout
local LayoutHost = UI.LayoutHost
local Window = PsychopatzWindow

function Window:requestResponsiveLayout(force)
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

function Window:invalidateLayout(reason)
    return LayoutHost.Invalidate(self, reason)
end

function Window:performLayout(force)
    return LayoutHost.Perform(self, force)
end

function Window:applyResponsiveBounds(center)
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

function Window:applyResize(width, height)
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

function Window:refreshTheme()
    local revision = Theme.GetRevision and Theme.GetRevision() or 0
    if self.psychopatzThemeRevision == revision then return false end
    if UI.RefreshTheme then UI.RefreshTheme(self) end
    self.psychopatzThemeRevision = revision
    return true
end

function Window:getContentRect(options)
    return Layout.ContentRect(self, options)
end

function Window:prerender()
    self:installRenderClip()
    self:refreshTheme()
    self:syncWindowControls()
    -- ISCollapsableWindow uses this flag to stencil the current window bounds
    -- before its children render. Keep it enabled even when a derived window
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

function Window:render()
    if self.psychopatzCustomRenderActive then
        -- Derived windows commonly call this method first and then draw their
        -- own content. Let the derived draw pass finish before the stencil is
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

function Window:onMouseUp(x, y)
    ISCollapsableWindow.onMouseUp(self, x, y)
    self:saveGeometry(false)
end

function Window:onMouseUpOutside(x, y)
    ISCollapsableWindow.onMouseUpOutside(self, x, y)
    self:saveGeometry(false)
end

return Window
