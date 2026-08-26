require "ISUI/ISTextEntryBox"

local UI = PsychopatzCore.UI

function UI.CreateTextEntry(parent, definition)
    definition = definition or {}
    local text = definition.text
    if text == nil then text = definition.value end
    if text == nil then text = "" end

    local entry = ISTextEntryBox:new(
        tostring(text),
        tonumber(definition.x) or 0,
        tonumber(definition.y) or 0,
        tonumber(definition.width) or 1,
        tonumber(definition.height) or 1
    )
    entry:initialise()
    entry:instantiate()
    if definition.clearButton and entry.setClearButton then
        entry:setClearButton(true)
    end
    if definition.onlyNumbers and entry.setOnlyNumbers then
        entry:setOnlyNumbers(true)
    end
    if definition.maxTextLength and entry.setMaxTextLength then
        entry:setMaxTextLength(tonumber(definition.maxTextLength))
    end
    if definition.onTextChange then
        entry.onTextChange = definition.onTextChange
    end
    if definition.tooltip ~= nil then
        entry.tooltip = definition.tooltip
    end
    if definition.preferredWidth ~= nil then
        entry.psychopatzPreferredWidth = definition.preferredWidth
    end
    if parent then parent:addChild(entry) end
    return entry
end

return UI
