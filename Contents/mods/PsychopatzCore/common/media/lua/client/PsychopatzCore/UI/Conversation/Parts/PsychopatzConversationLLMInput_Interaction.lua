local LLMInput = PsychopatzConversationLLMInput
local Internal = LLMInput.Internal

local UI = Internal.UI
local resolved = Internal.resolved
local optionTitle = Internal.optionTitle
local notifyNativeControlState = Internal.notifyNativeControlState

function LLMInput:setMode(mode, notify)
    mode = mode or self.inputMode
    for _, definition in ipairs(self.modeButtons or {}) do
        if definition.mode == mode then
            local previous = self.inputMode
            if notify and type(self.onModeChanged) == "function" then
                local accepted = self.onModeChanged(
                    self.owner,
                    mode,
                    self
                )
                if accepted == false then
                    self.inputMode = previous
                    self:updateModeButtonStyles("mode_rejected")
                    return false
                end
            end
            -- Integrations can reject a mode while rebuilding their
            -- recipients. Commit the visual selection only after that
            -- transaction succeeds, so a rejected click never flashes a
            -- mode that was not actually selected.
            self.inputMode = mode
            self:updateModeButtonStyles("mode_committed")
            if type(self.onModeCommitted) == "function" then
                self.onModeCommitted(self.owner, mode, self)
            end
            return true
        end
    end
    return false
end

function LLMInput:onModePressed(mode)
    return self:setMode(mode, true)
end

function LLMInput:setToggle(value, notify)
    if not self.toggleButton then return false end
    local previous = self.toggleValue
    self.toggleValue = value == true
    self:updateToggleButton()
    if notify and type(self.onToggleChanged) == "function" then
        local accepted = self.onToggleChanged(
            self.owner,
            self.toggleValue,
            self
        )
        if accepted == false then
            self.toggleValue = previous
            self:updateToggleButton()
            return false
        end
    end
    return true
end

function LLMInput:onTogglePressed()
    return self:setToggle(not self.toggleValue, true)
end

function LLMInput:onSubmit()
    local value = self.entry and self.entry:getText() or ""
    local accepted = type(self.submit) == "function"
        and self.submit(self.owner, value, self) == true
    if accepted and self.entry then self.entry:setText("") end
    self:refreshControls()
    return accepted
end

function LLMInput:onClosePressed()
    if type(self.onClose) == "function" then
        self.onClose(self.owner, self)
    end
end

function LLMInput:onPrevTargetPressed()
    if type(self.onPrevTarget) == "function" then
        self.onPrevTarget(self.owner, self)
    end
end

function LLMInput:onNextTargetPressed()
    if type(self.onNextTarget) == "function" then
        self.onNextTarget(self.owner, self)
    end
end

function LLMInput:onQuickReplyPressed(choiceID)
    if self.owner
        and type(self.owner.isConversationInteractive) == "function"
        and not self.owner:isConversationInteractive()
    then
        return false
    end
    if type(self.onQuickReply) == "function" and choiceID and choiceID ~= "" then
        self.onQuickReply(self.owner, choiceID, self)
        self:refreshControls()
    end
end

function LLMInput:syncQuickReplies(rows, enabled)
    rows = type(rows) == "table" and rows or {}
    self.quickReplyButtons = self.quickReplyButtons or {}
    local previousCount = self._visibleQuickReplyCount or 0
    local count = #rows
    for i = 1, count do
        local row = rows[i]
        local id = tostring(row.id or "")
        local title = tostring(row.label or row.text or id)
        local isFarewell = row.semanticRole == "farewell"
            or row.isFarewell == true
            or row.variant == "danger"
            or id == "goodbye"
        local button = self.quickReplyButtons[i]
        if not button then
            button = UI.CreateButton(self, {
                id = "quickReply_" .. tostring(i),
                title = title,
                target = self,
                onclick = function()
                    self:onQuickReplyPressed(button._quickReplyID)
                end,
                variant = isFarewell and "danger" or "quiet",
                width = math.max(80, (self.width or 280) - 20),
            })
            self.quickReplyButtons[i] = button
        end
        button._quickReplyID = id
        if button.setTitle then button:setTitle(title) else button.title = title end
        local tip = type(row.tooltip) == "string" and row.tooltip ~= "" and row.tooltip or nil
        if button.setTooltip then
            button:setTooltip(tip)
        else
            button.tooltip = tip
        end
        if isFarewell then
            button.backgroundColor = { r = 0.24, g = 0.05, b = 0.05, a = 0.90 }
            button.backgroundColorMouseOver = { r = 0.45, g = 0.09, b = 0.09, a = 0.96 }
            button.borderColor = { r = 0.88, g = 0.24, b = 0.24, a = 0.88 }
        end
        button:setVisible(true)
        if button.setEnable then
            button:setEnable(enabled and row.enabled ~= false)
        end
    end
    for i = count + 1, #self.quickReplyButtons do
        local button = self.quickReplyButtons[i]
        if button then
            button._quickReplyID = nil
            button:setVisible(false)
        end
    end
    self._visibleQuickReplyCount = count
    self.quickReplies = rows
    return previousCount ~= count
