-- Reusable attached panel window.
--
-- Attached windows share the Core window lifecycle and resize constraints, but
-- use a compact frameless header instead of native title-bar controls. They
-- are intended for panels that are owned by another window and therefore do
-- not need pin, collapse, detach, or close buttons.

require "PsychopatzCore/UI/PsychopatzFixedWindow"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

PsychopatzAttachedWindow = PsychopatzFixedWindow:derive(
    "PsychopatzAttachedWindow")
UI.AttachedWindow = PsychopatzAttachedWindow

function PsychopatzAttachedWindow:initialise()
    PsychopatzWindow.initialise(self)
    self.drawFrame = false
    self.background = true
    self.psychopatzOpacityMode = "surface"
    self.backgroundColor = Theme.Color("window")
    self.borderColor = Theme.Color("borderStrong")
end

function PsychopatzAttachedWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    if self.closeButton then self.closeButton:setVisible(false) end
    if self.psychopatzTitlebarPinButton then
        self.psychopatzTitlebarPinButton:setVisible(false)
    end
    if self.psychopatzTitlebarCollapseButton then
        self.psychopatzTitlebarCollapseButton:setVisible(false)
    end
    self:syncResizeWidgets()
end

function PsychopatzAttachedWindow:headerHeight()
    return Layout.Pixels(30, self.uiScale or Layout.Scale())
end

function PsychopatzAttachedWindow:footerHeight()
    if self.resizable == false then return 0 end
    -- ISCollapsableWindow creates the resize widgets using this native
    -- height. Keep the custom footer and the actual hitbox identical at every
    -- UI scale.
    return self:resizeWidgetHeight()
end

function PsychopatzAttachedWindow:getContentRect(options)
    local resolved = {}
    for key, value in pairs(options or {}) do resolved[key] = value end
    -- Layout.ContentRect scales logical values. Do not pass the already
    -- scaled header/footer pixel heights here or low-resolution UIs will
    -- scale them twice and place controls into the title bar/footer.
    local scale = self.uiScale or Layout.Scale()
    if resolved.top == nil then resolved.top = 30 end
    if resolved.bottom == nil then
        resolved.bottom = self:footerHeight() / math.max(scale, 0.01)
    end
    return PsychopatzWindow.getContentRect(self, resolved)
end

function PsychopatzAttachedWindow:prerender()
    PsychopatzWindow.prerender(self)
    local height = self:headerHeight()
    local alpha = self.commandHubSurfaceOpacity or self.commandHubOpacity
        or (self.backgroundColor and self.backgroundColor.a)
        or Theme.colors.window.a
    local background = Theme.Color("window", alpha)
    local accent = Theme.colors.accent
    self:drawRect(0, 0, self:getWidth(), height, background.a,
        background.r, background.g, background.b)
    self:drawTextCentre(self.title or "", self:getWidth() / 2,
        Layout.Pixels(7, self.uiScale or Layout.Scale()), accent.r, accent.g,
        accent.b, 1, Theme.Font(self.uiScale, "title"))
    self:drawRect(Layout.Pixels(8, self.uiScale or Layout.Scale()),
        height - 1, self:getWidth() - Layout.Pixels(16,
            self.uiScale or Layout.Scale()), 1, 0.75, accent.r, accent.g,
        accent.b)
end

function PsychopatzAttachedWindow:render()
    PsychopatzWindow.render(self)
    self:syncResizeWidgets()
    local border = self.borderColor or Theme.colors.borderStrong
    self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), border.a,
        border.r, border.g, border.b)

    local resize = self.resizeWidget
    if not self.isCollapsed and self.resizable ~= false and resize
        and resize:getIsVisible()
    then
        local handleHeight = self:footerHeight()
        local y = self:getHeight() - handleHeight
        local background = Theme.colors.surface
        self:drawRect(0, y, self:getWidth(), handleHeight,
            (self.backgroundColor and self.backgroundColor.a) or background.a,
            background.r, background.g, background.b)
        self:drawRectBorder(0, y, self:getWidth(), handleHeight, border.a,
            border.r, border.g, border.b)
        if self.resizeimage then
            self:drawTextureScaled(self.resizeimage,
                self:getWidth() - handleHeight + 1, y + 1,
                handleHeight - 2, handleHeight - 2, 1, 1, 1, 1)
        end
    end
end

function PsychopatzAttachedWindow:new(x, y, width, height, options)
    local object = PsychopatzFixedWindow.new(self, x, y, width, height,
        options)
    setmetatable(object, self)
    self.__index = self
    return object
end

return PsychopatzAttachedWindow
