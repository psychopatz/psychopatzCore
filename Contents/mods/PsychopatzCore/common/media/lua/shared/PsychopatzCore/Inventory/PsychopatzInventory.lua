PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Inventory = PsychopatzCore.Inventory or {}

local Inventory = PsychopatzCore.Inventory
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local Codecs = require "PsychopatzCore/Inventory/PsychopatzItemCodecRegistry"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Virtual = require "PsychopatzCore/Inventory/PsychopatzVirtualInventory"
local Physical = require "PsychopatzCore/Inventory/PsychopatzPhysicalInventoryAdapter"
local Transaction = require "PsychopatzCore/Inventory/PsychopatzInventoryTransaction"
local Serializer = require "PsychopatzCore/Inventory/PsychopatzInventorySerializer"
local Network = require "PsychopatzCore/Inventory/PsychopatzInventoryNetworkCodec"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"

Inventory.SCHEMA_VERSION = 1
Inventory.ItemTypeRegistry = Types
Inventory.ItemCodecRegistry = Codecs
Inventory.ItemRecord = ItemRecord
Inventory.Serializer = Serializer
Inventory.NetworkCodec = Network
Inventory.Metrics = Metrics

function Inventory.getItemTypeId(fullType, create) return Types.getId(fullType, create) end
function Inventory.getItemFullType(typeId) return Types.getFullType(typeId) end
function Inventory.encodeItem(item, quantity) return ItemRecord.encode(item, quantity) end
function Inventory.decodeItem(record, factory) return ItemRecord.decode(record, factory) end
function Inventory.createVirtualInventory(options) return Virtual.new(options) end
function Inventory.wrapPhysicalInventory(container, options) return Physical.new(container, options) end
function Inventory.transfer(...) return Transaction.transfer(...) end
function Inventory.deposit(...) return Transaction.deposit(...) end
function Inventory.withdraw(...) return Transaction.withdraw(...) end
function Inventory.consume(...) return Transaction.consume(...) end
function Inventory.reserve(store, ...) return store:reserve(...) end
function Inventory.commitReservation(store, ...) return store:commitReservation(...) end
function Inventory.releaseReservation(store, ...) return store:releaseReservation(...) end
function Inventory.registerCodec(definition) return Codecs.register(definition) end

function Inventory.virtualize(container, options)
    local physical, reason = Physical.new(container, options)
    if not physical then return nil, reason end
    local store = Virtual.new(options)
    local iterator = physical:iterate()
    while true do
        local item = iterator()
        if not item then break end
        local record
        record, reason = ItemRecord.encode(item, 1)
        if not record then return nil, reason end
        local ok
        ok, reason = store:add(record)
        if not ok then return nil, reason end
    end
    return store
end

function Inventory.materialize(store, container, options)
    local physical, reason = Physical.new(container, options)
    if not physical then return false, reason end
    local added = {}
    for i = 1, #(store and store.records or {}) do
        local ok, result = physical:add(store.records[i])
        if not ok then
            for j = #added, 1, -1 do physical:_nativeRemove(added[j]) end
            return false, result
        end
        for j = 1, #result do added[#added + 1] = result[j] end
    end
    return true, added
end

local function initialize()
    Types.initializeWorld()
end

if Events and Events.OnInitGlobalModData and Events.OnInitGlobalModData.Add then
    Events.OnInitGlobalModData.Add(initialize)
end

return Inventory
