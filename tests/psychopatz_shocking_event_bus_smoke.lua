-- Smoke test for bounded spatial PsychopatzShockingEventBus and catalog isolation.

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

require "PsychopatzCore/Composition/PC_SharedComposition"
local Catalog = require "PsychopatzCore/Kernel/PC_CapabilityCatalog"
local Bus = PsychopatzCore.Require("core.shocking_events", "shocking_bus_smoke")
if type(Bus) ~= "table" then
    Bus = PsychopatzCore.ShockingEventBus
end

local function assertEqual(actual, expected, msg)
    if actual ~= expected then
        error((msg or "mismatch") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

Bus.Reset()

-- 1. Emit + spatial QueryNear + z-delta + radius + sort order
local deliveredCount = 0
local ownerFn = function(ev)
    if ev and ev.eventType == "shock.gunfire" then
        deliveredCount = deliveredCount + 1
    end
end
Bus.Subscribe("shock.gunfire", ownerFn, "smoke_owner")
-- Duplicate subscription for same listener + owner must remain idempotent
Bus.Subscribe("shock.gunfire", ownerFn, "smoke_owner")

local e1, s1 = Bus.Emit({
    eventType = "shock.gunfire",
    x = 100,
    y = 100,
    z = 0,
    radius = 24,
    severity = 80,
    dedupKey = "tile:100:100",
    at = 1000,
})
assert(e1 ~= nil and s1 == "emitted", "first emit must succeed")
assertEqual(deliveredCount, 1, "idempotent subscriber must receive once")

-- Dedup within window
local eDedup, sDedup = Bus.Emit({
    eventType = "shock.gunfire",
    x = 100,
    y = 100,
    z = 0,
    radius = 24,
    severity = 90,
    dedupKey = "tile:100:100",
    at = 1500,
})
assertEqual(eDedup.id, e1.id, "dedup must return existing event")
assertEqual(sDedup, "deduplicated", "dedup status expected")
assertEqual(e1.severity, 90, "dedup should keep max severity")
assertEqual(deliveredCount, 1, "dedup must not re-fire subscribers")

-- Another event in same area with lower severity
Bus.Emit({
    eventType = "shock.suspicious_sound",
    x = 105,
    y = 100,
    z = 0,
    radius = 20,
    severity = 40,
    at = 1600,
})

-- Far away event + wrong floor
Bus.Emit({
    eventType = "shock.gunfire",
    x = 300,
    y = 300,
    z = 0,
    radius = 20,
    severity = 95,
    at = 1600,
})
Bus.Emit({
    eventType = "shock.gunfire",
    x = 102,
    y = 100,
    z = 2,
    radius = 20,
    severity = 99,
    at = 1600,
})

local near = Bus.QueryNear(104, 100, 0, 25, { at = 1700 })
assertEqual(#near, 2, "expected 2 nearby same-floor shocking events")
assertEqual(near[1].eventType, "shock.gunfire", "higher severity must sort first")
assertEqual(near[2].eventType, "shock.suspicious_sound", "lower severity sorts second")

-- 2. Capacity eviction (MAX_EVENTS = 128) leaves zero spatial cell leaks
for i = 1, 160 do
    Bus.Emit({
        eventType = "shock.burst",
        x = 500 + (i % 10),
        y = 500,
        z = 0,
        radius = 12,
        severity = 30,
        at = 2000 + i,
    })
end
local stats = Bus.GetStats()
assertEqual(stats.activeCount, 128, "activeCount must remain capped at MAX_EVENTS=128")
assert(stats.evicted >= 30, "excess events must be evicted cleanly")
local farBurst = Bus.QueryNear(100, 100, 0, 30, { at = 3000 })
assertEqual(#farBurst, 0, "evicted early events must leave zero spatial bucket entries")

-- 3. TTL Expiry + Prune
local pruned = Bus.Prune(2000 + 20000)
assertEqual(pruned, 128, "Prune must expire all stale events after TTL")
assertEqual(Bus.GetStats().activeCount, 0, "all expired events pruned")

-- 4. Catalog exclusion from DynamicTrading packs
local function packContains(packId, capId)
    local pack = Catalog.packs[packId]
    assert(pack ~= nil, "missing pack " .. packId)
    for i = 1, #pack.capabilities do
        if pack.capabilities[i] == capId then return true end
    end
    return false
end
assertEqual(Catalog.descriptors["core.shocking_events"] ~= nil, true,
    "core.shocking_events descriptor must be registered")
assertEqual(packContains("pack.trading_common", "core.shocking_events"), false,
    "core.shocking_events must be excluded from pack.trading_common")
assertEqual(packContains("pack.trading_abstract", "core.shocking_events"), false,
    "core.shocking_events must be excluded from pack.trading_abstract")
assertEqual(packContains("pack.trading_hoomans", "core.shocking_events"), false,
    "core.shocking_events must be excluded from pack.trading_hoomans")

Bus.ClearOwner("smoke_owner")
assertEqual(Bus._listeners["shock.gunfire"], nil, "ClearOwner must remove listener cleanly")

print("psychopatz shocking event bus smoke: ok")
