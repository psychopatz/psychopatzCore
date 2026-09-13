local Host = {}
local EMPTY_ADAPTER = {}

local function contextMenuVisible()
    local menu = ISContextMenu and ISContextMenu.instance or nil
    if not menu then return false end
    if menu.visibleCheck == true or menu.visible == true then return true end
    if menu.getIsVisible and menu:getIsVisible() then return true end
    return false
end

local function visible(window)
    if not window then return false end
    if window.isReallyVisible then return window:isReallyVisible() end
    if window.getIsVisible then return window:getIsVisible() end
    return true
end

local function listVisible(list)
    if not list then return false end
    if list.getIsVisible and not list:getIsVisible() then return false end
    if list.isMouseOver then return list:isMouseOver() end
    return true
end

local function adapterFor(window)
    return window and window.psychopatzInventoryTooltipAdapter or EMPTY_ADAPTER
end

local function candidateLists(window)
    local adapter = adapterFor(window)
    local lists
    if type(adapter.lists) == "function" then
        local ok
        ok, lists = pcall(adapter.lists, window)
        if ok and type(lists) == "table" then return lists end
    elseif type(adapter.lists) == "table" then
        return adapter.lists
    end
    return {}
end

local function currentList(window)
    local list = window and window.psychopatzInventoryTooltipList or nil
    local lists
    if list and listVisible(list) then return list end
    lists = candidateLists(window)
    for index = 1, #lists do
        local candidate = lists[index]
        if listVisible(candidate) then return candidate end
    end
    return nil
end

local function hoveredIndex(window, list)
    local adapter = adapterFor(window)
    local value
    if type(adapter.hoveredIndex) == "function" then
        local ok
        ok, value = pcall(adapter.hoveredIndex, list, window)
        if ok then return value end
    end
    if list and type(list.hoveredRowIndex) == "function" then
        return list:hoveredRowIndex()
    end
    if list and list.mouseoverselected ~= nil then
        return list.mouseoverselected
    end
    return nil
end

local function rowAt(window, list, index)
    local adapter = adapterFor(window)
    local row
    if type(adapter.rowAt) == "function" then
        local ok
        ok, row = pcall(adapter.rowAt, list, index, window)
        if ok then return row end
    end
    return list and list.items and list.items[index]
        and list.items[index].item or nil
end

local function playerFor(window, list)
    local adapter = adapterFor(window)
    local player
    if type(adapter.playerFor) == "function" then
        local ok
        ok, player = pcall(adapter.playerFor, list, window)
        if ok then return player end
    end
    return nil
end

local function suppressed(window, list)
    local adapter = adapterFor(window)
    if type(adapter.isSuppressed) == "function" then
        local ok, value = pcall(adapter.isSuppressed, window, list)
        if ok and value == true then return true end
    end
    return false
end

function Host.Install(window, options)
    if not window then return nil end
    options = type(options) == "table" and options or {}
    window.psychopatzInventoryTooltipAdapter = options.adapter
        or window.psychopatzInventoryTooltipAdapter or {}
    if window.psychopatzInventoryTooltip then
        return window.psychopatzInventoryTooltip
    end
    local Tooltip = require
        "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltip"
    local tooltip = Tooltip:new(0, 0, 240, 40, window,
        options.modelOptions)
    tooltip:initialise()
    tooltip:instantiate()
    tooltip:setVisible(false)
    if tooltip.setAlwaysOnTop then tooltip:setAlwaysOnTop(true) end
    window.psychopatzInventoryTooltip = tooltip
    window.psychopatzInventoryTooltipList = nil
    return tooltip
end

function Host.OnHover(window, list)
    if not window then return false end
    window.psychopatzInventoryTooltipList = list
    return Host.Update(window)
end

function Host.Update(window)
    local tooltip = window and window.psychopatzInventoryTooltip or nil
    local list
    local index
    local row
    if not tooltip or not visible(window) then
        if tooltip then tooltip:hide() end
        return false
    end
    list = currentList(window)
    if contextMenuVisible() or suppressed(window, list) then
        tooltip:hide()
        return false
    end
    if not list then
        tooltip:hide()
        return false
    end
    index = hoveredIndex(window, list)
    row = rowAt(window, list, index)
    if not index or not row or row.groupHeader == true
        or row.restricted == true or not row.fullType
    then
        tooltip:hide()
        return false
    end
    return tooltip:show(row, playerFor(window, list), list, index)
end

function Host.Hide(window)
    local tooltip = window and window.psychopatzInventoryTooltip or nil
    if tooltip then tooltip:hide() end
    if window then
        window.psychopatzInventoryTooltipList = nil
    end
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}
PsychopatzCore.UI.InventoryTooltipHost = Host

return Host