end

function LLMInput:refreshControls()
    -- Compact inputs are standalone UI roots, so they do not receive
    -- the normal PsychopatzWindow theme traversal. Reconcile a changed theme
    -- before native ISButton:setEnable() can restore its enabled-color cache.
    local themeChanged = self:refreshTheme()
    if themeChanged then self.lastConversationOpacitySignature = nil end
    local state = type(self.getStateCallback) == "function"
        and self.getStateCallback(self.owner, self) or {}
    local enabled = state.enabled == true
    self:setVisible(state.visible ~= false)
    if self.entry and self.entry.setEditable then
        self.entry:setEditable(enabled)
    end
    if self.sendButton then
        self.sendButton:setTitle(resolved(
            self.resolveText,
            state.sendKey or self.options.sendKey
                or "UI_PsychopatzConversation_LLM_Send",
            state.sendTitle or self.options.sendTitle or "SEND"
        ))
        notifyNativeControlState(self, "before_send_setEnable", self.sendButton)
        self.sendButton:setEnable(enabled)
        notifyNativeControlState(self, "after_send_setEnable", self.sendButton)
    end
    if self.closeButton then
        notifyNativeControlState(self, "before_close_setEnable", self.closeButton)
        self.closeButton:setEnable(true)
        notifyNativeControlState(self, "after_close_setEnable", self.closeButton)
    end
    local showSwitch = state.hasMultipleTargets == true
    local switchChanged = (self._showTargetSwitch ~= showSwitch)
    self._showTargetSwitch = showSwitch
    if self.prevTargetButton then
        self.prevTargetButton:setVisible(showSwitch)
        self.prevTargetButton:setEnable(enabled and showSwitch)
    end
    if self.nextTargetButton then
        self.nextTargetButton:setVisible(showSwitch)
        self.nextTargetButton:setEnable(enabled and showSwitch)
    end
    local repliesChanged = self:syncQuickReplies(state.quickReplies, enabled)
    if (switchChanged or repliesChanged) and type(self.onPartResize) == "function" then
        self:onPartResize()
    end
    self.statusText = state.statusText or ""
    for _, definition in ipairs(self.modeButtons or {}) do
        notifyNativeControlState(
            self,
            "before_mode_setEnable_" .. tostring(definition.mode),
            definition.button
        )
        definition.button:setEnable(enabled)
        notifyNativeControlState(
            self,
            "after_mode_setEnable_" .. tostring(definition.mode),
            definition.button
        )
    end
    if self.toggleButton then
        notifyNativeControlState(
            self,
            "before_toggle_setEnable",
            self.toggleButton.button
        )
        self.toggleButton.button:setEnable(enabled)
        notifyNativeControlState(
            self,
            "after_toggle_setEnable",
            self.toggleButton.button
        )
    end
    -- ISButton:setEnable() restores its cached native colors. Apply the
    -- logical selection styles after that restore, otherwise a refresh can
    -- leave the old mode painted blue while inputMode has already changed.
    self:updateModeButtonStyles("controls_refresh")
    self:updateToggleButton()
    self:refreshOpacity()
end

function LLMInput:focusInput(ignoreFirst)
    if not self.entry then return end
    if self.entry.setEditable then self.entry:setEditable(true) end
    if self.entry.focus then self.entry:focus() end
    if ignoreFirst == true and self.entry.ignoreFirstInput then
        self.entry:ignoreFirstInput()
    end
end

function LLMInput:blurInput()
    if self.entry and self.entry.unfocus then
        self.entry:unfocus()
        return true
    end
    return false
end

return Internal
