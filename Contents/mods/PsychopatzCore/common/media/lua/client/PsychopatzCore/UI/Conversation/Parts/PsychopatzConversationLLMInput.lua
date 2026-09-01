-- Reusable conversation text input for integrations backed by an external
-- language model. The owner supplies submission and state callbacks so the
-- component can be used by a full conversation view or a compact host.
require "ISUI/ISButton"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"

PsychopatzConversationLLMInput = PsychopatzConversationPart:derive(
    "PsychopatzConversationLLMInput"
)

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text
local UI = PsychopatzCore.UI

local function resolved(callback, key, fallback)
    if type(callback) == "function" then
        return callback(key, fallback)
    end
    return Text.Resolve({ key = key, fallback = fallback }, fallback)
end

local function optionTitle(component, definition)
    local title = definition and definition.title
    if type(title) == "table" then
        return resolved(
            component.resolveText,
            title.key,
            title.fallback or definition.id or ""
        )
    end
    if title ~= nil then return tostring(title) end
    local key = definition and (definition.titleKey or definition.key)
    return key and resolved(
        component.resolveText,
        key,
        definition.id or ""
    ) or ""
end

-- GameKeyboard.isKeyDown() intentionally reports false while a text entry is
-- focused.  The raw Keyboard API is still available here, which lets the
-- text-entry command callback distinguish Enter from Shift+Enter.
local function isShiftKeyDown()
    if not Keyboard or type(Keyboard.isKeyDown) ~= "function" then
        return false
    end
    return Keyboard.isKeyDown(Keyboard.KEY_LSHIFT)
        or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)
end

function PsychopatzConversationLLMInput:insertNewline()
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

function PsychopatzConversationLLMInput:createChildren()
    local options = self.options or {}
    local definitions = options.modeButtons or {}
    local modeIndex
    local modeDefinition
    for modeIndex = 1, #definitions do
        modeDefinition = definitions[modeIndex]
        local modeID = modeDefinition
            and (modeDefinition.mode or modeDefinition.id)
        if modeID then
            local button = UI.CreateButton(self, {
                id = modeDefinition.id or modeID,
                title = optionTitle(self, modeDefinition),
                target = self,
                onclick = function()
                    self:onModePressed(modeID)
                end,
                variant = "quiet",
                width = modeDefinition.width,
            })
            self.modeButtons[#self.modeButtons + 1] = {
                button = button,
                mode = modeID,
            }
        end
    end
    if type(options.toggleButton) == "table" then
        local toggleDefinition = options.toggleButton
        local toggleID = toggleDefinition.id or "toggle"
        local button = UI.CreateButton(self, {
            id = toggleID,
            title = optionTitle(self, {
                id = toggleID,
                title = self.toggleValue
                    and toggleDefinition.alternateTitle
                    or toggleDefinition.title,
                titleKey = self.toggleValue
                    and toggleDefinition.alternateTitleKey
                    or toggleDefinition.titleKey,
            }),
            target = self,
            onclick = function()
                self:onTogglePressed()
            end,
            variant = "quiet",
            width = toggleDefinition.width,
        })
        self.toggleButton = {
            button = button,
            definition = toggleDefinition,
        }
    end
    self.entry = UI.CreateTextEntry(self, {
        x = 10,
        y = 30,
        width = math.max(80, self.width - 104),
        height = 26,
        maxTextLength = self.maxInputLength,
        tooltip = resolved(
            self.resolveText,
            options.tooltipKey or "UI_PsychopatzConversation_LLMInputTooltip",
            options.tooltip or "Type a message for this NPC."
        ),
    })
    if self.entry.setMultipleLine then
        -- UITextBox2 consumes Enter itself when this flag is true, so Lua
        -- never receives onCommandEntered.  Keep the native box in command
        -- mode and emulate only the Shift+Enter newline action.
        self.entry:setMultipleLine(self.multiline and not self.submitOnEnter)
    end
    if self.maxInputLines and self.entry.setMaxLines then
        self.entry:setMaxLines(self.maxInputLines)
    end
    self.entry.onCommandEntered = function()
        if self.submitOnEnter and isShiftKeyDown() then
            self:insertNewline()
            return
        end
        self:onSubmit()
    end
    self.entry.onTextChange = function()
        self:onTextChanged()
    end
    self.sendButton = UI.CreateButton(self, {
        id = "send",
        title = resolved(
            self.resolveText,
            options.sendKey or "UI_PsychopatzConversation_Send",
            options.sendTitle or "SEND"
        ),
        target = self,
        onclick = PsychopatzConversationLLMInput.onSubmit,
        variant = "primary",
        width = 76,
    })
    if self.onClose then
        self.closeButton = UI.CreateButton(self, {
            id = "close",
            title = options.closeTitle or "X",
            target = self,
            onclick = PsychopatzConversationLLMInput.onClosePressed,
            variant = "quiet",
            width = 20,
        })
    end
    self:onPartResize()
    self:updateModeButtonStyles()
    self:updateToggleButton()
