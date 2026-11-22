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

local function near(actual, expected, eps, label)
    if math.abs((actual or 0) - expected) > (eps or 1e-6) then
        error((label or "near") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

-- 1. Core shared init & capability wiring
PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedEvents = Core.ScopedWorldEvents
truthy(ScopedEvents ~= nil, "Core.ScopedWorldEvents should resolve via capability kernel")
eq(ScopedEvents.MAX_ACTIVE_EVENTS, 32, "MAX_ACTIVE_EVENTS")
eq(ScopedEvents.MAX_HISTORY, 64, "MAX_HISTORY")
ScopedEvents.Reset()

-- 2. SurvivorWorld community regionID normalization & backwards compatibility
local World = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local registry = assert(World.NewRegistry({ worldSeed = 42 }))
assert(registry:UpsertFaction({
    id = "faction_traders",
    name = "Traders",
    archetypeID = "trader",
}))
local commSouth = assert(registry:UpsertCommunity({
    id = "comm_rosewood",
    factionID = "faction_traders",
    name = "Rosewood Haven",
    regionID = "region_south",
    home = { x = 8000, y = 11500, z = 0, radius = 30 },
}))
eq(commSouth.regionID, "region_south", "community regionID preserved")

local commLegacy = assert(registry:UpsertCommunity({
    id = "comm_muldraugh",
    factionID = "faction_traders",
    name = "Muldraugh Outpost",
    home = { x = 10600, y = 10000, z = 0, radius = 30 },
}))
eq(commLegacy.regionID, nil, "legacy community without regionID remains nil")

assert(registry:UpsertFaction({
    id = "faction_other",
    name = "Northerners",
    archetypeID = "survivor",
}))
local commNorth = assert(registry:UpsertCommunity({
    id = "comm_riverside",
    factionID = "faction_other",
    name = "Riverside Camp",
    regionID = "region_north",
    home = { x = 6000, y = 5200, z = 0, radius = 25 },
}))
local communities = { commSouth, commLegacy, commNorth }

-- 3. Subscription hooks + source feedback-loop guard
local dtRegisteredSeen = {}
local allRegisteredSeen = {}
local expiredSeen = {}

ScopedEvents.OnEventRegistered(function(ev)
    dtRegisteredSeen[#dtRegisteredSeen + 1] = ev.eventID
end, { id = "dt_listener", excludeSource = "DynamicTrading" })

ScopedEvents.OnEventRegistered(function(ev)
    allRegisteredSeen[#allRegisteredSeen + 1] = ev.eventID
end, { id = "all_listener" })

ScopedEvents.OnEventExpired(function(ev, meta)
    expiredSeen[#expiredSeen + 1] = { id = ev.eventID, reason = meta.reason }
end, { id = "expiry_listener" })

-- 4. Register events across all 5 scopes
local evGlobal = assert(ScopedEvents.Register({
    eventID = "ev_global_winter",
    eventType = "harsh_cold",
    semanticTags = { "weather", "food" },
    scope = "global",
    startsAt = 10,
    endsAt = 100,
    severity = 0.6,
    source = "WorldSim",
    provenance = "environmental",
    effects = {
        foodAvailabilityPressure = 0.25,
        scavengingYieldMultiplier = 0.8,
        moralePressure = 0.2,
    },
    metadata = { wave = 1 },
}))
eq(evGlobal.scope, "global", "global scope")

local evRegion = assert(ScopedEvents.Register({
    eventID = "ev_region_drought",
    eventType = "supply_shortage",
    semanticTags = { "food", "trade_disruption" },
    scope = "region",
    scopeID = "region_south",
    startsAt = 15,
    endsAt = 50,
    severity = 0.8,
    source = "DynamicTrading",
    provenance = "public",
    effects = {
        foodAvailabilityPressure = 0.5,
        tradeScarcity = 0.6,
        caravanRisk = 0.3,
    },
}, { communities = communities }))
eq(#evRegion.affectedSettlements, 1, "region resolves affected settlements once")
eq(evRegion.affectedSettlements[1], "comm_rosewood", "rosewood resolved for region_south")

local evFaction = assert(ScopedEvents.Register({
    eventID = "ev_faction_raid",
    eventType = "bandit_harassment",
    semanticTags = { "hostile", "caravan" },
    scope = "faction",
    scopeID = "faction_traders",
    startsAt = 20,
    endsAt = 60,
    severity = 0.7,
    source = "ProjectHoomans",
    provenance = "faction",
    effects = {
        hostileActivityMultiplier = 1.5,
        travelRisk = 0.4,
        caravanRisk = 0.4,
    },
}, { communities = communities }))
eq(#evFaction.affectedSettlements, 2, "faction resolved 2 trader communities")

local evSettlement = assert(ScopedEvents.Register({
    eventID = "ev_settlement_flu",
    eventType = "medical_outbreak",
    semanticTags = { "medical" },
    scope = "settlement",
    scopeID = "comm_riverside",
    startsAt = 20,
    endsAt = 40,
    severity = 0.9,
    source = "ProjectHoomans",
    provenance = "witnessed",
    effects = {
        medicalDemand = 0.9,
        moralePressure = 0.4,
    },
}))
eq(evSettlement.affectedSettlements[1], "comm_riverside", "settlement self-indexed")

local evLocal = assert(ScopedEvents.Register({
    eventID = "ev_local_bridge",
    eventType = "bridge_collapse",
    semanticTags = { "travel" },
    scope = "local_area",
    scopeID = "area_rosewood_east",
    x = 8010,
    y = 11510,
    radius = 50,
    startsAt = 20,
    endsAt = 45,
    severity = 0.5,
    source = "WorldSim",
    provenance = "environmental",
    effects = {
        travelRisk = 0.35,
    },
}, { communities = communities }))
eq(evLocal.affectedSettlements[1], "comm_rosewood", "local_area resolved nearby settlement")

-- Feedback loop guard check: dt_listener excluded DynamicTrading's ev_region_drought
eq(#allRegisteredSeen, 5, "all_listener saw 5 registrations")
eq(#dtRegisteredSeen, 4, "dt_listener skipped DynamicTrading event")

-- 5. Scope-indexed queries (without scanning unrelated registries)
local rosewoodEvents = ScopedEvents.QueryActive({ settlementID = "comm_rosewood" }, 25)
-- Matches: evGlobal + evRegion + evFaction + evLocal = 4
eq(#rosewoodEvents, 4, "comm_rosewood active events count")

local riversideEvents = ScopedEvents.QueryActive({ settlementID = "comm_riverside" }, 25)
-- Matches: evGlobal + evSettlement = 2 (no region_south, no faction_traders, no local_area)
eq(#riversideEvents, 2, "comm_riverside active events count")

local southOnly = ScopedEvents.QueryActive({ regionID = "region_south", includeGlobal = false }, 25)
eq(#southOnly, 1, "region_south exact query")
eq(southOnly[1].eventID, "ev_region_drought", "region_south event match")

local factionOnly = ScopedEvents.QueryActive({ factionID = "faction_traders", includeGlobal = false }, 25)
eq(#factionOnly, 1, "faction_traders exact query")
eq(factionOnly[1].eventID, "ev_faction_raid", "faction_traders event match")

local localOnly = ScopedEvents.QueryActive({ localAreaID = "area_rosewood_east", includeGlobal = false }, 25)
eq(#localOnly, 1, "local_area exact query")
eq(localOnly[1].eventID, "ev_local_bridge", "local_area event match")

local globalOnly = ScopedEvents.QueryActive({ global = true }, 25)
eq(#globalOnly, 1, "global-only query")
eq(globalOnly[1].eventID, "ev_global_winter", "global event match")

local taggedMedical = ScopedEvents.QueryActive({ effectTag = "medicalDemand" }, 25)
eq(#taggedMedical, 1, "effectTag on effect key")
eq(taggedMedical[1].eventID, "ev_settlement_flu", "medicalDemand tag match")

local taggedTrade = ScopedEvents.QueryActive({ settlementID = "comm_rosewood", effectTag = "trade_disruption" }, 25)
eq(#taggedTrade, 1, "settlement + semanticTag intersection")
eq(taggedTrade[1].eventID, "ev_region_drought", "trade_disruption match")

-- 6. AggregateEffects + PruneExpired
local aggBefore = ScopedEvents.AggregateEffects({ settlementID = "comm_rosewood" }, 25)
eq(aggBefore.eventCount, 4, "aggBefore eventCount")
near(aggBefore.effects.foodAvailabilityPressure, 0.75, 1e-6, "foodAvailabilityPressure")
near(aggBefore.effects.scavengingYieldMultiplier, 0.8, 1e-6, "scavengingYieldMultiplier")
near(aggBefore.effects.hostileActivityMultiplier, 1.5, 1e-6, "hostileActivityMultiplier")
near(aggBefore.effects.travelRisk, 0.75, 1e-6, "travelRisk")
near(aggBefore.effects.tradeScarcity, 0.6, 1e-6, "tradeScarcity")
near(aggBefore.effects.caravanRisk, 0.7, 1e-6, "caravanRisk")
near(aggBefore.effects.moralePressure, 0.2, 1e-6, "moralePressure")
near(aggBefore.effects.medicalDemand, 0.0, 1e-6, "medicalDemand neutral")

-- Advance to hour 52: ev_settlement_flu (40), ev_local_bridge (45), ev_region_drought (50) expire!
local prunedCount = ScopedEvents.PruneExpired(52)
eq(prunedCount, 3, "prunedCount at hour 52")
eq(#expiredSeen, 3, "OnEventExpired notified for 3 expired events")

local aggAfter = ScopedEvents.AggregateEffects({ settlementID = "comm_rosewood" }, 52)
-- Remaining for comm_rosewood: evGlobal + evFaction = 2
eq(aggAfter.eventCount, 2, "aggAfter eventCount")
near(aggAfter.effects.foodAvailabilityPressure, 0.25, 1e-6, "expired region food pressure gone")
near(aggAfter.effects.tradeScarcity, 0.0, 1e-6, "expired tradeScarcity gone")
near(aggAfter.effects.caravanRisk, 0.4, 1e-6, "only faction caravanRisk remains")
near(aggAfter.effects.travelRisk, 0.4, 1e-6, "expired local bridge travelRisk gone")

-- 7. Bounded active & history capacities (MAX_ACTIVE_EVENTS = 32, MAX_HISTORY = 64)
local boundedReg = ScopedEvents.NewRegistry()
for i = 1, 75 do
    assert(boundedReg:Register({
        eventID = "bulk_" .. tostring(i),
        eventType = "bulk_test",
        scope = "global",
        startsAt = i,
        endsAt = i + 200,
        source = "Stress",
    }))
end
local stats = boundedReg:GetStats()
eq(stats.activeCount, 32, "active registry bounded at 32")
eq(stats.historyCount, 43, "history contains evicted events")
for i = 1, 30 do
    assert(boundedReg:Register({
        eventID = "bulk_hist_" .. tostring(i),
        eventType = "bulk_test",
        scope = "global",
        startsAt = 100 + i,
        source = "Stress",
    }))
end
eq(boundedReg:GetStats().activeCount, 32, "active remains 32")
eq(boundedReg:GetStats().historyCount, 64, "history bounded at 64")

-- 8. WorldKnowledge all 8 provenances & ResolveEpistemicStatus
local WKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"
local Fact = WKG.Fact
local AK = WKG.ActorKnowledge
WKG.Reset()

local knownProvenances = { "experienced", "witnessed", "faction", "public", "environmental" }
for _, prov in ipairs(knownProvenances) do
    local f = assert(Fact.New({
        kind = "test.known",
        eventID = prov,
        provenance = prov,
        occurredAt = 1,
    }), "known provenance " .. prov)
    eq(Fact.ResolveEpistemicStatus(f), "known", prov .. " -> known")
end

local uncertainProvenances = { "radio", "told", "inferred" }
for _, prov in ipairs(uncertainProvenances) do
    local f = assert(Fact.New({
        kind = "test.uncertain",
        eventID = prov,
        provenance = prov,
        occurredAt = 1,
    }), "uncertain provenance " .. prov)
    eq(Fact.ResolveEpistemicStatus(f), "uncertain", prov .. " -> uncertain")
end

local unknownFact = assert(Fact.New({
    kind = "test.unknown",
    eventID = "none",
    occurredAt = 1,
}))
eq(Fact.ResolveEpistemicStatus(unknownFact), "unknown", "missing provenance -> unknown")
eq(AK.ResolveEpistemicStatus(nil), "unknown", "nil fact -> unknown")

-- Rumor does not silently become objective fact, and cannot downgrade a known ref
local rumorFact = assert(WKG.Publish({
    producer = "test",
    kind = "market.rumor",
    eventID = "rumor1",
    occurredAt = 10,
    observedAt = 10,
    provenance = "told",
}))
eq(Fact.ResolveEpistemicStatus(rumorFact), "uncertain", "published told rumor is uncertain")

assert(WKG.Acquire("actor_a", rumorFact.factID, {
    authorized = true,
    provenance = "told",
    confidence = 0.9,
    learnedAt = 11,
}))
local refA = AK.Get(WKG.KnowledgeState, "actor_a", rumorFact.factID)
eq(AK.ResolveEpistemicStatus(rumorFact, refA), "uncertain", "actor_a told ref stays uncertain")

-- Corroborating with witnessed upgrades to known
assert(WKG.Acquire("actor_a", rumorFact.factID, {
    authorized = true,
    provenance = "witnessed",
    confidence = 0.7,
    learnedAt = 12,
}))
local refA2 = AK.Get(WKG.KnowledgeState, "actor_a", rumorFact.factID)
eq(refA2.provenance, "witnessed", "corroboration upgraded provenance to witnessed")
eq(AK.ResolveEpistemicStatus(rumorFact, refA2), "known", "corroborated fact becomes known")

-- Subsequent high-confidence rumor cannot downgrade known ref back to told
assert(WKG.Acquire("actor_a", rumorFact.factID, {
    authorized = true,
    provenance = "told",
    confidence = 0.99,
    learnedAt = 13,
}))
local refA3 = AK.Get(WKG.KnowledgeState, "actor_a", rumorFact.factID)
eq(refA3.provenance, "witnessed", "told rumor did not downgrade witnessed fact")
eq(AK.ResolveEpistemicStatus(rumorFact, refA3), "known", "status remains known")

print("psychopatz_scoped_world_events_smoke: PASS")
