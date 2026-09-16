require "ISUI/ISPanel"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationText"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationTheme"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationOpacity"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationOpacityControl"

PsychopatzConversationPart = ISPanel:derive("PsychopatzConversationPart")

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text
local Theme = Conversation.Theme
local Opacity = Conversation.Opacity
local OpacityControl = Conversation.OpacityControl

local ACCENTS = {
    portrait = { r = 0.94, g = 0.53, b = 0.22 },
    history = { r = 0.28, g = 0.76, b = 0.62 },
    choices = { r = 0.20, g = 0.86, b = 0.68 },
}

local function accentFor(partID)
    return ACCENTS[tostring(partID)] or ACCENTS.history
end

function PsychopatzConversationPart:getAccentColor()
    return Theme.Resolve(
        self.owner and self.owner.spec or nil,
        accentFor(self.partID)
    )
end

local function drawCorner(panel, x, y, horizontal, vertical, alpha, color)
    local horizontalX = horizontal > 0 and x or x - 11
    local verticalY = vertical > 0 and y or y - 11
    panel:drawRect(horizontalX, y, 13, 2,
        alpha, color.r, color.g, color.b)
    panel:drawRect(x, verticalY, 2, 13,
        alpha, color.r, color.g, color.b)
end

function PsychopatzConversationPart:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.borderColor = { r = 0, g = 0, b = 0, a = 0 }
end

function PsychopatzConversationPart:createChildren()
    if ISPanel.createChildren then ISPanel.createChildren(self) end
    if not OpacityControl then return end
    self.opacityControl = OpacityControl:new(
        0,
        0,
        220,
        70,
        { owner = self, partID = self.partID }
    )
    self.opacityControl:initialise()
    self.opacityControl:instantiate()
    self.opacityControl:setVisible(false)
    self:addChild(self.opacityControl)
    self:positionOpacityControl()
end

function PsychopatzConversationPart:positionOpacityControl()
    if not self.opacityControl then return end
    local width = math.max(160, math.min(260, self.width - 16))
    local height = 70
    self.opacityControl:setWidth(width)
    self.opacityControl:setHeight(height)
    local offsetX = 0
    local offsetY = 0
    local host = self.opacityControlHost or self
    local current = self
    while host ~= self and current and current ~= host do
        offsetX = offsetX + (current.getX and current:getX() or current.x or 0)
        offsetY = offsetY + (current.getY and current:getY() or current.y or 0)
        current = current.getParent and current:getParent() or current.parent
    end
    self.opacityControl:setX(math.floor(offsetX + (self.width - width) / 2))
    self.opacityControl:setY(math.floor(offsetY + (self.height - height) / 2))
end

function PsychopatzConversationPart:attachOpacityControl(host)
    if not self.opacityControl or not host then return false end
    local currentHost = self.opacityControlHost or self
    if currentHost ~= host then
        if currentHost.removeChild then
            currentHost:removeChild(self.opacityControl)
        end
        if currentHost.children then
            local index
            for index = #currentHost.children, 1, -1 do
                if currentHost.children[index] == self.opacityControl then
                    table.remove(currentHost.children, index)
                end
            end
        end
        host:addChild(self.opacityControl)
        self.opacityControlHost = host
    end
    self:positionOpacityControl()
    return true
end

function PsychopatzConversationPart:refreshOpacityControlVisibility()
    if not self.opacityControl then return end
    local authorized = self.owner
        and type(self.owner.canUseDebug) == "function"
        and self.owner:canUseDebug() == true
    local visible = self.editMode == true and authorized
    self.opacityControl:setVisible(visible)
    if visible then
        self.opacityControl:refresh()
        if self.opacityControl.bringToTop then
            self.opacityControl:bringToTop()
        end
    end
end

function PsychopatzConversationPart:onPartResize()
    self:positionOpacityControl()
end

function PsychopatzConversationPart:setReveal(value)
    self.reveal = math.max(0, math.min(1, tonumber(value) or 0))
end

function PsychopatzConversationPart:setEditMode(enabled)
    self.editMode = enabled == true
    self.dragging = false
    self.resizing = false
    self:refreshOpacityControlVisibility()
end

function PsychopatzConversationPart:getBackgroundOpacity()
    return Opacity.Get(self.partID, "surface") * (self.reveal or 1)
end

function PsychopatzConversationPart:getContentOpacity()
    return Opacity.Get(self.partID, "detail") * (self.reveal or 1)
end

