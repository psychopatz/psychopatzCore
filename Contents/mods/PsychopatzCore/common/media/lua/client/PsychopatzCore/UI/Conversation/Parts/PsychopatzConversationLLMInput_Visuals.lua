local LLMInput = PsychopatzConversationLLMInput
local Internal = LLMInput.Internal

local UI = Internal.UI
local Opacity = Internal.Opacity
local optionTitle = Internal.optionTitle
local applyControlOpacity = Internal.applyControlOpacity

function LLMInput:refreshOpacity()
    local signature = Opacity.GetSignature()
    local reveal = tonumber(self.reveal) or 1
    if self.lastConversationOpacitySignature == signature
        and self.lastConversationOpacityReveal == reveal
    then
        return false
    end
    local panelAlpha = self:getBackgroundOpacity()
    local contentAlpha = self:getContentOpacity()
    for _, definition in ipairs(self.modeButtons or {}) do
        applyControlOpacity(definition.button, contentAlpha)
    end
    applyControlOpacity(
        self.toggleButton and self.toggleButton.button,
        contentAlpha
    )
    applyControlOpacity(self.entry, contentAlpha)
    applyControlOpacity(self.sendButton, contentAlpha)
    applyControlOpacity(self.closeButton, contentAlpha)
    self.conversationPanelOpacity = panelAlpha
    self.conversationContentOpacity = contentAlpha
    self.lastConversationOpacitySignature = signature
    self.lastConversationOpacityReveal = reveal
    return true
end

function LLMInput:prerender()
    PsychopatzConversationPart.prerender(self)
    self:refreshOpacity()
end

function LLMInput:update()
    -- Full conversation views are driven by ISPanel.update(), while compact
    -- headless hosts refresh this part explicitly from their integration
    -- heartbeat. Keep the native controls synchronized with the session in
    -- both modes; otherwise the widget is initialized before the session is
    -- created and its SEND button can remain disabled forever.
    ISPanel.update(self)
    self:refreshControls()
end

function LLMInput:updateModeButtonStyles(event)
    for _, definition in ipairs(self.modeButtons or {}) do
        local desired = definition.mode == self.inputMode
            and "selected" or "quiet"
        local button = definition.button
        -- Reconcile the native button itself, not only the logical input
        -- mode. A control refresh or reconstruction can reset a button
        -- variant while inputMode remains unchanged; a mode-only cache would
        -- then leave one icon selected and the other icon quiet incorrectly.
        if button and button.psychopatzVariant ~= desired then
            UI.SetButtonVariant(button, desired)
        end
    end
    self.styledInputMode = self.inputMode
    if type(self.onVisualRefresh) == "function" then
        self.onVisualRefresh(self.owner, self, event or "mode_buttons")
    end
end

function LLMInput:updateToggleButton()
    local toggle = self.toggleButton
    local definition = toggle and toggle.definition
    if not toggle or not definition then return end
    local title = self.toggleValue
        and definition.alternateTitle or definition.title
    local titleKey = self.toggleValue
        and definition.alternateTitleKey or definition.titleKey
    toggle.button:setTitle(optionTitle(self, {
        id = definition.id or "toggle",
        title = title,
        titleKey = titleKey,
    }))
    UI.SetButtonVariant(
        toggle.button,
        self.toggleValue and "selected" or "quiet"
    )
end

function LLMInput:refreshTheme()
    local theme = UI.Theme
    if not theme or not theme.GetRevision then return false end
    local revision = theme.GetRevision()
    if self.psychopatzThemeRevision == revision then return false end
    if UI.RefreshTheme then UI.RefreshTheme(self) end
    self.psychopatzThemeRevision = revision
    return true
end

function LLMInput:render()
    ISPanel.render(self)
    local accent = self:getAccentColor()
    self:drawText(
        tostring(self.statusText or ""),
        11,
        math.max(
            (self.inputY or 30) + (self.inputHeight or 26) + 4,
            self.height - 20
        ),
        accent.r,
        accent.g,
        accent.b,
        self:getContentOpacity() * 0.9,
        UIFont.Small
    )
end

return Internal
