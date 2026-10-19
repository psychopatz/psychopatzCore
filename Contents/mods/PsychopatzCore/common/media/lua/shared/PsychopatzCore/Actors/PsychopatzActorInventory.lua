local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = Inventory.Constants
local ItemRecord = Inventory.ItemRecord
local Types = Inventory.ItemTypeRegistry
local ItemUtil = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"

local ActorInventory = {}
local Ledger = {}
Ledger.__index = Ledger

ActorInventory.SCHEMA_VERSION = 1
ActorInventory.METADATA_SCHEMA = 2
ActorInventory.DEFAULT_STARTER_VERSION = 1

local DEFAULT_STARTERS = {
    { fullType = "Base.Tshirt", quantity = 1, wornSlot = "Torso_Upper" },
    { fullType = "Base.Trousers", quantity = 1, wornSlot = "Legs" },
    { fullType = "Base.Shoes", quantity = 1, wornSlot = "Shoes" },
}

local function clone(value)
    return ItemUtil.copy(value)
end

local function cloneRecord(record)
    return ItemRecord.clone(record)
end

local function cloneEntry(entry)
    local output = {}
    for key, value in pairs(entry or {}) do
        if key == "record" then output[key] = cloneRecord(value)
        else output[key] = clone(value) end
    end
    return output
end

local function text(value, fallback)
    if type(value) ~= "string" or value == "" then return fallback end
    return value
end

local function normalizeMode(mode)
    mode = tostring(mode or "FULL")
    if mode == "SEED_ONLY" or mode == "BASELINE_DELTA" or mode == "FULL" then
        return mode
    end
    return nil
end

local function defaultStarters()
    return clone(DEFAULT_STARTERS)
end

local function makeVirtualRecord(spec)
    local fullType = text(spec.fullType, nil)
    if not fullType then return nil, "full_type_required" end
    local typeId = Types.getId(fullType, true)
    if not typeId then return nil, "item_type_unavailable" end
    return ItemRecord.new(typeId, spec.quantity or 1, spec.flags or 0,
        spec.codecId or C.CODEC_GENERIC, spec.state or {},
        spec.unitWeight or 0, spec.stackDiscriminator)
end

local function normalizeRecord(spec)
    local record
    local reason
    if type(spec.record) == "table" then
        record = cloneRecord(spec.record)
    elseif spec.item ~= nil then
        record, reason = Inventory.encodeItem(spec.item, spec.quantity)
    else
        record, reason = makeVirtualRecord(spec)
    end
    if not record then return nil, reason or "item_record_required" end
    local valid
    valid, reason = ItemRecord.validate(record)
    if not valid then return nil, reason end
    return record
end

local function entryDefinition(entry)
    return {
        itemId = entry.itemId,
        fullType = entry.fullType,
        quantity = entry.record[C.QUANTITY],
        unitWeight = entry.record[C.UNIT_WEIGHT],
        containerId = entry.containerId,
        wornSlot = entry.wornSlot,
        equippedSlot = entry.equippedSlot,
        attachedSlot = entry.attachedSlot,
    }
end

local function containsID(items, itemId)
    for index = 1, #items do
        if items[index].itemId == itemId then return true end
    end
    return false
end

function Ledger:_find(itemId)
    for index = 1, #self.items do
        if self.items[index].itemId == itemId then return index, self.items[index] end
    end
    return nil, nil
end

