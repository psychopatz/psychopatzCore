local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"

local Network = {}

function Network.encodeSnapshot(store, registryRevision)
    local records = {}
    for i = 1, #(store and store.records or {}) do records[i] = ItemRecord.clone(store.records[i]) end
    return { C.NETWORK_SCHEMA, C.RECORD_SCHEMA, registryRevision or 0,
        store and store.revision or 0, records }
end

function Network.encodeRegistryDelta(sinceRevision)
    return Types.getDelta(sinceRevision)
end

function Network.applyRegistryDelta(payload)
    return Types.applyDelta(payload)
end

function Network.decodeSnapshot(payload)
    if type(payload) ~= "table" or tonumber(payload[1]) ~= C.NETWORK_SCHEMA
        or tonumber(payload[2]) ~= C.RECORD_SCHEMA
    then
        return nil, "network_schema_mismatch"
    end
    return { registryRevision = tonumber(payload[3]) or 0,
        inventoryRevision = tonumber(payload[4]) or 0, records = payload[5] or {} }
end

return Network
