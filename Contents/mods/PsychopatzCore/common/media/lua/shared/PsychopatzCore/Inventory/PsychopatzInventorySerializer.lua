local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Virtual = require "PsychopatzCore/Inventory/PsychopatzVirtualInventory"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"

local Serializer = {}

function Serializer.serialize(store)
    if not store or type(store.records) ~= "table" then return nil, "virtual_store_required" end
    local records = {}
    for i = 1, #store.records do records[i] = ItemRecord.clone(store.records[i]) end
    Metrics.gauge("serializedRecordCount", #records)
    return {
        C.VIRTUAL_SCHEMA,
        C.RECORD_SCHEMA,
        math.max(0, math.floor(tonumber(store.revision) or 0)),
        tonumber(store.maxWeight),
        records,
    }
end

function Serializer.deserialize(payload, options)
    if type(payload) ~= "table" or tonumber(payload[1]) ~= C.VIRTUAL_SCHEMA
        or tonumber(payload[2]) ~= C.RECORD_SCHEMA
    then
        return nil, "virtual_inventory_schema_mismatch"
    end
    options = options or {}
    options.revision = tonumber(payload[3]) or 0
    options.maxWeight = tonumber(payload[4])
    local store = Virtual.new(options)
    for i = 1, #(payload[5] or {}) do
        local ok, reason = store:add(payload[5][i])
        if not ok then return nil, reason end
    end
    store.revision = options.revision
    return store
end

return Serializer
