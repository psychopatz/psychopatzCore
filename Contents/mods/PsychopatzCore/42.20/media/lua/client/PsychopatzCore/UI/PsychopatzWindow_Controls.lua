local Core = PsychopatzCore
local UI = Core.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Toolbar = UI.WindowToolbar
local Window = PsychopatzWindow

function Window:initialise()
    ISCollapsableWindow.initialise(self)
    self.clearStentil = true
    self.uiScale = Layout.Scale()
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
    self.psychopatzThemeBackgroundName = "window"
    self.psychopatzThemeBorderName = "borderStrong"
    self.lastScreenWidth, self.lastScreenHeight = Layout.ScreenSize()
    self:installRenderClip()
end

function Window:installRenderClip()
    if self.psychopatzRenderClipInstalled then return end
    local render = self.render
    if not render or render == Window.render then return end

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

-- Derived windows may need a final overlay after their child controls render.
-- The normal PsychopatzWindow render path intentionally keeps the parent
-- stencil active while a derived render method adds content. Expose the
-- matching cleanup as a shared primitive so overlays can draw in the parent
-- pass without being clipped or leaving render state behind.
function Window:finishRenderClip()
    if self.psychopatzStencilActive then
        self:clearStencilRect()
        self.psychopatzStencilActive = false
    end
end

function Window:syncWindowControls()
    local collapseButton = self.psychopatzTitlebarCollapseButton or self.collapseButton
    local pinButton = self.psychopatzTitlebarPinButton or self.pinButton

    if Toolbar and Toolbar.SyncNativeControls then
        Toolbar.SyncNativeControls(self)
    end

    if self.collapsible == false then
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

function Window:createChildren()
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
    self.psychopatzResizeTopSynced = false
    self:syncResizeWidgets(true)
end

local function syncResizeHandle(widget, x, y, width, height, visible, resizeFunction, owner, yonly)
    local changed = false
    if widget.resizeFunction ~= resizeFunction then
        widget.resizeFunction = resizeFunction
        changed = true
    end
    if widget.target ~= owner then
        widget.target = owner
        changed = true
    end
    if widget.yonly ~= yonly then
        widget.yonly = yonly
        changed = true
    end
    local currentX = widget.getX and widget:getX() or widget.x
    local currentY = widget.getY and widget:getY() or widget.y
    local currentW = widget.getWidth and widget:getWidth() or widget.width
    local currentH = widget.getHeight and widget:getHeight() or widget.height
    local currentVis = widget.getIsVisible and widget:getIsVisible() or widget.visible
    if currentX ~= x then widget:setX(x); changed = true end
    if currentY ~= y then widget:setY(y); changed = true end
    if currentW ~= width then widget:setWidth(width); changed = true end
    if currentH ~= height then widget:setHeight(height); changed = true end
    if currentVis ~= visible then widget:setVisible(visible); changed = true end
    return changed
end

function Window:syncResizeWidgets(force)
    local resizable = self.resizable ~= false
    local bottomResize = self.bottomResize ~= false
    local handleHeight = self.resizeWidgetHeight
        and self:resizeWidgetHeight() or 12
    local windowWidth = self:getWidth()
    local windowHeight = self:getHeight()
    local corner = self.resizeWidget
    local bottom = self.resizeWidget2
    local syncKey = tostring(windowWidth) .. ":" .. tostring(windowHeight)
        .. ":" .. tostring(handleHeight)
        .. ":" .. tostring(resizable) .. ":" .. tostring(bottomResize)
        .. ":" .. tostring(corner ~= nil) .. ":" .. tostring(bottom ~= nil)
    if not force and self.psychopatzResizeSyncKey == syncKey
        and self.psychopatzResizeTopSynced == true
    then
        return
    end
    if not self.psychopatzResizeFunction then
        self.psychopatzResizeFunction = function(target, width, height)
            if target and target.applyResize then
                target:applyResize(width, height)
            end
        end
    end
    local resizeFunction = self.psychopatzResizeFunction
    local cornerChanged = false
    if corner then
        local cornerX = math.max(0, windowWidth - handleHeight)
        local cornerY = math.max(0, windowHeight - handleHeight)
        cornerChanged = syncResizeHandle(corner, cornerX, cornerY,
            handleHeight, handleHeight, resizable, resizeFunction, self, false)
        local bounds = self.psychopatzResizeCornerBounds
        if not bounds then
            bounds = {}
            self.psychopatzResizeCornerBounds = bounds
        end
        bounds.x = corner:getX()
        bounds.y = corner:getY()
        bounds.width = corner:getWidth()
        bounds.height = corner:getHeight()
    end

    local bottomChanged = false
    if bottom then
        local bottomY = math.max(0, windowHeight - handleHeight)
        local bottomW = math.max(1, windowWidth - handleHeight)
        bottomChanged = syncResizeHandle(bottom, 0, bottomY,
            bottomW, handleHeight, resizable and bottomResize,
            resizeFunction, self, true)
        local bounds = self.psychopatzResizeBottomBounds
        if not bounds then
            bounds = {}
            self.psychopatzResizeBottomBounds = bounds
        end
        bounds.x = bottom:getX()
        bounds.y = bottom:getY()
        bounds.width = bottom:getWidth()
        bounds.height = bottom:getHeight()
    end

    self.psychopatzResizeSyncKey = syncKey

    -- Content controls are added after the native resize widgets. Keep both
    -- hit targets above those controls without re-queuing bringToTop() on
    -- every frame when geometry and visibility have not changed.
    if force or cornerChanged or bottomChanged or not self.psychopatzResizeTopSynced then
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
end

return Window
