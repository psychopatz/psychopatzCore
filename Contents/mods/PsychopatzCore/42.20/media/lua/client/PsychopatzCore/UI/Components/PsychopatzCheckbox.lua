require "ISUI/ISTickBox"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI

function UI.CreateCheckbox(parent, definition)
    definition = definition or {}
    local callback
    if definition.onChange then
        callback = function(target, control, value)
            return definition.onChange(target, value == true, control)
        end
    end

    local checkbox = ISTickBox:new(
        tonumber(definition.x) or 0,
        tonumber(definition.y) or 0,
        tonumber(definition.width) or 230,
        tonumber(definition.height) or 20,
        "",
        definition.target or parent,
        callback
    )
    checkbox.internal = definition.id
    checkbox:initialise()
    checkbox:instantiate()
    checkbox:addOption(tostring(definition.label or definition.title or ""))
    checkbox:setSelected(1, definition.value == true)
    if definition.font and checkbox.setFont then
        checkbox:setFont(definition.font)
    end

    function checkbox:getChecked()
        return self:isSelected(1) == true
    end

    function checkbox:setChecked(value)
        self:setSelected(1, value == true)
        return self:getChecked()
    end

    if parent then parent:addChild(checkbox) end
    return checkbox
end

return UI
