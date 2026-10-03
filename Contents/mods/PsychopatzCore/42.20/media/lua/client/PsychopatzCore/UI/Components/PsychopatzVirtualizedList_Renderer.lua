local VirtualizedList = PsychopatzCore.UI.VirtualizedList
local Internal = VirtualizedList.Internal
local rebuildMetrics = Internal.rebuildMetrics
local rowHeight = Internal.rowHeight
local firstIntersectingRow = Internal.firstIntersectingRow
local syncScrollbars = Internal.syncScrollbars
local Layout = PsychopatzCore.UI.Layout

local function prepareStencil(self, yScroll)
    local stencilX, stencilY = 0, 0
    local stencilX2, stencilY2 = self.width, self.height

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
    return stencilX, stencilY, stencilX2, stencilY2
end

local function drawRows(self, items, first, last, y, nativePrerender)
    local index = first
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
            return "fallback"
        end
        if self.stopPrerender then
            self.stopPrerender = false
            return "stopped"
        end
        y = expectedY
        index = index + 1
    end
    return "complete"
end

local function drawHeaders(self, items)
    if #self.columns <= 0 then return end

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

local function finishRender(self, items, totalHeight,
    stencilX, stencilY, stencilX2, stencilY2)
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
    drawHeaders(self, items)

    if self.useStencilForChildren then
        self:setStencilRect(0, 0, self.width, self.height)
    end
end

local function prerender(self, nativePrerender)
    if not self.items then return end
    if not self.psychopatzVirtualized then
        return nativePrerender(self)
    end

    rebuildMetrics(self)
    local totalHeight = self.psychopatzTotalHeight or 0
    syncScrollbars(self, totalHeight)
    local yScroll = self:getYScroll()
    local stencilX, stencilY, stencilX2, stencilY2 =
        prepareStencil(self, yScroll)

    local items = self.items
    local count = #items
    if self.selected ~= -1 and self.selected > count then
        self.selected = count
    end

    local viewportTop = math.max(0, 0 - yScroll)
    local viewportBottom = viewportTop + self.height
    local first = firstIntersectingRow(self, viewportTop)
    local y = first > 0 and self.psychopatzRowOffsets[first] or 0
    local last = first
    while last > 0 and last <= count
        and self.psychopatzRowOffsets[last] < viewportBottom do
        last = last + 1
    end

    local rowResult = drawRows(self, items, first, last, y, nativePrerender)
    if rowResult == "fallback" then
        return nativePrerender(self)
    end
    if rowResult == "stopped" then return end
    finishRender(self, items, totalHeight,
        stencilX, stencilY, stencilX2, stencilY2)
end

local function install(list, native)
    function list:prerender()
        return prerender(self, native.prerender)
    end
end

Internal.installRenderer = install
