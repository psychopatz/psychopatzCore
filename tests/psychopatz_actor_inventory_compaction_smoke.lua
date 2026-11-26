local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.layerRoot("common_shared")
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

local ActorInventory =
    require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local ledger = assert(ActorInventory.CreateForActor(
    "inventory:compact:test", "inventory-compact-seed", {}))
local seedPayload, seedMode = ActorInventory.ToSmallestPayload(ledger)
truthy(seedPayload, seedMode)
equal(seedMode, "SEED_ONLY", "untouched baseline is seed-only")
local seedWire = assert(Json.Encode(seedPayload))
local seeded = assert(ActorInventory.Decode(assert(Json.Decode(seedWire))))
equal(seeded:Get(seedPayload.ownerActorId .. ":starter:1").wornSlot,
    "Torso_Upper", "seed-only outfit still reconstructs")
equal(assert(Json.Encode(assert(seeded:ToPayload("SEED_ONLY")))), seedWire,
    "untouched outfit retains the same seed-only bytes")

local added = assert(ledger:Add({
    fullType = "Base.Bandage",
    itemId = "inventory:compact:test:item:10",
    metadata = { source = "found" },
}))
truthy(added, "durable item added")
local deltaPayload, deltaMode = ActorInventory.ToSmallestPayload(ledger)
truthy(deltaPayload, deltaMode)
equal(deltaMode, "BASELINE_DELTA",
    "added item cannot collapse to seed-only")

local decoded = assert(ActorInventory.Decode(deltaPayload))
truthy(decoded:Get("inventory:compact:test:item:10"),
    "first delta survives decode")
local second = assert(decoded:Add({
    fullType = "Base.WaterBottleFull",
    metadata = { source = "second" },
}))
truthy(second, "second post-decode item added")
local secondPayload, secondMode = ActorInventory.ToSmallestPayload(decoded)
truthy(secondPayload, secondMode)
equal(secondMode, "BASELINE_DELTA",
    "decoded delta remains delta after mutation")

local reloaded = assert(ActorInventory.Decode(secondPayload))
truthy(reloaded:Get("inventory:compact:test:item:10"),
    "first delta survives second encode")
truthy(reloaded:Get(second.itemId),
    "second delta survives second encode")

-- Removing all durable additions returns exactly to the deterministic
-- baseline, so the ledger is again safe to collapse to SEED_ONLY.
truthy(reloaded:Remove("inventory:compact:test:item:10"),
    "remove first added item")
truthy(reloaded:Remove(second.itemId),
    "remove second added item")
local collapsed, collapsedMode =
    ActorInventory.ToSmallestPayload(reloaded)
truthy(collapsed, collapsedMode)
equal(collapsedMode, "SEED_ONLY",
    "exact baseline can collapse after prior deltas")

local shirt = assert(ledger:Add({ fullType = "Base.Shirt_FormalWhite" }))
local hammer = assert(ledger:Add({ fullType = "Base.Hammer" }))
local radio = assert(ledger:Add({ fullType = "Base.WalkieTalkie1" }))
assert(ledger:SetEquipmentState({
    worn = { Shirt = shirt.itemId },
    equipped = { primary = hammer.itemId },
    attached = { ["Walkie Belt Right"] = radio.itemId },
}))
local outfitPayload, outfitMode = ActorInventory.ToSmallestPayload(ledger)
equal(outfitMode, "BASELINE_DELTA", "outfit changes retain the compact codec")
local wire = assert(Json.Encode(outfitPayload))
local outfit = assert(ActorInventory.Decode(assert(Json.Decode(wire))))
equal(outfit:Get(shirt.itemId).wornSlot, "Shirt", "worn slot survives replay")
equal(outfit:Get(hammer.itemId).equippedSlot, "primary", "held slot survives replay")
equal(outfit:Get(radio.itemId).attachedSlot, "Walkie Belt Right",
    "attachment slot survives replay")
equal(outfit.revision, ledger.revision, "decode does not advance the revision")
equal(assert(Json.Encode(assert(outfit:ToPayload("BASELINE_DELTA")))), wire,
    "decode and re-encode preserve compact bytes")
for _, entry in ipairs(outfit:List()) do
    if entry.itemId ~= shirt.itemId then
        equal(entry.wornSlot, nil, "cleared starter outfit stays unequipped")
    end
end

print("psychopatz_actor_inventory_compaction_smoke: PASS")
