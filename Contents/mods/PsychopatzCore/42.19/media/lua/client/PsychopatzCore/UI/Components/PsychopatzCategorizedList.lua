require "ISUI/ISScrollingListBox"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
local VirtualizedList = require "PsychopatzCore/UI/Components/PsychopatzVirtualizedList"

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

    VirtualizedList.SetMetrics(list, offsets, totalHeight)
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
        virtualized = options.virtualized,
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

    return list
end

function UI.CreateCategorizedList(parent, options)
    return CategorizedList.Create(parent, options)
end

return CategorizedList
