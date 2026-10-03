local VirtualizedList = PsychopatzCore.UI.VirtualizedList
local Internal = VirtualizedList.Internal
local markDirty = Internal.markDirty

    local function install(list, native)
        local nativeClear = native.clear
        local nativeRemoveItem = native.removeItem
        local nativeRemoveItemByIndex = native.removeItemByIndex
        local nativeRemoveFirst = native.removeFirst

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

    end

    Internal.installCollections = install

