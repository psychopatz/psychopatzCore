local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local VERSIONED_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
package.path = VERSIONED_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;" .. package.path

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "eq") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(val, label)
    if not val then error(label or "expected truthy") end
end

local function falsy(val, label)
    if val then error((label or "expected falsy") .. " got=" .. tostring(val)) end
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local Location = Core.WorldEventLocation
local WorldKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

truthy(ScopedEvents ~= nil, "Core.ScopedWorldEvents available")
truthy(Observer ~= nil, "Core.VanillaEventObserver available")
truthy(Location ~= nil, "Core.WorldEventLocation available")

ScopedEvents.Reset()
WorldKnowledge.Reset()
Observer.Reset()
Location.ClearProviders()
Core.Zones._byID = {}
Core.Zones._buckets = {}
Core.Zones._memberships = {}

-- 1. Location resolution fallback (quantized grid cell + local area)
local coarseLoc = Location.Resolve(8150, 11520, 0)
eq(coarseLoc.cellX, 27, "quantized cellX")
eq(coarseLoc.cellY, 38, "quantized cellY")
eq(coarseLoc.regionID, "region:cell_27_38", "coarse regionID")
eq(coarseLoc.localAreaID, "area:81_115", "coarse localAreaID")

-- 2. Zone resolution reuse
assert(Core.Zones.register({
    id = "zone_muldraugh_clinic",
    ownerType = "settlement",
    ownerId = "settlement:muldraugh",
    type = "clinic",
    geometry = {
        levels = {
            [0] = {
                rows = {
                    [10020] = { 10600, 10640 },
                },
            },
        },
    },
}))
local zoneLoc = Location.Resolve(10620.4, 10020.9, 0)
eq(zoneLoc.zoneID, "zone_muldraugh_clinic", "Core.Zones reused for point query")
eq(zoneLoc.settlementID, "settlement:muldraugh", "Zone settlement owner resolved")

-- 3. Adopter location provider takes precedence by priority
Location.RegisterProvider("hoomans_settlements", function(x, y, _z)
    if x >= 8000 and x <= 8200 and y >= 11400 and y <= 11600 then
        return {
            settlementID = "settlement:rosewood",
            factionID = "faction:rosewood",
            regionID = "region_south",
            label = "Rosewood Haven",
            kind = "settlement",
        }
    end
    return nil
end, 10)

local rosewoodLoc = Location.Resolve(8150, 11520, 0)
eq(rosewoodLoc.settlementID, "settlement:rosewood", "provider resolved settlement")
eq(rosewoodLoc.regionID, "region_south", "provider resolved region")
eq(rosewoodLoc.label, "Rosewood Haven", "provider resolved label")
local factLoc = Location.ToFactReference(rosewoodLoc)
eq(factLoc.id, "settlement:rosewood", "fact ref id")
eq(factLoc.region, "region_south", "fact ref region")
eq(factLoc.name, "Rosewood Haven", "fact ref name")

-- 4. Missing coordinates/scope fails closed
local noLoc, noLocErr = Location.Resolve(nil, nil, nil, {})
falsy(noLoc, "location resolve without coordinates or scope fails closed")
eq(noLocErr, "location_coordinates_or_scope_required", "location fail reason")

-- 5. Global scope restriction: allowed for utility, forbidden for non-utility
local badGlobal, badGlobalErr = Observer.Observe({
    semanticType = "ambient.gunfire",
    sourceKind = "ambient_meta",
    phase = "instant",
    retention = "historical",
    provenance = "environmental",
    scope = "global",
    occurredAt = 12,
})
falsy(badGlobal, "non-utility automatic global event rejected")
eq(badGlobalErr, "global_scope_forbidden_for_semantic_type", "global scope rejection reason")

local missingScope, missingScopeErr = Observer.Observe({
    semanticType = "ambient.gunfire",
    sourceKind = "ambient_meta",
    phase = "instant",
    retention = "historical",
    provenance = "environmental",
    occurredAt = 12,
})
falsy(missingScope, "non-utility without location or scope fails closed")
eq(missingScopeErr, "non_global_scope_required", "missing scope fail closed reason")

local utilityObs = assert(Observer.Observe({
    eventID = "core:utility:electricity_cutoff",
    factID = "fact:core:utility.electricity_cutoff:global",
    semanticType = "utility.electricity_cutoff",
    sourceKind = "utility",
    vanillaSourceID = "OnElectricityChanged",
    phase = "transition",
    retention = "historical",
    provenance = "public",
    scope = "global",
    occurredAt = 24,
    observedAt = 24,
    severity = 0.8,
}))
eq(utilityObs.scopedEvent.scope, "global", "utility allowed as global scoped event")
truthy(ScopedEvents.Get("core:utility:electricity_cutoff") ~= nil, "stored in ScopedWorldEvents")
truthy(WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, "fact:core:utility.electricity_cutoff:global") ~= nil,
    "stored in WorldKnowledge")

