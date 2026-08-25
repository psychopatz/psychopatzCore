require "PsychopatzCore/UI/Components/PsychopatzUIControls"

local UI = PsychopatzCore.UI

local function apply(button)
    local state = button.psychopatzToggleState == true
    local title = state and button.psychopatzToggleOnTitle
        or button.psychopatzToggleOffTitle
    local variant = state and button.psychopatzToggleOnVariant
        or button.psychopatzToggleOffVariant
    if button.setTitle then button:setTitle(tostring(title or "")) end
    UI.SetButtonVariant(button, variant)
    return state
end

local function setToggleState(button, value)
    button.psychopatzToggleState = value == true
    apply(button)
    return button.psychopatzToggleState
end

local function getToggleState(button)
    return button.psychopatzToggleState == true
end

local function toggle(button)
    return setToggleState(button, not getToggleState(button))
end

local function setToggleLabels(button, offTitle, onTitle)
    button.psychopatzToggleOffTitle = tostring(offTitle or "")
    button.psychopatzToggleOnTitle = tostring(onTitle or "")
    apply(button)
    return button
end

function UI.CreateToggleButton(parent, definition)
    definition = definition or {}
    local callback = definition.onclick
    local changeCallback = definition.onChange
    local function onClick(target, button, ...)
        local value = button and button.getToggleState
            and button:getToggleState() or nil
        if definition.autoToggle == true and button
            and button.toggle then
            value = button:toggle()
        end
        if changeCallback then
            return changeCallback(target, button, value, ...)
        end
        if callback then
            return callback(target, button, value, ...)
        end
        return value
    end
    local button = UI.CreateButton(parent, {
        id = definition.id,
        title = definition.offTitle or definition.title,
        target = definition.target or parent,
        onclick = onClick,
        width = definition.width,
        font = definition.font,
        variant = definition.offVariant or definition.variant,
    })
    button.psychopatzToggleOffTitle = tostring(
        definition.offTitle or definition.title or "")
    button.psychopatzToggleOnTitle = tostring(
        definition.onTitle or definition.title or "")
    button.psychopatzToggleOffVariant = definition.offVariant
        or definition.variant or "quiet"
    button.psychopatzToggleOnVariant = definition.onVariant or "selected"
    button.setToggleState = setToggleState
    button.getToggleState = getToggleState
    button.toggle = toggle
    button.setToggleLabels = setToggleLabels
    setToggleState(button, definition.value == true)
    return button
end

return UI
