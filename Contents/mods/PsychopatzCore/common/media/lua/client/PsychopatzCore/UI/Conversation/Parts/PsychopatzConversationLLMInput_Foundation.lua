local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text
local UI = PsychopatzCore.UI
local Opacity = Conversation.Opacity
local Foundation = {}

local function applyControlOpacity(control, contentAlpha)
    if not control then return end
    local fields = {
        "backgroundColor",
        "backgroundColorMouseOver",
        "backgroundColorEnabled",
        "borderColor",
        "borderColorEnabled",
        "textColor",
        "textColor2",
        "textColorEnabled",
        "textureColor",
    }
    for _, field in ipairs(fields) do
        local color = control[field]
        if color then
            control.conversationOpacityColors =
                control.conversationOpacityColors or {}
            local state = control.conversationOpacityColors[field]
            if not state or state.color ~= color then
                state = { color = color, alpha = tonumber(color.a) or 1 }
                control.conversationOpacityColors[field] = state
            end
            color.a = state.alpha * contentAlpha
        end
    end
end

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

local function notifyNativeControlState(component, event, button)
    if type(component.onNativeControlState) == "function" then
        component.onNativeControlState(
            component.owner,
            component,
            event,
            button
        )
    end
end

-- GameKeyboard.isKeyDown() intentionally reports false while a text entry is
-- focused. The raw Keyboard API remains available for Shift+Enter handling.
local function isShiftKeyDown()
    if not Keyboard or type(Keyboard.isKeyDown) ~= "function" then
        return false
    end
    return Keyboard.isKeyDown(Keyboard.KEY_LSHIFT)
        or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)
end

Foundation.resolved = resolved
Foundation.optionTitle = optionTitle
Foundation.isShiftKeyDown = isShiftKeyDown
Foundation.UI = UI
Foundation.Opacity = Opacity
Foundation.applyControlOpacity = applyControlOpacity
Foundation.notifyNativeControlState = notifyNativeControlState

return Foundation
