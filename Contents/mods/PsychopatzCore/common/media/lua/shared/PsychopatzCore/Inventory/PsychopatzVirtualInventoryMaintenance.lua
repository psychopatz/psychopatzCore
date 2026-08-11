local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Virtual = PsychopatzCore.Inventory.VirtualInventoryClass

function Virtual:recalculateWeight()
    local weight = 0
    for i = 1, #self.records do
        weight = weight + self.records[i][C.UNIT_WEIGHT] * self.records[i][C.QUANTITY]
    end
    self.cachedWeight = weight
    return weight
end

function Virtual:rebuildIndexes()
    self.stackIndex, self.typeCounts = {}, {}
    for i = 1, #self.records do
        local record = self.records[i]
        local key = ItemRecord.stackKey(record)
        if key and not self.stackIndex[key] then self.stackIndex[key] = record end
        self.typeCounts[record[C.TYPE_ID]] = (self.typeCounts[record[C.TYPE_ID]] or 0)
            + record[C.QUANTITY]
    end
    self:recalculateWeight()
end

function Virtual:compact()
    local old = self.records
    self.records, self.stackIndex, self.typeCounts, self.cachedWeight = {}, {}, {}, 0
    for i = 1, #old do if old[i][C.QUANTITY] > 0 then self:add(old[i]) end end
    return #self.records
end

function Virtual:validate()
    local Validator = require "PsychopatzCore/Inventory/Debug/PsychopatzInventoryValidator"
    return Validator.validate(self)
end

return Virtual
