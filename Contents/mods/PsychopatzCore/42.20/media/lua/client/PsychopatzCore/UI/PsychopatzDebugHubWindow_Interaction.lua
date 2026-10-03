local Hub = PsychopatzCore.DebugHub
local Renderer = require "PsychopatzCore/UI/PsychopatzDebugHubWindow_Renderer"
local Window = PsychopatzDebugHubWindow

function Window:onToolListMouseDown(list, x, y)
    local selectedBefore = list:getItem()
    local selectedToolId = selectedBefore and selectedBefore.item
        and selectedBefore.item.kind ~= "group"
        and selectedBefore.item.id or nil
    local result = ISScrollingListBox.onMouseDown(list, x, y)
    local row = list:getItem()
    local item = row and row.item or nil
    if item and item.kind == "group" then
        self.selectedToolId = selectedToolId
        Hub.SetGroupExpanded(item.source, not item.expanded)
    elseif item and item.kind ~= "group" then
        self.selectedToolId = item.id
    end
    return result
end

function Window:onToolListMouseDoubleClick(list, x, y)
    local result = ISScrollingListBox.onMouseDoubleClick(list, x, y)
    local row = list:getItem()
    local item = row and row.item or nil
    if item and item.kind ~= "group" then
        self.selectedToolId = item.id
        self:onLaunchSelected()
    end
    return result
end

function Window:onLauncherClick(id)
    local definition = Hub.tools[id]
    if not definition or not Renderer.IsAvailable(definition) then
        local player = getPlayer and getPlayer() or nil
        if player and definition then
            player:Say(Renderer.Format("UI_PsychopatzDebugHub_ToolUnavailable",
                "%s unavailable in this session.", { definition.title }))
        end
        return
    end

    local ok, err = pcall(definition.action)
    if not ok then
        local player = getPlayer and getPlayer() or nil
        if player then
            player:Say(Renderer.Format("UI_PsychopatzDebugHub_ToolFailed",
                "%s failed to open.", { definition.title }))
        end
        print("[PsychopatzCore.DebugHub] " .. tostring(err))
    end
end

function Window:onLaunchSelected()
    local selected = self.toolList and self.toolList:getItem() or nil
    if selected and selected.item and selected.item.kind ~= "group" then
        self:onLauncherClick(selected.item.id)
    end
end
