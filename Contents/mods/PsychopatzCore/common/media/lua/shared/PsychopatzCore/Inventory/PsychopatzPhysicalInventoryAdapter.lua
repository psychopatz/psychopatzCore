local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"
local InitialCurrency = PsychopatzCore and PsychopatzCore.Currency or nil

local function currencyService()
    return PsychopatzCore and PsychopatzCore.Currency or InitialCurrency
end

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
    local output = {}
    local seen = {}
    local function visit(container, depth)
        if not container or depth > (tonumber(self.options.maxDepth) or 8) then
            return
        end
        if seen[container] then return end
        seen[container] = true
        local items = Util.javaList(Util.call(container, "getItems"))
        for i = 1, #items do
            local item = items[i]
            output[#output + 1] = item
            if self.options.recursive == true then
                local nested = Util.call(item, "getItemContainer")
                    or Util.call(item, "getInventory")
                if nested then visit(nested, depth + 1) end
            end
        end
    end
    visit(self.container, 1)
    return output
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
    return self:_nativeAddTo(self.container, item)
end

function Physical:_nativeAddTo(container, item)
    container = container or self.container
    if container and container.AddItem then
        local added = container:AddItem(item)
        added = added or item
        if self.options.syncOnMutation == true
            and isServer and isServer() == true
            and sendAddItemToContainer
        then
            pcall(sendAddItemToContainer, container, added)
        end
        return added
    end
    return nil
end

function Physical:add(value, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or (type(value) == "table" and value[C.QUANTITY]) or 1))
    local added = {}
    local currency = currencyService()
    local fullType
    if type(value) == "table" then
        fullType = value.fullType
        if not fullType and tonumber(value[C.TYPE_ID])
            and PsychopatzCore and PsychopatzCore.Inventory
            and PsychopatzCore.Inventory.getItemFullType
        then
            fullType = PsychopatzCore.Inventory.getItemFullType(
                value[C.TYPE_ID])
        end
    end
    if currency and currency.IsType(fullType) and quantity > 1
        and not (type(value) == "table" and value.getFullType)
    then
        local item, reason = ItemRecord.decode(value, 1)
        if not item then return false, reason end
        local setter = item.setCount
        local setOK = type(setter) == "function"
            and pcall(setter, item, quantity)
        if setOK then
            local result = self:_nativeAdd(item)
            if result then
                added[1] = result
                self.revision = self.revision + 1
                return true, added
            end
        end
    end
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

function Physical:countCurrency()
    local currency = currencyService()
    if not currency or type(currency.Snapshot) ~= "function" then return 0 end
    local snapshot = currency.Snapshot(self.container, {
        recursive = self.options.recursive == true,
    })
    return snapshot.units
end

function Physical:containsCurrency(quantity)
    return self:countCurrency()
        >= math.max(1, math.floor(tonumber(quantity) or 1))
end

function Physical:removeCurrency(quantity)
    local currency = currencyService()
    if not currency or type(currency.RemoveUnits) ~= "function" then
        return false, "currency_service_unavailable"
    end
    local ok, reason, details = currency.RemoveUnits(
        self.container,
        quantity,
        { recursive = self.options.recursive == true }
    )
    if not ok then return false, reason end
    self.revision = self.revision + 1
    details = details or {}
    details.currency = true
    return true, details
end

function Physical:_nativeRemove(item)
    local container = Util.call(item, "getContainer") or self.container
    local removed = false
    if container.DoRemoveItem then container:DoRemoveItem(item); removed = true
    elseif container.Remove then container:Remove(item); removed = true
    elseif container.RemoveItem then container:RemoveItem(item); removed = true end
    if removed and self.options.syncOnMutation == true
        and isServer and isServer() == true
        and sendRemoveItemFromContainer
    then
        pcall(sendRemoveItemFromContainer, container, item)
    end
    if removed then return true end
    return false
end

function Physical:remove(query, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local selected = self:query(query)
    if #selected < quantity then return false, "insufficient_quantity" end
    local removed = { physicalItems = {}, physicalContainers = {} }
    for i = 1, quantity do
        local record, reason = ItemRecord.encode(selected[i], 1)
        if not record then return false, reason end
        removed[#removed + 1] = record
        removed.physicalItems[#removed.physicalItems + 1] = selected[i]
        removed.physicalContainers[#removed.physicalContainers + 1] =
            Util.call(selected[i], "getContainer") or self.container
    end
    for i = 1, quantity do
        if not self:_nativeRemove(selected[i]) then
            for j = i - 1, 1, -1 do
                self:_nativeAddTo(removed.physicalContainers[j], selected[j])
            end
            return false, "physical_remove_failed"
        end
    end
    self.revision = self.revision + 1
    return true, removed
end

function Physical:restoreRemoved(removed)
    if type(removed) == "table" and removed.currency
        and type(removed.restore) == "function"
    then
        return removed.restore() == true
    end
    if type(removed) == "table" and type(removed.physicalItems) == "table" then
        for i = 1, #removed.physicalItems do
            if not self:_nativeAddTo(removed.physicalContainers
                and removed.physicalContainers[i], removed.physicalItems[i])
            then return false end
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