function PsychopatzConversationPart:prerender()
    self:refreshOpacityControlVisibility()
    ISPanel.prerender(self)
    local alpha = self:getBackgroundOpacity()
    local contentAlpha = self:getContentOpacity()
    local accent = self:getAccentColor()
    local bright = Theme.Brighten(accent, 0.34)
    local headerHeight = self.headerHeight or 24
    if alpha > 0.001 then
        self:drawRect(4, 5, self.width - 4, self.height - 5,
            alpha * 0.52, 0, 0, 0)
        self:drawRect(0, 0, self.width - 3, self.height - 3,
            alpha, 0.012, 0.022, 0.020)
        self:drawRect(1, 1, self.width - 5, headerHeight,
            alpha * 0.96,
            0.012 + accent.r * 0.06,
            0.018 + accent.g * 0.06,
            0.016 + accent.b * 0.06)
        self:drawRect(0, 0, 3, self.height - 3,
            alpha * 0.95, accent.r, accent.g, accent.b)
        self:drawRect(3, headerHeight, self.width - 6, 1,
            alpha * 0.72, accent.r, accent.g, accent.b)
        self:drawRectBorder(0, 0, self.width - 3, self.height - 3,
            alpha * 0.48, accent.r, accent.g, accent.b)
        local scanY
        for scanY = headerHeight + 4, self.height - 5, 6 do
            self:drawRect(4, scanY, self.width - 10, 1,
                alpha * 0.026, accent.r, accent.g, accent.b)
        end
        drawCorner(self, 0, 0, 1, 1, alpha * 0.9, accent)
        drawCorner(self, self.width - 5, 0, -1, 1,
            alpha * 0.65, accent)
        drawCorner(self, 0, self.height - 5, 1, -1,
            alpha * 0.55, accent)
        drawCorner(self, self.width - 5, self.height - 5, -1, -1,
            alpha * 0.9, accent)
    end
    self:drawText(
        Text.Resolve(self.title or self.editLabel, tostring(self.partID)),
        11,
        5,
        bright.r,
        bright.g,
        bright.b,
        contentAlpha,
        UIFont.Small
    )
    if alpha > 0.001 then
        local dot
        for dot = 0, 2 do
            self:drawRect(
                self.width - 18 - dot * 7,
                10,
                3,
                3,
                alpha * (0.35 + dot * 0.2),
                accent.r,
                accent.g,
                accent.b
            )
        end
    end
    if self.editMode then
        self:drawRectBorder(0, 0, self.width, self.height, 0.95, 0.3, 0.82, 1.0)
        self:drawRect(self.width - 14, self.height - 14, 14, 14, 0.85, 0.3, 0.82, 1.0)
    end
end

function PsychopatzConversationPart:onMouseDown(x, y)
    if not self.editMode then return false end
    self.capture = true
    self.mouseStartX = getMouseX and getMouseX() or x
    self.mouseStartY = getMouseY and getMouseY() or y
    self.boundsStart = {
        x = self:getX(),
        y = self:getY(),
        w = self:getWidth(),
        h = self:getHeight(),
    }
    self.resizing = x >= self.width - 20 and y >= self.height - 20
    self.dragging = not self.resizing
    return true
end

function PsychopatzConversationPart:applyPointerMove()
    if not self.capture or not self.boundsStart then return false end
    local mouseX = getMouseX and getMouseX() or self.mouseStartX
    local mouseY = getMouseY and getMouseY() or self.mouseStartY
    local dx = mouseX - self.mouseStartX
    local dy = mouseY - self.mouseStartY
    local rootW = self.parent and self.parent:getWidth() or getCore():getScreenWidth()
    local rootH = self.parent and self.parent:getHeight() or getCore():getScreenHeight()
    if self.resizing then
        self:setWidth(math.max(self.minimumWidth or 160, math.min(rootW - self:getX(), self.boundsStart.w + dx)))
        self:setHeight(math.max(self.minimumHeight or 100, math.min(rootH - self:getY(), self.boundsStart.h + dy)))
        if self.onPartResize then self:onPartResize() end
    else
        self:setX(math.max(0, math.min(rootW - self.width, self.boundsStart.x + dx)))
        self:setY(math.max(0, math.min(rootH - self.height, self.boundsStart.y + dy)))
    end
    return true
end

function PsychopatzConversationPart:onMouseMove(dx, dy)
    if self.capture then return self:applyPointerMove() end
    return false
end

function PsychopatzConversationPart:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function PsychopatzConversationPart:finishPointer()
    if not self.capture then return false end
    self.capture = false
    self.dragging = false
    self.resizing = false
    if self.owner and self.owner.savePartLayout then
        self.owner:savePartLayout(self)
    end
    return true
end

function PsychopatzConversationPart:onMouseUp(x, y)
    return self:finishPointer()
end

function PsychopatzConversationPart:onMouseUpOutside(x, y)
    return self:finishPointer()
end

function PsychopatzConversationPart:new(x, y, width, height, options)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    options = options or {}
    o.owner = options.owner
    o.partID = options.partID or "history"
    o.editLabel = options.editLabel
    o.title = options.title or options.editLabel
    o.headerHeight = tonumber(options.headerHeight) or 24
    o.minimumWidth = tonumber(options.minimumWidth) or 160
    o.minimumHeight = tonumber(options.minimumHeight) or 100
    o.reveal = 0
    o.editMode = false
    return o
end

return PsychopatzConversationPart
