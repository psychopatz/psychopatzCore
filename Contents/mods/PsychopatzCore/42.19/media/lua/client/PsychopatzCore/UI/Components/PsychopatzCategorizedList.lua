require "ISUI/ISScrollingListBox"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local CategorizedList = UI.CategorizedList or {}
UI.CategorizedList = CategorizedList

local PATH_SEPARATOR = string.char(31)

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function normalizePath(path)
    local result = {}
    if type(path) == "table" then
        for _, value in ipairs(path) do
            value = tostring(value or "")
            if value ~= "" then result[#result + 1] = value end
        end
    else
        for value in string.gmatch(tostring(path or ""), "[^/]+") do
            if value ~= "" then result[#result + 1] = value end
        end
    end
    if #result == 0 then result[1] = "General" end
    return result
end

local function pathKey(path)
    return table.concat(path, PATH_SEPARATOR)
end

local function pathLabel(path, separator)
    return table.concat(path, separator or "/")
end

local function defaultItemKey(item)
    if type(item) == "table" then
        return item.id or item.fullType or item.item or item.name or item.text
    end
    return item
end

local function defaultItemText(item)
    if type(item) == "table" then
        return item.displayName or item.name or item.text or item.fullType
            or item.item
    end
    return item
end

local function defaultCategoryPath(item)
    if type(item) == "table" then
        return item.categoryPath or item.category or "General"
    end
    return "General"
end

local function comparePaths(left, right, categoryOrder)
    for index = 1, math.max(#left.path, #right.path) do
        local leftPart = left.path[index] or ""
        local rightPart = right.path[index] or ""
        if index == 1 and categoryOrder then
            local leftOrder = tonumber(categoryOrder[leftPart]) or 9999
            local rightOrder = tonumber(categoryOrder[rightPart]) or 9999
            if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        end
        if lower(leftPart) ~= lower(rightPart) then
            return lower(leftPart) < lower(rightPart)
        end
    end
    return left.key < right.key
end

local function compareItems(left, right, getText, getKey)
    local leftText = lower(getText(left) or "")
    local rightText = lower(getText(right) or "")
    if leftText == rightText then
        return tostring(getKey(left) or "") < tostring(getKey(right) or "")
    end
    return leftText < rightText
end

local function drawDefaultCategory(list, y, entry, alternate, options)
    local category = entry.item
    local height = entry.height or list.itemheight
    UI.DrawListSelection(list, y, height, false, alternate)
    local background = Theme.colors.surfaceRaised
    local accent = Theme.colors.accent
    list:drawRect(0, y, list:getWidth(), height, background.a,
        background.r, background.g, background.b)
    list:drawRect(0, y, 4, height, 1, accent.r, accent.g, accent.b)

    local indicator = category.expanded and "[-] " or "[+] "
    local label = options.uppercaseCategories == false
        and category.label or string.upper(category.label)
    local font = Theme.Font(options.uiScale or 1, "body")
    local text = Theme.colors.text
    list:drawText(indicator .. label, 12, y + 8,
        text.r, text.g, text.b, text.a, font)

    if options.formatCategoryCount then
        local count = tostring(options.formatCategoryCount(category.count, category) or "")
        local muted = Theme.colors.textMuted
        list:drawText(count,
            list:getWidth() - Theme.TextWidth(UIFont.Small, count) - 12,
            y + 11, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    end
    return y + height
end

local function drawDefaultItem(list, y, entry, alternate, options)
    local itemEntry = entry.item
    local height = entry.height or list.itemheight
    UI.DrawListSelection(list, y, height,
        list.selected == entry.index, alternate)
    local text = Theme.colors.text
    local value = tostring(options.getItemText(itemEntry.item) or "-")
    local x = options.itemLeftPadding or 24
    local available = math.max(40, list:getWidth() - x - 12)
    list:drawText(Layout.Ellipsize(value, UIFont.Small, available), x, y + 8,
        text.r, text.g, text.b, text.a, UIFont.Small)
    return y + height
end

local function currentItemKey(list, getKey)
    local selected
    if list.getItem then selected = list:getItem() end
    local entry = selected and selected.item or nil
    if entry and entry.kind == "item" then
        return tostring(getKey(entry.item) or "")
    end
    return nil
end

local function addBuiltRow(list, label, item, height)
    -- Build rows directly during a rebuild.  ISScrollingListBox:addItem()
    -- recalculates the scrollbar height for every row, which is needlessly
    -- expensive when a catalog contains thousands of entries.
    local added = {
        text = label,
        item = item,
        tooltip = nil,
        itemindex = list.count + 1,
        height = height,
    }
    list.items[#list.items + 1] = added
    list.count = list.count + 1
    return added
end

local function rebuildRows(list)
    local options = list.psychopatzCategoryOptions
    local getKey = options.getItemKey
    local getText = options.getItemText
    local selectedKey = currentItemKey(list, getKey)
    local offsets = {}
    local totalHeight = 0

    list.psychopatzVisibleItemCount = 0
    list:clear()

    for _, group in ipairs(list.psychopatzGroups or {}) do
        local expanded = list.psychopatzExpanded[group.key]
        if expanded == nil then
            expanded = list.psychopatzExpandedByDefault
        end
        local category = {
            kind = "category",
            categoryKey = group.key,
            categoryPath = group.path,
            label = pathLabel(group.path, options.categorySeparator),
            count = #group.items,
            expanded = expanded == true,
        }
        list.psychopatzExpanded[group.key] = category.expanded
        offsets[#list.items + 1] = totalHeight
        addBuiltRow(list, category.label, category,
            list.psychopatzCategoryHeight)
        totalHeight = totalHeight + list.psychopatzCategoryHeight

        if category.expanded then
            for _, item in ipairs(group.items) do
                local row = {
                    kind = "item",
                    categoryKey = group.key,
                    categoryPath = group.path,
                    item = item,
                }
                offsets[#list.items + 1] = totalHeight
                addBuiltRow(list, tostring(getText(item) or ""), row,
                    list.psychopatzItemHeight)
                totalHeight = totalHeight + list.psychopatzItemHeight
                list.psychopatzVisibleItemCount =
                    list.psychopatzVisibleItemCount + 1
                if selectedKey and tostring(getKey(item) or "") == selectedKey then
                    list.selected = #list.items
                end
            end
        end
    end

    list.psychopatzRowOffsets = offsets
    list.psychopatzTotalHeight = totalHeight
    if list.setScrollHeight then list:setScrollHeight(totalHeight) end
end

local function rebuild(list, sourceItems)
    local options = list.psychopatzCategoryOptions
    local getPath = options.getCategoryPath
    local getKey = options.getItemKey
    local getText = options.getItemText
    local groupsByKey = {}
    local groups = {}

    for _, item in ipairs(sourceItems or {}) do
        local path = normalizePath(getPath(item))
        local key = pathKey(path)
        local group = groupsByKey[key]
        if not group then
            group = { key = key, path = path, items = {} }
            groupsByKey[key] = group
            groups[#groups + 1] = group
        end
        group.items[#group.items + 1] = item
    end

    table.sort(groups, function(left, right)
        return comparePaths(left, right, options.categoryOrder)
    end)
    if not options.itemsAlreadySorted then
        for _, group in ipairs(groups) do
            table.sort(group.items, function(left, right)
                return compareItems(left, right, getText, getKey)
            end)
        end
    end

    list.psychopatzSourceItems = sourceItems or {}
    list.psychopatzGroups = groups
    rebuildRows(list)
end

local function rowAtOffset(list, y)
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
    if item and y < offsets[index] + (item.height or list.itemheight) then
        return index
    end
    return -1
end

local function firstIntersectingRow(list, y)
    local offsets = list.psychopatzRowOffsets or {}
    local items = list.items or {}
    if #offsets == 0 then return -1 end

    local low, high = 1, #offsets
    while low < high do
        local middle = math.floor((low + high) / 2)
        local item = items[middle]
        local bottom = offsets[middle] + (item and item.height or list.itemheight)
        if bottom > y then
            high = middle
        else
            low = middle + 1
        end
    end

    local item = items[low]
    if item and offsets[low] + (item.height or list.itemheight) > y then
        return low
    end
    return -1
end

local function installVirtualizedBehavior(list)
    -- ISScrollingListBox:prerender() scans every row to find the viewport.
    -- Categorized debug catalogs use fixed row heights, so we can jump to the
    -- visible range with the offsets built during rebuildRows().
    local nativeRowAt = list.rowAt
    local nativeTopOfItem = list.topOfItem
    local nativeEnsureVisible = list.ensureVisible

    function list:rowAt(x, y)
        if self.psychopatzRowOffsets then
            return rowAtOffset(self, y)
        end
        return nativeRowAt(self, x, y)
    end

    function list:topOfItem(index)
        if self.psychopatzRowOffsets then
            return self.psychopatzRowOffsets[index] or -1
        end
        return nativeTopOfItem(self, index)
    end

    function list:ensureVisible(index)
        local offsets = self.psychopatzRowOffsets
        local item = self.items and self.items[index]
        if not offsets or not item or not offsets[index] then
            return nativeEnsureVisible(self, index)
        end
        local y = offsets[index]
        local height = item.height or self.itemheight
        if not self.smoothScrollTargetY then
            self.smoothScrollY = self:getYScroll()
        end
        if y <= 0 - self:getYScroll() then
            self.smoothScrollTargetY = 0 - y
        elseif y + height > 0 - self:getYScroll() + self.height then
            self.smoothScrollTargetY = 0 - (y + height - self.height)
        end
    end

    function list:prerender()
        if self.items == nil then return end

        local totalHeight = self.psychopatzTotalHeight or 0
        if self:getScrollHeight() ~= totalHeight then
            self:setScrollHeight(totalHeight)
        end

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
            and self.psychopatzRowOffsets[last] < viewportBottom
        do
            last = last + 1
        end

        local altBg = self.altBgColor
        while index > 0 and index < last do
            local entry = items[index]
            if not entry.height then entry.height = self.itemheight end
            if index % 2 == 0 and altBg then
                self:drawRect(0, y, self:getWidth(), entry.height - 1,
                    altBg.r, altBg.g, altBg.b, altBg.a)
            end
            entry.index = index
            local y2 = self:doDrawItem(y, entry, index % 2 == 0)
            if self.stopPrerender then
                self.stopPrerender = false
                return
            end
            y = y2
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
            for _, column in ipairs(self.columns) do
                self:drawRectStatic(column.size, 0 - self.itemheight,
                    1, self.itemheight + math.min(self.height,
                        self.itemheight * #items - 1), 1,
                    self.borderColor.r, self.borderColor.g, self.borderColor.b)
                if column.name then
                    self:drawText(column.name, column.size + 10,
                        0 - self.itemheight - 1 + dyText - self:getYScroll(),
                        1, 1, 1, 1, UIFont.Small)
                end
            end
        end
        if self.useStencilForChildren then
            self:setStencilRect(0, 0, self.width, self.height)
        end
    end
end

function CategorizedList.NormalizePath(path)
    return normalizePath(path)
end

function CategorizedList.PathKey(path)
    return pathKey(normalizePath(path))
end

function CategorizedList.PathLabel(path, separator)
    return pathLabel(normalizePath(path), separator)
end

function CategorizedList.Create(parent, options)
    options = options or {}
    local list = UI.CreateList(parent, {
        itemHeight = Layout.Pixels(options.itemHeight or 42, options.uiScale),
        drawBorder = options.drawBorder,
    })
    list.psychopatzCategoryOptions = options
    list.psychopatzCategoryHeight = Layout.Pixels(
        options.categoryHeight or 38, options.uiScale)
    list.psychopatzItemHeight = Layout.Pixels(
        options.itemHeight or 42, options.uiScale)
    list.psychopatzExpanded = options.expanded or {}
    list.psychopatzExpandedByDefault = options.expandedByDefault ~= false
    list.psychopatzSourceItems = {}
    list.psychopatzGroups = {}
    list.psychopatzVisibleItemCount = 0
    list.psychopatzRowOffsets = {}
    list.psychopatzTotalHeight = 0

    options.getCategoryPath = options.getCategoryPath or defaultCategoryPath
    options.getItemKey = options.getItemKey or defaultItemKey
    options.getItemText = options.getItemText or defaultItemText
    options.categorySeparator = options.categorySeparator or "/"
    options.uiScale = options.uiScale or Layout.Scale()

    list.doDrawItem = function(self, y, entry, alternate)
        if entry.item and entry.item.kind == "category" then
            if options.drawCategory then
                return options.drawCategory(self, y, entry, alternate)
            end
            return drawDefaultCategory(self, y, entry, alternate, options)
        end
        if options.drawItem then
            return options.drawItem(self, y, entry, alternate)
        end
        return drawDefaultItem(self, y, entry, alternate, options)
    end

    local nativeMouseDown = list.onMouseDown
    list.onMouseDown = function(self, x, y)
        local rowIndex = self:rowAt(x, y)
        local row = self.items[rowIndex]
        local entry = row and row.item or nil
        if entry and entry.kind == "category" then
            self.selected = rowIndex
            self:toggleCategory(entry.categoryKey)
            return true
        end
        local result = nativeMouseDown(self, x, y)
        row = self.items[self.selected]
        entry = row and row.item or nil
        if entry and entry.kind == "item" and options.onItemSelected then
            options.onItemSelected(self, entry.item, entry)
        end
        return result
    end

    local nativeDoubleClick = list.onMouseDoubleClick
    list.onMouseDoubleClick = function(self, x, y)
        local result = nativeDoubleClick(self, x, y)
        local row = self.items[self.selected]
        local entry = row and row.item or nil
        if entry and entry.kind == "item" and options.onItemActivated then
            options.onItemActivated(self, entry.item, entry)
        end
        return result
    end

    function list:setItems(items)
        rebuild(self, items or {})
    end

    function list:rebuild(items)
        rebuild(self, items or self.psychopatzSourceItems)
    end

    function list:isCategoryExpanded(key)
        return self.psychopatzExpanded[tostring(key or "")] == true
    end

    function list:setCategoryExpanded(key, expanded)
        key = tostring(key or "")
        if key == "" then return end
        self.psychopatzExpanded[key] = expanded == true
        rebuildRows(self)
    end

    function list:toggleCategory(key)
        key = tostring(key or "")
        self.psychopatzExpanded[key] = not self:isCategoryExpanded(key)
        rebuildRows(self)
        if options.onCategoryToggled then
            options.onCategoryToggled(self, key,
                self.psychopatzExpanded[key] == true)
        end
    end

    function list:setAllCategoriesExpanded(expanded)
        for _, group in ipairs(self.psychopatzGroups or {}) do
            self.psychopatzExpanded[group.key] = expanded == true
        end
        rebuildRows(self)
    end

    function list:collapseAll()
        self:setAllCategoriesExpanded(false)
    end

    function list:expandAll()
        self:setAllCategoriesExpanded(true)
    end

    if options.virtualized then
        installVirtualizedBehavior(list)
    end

    return list
end

function UI.CreateCategorizedList(parent, options)
    return CategorizedList.Create(parent, options)
end

return CategorizedList
