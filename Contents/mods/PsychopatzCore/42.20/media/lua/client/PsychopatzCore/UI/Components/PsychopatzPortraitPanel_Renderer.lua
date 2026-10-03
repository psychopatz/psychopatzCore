local Window = PsychopatzPortraitPanel

function Window:prerender()
    local padding = tonumber(self.padding) or 2
    local current = getTimeInMillis and getTimeInMillis() or 0
    self:applyModelVisibility(self.contentOpacity)
    if (tonumber(self.contentOpacity) or 1) <= 0.001 then return end
    self:refreshAnimationState(current)
    if self.modelView and self.speechPulseUntil
        and current < self.speechPulseUntil
    then
        local phase = (current - (self.speechPulseStartedAt or current)) / 90
        local offset = (tonumber(self.yOffset) or -0.85) + math.sin(phase) * 0.025
        self.modelView:setYOffset(offset)
    elseif self.modelView and self.speechPulseUntil then
        self.speechPulseUntil = nil
        self.modelView:setYOffset(tonumber(self.yOffset) or -0.85)
    end
    ISPanel.prerender(self)
    if self.showBackground then
        if self.avatarBackground then
            self:drawTextureScaled(
                self.avatarBackground,
                padding,
                padding,
                math.max(1, self.width - padding * 2),
                math.max(1, self.height - padding * 2),
                1,
                0.4,
                0.4,
                0.4
            )
        else
            self:drawRect(
                padding,
                padding,
                math.max(1, self.width - padding * 2),
                math.max(1, self.height - padding * 2),
                1,
                0.28,
                0.28,
                0.28
            )
        end
    end
    if self.showBorder then
        self:drawRectBorder(
            0,
            0,
            self.width,
            self.height,
            1,
            0.3,
            0.3,
            0.3
        )
    end
end

function Window:render()
    -- UI3DModel can retain its viewport clear surface even after the model
    -- itself is hidden. A fully transparent content layer must skip the child
    -- renderer as well, otherwise it leaves an opaque black rectangle.
    if (tonumber(self.contentOpacity) or 1) <= 0.001 then return end
    local padding = tonumber(self.padding) or 2
    local width = math.max(1, self.width - padding * 2)
    local height = math.max(1, self.height - padding * 2)
    local variant = self:getScreenVariant()
    local alpha
    local time
    local offsetX = padding
    local offsetY = padding

    ISPanel.render(self)
    if variant == "none" or not self.crtTexture then return end
    if variant == "crt" then
        time = tonumber(getTimeInMillis and getTimeInMillis() or 0) or 0
        alpha = tonumber(self.crtOpacity) or 0.52
        alpha = alpha * (0.91 + math.sin(time / 83) * 0.055
            + math.sin(time / 211) * 0.035)
        offsetX = offsetX + math.floor(math.sin(time / 127) * 1.5)
        offsetY = offsetY + math.floor(math.sin(time / 173) * 1.0)
    else
        alpha = tonumber(self.subtleOpacity) or 0.18
    end
    alpha = alpha * (tonumber(self.contentOpacity) or 1)
    alpha = math.max(0, math.min(1, alpha))
    self:drawTextureScaled(
        self.crtTexture,
        offsetX,
        offsetY,
        width,
        height,
        alpha,
        1,
        1,
        1
    )
    if variant == "crt" then
        local scanY = padding + math.floor((time / 7) % height)
        self:drawRect(padding, scanY, width, 2, alpha * 0.24,
            0.42, 0.88, 0.78)
    end
end

return Window
