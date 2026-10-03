local Portrait = PsychopatzConversationPortrait

function Portrait:prerender()
    local reveal = self.reveal or 0
    self:syncScreenVariant()
    if reveal <= 0.18 then
        self.reveal = 0
        PsychopatzConversationPart.prerender(self)
        self.reveal = reveal
    else
        PsychopatzConversationPart.prerender(self)
    end
    local contentAlpha = self:getContentOpacity()
    local accent = self:getAccentColor()
    local contentVisible = contentAlpha > 0.001
    if self.portrait then
        if self.portrait.setContentOpacity then
            self.portrait:setContentOpacity(contentAlpha)
        end
        if self.portrait.setVisible then
            self.portrait:setVisible(contentVisible)
        end
    end
    if reveal <= 0 then
        if self.portrait then self.portrait:setVisible(false) end
        return
    end
    local linePhase = math.min(1, reveal / 0.18)
    local expansion = reveal <= 0.18 and 0 or ((reveal - 0.18) / 0.82)
    expansion = math.max(0, math.min(1, expansion))
    if expansion <= 0 then
        if self.portrait then self.portrait:setVisible(false) end
        if contentVisible then
            self:drawRect(
                self.width * 0.5 * (1 - linePhase),
                math.floor(self.height / 2),
                self.width * linePhase,
                2,
                contentAlpha,
                accent.r,
                accent.g,
                accent.b
            )
        end
        return
    end
    local visibleH = math.max(2, self.height * expansion)
    local visibleY = (self.height - visibleH) / 2
    self:setStencilRect(1, visibleY, self.width - 2, visibleH)
    if self.backgroundTexture and contentVisible then
        local tint = self.backgroundDefinition.tint or { r = 1, g = 1, b = 1 }
        self:drawTextureScaled(
            self.backgroundTexture,
            2,
            2,
            self.width - 4,
            self.height - 4,
            contentAlpha,
            tint.r or 1,
            tint.g or 1,
            tint.b or 1
        )
    end
    if self.portrait and self.portrait.setVisible then
        self.portrait:setVisible(contentVisible)
    end
end

return Portrait
