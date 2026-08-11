local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function list(values)
    return { size = function() return #values end,
        get = function(_, index) return values[index + 1] end }
end

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Types = Inventory.ItemTypeRegistry
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

Types.load(nil)
Types.scan({ "Base.Nails", "Base.Apple", "Base.Axe" })
equal(Types.getItemFullType, nil, "registry API remains encapsulated")
equal(Types.getId("Base.Apple", false), 1, "deterministic initial id")
equal(Types.getId("Base.Axe", false), 2, "sorted initial ids")
equal(Types.getId("Base.Nails", false), 3, "sorted final id")
local saved = Types.getData()
Types.load(saved)
Types.scan({ "Base.Nails", "Base.Axe", "Mod.Rifle" })
equal(Types.getId("Base.Apple", false), 1, "removed type remains reserved")
equal(Types.getId("Mod.Rifle", false), 4, "new type appends")
Types.scan({ "Base.Apple", "Base.Nails", "Base.Axe", "Mod.Rifle" })
equal(Types.getId("Base.Apple", false), 1, "returning type keeps id")

local function makeItem(fullType, options)
    options = options or {}
    local item = {
        fullType = fullType, condition = options.condition,
        conditionMax = options.conditionMax or options.condition,
        usedDelta = options.usedDelta, favorite = options.favorite,
        customName = options.customName, modData = options.modData or {},
        weight = options.weight or 1, age = options.age,
        cooked = options.cooked, ammo = options.ammo,
        wetness = options.wetness,
        parts = options.parts or {},
    }
    function item:getFullType() return self.fullType end
    function item:getCondition() return self.condition end
    function item:getConditionMax() return self.conditionMax end
    function item:setCondition(value) self.condition = value end
    function item:getUsedDelta() return self.usedDelta end
    function item:setUsedDelta(value) self.usedDelta = value end
    function item:IsDrainable() return self.usedDelta ~= nil end
    function item:isFavorite() return self.favorite == true end
    function item:setFavorite(value) self.favorite = value end
    function item:isCustomName() return self.customName ~= nil end
    function item:getName() return self.customName end
    function item:setName(value) self.customName = value end
    function item:getModData() return self.modData end
    function item:getActualWeight() return self.weight end
    function item:getWeight() return self.weight end
    function item:setActualWeight(value) self.weight = value end
    function item:getAllWeaponParts() return list(self.parts) end
    function item:attachWeaponPart(part) self.parts[#self.parts + 1] = part end
    if options.container then
        item.nested = options.container
        function item:getInventory() return self.nested end
    end
    if options.food then
        item.isFood = true
        function item:getAge() return self.age end
        function item:setAge(value) self.age = value end
        function item:isCooked() return self.cooked == true end
        function item:setCooked(value) self.cooked = value end
        function item:isBurnt() return false end
        function item:setBurnt(value) self.burnt = value end
        function item:isFrozen() return false end
        function item:setFrozen(value) self.frozen = value end
    end
    if options.weapon then
        item.isWeapon = true
        function item:getCurrentAmmoCount() return self.ammo end
        function item:setCurrentAmmoCount(value) self.ammo = value end
    end
    if options.clothing then
        item.isClothing = true
        function item:getWetness() return self.wetness end
        function item:setWetness(value) self.wetness = value end
        function item:getBloodlevel() return self.bloodLevel end
        function item:setBloodLevel(value) self.bloodLevel = value end
        function item:getDirtyness() return self.dirtyness end
        function item:setDirtyness(value) self.dirtyness = value end
    end
    return item
end

local function factory(fullType)
    if fullType == "Base.Nails" then return makeItem(fullType, { condition = 10, weight = 0.01 }) end
    if fullType == "Base.Apple" then return makeItem(fullType, { food = true, condition = 10 }) end
    if fullType == "Base.Axe" then return makeItem(fullType, { weapon = true, condition = 10, ammo = 0 }) end
    if fullType == "Base.WaterBottle" then
        return makeItem(fullType, { condition = 10, usedDelta = 1 })
    end
    if fullType == "Base.Shirt" then
        return makeItem(fullType, { condition = 10, clothing = true })
    end
    if fullType == "Base.Bag" then
        local nestedValues = {}
        local nested = { getItems = function() return list(nestedValues) end,
            AddItem = function(_, value) nestedValues[#nestedValues + 1] = value return value end }
        return makeItem(fullType, { condition = 10, container = nested })
    end
    return makeItem(fullType, { condition = 10 })
end

local store = Inventory.createVirtualInventory({ maxWeight = 100000 })
local nails = makeItem("Base.Nails", { condition = 10, weight = 0.01 })
truthy(store:add(nails, 9000), "add nails")
truthy(store:add(nails, 282), "batch nails")
equal(store:getRecordCount(), 1, "identical records batch")
equal(store:count("Base.Nails"), 9282, "logical count")
equal(store:getLogicalItemCount(), 9282, "logical item count")

local axeGood = makeItem("Base.Axe", { weapon = true, condition = 10, conditionMax = 10, ammo = 0 })
local axeWorn = makeItem("Base.Axe", { weapon = true, condition = 7,
    conditionMax = 10, ammo = 0, parts = { makeItem("Base.Scope") } })
truthy(store:add(axeGood), "add good axe")
truthy(store:add(axeWorn), "add worn axe")
equal(store:getRecordCount(), 3, "different condition remains separate")

local unknownA = makeItem("Mod.Rifle", { condition = 5, modData = { serial = "A" } })
local unknownB = makeItem("Mod.Rifle", { condition = 5, modData = { serial = "B" } })
truthy(store:add(unknownA), "add unknown A")
truthy(store:add(unknownB), "add unknown B")
equal(store:getRecordCount(), 5, "unknown modded items do not merge")

local token = store:reserve("Base.Nails", 3, "job-a")
truthy(token, "reserve")
equal(store:count("Base.Nails"), 9279, "reservation lowers available count")
truthy(store:releaseReservation(token), "release reservation")
equal(store:count("Base.Nails"), 9282, "release restores availability")
token = store:reserve("Base.Nails", 2, "job-b")
truthy(store:commitReservation(token), "commit reservation")
equal(store:count("Base.Nails"), 9280, "commit consumes")

local destination = Inventory.createVirtualInventory()
truthy(Inventory.transfer(store, destination, "Base.Nails", 80,
    { skipAuthorityCheck = true }), "atomic transfer")
equal(destination:count("Base.Nails"), 80, "destination transfer count")
equal(store:count("Base.Nails"), 9200, "source transfer count")
local failing = { add = function() return false, "rejected" end }
local before = store:count("Base.Nails")
local ok = Inventory.transfer(store, failing, "Base.Nails", 5,
    { skipAuthorityCheck = true })
equal(ok, false, "failed transfer")
equal(store:count("Base.Nails"), before, "failed transfer rolls back")

local payload = Inventory.Serializer.serialize(store)
equal(payload[1], C.VIRTUAL_SCHEMA, "virtual schema")
local loaded = Inventory.Serializer.deserialize(payload)
truthy(loaded, "deserialize")
equal(loaded:count("Base.Nails"), store:count("Base.Nails"), "save load count")
truthy(loaded:validate(), "loaded inventory validates")

local apple = makeItem("Base.Apple", { food = true, condition = 8,
    conditionMax = 10, age = 2.5, cooked = true, favorite = true })
local Tester = require "PsychopatzCore/Inventory/Debug/PsychopatzInventoryRoundTripTester"
truthy(Tester.test(apple, factory), "food round trip")
truthy(Tester.test(axeWorn, factory), "weapon round trip")
truthy(Tester.test(makeItem("Base.Nails", { condition = 10, weight = 0.01 }), factory),
    "generic round trip")
truthy(Tester.test(makeItem("Base.WaterBottle", {
    condition = 10, usedDelta = 0.35 }), factory), "drainable round trip")
truthy(Tester.test(makeItem("Base.Shirt", {
    condition = 8, conditionMax = 10, clothing = true,
    wetness = 12, bloodLevel = 3 }), factory), "clothing round trip")
truthy(Tester.test(unknownA, factory), "fallback modded round trip")
local bagValues = { makeItem("Base.Nails", { condition = 10, weight = 0.01 }) }
local bagContainer = { getItems = function() return list(bagValues) end,
    AddItem = function(_, value) bagValues[#bagValues + 1] = value return value end }
local bag = makeItem("Base.Bag", { condition = 10, container = bagContainer })
truthy(Tester.test(bag, factory), "nested container round trip")

local customCodecOk = Inventory.registerCodec({
    id = 1001, name = "smoke_charge", priority = 200,
    matches = function(item) return item.charge ~= nil end,
    encode = function(item)
        return { flags = 0, state = { item.charge }, unitWeight = 1,
            batchable = true }
    end,
    decode = function(item, _, state) item.charge = state[1] return true end,
    getStackKey = function(item) return item.charge end,
})
truthy(customCodecOk, "custom codec registration")
local charged = makeItem("Mod.PowerCell", { condition = 10 })
charged.charge = 75
local chargedRecord = Inventory.encodeItem(charged)
equal(chargedRecord[C.CODEC_ID], 1001, "custom codec selection")
equal(chargedRecord[C.STACK_DISCRIMINATOR], 75, "custom codec stack key")

local registryDelta = Inventory.NetworkCodec.encodeRegistryDelta(Types.getData().revision - 1)
equal(#registryDelta.entries, 1, "incremental registry delta")

local physicalItems = { apple, axeWorn }
local container = {}
function container:getItems() return list(physicalItems) end
function container:AddItem(item) physicalItems[#physicalItems + 1] = item return item end
function container:DoRemoveItem(item)
    for i = #physicalItems, 1, -1 do if physicalItems[i] == item then table.remove(physicalItems, i) return end end
end
local virtualized = Inventory.virtualize(container)
truthy(virtualized, "physical to virtual")
equal(virtualized:getLogicalItemCount(), 2, "physical conversion count")
local destinationItems = {}
local destinationContainer = {}
function destinationContainer:getItems() return list(destinationItems) end
function destinationContainer:AddItem(item) destinationItems[#destinationItems + 1] = item return item end
function destinationContainer:DoRemoveItem(item)
    for i = #destinationItems, 1, -1 do if destinationItems[i] == item then table.remove(destinationItems, i) return end end
end
truthy(Inventory.materialize(virtualized, destinationContainer, { factory = factory }),
    "virtual to physical")
equal(#destinationItems, 2, "materialized item count")

print("psychopatz_inventory_framework_smoke: PASS")
