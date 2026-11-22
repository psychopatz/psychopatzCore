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

-- Mock PZ Events + ModData + GameTime before initializing PsychopatzCore
local mockClockHours = 40
local mockModDataStore = {}
local hookHandlers = { OnInitGlobalModData = {}, OnSave = {} }

ModData = {
    getOrCreate = function(key)
        mockModDataStore[key] = mockModDataStore[key] or {}
        return mockModDataStore[key]
    end,
    get = function(key)
        return mockModDataStore[key]
    end,
}

Events = {
    OnInitGlobalModData = {
        Add = function(fn) hookHandlers.OnInitGlobalModData[#hookHandlers.OnInitGlobalModData + 1] = fn end,
    },
    OnSave = {
        Add = function(fn) hookHandlers.OnSave[#hookHandlers.OnSave + 1] = fn end,
    },
}

function getGameTime()
    return {
        getWorldAgeHours = function() return mockClockHours end,
    }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local WorldKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

ScopedEvents.Reset()
Observer.Reset()
WorldKnowledge.Reset()

-- Persistence hooks should have installed automatically on module load
truthy(#hookHandlers.OnSave >= 1, "OnSave persistence hook installed")
truthy(#hookHandlers.OnInitGlobalModData >= 1, "OnInitGlobalModData persistence hook installed")

-- 1. Seed utility watermark, active episode, expiring short event, and discovery fingerprint
Observer.SetUtilityState("electricity", { powerOn = false, cutoffEmitted = true, changedAt = 20 })
Observer.SetHelicopterState({ active = true, episodeSeq = 7, lastAreaID = "area:80_115" })

assert(Observer.Observe({
    eventID = "core:utility:electricity_cutoff",
    factID = "fact:core:utility.electricity_cutoff:global",
    semanticType = "utility.electricity_cutoff",
    sourceKind = "utility",
    phase = "transition",
    retention = "historical",
    provenance = "public",
    scope = "global",
    occurredAt = 20,
    observedAt = 20,
}))

assert(Observer.Observe({
    eventID = "core:storm:episode:1",
    factID = "fact:core:weather.severe_storm:1",
    semanticType = "weather.severe_storm",
    sourceKind = "weather",
    phase = "start",
    retention = "historical",
    provenance = "environmental",
    x = 8100,
    y = 11500,
    occurredAt = 35,
    observedAt = 35,
    durationHours = 48, -- ends at 83 (stays active at 60)
}))

assert(Observer.Observe({
    eventID = "core:ambient:gunfire:old",
    factID = "fact:core:ambient.gunfire:old",
    semanticType = "ambient.gunfire",
    sourceKind = "ambient_meta",
    phase = "instant",
    retention = "historical",
    provenance = "environmental",
    x = 8100,
    y = 11500,
    occurredAt = 38,
    observedAt = 38,
    durationHours = 6,   -- ends at 44 (expired by 60)
    factTTLHours = 12,   -- fact expires at 50
}))

assert(Observer.Observe({
    eventID = "core:discovery:ambulance:area:80_115",
    factID = "fact:core:discovery.vehicle_story.ambulance_crash:80_115",
    semanticType = "discovery.vehicle_story.ambulance_crash",
    sourceKind = "randomized_vehicle_story",
    vanillaSourceID = "RVSAmbulanceCrash",
    phase = "discovery",
    retention = "historical",
    provenance = "witnessed",
    fingerprint = "disc:ambulance:80_115",
    x = 8050,
    y = 11550,
    occurredAt = 39,
    observedAt = 39,
}))

-- 2. Trigger OnSave hook and save WorldKnowledge payload
for i = 1, #hookHandlers.OnSave do hookHandlers.OnSave[i]() end
local savedWkgPayload = WorldKnowledge.ToPayload()
truthy(mockModDataStore[ScopedEvents.MODDATA_KEY] ~= nil, "ModData root populated")

-- 3. Simulate full server/session restart at t = 60 hours
mockClockHours = 60
ScopedEvents.Reset()
Observer.Reset()
WorldKnowledge.Reset()

local stateLoadedSnapshots = {}
ScopedEvents.OnStateLoaded(function(snapshot, meta)
    stateLoadedSnapshots[#stateLoadedSnapshots + 1] = {
        snapshot = snapshot,
        meta = meta,
    }
end, { id = "dt_reconcile_listener" })

for i = 1, #hookHandlers.OnInitGlobalModData do
    hookHandlers.OnInitGlobalModData[i]()
end
local okWkg, wkgErr = WorldKnowledge.FromPayload(savedWkgPayload, { now = mockClockHours })
truthy(okWkg, wkgErr or "WorldKnowledge FromPayload ok")

-- Verify active vs expired event separation after reload
truthy(ScopedEvents.Get("core:utility:electricity_cutoff") ~= nil, "global utility event survives reload")
truthy(ScopedEvents.Get("core:storm:episode:1") ~= nil, "ongoing storm episode survives reload")
falsy(ScopedEvents.Get("core:ambient:gunfire:old"), "expired gunfire does NOT reactivate on reload")

-- Verify OnStateLoaded notified listeners with reconciled active events
eq(#stateLoadedSnapshots, 1, "OnStateLoaded fired once on reload")
eq(stateLoadedSnapshots[1].meta.nowHours, 60, "OnStateLoaded carries reload clock")

-- Verify WorldKnowledge retention pruning on load
truthy(WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, "fact:core:utility.electricity_cutoff:global") ~= nil,
    "historical utility fact retained")
truthy(WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, "fact:core:discovery.vehicle_story.ambulance_crash:80_115") ~= nil,
    "historical ambulance discovery retained")
falsy(WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, "fact:core:ambient.gunfire:old"),
    "expired short-lived gunfire fact pruned on load")

-- Verify observer watermarks, helicopter episode state, and discovery dedupe survived reload
eq(Observer.GetUtilityState("electricity").cutoffEmitted, true, "utility watermark survives reload")
eq(Observer.GetHelicopterState().episodeSeq, 7, "helicopter episode seq survives reload")
truthy(Observer.HasDiscoveryFingerprint("disc:ambulance:80_115"), "discovery fingerprint survives reload")

local dupDiscovery = assert(Observer.Observe({
    eventID = "core:discovery:ambulance:area:80_115",
    factID = "fact:core:discovery.vehicle_story.ambulance_crash:80_115",
    semanticType = "discovery.vehicle_story.ambulance_crash",
    sourceKind = "randomized_vehicle_story",
    vanillaSourceID = "RVSAmbulanceCrash",
    phase = "discovery",
    retention = "historical",
    provenance = "witnessed",
    fingerprint = "disc:ambulance:80_115",
    x = 8050,
    y = 11550,
    occurredAt = 61,
    observedAt = 61,
}))
eq(dupDiscovery.status, "deduped", "story discovery remains deduped after save/reload")

-- 4. Verify caps remain strictly enforced when loading oversized payloads
local oversizedScoped = {
    schema = ScopedEvents.SCHEMA,
    schemaVersion = ScopedEvents.SCHEMA_VERSION,
    events = {},
    history = {},
}
for i = 1, 50 do
    oversizedScoped.events[i] = {
        eventID = "ov_ev_" .. i,
        eventType = "storm",
        scope = "local_area",
        scopeID = "area:" .. i .. "_0",
        startsAt = i,
        endsAt = 1000,
    }
end
for i = 1, 90 do
    oversizedScoped.history[i] = {
        eventID = "ov_hist_" .. i,
        eventType = "storm",
        scope = "local_area",
        scopeID = "area:0_" .. i,
        startsAt = i,
    }
end
assert(ScopedEvents.LoadPayload(oversizedScoped, { nowHours = 100, notify = false }))
local stats = ScopedEvents.GetStats()
eq(stats.activeCount, ScopedEvents.MAX_ACTIVE_EVENTS, "active events bounded at 32 after oversized load")
truthy(stats.historyCount <= ScopedEvents.MAX_HISTORY, "history bounded at <= 64 after oversized load")

local oversizedObserver = {
    schema = Observer.SCHEMA,
    schemaVersion = Observer.SCHEMA_VERSION,
    utilityWatermarks = {},
    helicopterState = { active = false, episodeSeq = 1 },
    discoveries = {},
    cooldowns = {},
}
for i = 1, 320 do
    oversizedObserver.discoveries[i] = "fp:" .. i
end
assert(Observer.LoadPayload(oversizedObserver, 100))
eq(Observer.GetStats().discoveryCount, Observer.MAX_DISCOVERY_FINGERPRINTS,
    "discovery fingerprints bounded at 256 after oversized load")
falsy(Observer.HasDiscoveryFingerprint("fp:1"), "oldest overflow discovery evicted")
truthy(Observer.HasDiscoveryFingerprint("fp:320"), "newest discovery preserved")

print("psychopatz_world_events_persistence_smoke: OK")
