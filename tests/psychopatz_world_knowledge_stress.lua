local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local WKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"
local Ledger = WKG.Ledger

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function countKeys(value)
    local count = 0
    if type(value) ~= "table" then return count end
    for _ in pairs(value) do count = count + 1 end
    return count
end

local function boundedSize(value, depth)
    local total = 0
    depth = depth or 0
    if depth > 8 then return 1 end
    if type(value) == "string" then return #value end
    if type(value) == "number" or type(value) == "boolean" then return 1 end
    if type(value) ~= "table" then return 0 end
    for key, child in pairs(value) do
        total = total + #tostring(key) + boundedSize(child, depth + 1)
    end
    return total
end

local function containsPersistedProse(value)
    if type(value) ~= "table" then return false end
    for key, child in pairs(value) do
        local normalized = string.lower(tostring(key))
        if normalized == "statement" or normalized == "statements"
            or normalized == "transcript" or normalized == "prose"
            or normalized == "localizedtext"
        then return true end
        if containsPersistedProse(child) then return true end
    end
    return false
end

local function payloadHasReference(payload, actorID, factID)
    local actor = payload.actors and payload.actors.byActor
        and payload.actors.byActor[actorID]
    if not actor then return false end
    for _, ref in ipairs(actor.refs or {}) do
        if ref.factID == factID then return true end
    end
    return false
end

local ledger, knowledge = WKG.Reset({
    maxFacts = 256, maxActors = 128, maxRefs = 16,
})
local started = os.clock()
local firstFact
for index = 1, 1000 do
    local fact = WKG.Publish({
        producer = "stress:producer",
        kind = "stress.event",
        subject = { id = "region:stress", kind = "region" },
        eventID = "stress:" .. tostring(index),
        occurredAt = index,
        observedAt = index,
        severity = (index % 10) / 10,
        retention = "historical",
        payload = { band = "moderate", sample = index },
    })
    truthy(fact, "stress fact publication")
    firstFact = firstFact or fact
end
for index = 1, 500 do
    local actor = "actor:stress:" .. tostring(index)
    local factID = "fact:stress:producer:stress.event:region:stress:stress:"
        .. tostring(math.max(1, index))
    WKG.Acquire(actor, factID, {
        authorized = true,
        provenance = index % 2 == 0 and "public" or "witnessed",
        confidence = 0.75,
        source = "stress_fixture",
        acquisitionPath = "stress_fixture",
        learnedAt = index,
    })
end
for _ = 1, 20 do
    WKG.Publish({
        factID = firstFact.factID,
        producer = firstFact.producer,
        kind = firstFact.kind,
        subject = firstFact.subject,
        eventID = "stress:1",
        occurredAt = firstFact.occurredAt,
        observedAt = firstFact.observedAt,
        retention = firstFact.retention,
        payload = firstFact.payload,
    })
end
local ephemeral = WKG.Publish({
    producer = "stress:runtime", kind = "stress.sample", eventID = "ephemeral",
    retention = "ephemeral", occurredAt = 2000, observedAt = 2000,
})
local derived = WKG.Publish({
    producer = "stress:runtime", kind = "stress.current", eventID = "derived",
    retention = "derived_current", occurredAt = 2000, observedAt = 2000,
})
truthy(ephemeral and derived, "runtime facts")
WKG.Acquire("actor:stress:500", ephemeral.factID, {
    authorized = true, provenance = "environmental", confidence = 0.4,
    source = "runtime", acquisitionPath = "runtime", learnedAt = 2000,
})
WKG.Acquire("actor:stress:500", derived.factID, {
    authorized = true, provenance = "public", confidence = 0.4,
    source = "runtime", acquisitionPath = "runtime", learnedAt = 2000,
})
local payload = WKG.ToPayload()
local elapsed = os.clock() - started
local actorCount = countKeys(knowledge.byActor)
local factCount = #ledger.order
local persistedFacts = #(payload.ledger.facts or {})
truthy(factCount <= 256, "ledger remains bounded")
truthy(actorCount <= 128, "actor state remains bounded")
truthy(persistedFacts <= 256, "persisted ledger remains bounded")
truthy(not containsPersistedProse(payload), "no localized prose is persisted")
truthy(boundedSize(payload) < 180000, "stress payload remains bounded")
truthy(not payloadHasReference(payload, "actor:stress:500", ephemeral.factID),
    "ephemeral ref excluded from payload")
truthy(not payloadHasReference(payload, "actor:stress:500", derived.factID),
    "derived ref excluded from payload")

local restored, restoreReason = WKG.FromPayload(payload, {
    maxFacts = 256, maxActors = 128, maxRefs = 16,
})
truthy(restored, restoreReason)
truthy(#WKG.LedgerState.order <= 256, "reload ledger remains bounded")
truthy(countKeys(WKG.KnowledgeState.byActor) <= 128,
    "reload actor state remains bounded")
print(string.format(
    "psychopatz_world_knowledge_stress: PASS elapsed=%.4f ledger=%d actors=%d persistedFacts=%d payloadUnits=%d deduped=%d",
    elapsed, factCount, actorCount, persistedFacts, boundedSize(payload),
    ledger.metrics.deduped or 0
))
