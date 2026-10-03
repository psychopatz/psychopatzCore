local LLMInput = PsychopatzConversationLLMInput
local Internal = LLMInput.Internal
local UI = PsychopatzCore.UI

local resolved = Internal.resolved
local optionTitle = Internal.optionTitle
local isShiftKeyDown = Internal.isShiftKeyDown

function Internal.createModeButtons(component, definitions)
    for index = 1, #definitions do
        local definition = definitions[index]
        local modeID = definition
            and (definition.mode or definition.id)
        if modeID then
            local modeTitle = optionTitle(component, definition)
            local button = UI.CreateButton(component, {
                id = definition.id or modeID,
                title = definition.image and "" or modeTitle,
                image = definition.image,
                target = component,
                onclick = function()
                    component:onModePressed(modeID)
                end,
                variant = "quiet",
                width = definition.width,
            })
            if definition.image then button.tooltip = modeTitle end
            component.modeButtons[#component.modeButtons + 1] = {
                button = button,
                mode = modeID,
            }
        end
    end
end

function Internal.createToggleButton(component, definition)
    if type(definition) ~= "table" then return end
    local toggleID = definition.id or "toggle"
    local button = UI.CreateButton(component, {
        id = toggleID,
        title = optionTitle(component, {
            id = toggleID,
            title = component.toggleValue
                and definition.alternateTitle or definition.title,
            titleKey = component.toggleValue
                and definition.alternateTitleKey or definition.titleKey,
        }),
        target = component,
        onclick = function()
            component:onTogglePressed()
        end,
        variant = "quiet",
        width = definition.width,
    })
    component.toggleButton = {
        button = button,
        definition = definition,
    }
end

function Internal.createTextEntry(component, options)
    component.entry = UI.CreateTextEntry(component, {
        x = 10,
        y = 30,
        width = math.max(80, component.width - 104),
        height = 26,
        maxTextLength = component.maxInputLength,
        tooltip = resolved(
            component.resolveText,
            options.tooltipKey or "UI_PsychopatzConversation_LLMInputTooltip",
            options.tooltip or "Type a message for this NPC."
        ),
    })
    if component.entry.setMultipleLine then
        -- UITextBox2 consumes Enter itself when this flag is true, so Lua
        -- never receives onCommandEntered. Keep the native box in command
        -- mode and emulate only the Shift+Enter newline action.
        component.entry:setMultipleLine(
            component.multiline and not component.submitOnEnter)
    end
    if component.maxInputLines and component.entry.setMaxLines then
        component.entry:setMaxLines(component.maxInputLines)
    end
    component.entry.onCommandEntered = function()
        if component.submitOnEnter and isShiftKeyDown() then
            component:insertNewline()
            return
        end
        component:onSubmit()
    end
    component.entry.onTextChange = function()
        component:onTextChanged()
    end
end

function Internal.createActionButtons(component, options)
    component.sendButton = UI.CreateButton(component, {
        id = "send",
        title = resolved(
            component.resolveText,
            options.sendKey or "UI_PsychopatzConversation_Send",
            options.sendTitle or "SEND"
        ),
        target = component,
        onclick = LLMInput.onSubmit,
        variant = "primary",
        width = 76,
    })
    if component.onClose then
        component.closeButton = UI.CreateButton(component, {
            id = "close",
            title = options.closeTitle or "X",
            target = component,
            onclick = LLMInput.onClosePressed,
            variant = "quiet",
            width = 20,
        })
    end
end

function Internal.createChildren(component)
    if PsychopatzConversationPart.createChildren then
        PsychopatzConversationPart.createChildren(component)
    end
    local options = component.options or {}
    Internal.createModeButtons(component, options.modeButtons or {})
    Internal.createToggleButton(component, options.toggleButton)
    Internal.createTextEntry(component, options)
    Internal.createActionButtons(component, options)
    component:onPartResize()
    component:updateModeButtonStyles()
    component:updateToggleButton()
    component:refreshOpacity()
end

return Internal