-- 6. Single-location resolution + routing into existing ScopedWorldEvents & WorldKnowledge
local gunfire = assert(Observer.Observe({
    semanticType = "ambient.gunfire",
    sourceKind = "ambient_meta",
    vanillaSourceID = "MetaShotgun1",
    phase = "instant",
    retention = "historical",
    provenance = "environmental",
    x = 8150,
    y = 11520,
    occurredAt = 30,
    observedAt = 30,
    durationHours = 6,
    factTTLHours = 24,
    cooldownHours = 0.5,
    severity = 0.7,
    effects = { travelRisk = 0.25 },
}))
eq(gunfire.observation.scope, "settlement", "gunfire scoped to settlement via single resolution")
eq(gunfire.observation.scopeID, "settlement:rosewood", "gunfire resolved scopeID")
eq(gunfire.fact.location.id, "settlement:rosewood", "fact carries resolved settlement reference")
eq(gunfire.fact.payload.vanillaSourceID, "MetaShotgun1", "exact vanilla source preserved")

-- Cooldown deduplication suppresses rapid duplicate in same bucket
local dupGunfire = assert(Observer.Observe({
    semanticType = "ambient.gunfire",
    sourceKind = "ambient_meta",
    vanillaSourceID = "MetaPistol1",
    phase = "instant",
    retention = "historical",
    provenance = "environmental",
    x = 8150,
    y = 11520,
    occurredAt = 30.1,
    observedAt = 30.1,
    cooldownHours = 0.5,
}))
eq(dupGunfire.status, "deduped", "cooldown deduped second gunfire in same bucket")
eq(dupGunfire.reason, "cooldown_active", "cooldown reason")

-- 7. Ephemeral events fire transient callback ONLY and write 0 ledger/scoped rows
local ephemeralSeen = 0
local ephToken = Observer.OnEphemeral(function(obs)
    ephemeralSeen = ephemeralSeen + 1
    eq(obs.semanticType, "ambient.dog_bark", "ephemeral observation type")
end, { id = "test_ephemeral" })
truthy(ephToken ~= nil, "ephemeral listener registered")

local beforeStats = ScopedEvents.GetStats()
local beforeFacts = #WorldKnowledge.Ledger.Query(WorldKnowledge.LedgerState, { max = 100 })
local bark = assert(Observer.Observe({
    semanticType = "ambient.dog_bark",
    sourceKind = "ambient_meta",
    vanillaSourceID = "MetaDogBark",
    phase = "instant",
    retention = "ephemeral",
    provenance = "environmental",
    x = 8150,
    y = 11520,
    occurredAt = 31,
}))
eq(bark.status, "ephemeral", "ephemeral status returned")
eq(ephemeralSeen, 1, "ephemeral listener notified")
eq(ScopedEvents.GetStats().activeCount, beforeStats.activeCount, "ephemeral adds 0 ScopedWorldEvents")
eq(#WorldKnowledge.Ledger.Query(WorldKnowledge.LedgerState, { max = 100 }), beforeFacts,
    "ephemeral adds 0 WorldKnowledge facts")

-- 8. Discovery fingerprint dedupe
local ambulance1 = assert(Observer.Observe({
    eventID = "core:discovery:ambulance:area:10_10",
    factID = "fact:core:discovery.vehicle_story.ambulance_crash:10_10",
    semanticType = "discovery.vehicle_story.ambulance_crash",
    sourceKind = "randomized_vehicle_story",
    vanillaSourceID = "RVSAmbulanceCrash",
    phase = "discovery",
    retention = "historical",
    provenance = "witnessed",
    fingerprint = "disc:ambulance:10_10",
    x = 3100,
    y = 3100,
    occurredAt = 35,
}))
eq(ambulance1.status, "registered", "first ambulance crash discovery registered")

local ambulance2 = assert(Observer.Observe({
    eventID = "core:discovery:ambulance:area:10_10",
    factID = "fact:core:discovery.vehicle_story.ambulance_crash:10_10",
    semanticType = "discovery.vehicle_story.ambulance_crash",
    sourceKind = "randomized_vehicle_story",
    vanillaSourceID = "RVSAmbulanceCrash",
    phase = "discovery",
    retention = "historical",
    provenance = "witnessed",
    fingerprint = "disc:ambulance:10_10",
    x = 3100,
    y = 3100,
    occurredAt = 36,
}))
eq(ambulance2.status, "deduped", "repeat ambulance discovery deduped")
eq(ambulance2.reason, "discovery_fingerprint_exists", "discovery fingerprint reason")

print("psychopatz_vanilla_event_observer_smoke: OK")
