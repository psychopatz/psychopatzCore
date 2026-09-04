local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local UI = {
    Theme = {
        colors = {
            surfaceRaised = { r = 0, g = 0, b = 0, a = 1 },
            accent = { r = 1, g = 1, b = 1, a = 1 },
            text = { r = 1, g = 1, b = 1, a = 1 },
            textMuted = { r = 1, g = 1, b = 1, a = 1 },
        },
        Font = function() return UIFont.Small end,
        TextWidth = function() return 1 end,
    },
    Layout = {
        Pixels = function(value) return value end,
        Scale = function() return 1 end,
        Ellipsize = function(value) return value end,
    },
}
PsychopatzCore = { UI = UI }
UIFont = { Small = 1 }

package.preload["ISUI/ISScrollingListBox"] = function()
    ISScrollingListBox = {}
    return ISScrollingListBox
end
package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] = function()
    return UI
end

function UI.CreateList(_, options)
    local list = {
        items = {}, count = 0, selected = 1, width = 400, height = 100,
        javaObject = {},
        itemheight = options and options.itemHeight or 28,
        backgroundColor = { r = 0, g = 0, b = 0, a = 1 },
        borderColor = { r = 1, g = 1, b = 1, a = 1 },
        columns = {}, useStencilForChildren = false,
    }
    function list:addItem(text, item)
        local row = { text = text, item = item, height = 1 }
        self.items[#self.items + 1] = row
        self.count = #self.items
        return row
    end
    function list:clear()
        self.items = {}
        self.count = 0
        self.selected = 1
    end
    function list:insertItem(index, text, item)
        local row = { text = text, item = item, height = self.itemheight }
        table.insert(self.items, math.max(1, math.min(index, #self.items + 1)), row)
        self.count = #self.items
        return row
    end
    function list:removeItemByIndex(index)
        if index < 1 or index > #self.items then return nil end
        local row = table.remove(self.items, index)
        self.count = #self.items
        return row
    end
    function list:removeItem(text)
        for index, row in ipairs(self.items) do
            if row.text == text then return self:removeItemByIndex(index) end
        end
        return nil
    end
    function list:removeFirst()
        return self:removeItemByIndex(1)
    end
    function list:rowAt(_, y)
        local offset = 0
        for index, row in ipairs(self.items) do
            if y >= offset and y < offset + row.height then return index end
            offset = offset + row.height
        end
        return -1
    end
    function list:topOfItem(index)
        local offset = 0
        for current, row in ipairs(self.items) do
            if current == index then return offset end
            offset = offset + row.height
        end
        return -1
    end
    function list:ensureVisible() end
    function list:prerender() end
    function list:getItem()
        return self.items[self.selected]
    end
    function list:getWidth() return 400 end
    function list:getHeight() return self.height end
    function list:getYScroll() return self.yScroll or 0 end
    function list:getScrollHeight() return self.scrollHeight or 0 end
    function list:isVScrollBarVisible() return false end
    function list:parentsHaveScrollChildren() return false end
    function list:getMouseY() return 0 end
    function list:isMouseOver() return false end
    function list:drawRect() end
    function list:drawText() end
    function list:setStencilRect() end
    function list:clearStencilRect() end
    function list:updateSmoothScrolling() end
    function list:updateTooltip() end
    function list:setScrollHeight(value)
        self.scrollHeight = value
        self.scrollHeightUpdates = (self.scrollHeightUpdates or 0) + 1
    end
    function list:updateScrollbars()
        self.scrollbarRefreshes = (self.scrollbarRefreshes or 0) + 1
    end
    if options and options.doDrawItem then
        list.doDrawItem = options.doDrawItem
    end
    if options and options.virtualized ~= false then
        local virtualized = require
            "PsychopatzCore/UI/Components/PsychopatzVirtualizedList"
        virtualized.Install(list)
    end
    return list
end

UI.DrawListSelection = function() end
UI.TextWidth = function() return 1 end

local categorized = dofile(CLIENT
    .. "PsychopatzCore/UI/Components/PsychopatzCategorizedList.lua")

equal(categorized.PathLabel({ "Weapon", "Ranged", "Ammo" }),
    "Weapon/Ranged/Ammo", "category path label")
local list = UI.CreateCategorizedList(nil, {
    categoryOrder = { Weapon = 1, Food = 2 },
    getCategoryPath = function(item) return item.path end,
    getItemKey = function(item) return item.id end,
    getItemText = function(item) return item.name end,
})

list:setItems({
    { id = "Base.Shell", name = "12g Round", path = { "Weapon", "Ranged", "Ammo" } },
    { id = "Base.Magnum", name = ".44 Magnum Round", path = { "Weapon", "Ranged", "Ammo" } },
    { id = "Base.Rifle", name = "L94 Rifle", path = { "Weapon", "Ranged", "Firearm" } },
})

equal(#list.psychopatzGroups, 2, "category count")
equal(#list.items, 5, "expanded row count")
equal(list.items[1].item.label, "Weapon/Ranged/Ammo", "category order")
equal(list.psychopatzVisibleItemCount, 3, "expanded item count")
equal(list:doDrawItem(0, list.items[1], false), 38,
    "default category renderer uses the PZ row payload")

list:collapseAll()
equal(#list.items, 2, "collapsed row count")
equal(list.psychopatzVisibleItemCount, 0, "collapsed item count")

list:expandAll()
equal(#list.items, 5, "expand all row count")
list:setCategoryExpanded(categorized.PathKey({ "Weapon", "Ranged", "Ammo" }), false)
equal(#list.items, 3, "single category collapse")
equal(list.psychopatzVisibleItemCount, 1, "single category visible item count")

local virtual = UI.CreateCategorizedList(nil, {
    categoryOrder = { Weapon = 1, Food = 2 },
    itemsAlreadySorted = true,
    virtualized = true,
    getCategoryPath = function(item) return item.path end,
    getItemKey = function(item) return item.id end,
    getItemText = function(item) return item.name end,
})
virtual:setItems({
    { id = "Base.Shell", name = "12g Round", path = { "Weapon", "Ranged", "Ammo" } },
    { id = "Base.Magnum", name = ".44 Magnum Round", path = { "Weapon", "Ranged", "Ammo" } },
})
equal(virtual:rowAt(0, 0), 1, "virtual category hit test")
equal(virtual:rowAt(0, 38), 2, "virtual item hit test")
equal(virtual:topOfItem(2), 38, "virtual row offset")
virtual:prerender()
equal(virtual.listHeight, 122, "virtual total height")

local genericDraws = 0
local generic = UI.CreateList(nil, {
    itemHeight = 10,
    doDrawItem = function(list, y, entry)
        genericDraws = genericDraws + 1
        return y + list.itemheight
    end,
})
for index = 1, 100 do
    generic:addItem(tostring(index), { id = index })
end
equal(generic.scrollHeightUpdates or 0, 0,
    "generic addItem does not recalculate scroll height per row")
equal(generic:topOfItem(51), 500, "generic virtual row offset")
equal(generic:rowAt(0, 505), 51, "generic virtual hit test")
equal(generic.scrollHeightUpdates, 1,
    "generic metrics rebuild recalculates scroll height once")
generic:prerender()
equal(generic.listHeight, 1000, "generic virtual total height")
equal(genericDraws, 10, "generic virtual visible draw count")
equal(generic.scrollbarRefreshes, 1,
    "generic first frame refreshes native scrollbar state")

local variable = UI.CreateList(nil, {
    itemHeight = 10,
    doDrawItem = function(_, y) return y + 20 end,
})
variable:addItem("variable", {})
variable:prerender()
equal(variable.psychopatzVirtualized, false,
    "variable-height renderer falls back to native list")

print("psychopatz_categorized_list_smoke: PASS")
