local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"

local Validator = {}

function Validator.validate(store)
    local findings = {}
    local stackKeys = {}
    local typeCounts = {}
    local weight = 0
    local record
    local valid
    local reason
    for i = 1, #(store and store.records or {}) do
        record = store.records[i]
        valid, reason = ItemRecord.validate(record)
        if not valid then findings[#findings + 1] = { code = reason, record = i } end
        if valid and not Types.getFullType(record[C.TYPE_ID]) then
            findings[#findings + 1] = { code = "missing_registered_type", record = i }
        end
        local key = valid and ItemRecord.stackKey(record) or nil
        if key and stackKeys[key] then
            findings[#findings + 1] = { code = "duplicate_mergeable_batch", record = i }
        elseif key then stackKeys[key] = true end
        if valid then
            typeCounts[record[C.TYPE_ID]] = (typeCounts[record[C.TYPE_ID]] or 0) + record[C.QUANTITY]
            weight = weight + record[C.UNIT_WEIGHT] * record[C.QUANTITY]
        end
    end
    if math.abs(weight - (tonumber(store and store.cachedWeight) or 0)) > 0.0001 then
        findings[#findings + 1] = { code = "weight_inconsistency", expected = weight,
            actual = store and store.cachedWeight }
    end
    for typeId, count in pairs(typeCounts) do
        if count ~= (store.typeCounts[typeId] or 0) then
            findings[#findings + 1] = { code = "type_index_inconsistency", typeId = typeId }
        end
    end
    for typeId, reserved in pairs(store and store.reservedByType or {}) do
        if reserved < 0 or reserved > (typeCounts[typeId] or 0) then
            findings[#findings + 1] = { code = "reservation_inconsistency", typeId = typeId }
        end
    end
    return #findings == 0, findings
end

function Validator.repair(store)
    store:compact()
    store:rebuildIndexes()
    return Validator.validate(store)
end

return Validator
