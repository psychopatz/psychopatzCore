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
    self:syncResizeWidgets()
end

function Window:syncResizeWidgets()
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

return Window
