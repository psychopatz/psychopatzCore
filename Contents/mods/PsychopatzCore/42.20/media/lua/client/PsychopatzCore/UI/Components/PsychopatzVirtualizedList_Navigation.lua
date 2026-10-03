local VirtualizedList = PsychopatzCore.UI.VirtualizedList
local Internal = VirtualizedList.Internal
local rebuildMetrics = Internal.rebuildMetrics
local rowAtOffset = Internal.rowAtOffset
local rowHeight = Internal.rowHeight

    local function install(list, native)
        local nativeRowAt = native.rowAt
        local nativeTopOfItem = native.topOfItem
        local nativeEnsureVisible = native.ensureVisible

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


    end

    Internal.installNavigation = install

