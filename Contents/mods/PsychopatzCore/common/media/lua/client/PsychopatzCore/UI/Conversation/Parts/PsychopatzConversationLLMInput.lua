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

function PsychopatzConversationLLMInput:createChildren()
    local options = self.options or {}
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
    self.entry.onCommandEntered = function()
        self:onSubmit()
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
end

function PsychopatzConversationLLMInput:onPartResize()
    if not self.entry or not self.sendButton then return end
    local width = math.max(80, self.width - 104)
    self.entry:setX(10)
    self.entry:setY(30)
    self.entry:setWidth(width)
    self.entry:setHeight(26)
    self.sendButton:setX(math.max(10, self.width - 86))
    self.sendButton:setY(30)
    self.sendButton:setWidth(76)
    self.sendButton:setHeight(26)
    if self.closeButton then
        self.closeButton:setX(math.max(10, self.width - 29))
        self.closeButton:setY(3)
        self.closeButton:setWidth(20)
        self.closeButton:setHeight(18)
    end
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
        math.max(57, self.height - 20),
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
    object.onClose = options.onClose
    object.statusText = options.initialStatus or ""
    return object
end

return PsychopatzConversationLLMInput
