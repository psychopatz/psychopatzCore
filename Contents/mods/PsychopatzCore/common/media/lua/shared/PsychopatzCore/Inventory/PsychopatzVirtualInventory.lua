local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"

local Virtual = PsychopatzCore.Inventory.VirtualInventoryClass or {}
PsychopatzCore.Inventory.VirtualInventoryClass = Virtual
Virtual.__index = Virtual

local function queryTypeId(query)
    if type(query) == "number" then return math.floor(query) end
    if type(query) == "string" then return Types.getId(query, false) end
    if type(query) == "table" then
        return tonumber(query.typeId) or (query.fullType and Types.getId(query.fullType, false))
    end
    return nil
end

local function matches(record, query)
    local typeId = queryTypeId(query)
    if typeId and record[C.TYPE_ID] ~= typeId then return false end
    if type(query) == "function" then return query(record) == true end
    if type(query) == "table" and type(query.predicate) == "function" then
        return query.predicate(record) == true
    end
    return typeId ~= nil or query == nil
end

function Virtual.new(options)
    options = options or {}
    local self = setmetatable({
        schemaVersion = C.VIRTUAL_SCHEMA,
        records = {}, stackIndex = {}, typeCounts = {}, reservations = {},
        reservedByType = {}, nextReservationId = 1, cachedWeight = 0,
        revision = math.max(0, math.floor(tonumber(options.revision) or 0)),
        maxWeight = tonumber(options.maxWeight), authority = options.authority or "server",
    }, Virtual)
    Metrics.increment("virtualInventoryCount")
    return self
end

function Virtual:_canAddWeight(delta)
    return not self.maxWeight or self.cachedWeight + delta <= self.maxWeight + 0.000001
end

function Virtual:add(value, quantity)
    local record
    local reason
    if type(value) == "table" and tonumber(value[C.TYPE_ID]) then
        record = ItemRecord.clone(value, quantity)
    else
        record, reason = ItemRecord.encode(value, quantity)
    end
    if not record then return false, reason end
    local valid
    valid, reason = ItemRecord.validate(record)
    if not valid then return false, reason end
    local deltaWeight = record[C.UNIT_WEIGHT] * record[C.QUANTITY]
    if not self:_canAddWeight(deltaWeight) then return false, "capacity_exceeded" end
    local key = ItemRecord.stackKey(record)
    local existing = key and self.stackIndex[key] or nil
    if existing then
        existing[C.QUANTITY] = existing[C.QUANTITY] + record[C.QUANTITY]
        Metrics.increment("batchCount")
    else
        self.records[#self.records + 1] = record
        if key then self.stackIndex[key] = record else Metrics.increment("uniqueRecordCount") end
    end
    local typeId = record[C.TYPE_ID]
    self.typeCounts[typeId] = (self.typeCounts[typeId] or 0) + record[C.QUANTITY]
    self.cachedWeight = self.cachedWeight + deltaWeight
    self.revision = self.revision + 1
    Metrics.increment("logicalItemCount", record[C.QUANTITY])
    return true, record
end

function Virtual:count(query, includeReserved)
    local typeId = queryTypeId(query)
    local total = 0
    if typeId and (type(query) ~= "table" or not query.predicate) then
        total = self.typeCounts[typeId] or 0
        if not includeReserved then total = total - (self.reservedByType[typeId] or 0) end
        return math.max(0, total)
    end
    local matchedTypes = {}
    for i = 1, #self.records do
        if matches(self.records[i], query) then
            total = total + self.records[i][C.QUANTITY]
            matchedTypes[self.records[i][C.TYPE_ID]] = true
        end
    end
    if not includeReserved then
        for matchedType, _ in pairs(matchedTypes) do
            total = total - (self.reservedByType[matchedType] or 0)
        end
    end
    return math.max(0, total)
end

function Virtual:contains(query, quantity)
    return self:count(query) >= math.max(1, math.floor(tonumber(quantity) or 1))
end

function Virtual:find(query)
    for i = 1, #self.records do
        if matches(self.records[i], query) then return ItemRecord.clone(self.records[i]) end
    end
    return nil
end

function Virtual:query(query)
    local output = {}
    for i = 1, #self.records do
        if matches(self.records[i], query) then output[#output + 1] = ItemRecord.clone(self.records[i]) end
    end
    return output
end

function Virtual:iterate()
    local index = 0
    return function()
        index = index + 1
        local record = self.records[index]
        return record and ItemRecord.clone(record) or nil
    end
end

function Virtual:remove(query, quantity, options)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    options = options or {}
    if not options.includeReserved and self:count(query, false) < quantity then
        return false, "insufficient_quantity"
    end
    if options.includeReserved and self:count(query, true) < quantity then
        return false, "insufficient_quantity"
    end
    local remaining = quantity
    local removed = {}
    local index = #self.records
    while index >= 1 and remaining > 0 do
        local record = self.records[index]
        if matches(record, query) then
            local take = math.min(remaining, record[C.QUANTITY])
            removed[#removed + 1] = ItemRecord.clone(record, take)
            record[C.QUANTITY] = record[C.QUANTITY] - take
            self.typeCounts[record[C.TYPE_ID]] = self.typeCounts[record[C.TYPE_ID]] - take
            self.cachedWeight = self.cachedWeight - record[C.UNIT_WEIGHT] * take
            remaining = remaining - take
            if record[C.QUANTITY] <= 0 then
                local key = ItemRecord.stackKey(record)
                if key then self.stackIndex[key] = nil end
                table.remove(self.records, index)
            end
        end
        index = index - 1
    end
    self.cachedWeight = math.max(0, self.cachedWeight)
    self.revision = self.revision + 1
    Metrics.increment("logicalItemCount", -quantity)
    return true, removed
end

function Virtual:clear()
    if next(self.reservations) then return false, "active_reservations" end
    self.records, self.stackIndex, self.typeCounts = {}, {}, {}
    self.cachedWeight = 0
    self.revision = self.revision + 1
    return true
end

function Virtual:getWeight() return self.cachedWeight end
function Virtual:getRecordCount() return #self.records end
function Virtual:getLogicalItemCount()
    local count = 0
    for _, quantity in pairs(self.typeCounts) do count = count + quantity end
    return count
end

require "PsychopatzCore/Inventory/PsychopatzVirtualInventoryMaintenance"
require "PsychopatzCore/Inventory/PsychopatzInventoryReservations"

PsychopatzCore.Inventory.VirtualInventory = Virtual
return Virtual