end

function PsychopatzConversationLLMInput:onPartResize()
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

function PsychopatzConversationLLMInput:updateModeButtonStyles()
    for _, definition in ipairs(self.modeButtons or {}) do
        UI.SetButtonVariant(
            definition.button,
            definition.mode == self.inputMode and "selected" or "quiet"
        )
    end
end

function PsychopatzConversationLLMInput:updateToggleButton()
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

function PsychopatzConversationLLMInput:setMode(mode, notify)
    mode = mode or self.inputMode
    for _, definition in ipairs(self.modeButtons or {}) do
        if definition.mode == mode then
            local previous = self.inputMode
            self.inputMode = mode
            self:updateModeButtonStyles()
            if notify and type(self.onModeChanged) == "function" then
                local accepted = self.onModeChanged(
                    self.owner,
                    mode,
                    self
                )
                if accepted == false then
                    self.inputMode = previous
                    self:updateModeButtonStyles()
                    return false
                end
            end
            return true
        end
    end
    return false
end

function PsychopatzConversationLLMInput:onModePressed(mode)
    return self:setMode(mode, true)
end

function PsychopatzConversationLLMInput:setToggle(value, notify)
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

function PsychopatzConversationLLMInput:onTogglePressed()
    return self:setToggle(not self.toggleValue, true)
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

function PsychopatzConversationLLMInput:resizeForText()
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

function PsychopatzConversationLLMInput:onTextChanged()
    self:resizeForText()
end

function PsychopatzConversationLLMInput:onSubmit()
    local value = self.entry and self.entry:getText() or ""
    local accepted = type(self.submit) == "function"
        and self.submit(self.owner, value, self) == true
    if accepted and self.entry then self.entry:setText("") end
    self:refreshControls()
    return accepted
end

function PsychopatzConversationLLMInput:onClosePressed()
    if type(self.onClose) == "function" then self.onClose(self.owner, self) end
end

function PsychopatzConversationLLMInput:refreshControls()
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
                or "UI_PsychopatzConversation_Send",
            state.sendTitle or self.options.sendTitle or "SEND"
        ))
        self.sendButton:setEnable(enabled)
    end
    if self.closeButton then self.closeButton:setEnable(true) end
    self.statusText = state.statusText or ""
    self:updateModeButtonStyles()
    self:updateToggleButton()
    for _, definition in ipairs(self.modeButtons or {}) do
        definition.button:setEnable(enabled)
    end
    if self.toggleButton then
        self.toggleButton.button:setEnable(enabled)
    end
end

function PsychopatzConversationLLMInput:focusInput()
    if self.entry and self.entry.focus then self.entry:focus() end
end

function PsychopatzConversationLLMInput:render()
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

function PsychopatzConversationLLMInput:new(x, y, width, height, options)
    options = options or {}
    options.partID = options.partID or "llmInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.title = options.title or {
        key = "UI_PsychopatzConversation_LLMInput",
        fallback = "TYPE TO TALK",
    }
    local object = PsychopatzConversationPart.new(
        self, x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    object.options = options
    object.submit = options.submit
    object.getStateCallback = options.getState
    object.resolveText = options.resolveText
    object.maxInputLength = tonumber(options.maxInputLength) or 4000
    object.modeButtons = {}
    object.inputMode = options.initialMode
    if not object.inputMode and options.modeButtons then
        local first = options.modeButtons[1]
        object.inputMode = first and (first.mode or first.id) or nil
    end
    object.onModeChanged = options.onModeChanged
    object.toggleButton = nil
    object.toggleValue = options.initialToggleValue == true
    object.onToggleChanged = options.onToggleChanged
    object.multiline = options.multiline ~= false
    object.submitOnEnter = options.submitOnEnter ~= false
    object.maxInputLines = math.max(
        1,
        tonumber(options.maxInputLines) or 6
    )
    object.maxInputHeight = math.max(
        26,
        tonumber(options.maxInputHeight) or 122
    )
    object.inputHeight = 26
    object.lineHeight = math.max(12, tonumber(options.lineHeight) or 16)
    object.onClose = options.onClose
    object.statusText = options.initialStatus or ""
    return object
end

return PsychopatzConversationLLMInput
