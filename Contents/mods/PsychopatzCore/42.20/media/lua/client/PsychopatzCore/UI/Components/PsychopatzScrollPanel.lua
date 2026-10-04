require "ISUI/ISPanel"

local ScrollPanel = ISPanel:derive("PsychopatzScrollPanel")

function ScrollPanel:initialise()
    ISPanel.initialise(self)
end

function ScrollPanel:createChildren()
    ISPanel.createChildren(self)
    self:setScrollChildren(true)
    self:addScrollBars()
    self.contentHeight = self:getHeight()
end

function ScrollPanel:onResize()
    local layout = PsychopatzCore and PsychopatzCore.UI
        and PsychopatzCore.UI.Layout
    if layout and layout.SyncNativeScrollbars then
        layout.SyncNativeScrollbars(self)
    end
end

function ScrollPanel:onMouseWheel(delta)
    local current = self.getYScroll and tonumber(self:getYScroll()) or 0
    local maximum = math.max(0, (tonumber(self.contentHeight) or 0)
        - (tonumber(self.height) or 0))
    if self.setYScroll then
        self:setYScroll(math.max(-maximum, math.min(0,
            current + (tonumber(delta) or 0) * 32)))
    end
    return true
end

function ScrollPanel:setContentHeight(height)
    local minimum = tonumber(self.height) or 0
    self.contentHeight = math.max(minimum, tonumber(height) or minimum)
    if self.setScrollHeight then self:setScrollHeight(self.contentHeight) end
    local maximum = math.max(0, self.contentHeight - minimum)
    if self.getYScroll and self.setYScroll then
        self:setYScroll(math.max(-maximum, math.min(0, self:getYScroll())))
    end
end

function ScrollPanel:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

function ScrollPanel:render()
    ISPanel.render(self)
    self:clearStencilRect()
end

function ScrollPanel:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

return ScrollPanel
