local Hub = PsychopatzCore.DebugHub
local Renderer = require "PsychopatzCore/UI/PsychopatzDebugHubWindow_Renderer"

local Cards = {}

function Cards.Rebuild(window)
    if not window.toolList then return end
    local selected = window.toolList:getItem()
    local selectedId = window.selectedToolId or (selected and selected.item
        and selected.item.kind ~= "group" and selected.item.id or nil)
    window.definitions = Hub.GetTools()
    window.groups = Hub.GetToolGroups()
    window.toolList:clear()
    local restoredSelection = false
    for _, group in ipairs(window.groups) do
        window.toolList:addItem(group.source, {
            kind = "group",
            source = group.source,
            count = #group.tools,
            expanded = group.expanded,
        })
        if group.expanded then
            for _, definition in ipairs(group.tools) do
                local item = {
                    kind = "tool",
                    id = definition.id,
                    title = definition.title,
                    description = definition.description,
                    available = Renderer.IsAvailable(definition),
                }
                window.toolList:addItem(definition.title, item)
                if selectedId == definition.id then
                    window.toolList.selected = #window.toolList.items
                    restoredSelection = true
                end
            end
        end
    end
    window.selectedToolId = restoredSelection and selectedId or nil
    Cards.RefreshAvailability(window)
end

function Cards.RefreshAvailability(window)
    for _, entry in ipairs(window.toolList and window.toolList.items or {}) do
        if entry.item and entry.item.kind ~= "group" then
            local definition = Hub.tools[entry.item.id]
            entry.item.available = definition and Renderer.IsAvailable(definition) or false
        end
    end
    local selected = window.toolList and window.toolList:getItem() or nil
    window.launchButton:setEnable(selected and selected.item
        and selected.item.kind ~= "group"
        and selected.item.available or false)
end

return Cards
