local LLMInput = PsychopatzConversationLLMInput

function LLMInput:createChildren()
    LLMInput.Internal.createChildren(self)
end

function LLMInput:new(x, y, width, height, options)
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
    object.styledInputMode = nil
    object.psychopatzThemeRevision = nil
    object.lastConversationOpacitySignature = nil
    object.lastConversationOpacityReveal = nil
    if not object.inputMode and options.modeButtons then
        local first = options.modeButtons[1]
        object.inputMode = first and (first.mode or first.id) or nil
    end
    object.onModeChanged = options.onModeChanged
    object.onModeCommitted = options.onModeCommitted
    object.onVisualRefresh = options.onVisualRefresh
    object.onNativeControlState = options.onNativeControlState
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

return LLMInput
