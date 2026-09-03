require "ISUI/ISScrollingListBox"

-- Fixed-row virtualization for reusable PsychopatzCore lists.
--
-- The PZ list widget walks every row in prerender(), even when only a small
-- portion of the list is visible.  This component keeps the native widget's
-- interaction model, but indexes row offsets and draws only rows intersecting
-- the viewport.  It is intended for lists whose draw callback returns
-- y + list.itemheight (the default contract of UI.CreateList).
local VirtualizedList = {}
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

function VirtualizedList.Install(list)
    if not list or list.psychopatzVirtualizedInstalled then return list end

    list.psychopatzVirtualizedInstalled = true
    list.psychopatzVirtualized = true
    list.psychopatzVirtualMetricsDirty = true

    local nativeClear = list.clear
    local nativeRemoveItem = list.removeItem
    local nativeRemoveItemByIndex = list.removeItemByIndex
    local nativeRemoveFirst = list.removeFirst
    local nativeRowAt = list.rowAt
    local nativeTopOfItem = list.topOfItem
    local nativeEnsureVisible = list.ensureVisible
    local nativePrerender = list.prerender

    -- Avoid ISScrollingListBox:setScrollHeight() on every row while a list is
    -- being filled. Metrics are rebuilt once at the next query or frame.
    function list:addItem(name, item, tooltip)
        local row = {
            text = name,
            item = item,
            tooltip = tooltip,
            itemindex = self.count + 1,
            height = self.itemheight,
        }
        self.items[#self.items + 1] = row
        self.count = self.count + 1
        markDirty(self)
        return row
    end

    function list:insertItem(index, name, item)
        local row = {
            text = name,
            item = item,
            tooltip = nil,
            height = self.itemheight,
        }
        if #self.items == 0 or index > #self.items then
            row.itemindex = 1
            table.insert(self.items, row)
        elseif index < 1 then
            row.itemindex = 1
            table.insert(self.items, 1, row)
        else
            row.itemindex = index
            table.insert(self.items, index, row)
        end
        self.count = self.count + 1
        markDirty(self)
        return row
    end

    function list:clear()
        nativeClear(self)
        markDirty(self)
        if self.setScrollHeight then self:setScrollHeight(0) end
    end

    function list:removeItem(itemText)
        local row = nativeRemoveItem(self, itemText)
        if row then markDirty(self) end
        return row
    end

    function list:removeItemByIndex(index)
        local row = nativeRemoveItemByIndex(self, index)
        if row then markDirty(self) end
        return row
    end

    function list:removeFirst()
        local count = self.count
        local result = nativeRemoveFirst(self)
        if self.count ~= count then markDirty(self) end
        return result
    end

    function list:rowAt(x, y)
        if self.psychopatzVirtualized then
            return rowAtOffset(self, y)
        end
        return nativeRowAt(self, x, y)
    end

    function list:topOfItem(index)
        if self.psychopatzVirtualized then
            rebuildMetrics(self)
            return self.psychopatzRowOffsets[index] or -1
        end
        return nativeTopOfItem(self, index)
    end

    function list:ensureVisible(index)
        if not self.psychopatzVirtualized then
            return nativeEnsureVisible(self, index)
        end

        rebuildMetrics(self)
        local offsets = self.psychopatzRowOffsets
        local item = self.items and self.items[index]
        if not offsets or not item or not offsets[index] then return end

        local y = offsets[index]
        local height = rowHeight(self, item)
        if not self.smoothScrollTargetY then
            self.smoothScrollY = self:getYScroll()
        end
        if y <= 0 - self:getYScroll() then
            self.smoothScrollTargetY = 0 - y
        elseif y + height > 0 - self:getYScroll() + self.height then
            self.smoothScrollTargetY = 0 - (y + height - self.height)
        end
    end

    function list:rebuildVirtualizedMetrics()
        return VirtualizedList.RebuildMetrics(self)
    end

    function list:prerender()
        if not self.items then return end
        if not self.psychopatzVirtualized then
            return nativePrerender(self)
        end

        rebuildMetrics(self)
        local totalHeight = self.psychopatzTotalHeight or 0
        syncScrollbars(self, totalHeight)
        local stencilX, stencilY = 0, 0
        local stencilX2, stencilY2 = self.width, self.height
        local yScroll = self:getYScroll()

        self:drawRect(0, -yScroll, self.width, self.height,
            self.backgroundColor.a, self.backgroundColor.r,
            self.backgroundColor.g, self.backgroundColor.b)
        if self.drawBorder then
            self:drawRectBorder(0, -yScroll, self.width, self.height,
                self.borderColor.a, self.borderColor.r,
                self.borderColor.g, self.borderColor.b)
            stencilX, stencilY = 1, 1
            stencilX2, stencilY2 = self.width - 1, self.height - 1
        end

        if self:isVScrollBarVisible() then
            stencilX2 = self.vscroll.x + 3
        end

        if self:parentsHaveScrollChildren() then
            stencilX = self.javaObject:clampToParentX(
                self:getAbsoluteX() + stencilX) - self:getAbsoluteX()
            stencilX2 = self.javaObject:clampToParentX(
                self:getAbsoluteX() + stencilX2) - self:getAbsoluteX()
            stencilY = self.javaObject:clampToParentY(
                self:getAbsoluteY() + stencilY) - self:getAbsoluteY()
            stencilY2 = self.javaObject:clampToParentY(
                self:getAbsoluteY() + stencilY2) - self:getAbsoluteY()
        end
        self:setStencilRect(stencilX, stencilY,
            stencilX2 - stencilX, stencilY2 - stencilY)

        local items = self.items
        local count = #items
        if self.selected ~= -1 and self.selected > count then
            self.selected = count
        end

        local viewportTop = math.max(0, 0 - yScroll)
        local viewportBottom = viewportTop + self.height
        local first = firstIntersectingRow(self, viewportTop)
        local y = first > 0 and self.psychopatzRowOffsets[first] or 0
        local index = first
        local last = first
        while last > 0 and last <= count
            and self.psychopatzRowOffsets[last] < viewportBottom do
            last = last + 1
        end

        local altBg = self.altBgColor
        while index > 0 and index < last do
            local entry = items[index]
            local height = rowHeight(self, entry)
            if index % 2 == 0 and altBg then
                self:drawRect(0, y, self:getWidth(), height - 1,
                    altBg.r, altBg.g, altBg.b, altBg.a)
            end
            entry.index = index
            local nextY = self:doDrawItem(y, entry, index % 2 == 0)
            local expectedY = y + height
            if nextY and math.abs(nextY - expectedY) > 0.01 then
                -- Preserve native behavior if a caller violates the fixed-row
                -- contract. The next frame will use the native full scan.
                self.psychopatzVirtualized = false
                self:clearStencilRect()
                return nativePrerender(self)
            end
            if self.stopPrerender then
                self.stopPrerender = false
                return
            end
            y = expectedY
            index = index + 1
        end

        self.listHeight = totalHeight
        self:clearStencilRect()
        if self.doRepaintStencil then
            self:repaintStencilRect(stencilX, stencilY,
                stencilX2 - stencilX, stencilY2 - stencilY)
        end

        local mouseY = self:getMouseY()
        self:updateSmoothScrolling()
        if mouseY ~= self:getMouseY() and self:isMouseOver() then
            self:onMouseMove(0, self:getMouseY() - mouseY)
        end
        self:updateTooltip()

        if #self.columns > 0 then
            self:drawRectBorderStatic(0, 0 - self.itemheight,
                self.width, self.itemheight, 1,
                self.borderColor.r, self.borderColor.g, self.borderColor.b)
            self:drawRectStatic(0, 0 - self.itemheight,
                self.width, self.itemheight, self.listHeaderColor.a,
                self.listHeaderColor.r, self.listHeaderColor.g,
                self.listHeaderColor.b)
            local fontHeight = getTextManager():getFontHeight(UIFont.Small)
            local dyText = (self.itemheight - fontHeight) / 2
            for columnIndex, column in ipairs(self.columns) do
                self:drawRectStatic(column.size, 0 - self.itemheight,
                    1, self.itemheight + math.min(self.height,
                        self.itemheight * #items - 1), 1,
                    self.borderColor.r, self.borderColor.g, self.borderColor.b)
                if column.name then
                    local nextColumn = self.columns[columnIndex + 1]
                    local columnWidth = (nextColumn and nextColumn.size or self.width)
                        - column.size - 14
                    self:drawText(Layout.Ellipsize(column.name, UIFont.Small,
                        math.max(1, columnWidth)), column.size + 10,
                        0 - self.itemheight - 1 + dyText - self:getYScroll(),
                        1, 1, 1, 1, UIFont.Small)
                end
            end
        end
        if self.useStencilForChildren then
            self:setStencilRect(0, 0, self.width, self.height)
        end
    end

    return list
end

return VirtualizedList
