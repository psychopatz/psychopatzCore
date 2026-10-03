local View = PsychopatzConversationView
local Internal = View.Internal
local Conversation = Internal.Conversation
local OpacityControl = Internal.OpacityControl
local buttonLabel = Internal.buttonLabel

local function initialiseButton(view, button)
    button:initialise()
    button:instantiate()
    button:setAnchorLeft(false)
    button:setAnchorRight(true)
end

function Internal.buildControls(view, accent)
    view.closeButton = ISButton:new(
        view.width - 42, 10, 32, 28,
        buttonLabel("UI_PsychopatzConversation_Close", "X"),
        view,
        View.onCloseButton
    )
    initialiseButton(view, view.closeButton)
    view.closeButton.backgroundColor = {
        r = 0.14, g = 0.05, b = 0.04, a = 0.88,
    }
    view.closeButton.backgroundColorMouseOver = {
        r = 0.42, g = 0.08, b = 0.05, a = 0.95,
    }
    view.closeButton.borderColor = {
        r = 0.92, g = 0.38, b = 0.26, a = 0.8,
    }
    view:addChild(view.closeButton)

    view.layoutButton = ISButton:new(
        view.width - 170, 10, 120, 28,
        buttonLabel("UI_PsychopatzConversation_EditLayout", "Edit layout"),
        view,
        View.toggleEditMode
    )
    initialiseButton(view, view.layoutButton)
    view.layoutButton.backgroundColor = {
        r = accent.r * 0.16,
        g = accent.g * 0.16,
        b = accent.b * 0.16,
        a = 0.88,
    }
    view.layoutButton.backgroundColorMouseOver = {
        r = accent.r * 0.34,
        g = accent.g * 0.34,
        b = accent.b * 0.34,
        a = 0.95,
    }
    view.layoutButton.borderColor = {
        r = accent.r,
        g = accent.g,
        b = accent.b,
        a = 0.78,
    }
    view.layoutButton:setVisible(
        view.editMode or Conversation.Settings.Get("showEditorButton", true) == true
    )
    view:addChild(view.layoutButton)

    view.resetLayoutButton = ISButton:new(
        view.width - 320, 10, 140, 28,
        buttonLabel(
            "UI_PsychopatzConversation_ResetLayout",
            "RESET TO DEFAULT"
        ),
        view,
        View.onResetLayoutButton
    )
    initialiseButton(view, view.resetLayoutButton)
    view.resetLayoutButton.backgroundColor = {
        r = 0.20, g = 0.10, b = 0.04, a = 0.88,
    }
    view.resetLayoutButton.backgroundColorMouseOver = {
        r = 0.42, g = 0.20, b = 0.06, a = 0.95,
    }
    view.resetLayoutButton.borderColor = {
        r = 0.95, g = 0.58, b = 0.22, a = 0.82,
    }
    view.resetLayoutButton:setVisible(view.editMode == true)
    view:addChild(view.resetLayoutButton)

    view.crtDebugButton = ISButton:new(
        view.width - 470, 10, 140, 28,
        buttonLabel(
            "UI_PsychopatzConversation_DebugCRT_Off",
            "CRT DEBUG: OFF"
        ),
        view,
        View.onCRTDebugButton
    )
    initialiseButton(view, view.crtDebugButton)
    view.crtDebugButton.backgroundColor = {
        r = 0.18, g = 0.08, b = 0.28, a = 0.88,
    }
    view.crtDebugButton.backgroundColorMouseOver = {
        r = 0.38, g = 0.16, b = 0.52, a = 0.95,
    }
    view.crtDebugButton.borderColor = {
        r = 0.78, g = 0.38, b = 0.92, a = 0.82,
    }
    view:addChild(view.crtDebugButton)
end

function Internal.attachOpacityControls(view)
    if not OpacityControl then return end
    local parts = {
        view.portraitPart,
        view.historyPart,
        view.choicesPart,
    }
    for _, part in pairs(view.extensionParts or {}) do
        parts[#parts + 1] = part
    end
    for _, part in ipairs(parts) do
        if part and part.attachOpacityControl then
            part:attachOpacityControl(view)
        end
    end
end

function Internal.refreshOpacityControls(view)
    local parts = {
        view.portraitPart,
        view.historyPart,
        view.choicesPart,
    }
    for _, part in pairs(view.extensionParts or {}) do
        parts[#parts + 1] = part
    end
    for _, part in ipairs(parts) do
        if part and part.positionOpacityControl then
            part:positionOpacityControl()
        end
        if part and part.refreshOpacityControlVisibility then
            part:refreshOpacityControlVisibility()
        end
        if part and part.opacityControl
            and part.opacityControl.parent == view
            and part.opacityControl.bringToTop
        then
            part.opacityControl:bringToTop()
        end
    end
end

return Internal
