local LLMInput = PsychopatzConversationLLMInput
local Internal = LLMInput.Internal

local ConversationPart = PsychopatzConversationPart
local isShiftKeyDown = Internal.isShiftKeyDown

function LLMInput:insertNewline()
    if not self.entry or not self.entry.setText then return false end

    local value = self.entry.getInternalText
        and self.entry:getInternalText()
        or self.entry:getText()
    value = tostring(value or "")

    if self.maxInputLength and #value >= self.maxInputLength then
        return false
    end

    local lineCount = select(2, string.gsub(value, "\n", "")) + 1
    if self.maxInputLines and lineCount >= self.maxInputLines then
        return false
    end

    local cursor = #value
    if self.entry.getCursorPos then
        cursor = tonumber(self.entry:getCursorPos()) or cursor
    end
    cursor = math.max(0, math.min(cursor, #value))

    local nextValue = string.sub(value, 1, cursor)
        .. "\n" .. string.sub(value, cursor + 1)
    self.entry:setText(nextValue)
    if self.entry.setCursorPos then
        self.entry:setCursorPos(cursor + 1)
    end
    self:onTextChanged()
    return true
end

function LLMInput:onPartResize()
    if ConversationPart.onPartResize then
        ConversationPart.onPartResize(self)
    end
    if not self.entry or not self.sendButton then return end
    local modeCount = #self.modeButtons
    local controlCount = modeCount + (self.toggleButton and 1 or 0)
    local inputY = controlCount > 0 and 54 or 30
    local width = math.max(80, self.width - 104)
    self.inputY = inputY
    self.entry:setX(10)
    self.entry:setY(inputY)
    self.entry:setWidth(width)
    self.entry:setHeight(self.inputHeight or 26)
    self.sendButton:setX(math.max(10, self.width - 86))
    self.sendButton:setY(inputY)
    self.sendButton:setWidth(76)
    self.sendButton:setHeight(26)
    local modeWidth
    local modeX = 10
    local modeGap = 4
    if controlCount > 0 then
        modeWidth = math.max(
            40,
            math.floor((self.width - 20 - modeGap * (controlCount - 1))
                / controlCount)
        )
        for _, definition in ipairs(self.modeButtons) do
            definition.button:setX(modeX)
            definition.button:setY(29)
            definition.button:setWidth(modeWidth)
            definition.button:setHeight(20)
            modeX = modeX + modeWidth + modeGap
        end
        if self.toggleButton then
            self.toggleButton.button:setX(modeX)
            self.toggleButton.button:setY(29)
            self.toggleButton.button:setWidth(modeWidth)
            self.toggleButton.button:setHeight(20)
        end
    end
    if self.closeButton then
        self.closeButton:setX(math.max(10, self.width - 29))
        self.closeButton:setY(3)
        self.closeButton:setWidth(20)
        self.closeButton:setHeight(18)
    end
    if not self.resizingForText then self:resizeForText() end
end

local function wrappedLines(value, charsPerLine)
    local lines = 0
    local line
    value = tostring(value or "")
    charsPerLine = math.max(1, tonumber(charsPerLine) or 1)
    for line in string.gmatch(value .. "\n", "([^\n]*)\n") do
        lines = lines + math.max(1, math.ceil(#line / charsPerLine))
    end
    return math.max(1, lines)
end

function LLMInput:resizeForText()
    if not self.entry or not self.multiline then return end
    local width = math.max(80, self.entry:getWidth() - 16)
    local charsPerLine = math.floor(width / 8)
    local lines = wrappedLines(self.entry:getText(), charsPerLine)
    lines = math.min(self.maxInputLines or lines, lines)
    local lineHeight = self.lineHeight or 16
    local desired = 26 + math.max(0, lines - 1) * lineHeight
    desired = math.min(self.maxInputHeight or desired, desired)
    if desired == self.inputHeight then return end
    self.inputHeight = desired
    local desiredPanelHeight = (self.inputY or 30) + desired + 24
    self.resizingForText = true
    self:setHeight(math.max(self.minimumHeight or 82, desiredPanelHeight))
    self:onPartResize()
    self.resizingForText = false
end

function LLMInput:onTextChanged()
    self:resizeForText()
end

return Internal
