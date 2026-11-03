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

local ActorInventory =
    require "PsychopatzCore/Actors/PsychopatzActorInventory"

local ledger = assert(ActorInventory.CreateForActor(
    "inventory:compact:test", "inventory-compact-seed", {}))
local seedPayload, seedMode = ActorInventory.ToSmallestPayload(ledger)
truthy(seedPayload, seedMode)
equal(seedMode, "SEED_ONLY", "untouched baseline is seed-only")

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

print("psychopatz_actor_inventory_compaction_smoke: PASS")
