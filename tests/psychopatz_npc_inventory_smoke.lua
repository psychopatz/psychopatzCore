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

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local C = Inventory.Constants

local function mockWeapon()
    local item = {
        fullType = "Base.Axe", condition = 7, conditionMax = 10,
        customName = "Found Axe", modData = { source = "p2" },
        weight = 2, ammo = 3, isWeapon = true,
    }
    function item:getFullType() return self.fullType end
    function item:getCondition() return self.condition end
    function item:getConditionMax() return self.conditionMax end
    function item:getCurrentAmmoCount() return self.ammo end
    function item:isCustomName() return self.customName ~= nil end
    function item:getName() return self.customName end
    function item:getModData() return self.modData end
    function item:getActualWeight() return self.weight end
    function item:getWeight() return self.weight end
    function item:isFavorite() return false end
    return item
end

local encoded = Inventory.encodeItem(mockWeapon())
truthy(encoded, "Core item codec encoded weapon")
equal(encoded[C.CODEC_ID], C.CODEC_WEAPON, "weapon codec selected")

local ledger, reason = ActorInventory.new({
    actorId = "pnc:test:inventory",
    seed = "inventory-seed",
    starterItems = {
        { itemId = "pnc:test:inventory:axe", fullType = "Base.Axe",
            record = encoded, equippedSlot = "primary" },
        { itemId = "pnc:test:inventory:bag", fullType = "Base.Bag",
            containerId = nil },
    },
})
truthy(ledger, reason)
truthy(ledger:SetContainer("pnc:test:inventory:axe",
    "pnc:test:inventory:bag"), "container reference")
local updated = mockWeapon()
updated.condition = 4
updated.customName = "Worn Axe"
local updatedRecord = Inventory.encodeItem(updated)
truthy(ledger:Update("pnc:test:inventory:axe", { record = updatedRecord }),
    "exact item state update")

local fullPayload = ledger:ToPayload("FULL")
truthy(fullPayload, "full payload")
equal(fullPayload.mode, "FULL", "full mode")
local fullReloaded, fullReason = ActorInventory.Decode(fullPayload)
truthy(fullReloaded, fullReason)
equal(fullReloaded:Get("pnc:test:inventory:axe").record[C.QUANTITY],
    encoded[C.QUANTITY], "full quantity")
equal(fullReloaded:Get("pnc:test:inventory:axe").record[C.STATE][1],
    updatedRecord[C.STATE][1], "full exact item state")
equal(fullReloaded:Get("pnc:test:inventory:axe").containerId,
    "pnc:test:inventory:bag", "full container reference")

local deltaPayload = ledger:ToPayload("BASELINE_DELTA")
truthy(deltaPayload, "baseline delta payload")
truthy(deltaPayload.baseline.items, "baseline item records")
truthy(deltaPayload.deltas, "item deltas")
local deltaReloaded, deltaReason = ActorInventory.Decode(deltaPayload)
truthy(deltaReloaded, deltaReason)
equal(deltaReloaded:Get("pnc:test:inventory:axe").record[C.STATE][1],
    updatedRecord[C.STATE][1], "delta exact item state")
equal(deltaReloaded:Get("pnc:test:inventory:axe").containerId,
    "pnc:test:inventory:bag", "delta container reference")

local deterministic = ActorInventory.new({
    actorId = "pnc:test:deterministic", seed = "starter-seed",
})
local seedPayload, seedReason = deterministic:ToPayload("SEED_ONLY")
truthy(seedPayload, seedReason)
local seedReloaded, seedReloadReason = ActorInventory.Decode(seedPayload)
truthy(seedReloaded, seedReloadReason)
local seedItems = deterministic:List()
local restoredSeedItems = seedReloaded:List()
equal(#restoredSeedItems, #seedItems, "seed starter count")
for index = 1, #seedItems do
    equal(restoredSeedItems[index].itemId, seedItems[index].itemId,
        "seed stable item id")
    equal(restoredSeedItems[index].fullType, seedItems[index].fullType,
        "seed stable full type")
    equal(restoredSeedItems[index].wornSlot, seedItems[index].wornSlot,
        "seed stable equipment slot")
end

local sparse = Json.Decode(Json.Encode({ 1, nil, nil, { attachment = true } }))
truthy(sparse, "sparse codec state decoded")
equal(sparse[4].attachment, true, "sparse codec state preserves tail")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
truthy(Actors.Inventory, "public actor inventory API")
local registry = Actors.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "pnc:test:actor-inventory",
    identitySeed = "actor-inventory-seed",
})
truthy(actor, actorReason)
truthy(actor.personalInventory, "actor personal inventory")
equal(actor.personalInventory.stock, nil, "inventory has no merchant stock")
equal(actor.personalInventory.budget, nil, "inventory has no merchant budget")
local actorSave = registry:Save()
local actorFresh = Actors.NewRegistry()
truthy(actorFresh:Load(actorSave), "actor inventory save reload")
local actorReloaded = actorFresh:Get("pnc:test:actor-inventory")
equal(Json.Encode(actorReloaded.personalInventory),
    Json.Encode(actor.personalInventory), "actor inventory payload parity")

print("psychopatz_npc_inventory_smoke: PASS")
