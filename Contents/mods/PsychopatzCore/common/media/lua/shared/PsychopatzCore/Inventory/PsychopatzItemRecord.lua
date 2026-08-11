local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local Codecs = require "PsychopatzCore/Inventory/PsychopatzItemCodecRegistry"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"
require "PsychopatzCore/Inventory/Codecs/PsychopatzBuiltinItemCodecs"

local ItemRecord = {}

function ItemRecord.new(typeId, quantity, flags, codecId, state, unitWeight, stackDiscriminator)
    return {
        math.floor(tonumber(typeId) or 0),
        math.max(1, math.floor(tonumber(quantity) or 1)),
        math.max(0, math.floor(tonumber(flags) or 0)),
        math.floor(tonumber(codecId) or C.CODEC_FALLBACK),
        type(state) == "table" and state or {},
        math.max(0, tonumber(unitWeight) or 0),
        stackDiscriminator,
    }
end

function ItemRecord.clone(record, quantity)
    if type(record) ~= "table" then return nil end
    return ItemRecord.new(record[C.TYPE_ID], quantity or record[C.QUANTITY],
        record[C.FLAGS], record[C.CODEC_ID], Util.copy(record[C.STATE]),
        record[C.UNIT_WEIGHT], record[C.STACK_DISCRIMINATOR])
end

function ItemRecord.validate(record)
    if type(record) ~= "table" then return false, "record_not_table" end
    if math.floor(tonumber(record[C.TYPE_ID]) or 0) <= 0 then return false, "invalid_type_id" end
    if math.floor(tonumber(record[C.QUANTITY]) or 0) <= 0 then return false, "invalid_quantity" end
    local flags = math.floor(tonumber(record[C.FLAGS]) or -1)
    if flags < 0 or flags > C.KNOWN_FLAGS then return false, "invalid_state_flags" end
    if not Codecs.byId[math.floor(tonumber(record[C.CODEC_ID]) or 0)] then
        return false, "unknown_codec"
    end
    if type(record[C.STATE]) ~= "table" then return false, "invalid_state" end
    local discriminatorType = type(record[C.STACK_DISCRIMINATOR])
    if discriminatorType ~= "nil" and discriminatorType ~= "boolean"
        and discriminatorType ~= "string" and discriminatorType ~= "number"
        and discriminatorType ~= "table"
    then return false, "invalid_stack_discriminator" end
    return true
end

function ItemRecord.isBatchable(record)
    local flags = tonumber(record and record[C.FLAGS]) or 0
    local codecId = tonumber(record and record[C.CODEC_ID])
    if record and record[C.STACK_DISCRIMINATOR] == false then return false end
    if codecId == C.CODEC_FALLBACK or codecId == C.CODEC_CONTAINER then return false end
    if Util.hasFlag(flags, C.FLAG_MOD_DATA) or Util.hasFlag(flags, C.FLAG_CUSTOM_NAME) then return false end
    return true
end

function ItemRecord.stackKey(record)
    if not ItemRecord.isBatchable(record) then return nil end
    return tostring(record[C.TYPE_ID]) .. ":" .. tostring(record[C.CODEC_ID])
        .. ":" .. tostring(record[C.FLAGS]) .. ":" .. Util.canonical(record[C.STATE])
        .. ":" .. Util.canonical(record[C.STACK_DISCRIMINATOR])
end

function ItemRecord.encode(item, quantity)
    local fullType = Util.call(item, "getFullType") or item and (item.fullType or item.type)
    local codec
    local encoded
    local record
    if type(fullType) ~= "string" or fullType == "" then return nil, "missing_full_type" end
    codec = Codecs.resolve(item)
    if not codec then return nil, "codec_unavailable" end
    local ok, value = pcall(codec.encode, item, { encodeItem = ItemRecord.encode })
    if not ok or type(value) ~= "table" then return nil, "codec_encode_failed" end
    encoded = value
    local discriminator = encoded.batchable == false and false or nil
    if discriminator ~= false and type(codec.getStackKey) == "function" then
        local stackOk, stackValue = pcall(codec.getStackKey, item, encoded)
        if not stackOk then return nil, "codec_stack_key_failed" end
        discriminator = stackValue
    end
    record = ItemRecord.new(Types.getId(fullType), quantity or item.stack or 1,
        encoded.flags, codec.id, encoded.state, encoded.unitWeight, discriminator)
    Metrics.increment("encodeCount")
    return record
end

local function createItem(fullType, factory)
    if type(factory) == "function" then return factory(fullType) end
    if InventoryItemFactory then
        if InventoryItemFactory.CreateItem then return InventoryItemFactory.CreateItem(fullType) end
        if InventoryItemFactory.instanceItem then return InventoryItemFactory.instanceItem(fullType) end
    end
    return nil
end

function ItemRecord.decode(record, factory)
    local valid, reason = ItemRecord.validate(record)
    local fullType
    local item
    local codec
    local ok
    local decoded
    if not valid then return nil, reason end
    fullType = Types.getFullType(record[C.TYPE_ID])
    if not fullType then return nil, "unknown_type_id" end
    item = createItem(fullType, factory)
    if not item then
        Metrics.increment("missingItemTypes")
        return nil, "item_type_unavailable"
    end
    codec = Codecs.get(record[C.CODEC_ID])
    if not codec then return nil, "codec_unavailable" end
    ok, decoded, reason = pcall(codec.decode, item, record[C.FLAGS],
        record[C.STATE], {
            decodeItem = function(child) return ItemRecord.decode(child, factory) end,
            createItem = function(childType) return createItem(childType, factory) end,
        })
    if not ok or decoded == false then return nil, reason or "codec_decode_failed" end
    Metrics.increment("decodeCount")
    return item
end

PsychopatzCore.Inventory.ItemRecord = ItemRecord
return ItemRecord
