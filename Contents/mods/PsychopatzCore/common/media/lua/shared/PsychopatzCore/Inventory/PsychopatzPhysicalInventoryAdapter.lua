local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"

local Physical = {}
Physical.__index = Physical

local function typeIdForItem(item)
    local fullType = Util.call(item, "getFullType") or item and (item.fullType or item.type)
    return fullType and Types.getId(fullType) or nil
end

local function wantedType(query)
    if type(query) == "number" then return math.floor(query) end
    if type(query) == "string" then return Types.getId(query, false) end
    if type(query) == "table" then
        return tonumber(query.typeId) or (query.fullType and Types.getId(query.fullType, false))
    end
    return nil
end

local function matches(item, query)
    local typeId = wantedType(query)
    if typeId and typeIdForItem(item) ~= typeId then return false end
    if type(query) == "function" then return query(item) == true end
    if type(query) == "table" and type(query.predicate) == "function" then
        return query.predicate(item) == true
    end
    return typeId ~= nil or query == nil
end

function Physical.new(container, options)
    if not container then return nil, "container_required" end
    local self = setmetatable({ container = container, options = options or {}, revision = 0 }, Physical)
    Metrics.increment("physicalAdapterCount")
    return self
end

function Physical:_items()
    return Util.javaList(Util.call(self.container, "getItems"))
end

function Physical:count(query)
    local count = 0
    local items = self:_items()
    for i = 1, #items do
        if matches(items[i], query) then count = count + 1 end
    end
    return count
end

function Physical:contains(query, quantity)
    return self:count(query) >= math.max(1, math.floor(tonumber(quantity) or 1))
end

function Physical:find(query)
    local items = self:_items()
    for i = 1, #items do if matches(items[i], query) then return items[i] end end
    return nil
end

function Physical:query(query)
    local output = {}
    local items = self:_items()
    for i = 1, #items do if matches(items[i], query) then output[#output + 1] = items[i] end end
    return output
end

function Physical:iterate()
    local items = self:_items()
    local index = 0
    return function() index = index + 1 return items[index] end
end

function Physical:_nativeAdd(item)
    if self.container.AddItem then
        local added = self.container:AddItem(item)
        return added or item
    end
    return nil
end

function Physical:add(value, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or (type(value) == "table" and value[C.QUANTITY]) or 1))
    local added = {}
    if type(value) == "table" and (value.getFullType or value.fullType) and not tonumber(value[C.TYPE_ID]) then
        local result = self:_nativeAdd(value)
        if not result then return false, "physical_add_failed" end
        added[1] = result
    else
        for i = 1, quantity do
            local item, reason = ItemRecord.decode(value, self.options.factory)
            if not item then
                for j = #added, 1, -1 do self:_nativeRemove(added[j]) end
                return false, reason
            end
            local result = self:_nativeAdd(item)
            if not result then
                for j = #added, 1, -1 do self:_nativeRemove(added[j]) end
                return false, "physical_add_failed"
            end
            added[#added + 1] = result
        end
    end
    self.revision = self.revision + 1
    return true, added
end

function Physical:_nativeRemove(item)
    if self.container.DoRemoveItem then self.container:DoRemoveItem(item) return true end
    if self.container.Remove then self.container:Remove(item) return true end
    if self.container.RemoveItem then self.container:RemoveItem(item) return true end
    return false
end

function Physical:remove(query, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local selected = self:query(query)
    if #selected < quantity then return false, "insufficient_quantity" end
    local removed = { physicalItems = {} }
    for i = 1, quantity do
        local record, reason = ItemRecord.encode(selected[i], 1)
        if not record then return false, reason end
        removed[#removed + 1] = record
        removed.physicalItems[#removed.physicalItems + 1] = selected[i]
    end
    for i = 1, quantity do
        if not self:_nativeRemove(selected[i]) then
            for j = i - 1, 1, -1 do self:_nativeAdd(selected[j]) end
            return false, "physical_remove_failed"
        end
    end
    self.revision = self.revision + 1
    return true, removed
end

function Physical:restoreRemoved(removed)
    if type(removed) == "table" and type(removed.physicalItems) == "table" then
        for i = 1, #removed.physicalItems do
            if not self:_nativeAdd(removed.physicalItems[i]) then return false end
        end
        return true
    end
    for i = 1, #(removed or {}) do
        local ok = self:add(removed[i])
        if not ok then return false end
    end
    return true
end

function Physical:clear()
    local items = self:_items()
    for i = #items, 1, -1 do if not self:_nativeRemove(items[i]) then return false end end
    self.revision = self.revision + 1
    return true
end

function Physical:getWeight()
    local weight = Util.call(self.container, "getContentsWeight")
    if weight ~= nil then return Util.number(weight, 0) end
    weight = 0
    local items = self:_items()
    for i = 1, #items do
        weight = weight + Util.number(
            (Util.call(items[i], "getActualWeight")), 0)
    end
    return weight
end

function Physical:getRecordCount() return #self:_items() end
function Physical:getLogicalItemCount() return #self:_items() end

PsychopatzCore.Inventory.PhysicalInventoryAdapter = Physical
return Physical