function Ledger:_appendDelta(delta)
    self.deltas[#self.deltas + 1] = clone(delta)
end

function Ledger:_add(spec, trackDelta)
    spec = type(spec) == "table" and spec or {}
    local record, reason = normalizeRecord(spec)
    if not record then return nil, reason end
    local itemId = text(spec.itemId, nil)
    if not itemId then
        itemId = self.ownerActorId .. ":item:" .. tostring(self.nextItemOrdinal)
    end
    if containsID(self.items, itemId) then return nil, "duplicate_item_id" end
    self.nextItemOrdinal = self.nextItemOrdinal + 1
    local fullType = text(spec.fullType, Types.getFullType(record[C.TYPE_ID]))
    if not fullType then return nil, "full_type_required" end
    local entry = {
        itemId = itemId,
        fullType = fullType,
        record = record,
        containerId = text(spec.containerId, nil),
        wornSlot = text(spec.wornSlot, nil),
        equippedSlot = text(spec.equippedSlot, nil),
        attachedSlot = text(spec.attachedSlot, nil),
        metadata = clone(spec.metadata or {}),
    }
    self.items[#self.items + 1] = entry
    if trackDelta then self:_appendDelta({ op = "upsert", item = entry }) end
    return cloneEntry(entry)
end

function ActorInventory.new(options)
    options = type(options) == "table" and options or {}
    local ownerActorId = text(options.actorId, nil)
    if not ownerActorId then return nil, "actor_id_required" end
    local seed = options.seed
    if type(seed) ~= "string" and type(seed) ~= "number" then seed = ownerActorId end
    local starterVersion = tonumber(options.starterVersion)
        or ActorInventory.DEFAULT_STARTER_VERSION
    local self = setmetatable({
        schemaVersion = ActorInventory.SCHEMA_VERSION,
        metadataSchema = ActorInventory.METADATA_SCHEMA,
        ownerActorId = ownerActorId,
        seed = seed,
        starterVersion = starterVersion,
        revision = 0,
        nextItemOrdinal = 1,
        items = {},
        baselineItems = {},
        baselineDefinitions = {},
        deltas = {},
        equipment = { worn = {}, equipped = {}, attached = {} },
    }, Ledger)

    local starters = options.starterItems
    if starters == nil then starters = defaultStarters() end
    if type(starters) ~= "table" then return nil, "starter_items_required" end
    for index = 1, #starters do
        local starter = clone(starters[index])
        if not starter.itemId then
            starter.itemId = ownerActorId .. ":starter:" .. tostring(index)
        end
        local entry, reason = self:_add(starter, false)
        if not entry then return nil, reason end
        self.baselineDefinitions[#self.baselineDefinitions + 1] = entryDefinition(entry)
        if entry.wornSlot then self.equipment.worn[entry.wornSlot] = entry.itemId end
        if entry.equippedSlot then self.equipment.equipped[entry.equippedSlot] = entry.itemId end
        if entry.attachedSlot then self.equipment.attached[entry.attachedSlot] = entry.itemId end
    end
    self.baselineItems = self:List()
    self.revision = 1
    return self
end

function Ledger:List()
    local output = {}
    for index = 1, #self.items do output[index] = cloneEntry(self.items[index]) end
    table.sort(output, function(left, right) return left.itemId < right.itemId end)
    return output
end

function Ledger:Get(itemId)
    local _, entry = self:_find(itemId)
    if not entry then return nil, "item_not_found" end
    return cloneEntry(entry)
end

function Ledger:Count()
    return #self.items
end

function Ledger:Add(spec)
    local entry, reason = self:_add(spec, true)
    if not entry then return nil, reason end
    self.revision = self.revision + 1
    return entry
end

function Ledger:Update(itemId, patch)
    local index, entry = self:_find(itemId)
    if not entry then return nil, "item_not_found" end
    if type(patch) ~= "table" then return nil, "patch_required" end
    local nextEntry = cloneEntry(entry)
    if patch.record then
        local valid, reason = ItemRecord.validate(patch.record)
        if not valid then return nil, reason end
        nextEntry.record = cloneRecord(patch.record)
    end
    for _, key in ipairs({ "fullType", "containerId", "wornSlot",
        "equippedSlot", "attachedSlot", "metadata" }) do
        if patch[key] ~= nil then nextEntry[key] = clone(patch[key]) end
    end
    if nextEntry.fullType == "" or type(nextEntry.fullType) ~= "string" then
        return nil, "full_type_required"
    end
    self.items[index] = nextEntry
    self:_appendDelta({ op = "upsert", item = nextEntry })
    self.revision = self.revision + 1
    return cloneEntry(nextEntry)
end

function Ledger:Remove(itemId)
    local index = self:_find(itemId)
    if not index then return nil, "item_not_found" end
    for _, category in ipairs({ "worn", "equipped", "attached" }) do
        for slot, currentID in pairs(self.equipment[category]) do
            if currentID == itemId then self.equipment[category][slot] = nil end
        end
    end
    table.remove(self.items, index)
    self:_appendDelta({ op = "remove", itemId = itemId })
    self.revision = self.revision + 1
    return true
end

function Ledger:SetContainer(itemId, containerId)
    local _, entry = self:_find(itemId)
    if not entry then return nil, "item_not_found" end
    if containerId ~= nil and not self:_find(containerId) then
        return nil, "container_not_found"
    end
    return self:Update(itemId, { containerId = containerId })
end

function Ledger:SetEquipment(itemId, slot, category)
    category = category or "worn"
    if not self.equipment[category] then return nil, "equipment_category_invalid" end
    slot = text(slot, nil)
    if not slot then return nil, "equipment_slot_required" end
    local _, entry = self:_find(itemId)
    if not entry then return nil, "item_not_found" end
    local previous = self.equipment[category][slot]
    if previous and previous ~= itemId then
        local _, previousEntry = self:_find(previous)
        if previousEntry then
            if category == "worn" then previousEntry.wornSlot = nil end
            if category == "equipped" then previousEntry.equippedSlot = nil end
            if category == "attached" then previousEntry.attachedSlot = nil end
        end
    end
    for oldSlot, currentID in pairs(self.equipment[category]) do
        if currentID == itemId then self.equipment[category][oldSlot] = nil end
    end
    self.equipment[category][slot] = itemId
    if category == "worn" then entry.wornSlot = slot end
    if category == "equipped" then entry.equippedSlot = slot end
    if category == "attached" then entry.attachedSlot = slot end
    self:_appendDelta({ op = "upsert", item = entry })
    self:_appendDelta({ op = "equipment", equipment = self.equipment })
    self.revision = self.revision + 1
    return cloneEntry(entry)
end

function Ledger:Validate()
    if tonumber(self.schemaVersion) ~= ActorInventory.SCHEMA_VERSION
        or tonumber(self.metadataSchema) ~= ActorInventory.METADATA_SCHEMA
    then return false, "inventory_schema_mismatch" end
    if text(self.ownerActorId, nil) == nil
        or (type(self.seed) ~= "string" and type(self.seed) ~= "number")
    then
        return false, "inventory_identity_required"
    end
    local seen = {}
    for index = 1, #self.items do
        local entry = self.items[index]
        if type(entry) ~= "table" or text(entry.itemId, nil) == nil
            or seen[entry.itemId] or type(entry.fullType) ~= "string"
        then return false, "item_identity_invalid" end
        seen[entry.itemId] = true
        local valid, reason = ItemRecord.validate(entry.record)
        if not valid then return false, reason end
        if entry.containerId and not seen[entry.containerId] then
            local _, container = self:_find(entry.containerId)
            if not container then return false, "container_not_found" end
        end
    end
    for _, category in ipairs({ "worn", "equipped", "attached" }) do
        for slot, itemId in pairs(self.equipment[category] or {}) do
            if text(slot, nil) == nil or not seen[itemId] then
                return false, "equipment_reference_invalid"
            end
        end
    end
    return true
end

function Ledger:_seedCompatible()
    for index = 1, #self.items do
        local entry = self.items[index]
        if tonumber(entry.record[C.FLAGS]) ~= 0
            or #(entry.record[C.STATE] or {}) > 0
        then return false end
    end
    return true
end

function Ledger:ToPayload(mode)
    mode = normalizeMode(mode)
    if not mode then return nil, "inventory_mode_invalid" end
    local valid, reason = self:Validate()
    if not valid then return nil, reason end
    if mode == "SEED_ONLY" and not self:_seedCompatible() then
        return nil, "seed_only_not_compatible"
    end
    local payload = {
        schema = "PsychopatzCore.NPC.Inventory",
        schemaVersion = self.schemaVersion,
        metadataSchema = self.metadataSchema,
        ownerActorId = self.ownerActorId,
        seed = self.seed,
        starterVersion = self.starterVersion,
        mode = mode,
        revision = self.revision,
        equipment = clone(self.equipment),
    }
    if mode == "SEED_ONLY" then
        payload.baseline = { definitions = clone(self.baselineDefinitions) }
    elseif mode == "BASELINE_DELTA" then
        payload.baseline = { items = clone(self.baselineItems), definitions = clone(self.baselineDefinitions) }
        payload.deltas = clone(self.deltas)
    else
        payload.items = self:List()
        payload.baseline = { definitions = clone(self.baselineDefinitions) }
    end
    return payload
end

local function loadItems(self, items)
    self.items = {}
    self.nextItemOrdinal = 1
    for index = 1, #(items or {}) do
        local entry = cloneEntry(items[index])
        local valid, reason = ItemRecord.validate(entry.record)
        if not valid then return false, reason end
        if not entry.itemId or self:_find(entry.itemId) then return false, "duplicate_item_id" end
        self.items[#self.items + 1] = entry
        self.nextItemOrdinal = self.nextItemOrdinal + 1
    end
    return true
end

local function applyDelta(self, delta)
    if type(delta) ~= "table" then return false, "delta_invalid" end
    if delta.op == "upsert" then
        local item = delta.item
        local index = item and self:_find(item.itemId)
        if index then self.items[index] = cloneEntry(item)
        else
            self.items[#self.items + 1] = cloneEntry(item)
        end
        return true
    end
    if delta.op == "remove" then
        local index = self:_find(delta.itemId)
        if index then table.remove(self.items, index) end
        return true
    end
    if delta.op == "equipment" then
        self.equipment = clone(delta.equipment or {})
        return true
    end
    return false, "delta_operation_invalid"
end

function ActorInventory.Decode(payload)
    if type(payload) ~= "table"
        or payload.schema ~= "PsychopatzCore.NPC.Inventory"
        or tonumber(payload.schemaVersion) ~= ActorInventory.SCHEMA_VERSION
        or tonumber(payload.metadataSchema) ~= ActorInventory.METADATA_SCHEMA
    then return nil, "inventory_schema_mismatch" end
    local mode = normalizeMode(payload.mode)
    if not mode then return nil, "inventory_mode_invalid" end
    local baseline = type(payload.baseline) == "table" and payload.baseline or {}
    local options = {
        actorId = payload.ownerActorId,
        seed = payload.seed,
        starterVersion = payload.starterVersion,
        starterItems = mode == "SEED_ONLY" and baseline.definitions or {},
    }
    local self, reason = ActorInventory.new(options)
    if not self then return nil, reason end
    self.baselineDefinitions = clone(baseline.definitions or {})
    if mode == "SEED_ONLY" then
        if #self.items ~= #(baseline.definitions or {}) then
            return nil, "seed_baseline_mismatch"
        end
    elseif mode == "BASELINE_DELTA" then
        local ok
        ok, reason = loadItems(self, baseline.items)
        if not ok then return nil, reason end
        for index = 1, #(payload.deltas or {}) do
            ok, reason = applyDelta(self, payload.deltas[index])
            if not ok then return nil, reason end
        end
    else
        local ok
        ok, reason = loadItems(self, payload.items)
        if not ok then return nil, reason end
    end
    self.equipment = clone(payload.equipment or self.equipment)
    self.revision = tonumber(payload.revision) or 0
    local valid
    valid, reason = self:Validate()
    if not valid then return nil, reason end
    return self
end

function ActorInventory.ValidatePayload(payload)
    local ledger, reason = ActorInventory.Decode(payload)
    if not ledger then return false, reason end
    return ledger:Validate()
end

function ActorInventory.CreateForActor(actorId, seed, options)
    options = clone(options or {})
    options.actorId = actorId
    options.seed = seed
    return ActorInventory.new(options)
end

ActorInventory.Ledger = Ledger
ActorInventory.DefaultStarters = defaultStarters
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ActorInventory = ActorInventory
return ActorInventory
