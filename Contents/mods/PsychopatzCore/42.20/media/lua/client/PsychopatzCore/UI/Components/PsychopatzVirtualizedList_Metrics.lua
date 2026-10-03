local VirtualizedList = PsychopatzCore.UI.VirtualizedList
local Internal = VirtualizedList.Internal
local Layout = PsychopatzCore.UI.Layout

local function rowHeight(list, row)
    return row and row.height or list.itemheight
end

local function rebuildMetrics(list)
    if not list.psychopatzVirtualMetricsDirty
        and list.psychopatzRowOffsets then
        return
    end

    local offsets = {}
    local totalHeight = 0
    for index, row in ipairs(list.items or {}) do
        local height = rowHeight(list, row)
        row.height = height
        offsets[index] = totalHeight
        totalHeight = totalHeight + height
    end

    list.psychopatzRowOffsets = offsets
    list.psychopatzTotalHeight = totalHeight
    list.psychopatzVirtualMetricsDirty = false
    if list.setScrollHeight then list:setScrollHeight(totalHeight) end
end

local function markDirty(list)
    list.psychopatzVirtualMetricsDirty = true
end

local function rowAtOffset(list, y)
    rebuildMetrics(list)
    local offsets = list.psychopatzRowOffsets or {}
    local items = list.items or {}
    if y < 0 or #offsets == 0 then return -1 end

    local low, high = 1, #offsets
    while low <= high do
        local middle = math.floor((low + high) / 2)
        if offsets[middle] <= y then
            low = middle + 1
        else
            high = middle - 1
        end
    end

    local index = high
    local item = items[index]
    if item and y < offsets[index] + rowHeight(list, item) then
        return index
    end
    return -1
end

local function firstIntersectingRow(list, y)
    rebuildMetrics(list)
    local offsets = list.psychopatzRowOffsets or {}
    local items = list.items or {}
    if #offsets == 0 then return -1 end

    local low, high = 1, #offsets
    while low < high do
        local middle = math.floor((low + high) / 2)
        local item = items[middle]
        local bottom = offsets[middle] + rowHeight(list, item)
        if bottom > y then
            high = middle
        else
            low = middle + 1
        end
    end

    local item = items[low]
    if item and offsets[low] + rowHeight(list, item) > y then
        return low
    end
    return -1
end

function VirtualizedList.MarkDirty(list)
    markDirty(list)
end

function VirtualizedList.RebuildMetrics(list)
    rebuildMetrics(list)
    return list.psychopatzTotalHeight or 0
end

function VirtualizedList.SetMetrics(list, offsets, totalHeight)
    list.psychopatzRowOffsets = offsets or {}
    list.psychopatzTotalHeight = totalHeight or 0
    list.psychopatzVirtualMetricsDirty = false
    if list.setScrollHeight then
        list:setScrollHeight(list.psychopatzTotalHeight)
    end
end

local function syncScrollbars(list, totalHeight)
    local width = list:getWidth()
    local height = list:getHeight()
    if list.psychopatzScrollBarWidth == width
        and list.psychopatzScrollBarHeight == height
        and list.psychopatzScrollBarContentHeight == totalHeight
    then
        return
    end

    -- Responsive bounds change the Java list dimensions but do not refresh
    -- the native scrollbar thumb. Do this once per geometry/content change,
    -- before asking the scrollbar whether it is visible.
    if list.updateScrollbars and list.javaObject then
        list:updateScrollbars()
    end
    list.psychopatzScrollBarWidth = width
    list.psychopatzScrollBarHeight = height
    list.psychopatzScrollBarContentHeight = totalHeight
end


    Internal.rowHeight = rowHeight
    Internal.rebuildMetrics = rebuildMetrics
    Internal.markDirty = markDirty
    Internal.rowAtOffset = rowAtOffset
    Internal.firstIntersectingRow = firstIntersectingRow
    Internal.syncScrollbars = syncScrollbars

