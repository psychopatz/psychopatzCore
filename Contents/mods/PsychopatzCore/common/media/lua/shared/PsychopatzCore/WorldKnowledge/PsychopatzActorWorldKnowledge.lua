local Fact = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFact"
local Ledger = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFactLedger"
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Knowledge = {}
Knowledge.SCHEMA = "PsychopatzCore.ActorWorldKnowledge"
Knowledge.SCHEMA_VERSION = 1
Knowledge.DEFAULT_MAX_ACTORS = 256
Knowledge.DEFAULT_MAX_REFS = 64
Knowledge.DEFAULT_SHARE_LIMIT = 3
Knowledge.PROVENANCE_WEIGHT = {
    experienced = 1.0, witnessed = 0.95, faction = 0.85, public = 0.75,
    environmental = 0.75, radio = 0.7, told = 0.6, inferred = 0.4,
}

local function copy(value)
    return type(value) == "table" and Util.clone(value) or value
end

local function actorID(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function confidence(value)
    value = tonumber(value)
    if not value or value ~= value then return 0 end
    return math.max(0, math.min(1, value))
end

function Knowledge.NewState(source, options)
    source = type(source) == "table" and source or {}
    options = type(options) == "table" and options or {}
    local state = {
        schema = Knowledge.SCHEMA,
        schemaVersion = Knowledge.SCHEMA_VERSION,
        maxActors = math.max(1, math.floor(tonumber(options.maxActors
            or source.maxActors) or Knowledge.DEFAULT_MAX_ACTORS)),
        maxRefs = math.max(1, math.floor(tonumber(options.maxRefs
            or source.maxRefs) or Knowledge.DEFAULT_MAX_REFS)),
        byActor = {},
        metrics = { acquired = 0, deduped = 0, shared = 0, rejected = 0 },
        runtime = { cooldowns = {} },
    }
    for key, value in pairs(source.byActor or {}) do
        if actorID(key) and type(value) == "table" then
            local entry = { refs = {}, order = {} }
            for index = 1, #(value.refs or {}) do
                local ref = value.refs[index]
                if type(ref) == "table" and tostring(ref.factID or "") ~= "" then
                    entry.refs[ref.factID] = copy(ref)
                    entry.order[#entry.order + 1] = ref.factID
                end
            end
            while #entry.order > state.maxRefs do
                entry.refs[table.remove(entry.order, 1)] = nil
            end
            state.byActor[tostring(key)] = entry
        end
    end
    return state
end

local function entryFor(state, id)
    id = actorID(id)
    if not id then return nil end
    local entry = state.byActor[id]
    if entry then return entry end
    local count = 0
    for _ in pairs(state.byActor) do count = count + 1 end
    if count >= state.maxActors then
        local first
        for key in pairs(state.byActor) do first = key break end
        if first then state.byActor[first] = nil end
    end
    entry = { refs = {}, order = {} }
    state.byActor[id] = entry
    return entry
end

function Knowledge.Get(state, id, factID)
    local entry = state.byActor[actorID(id) or ""]
    local ref = entry and entry.refs[tostring(factID or "")]
    return ref and copy(ref) or nil
end

function Knowledge.Acquire(state, ledger, id, factID, specification)
    specification = type(specification) == "table" and specification or {}
    local entry = entryFor(state, id)
    local fact = Ledger.Get(ledger, factID)
    local normalizedProvenance = tostring(specification.provenance
        or specification.sourceKind or "")
    local ref
    local existing
    if specification.authorized ~= true then
        state.metrics.rejected = state.metrics.rejected + 1
        return nil, "knowledge_authorization_required"
    end
    if not entry or not fact then return nil, "fact_not_found" end
    if not Fact.PROVENANCE[normalizedProvenance] then
        return nil, "knowledge_provenance_invalid"
    end
    ref = {
        factID = fact.factID,
        learnedAt = tonumber(specification.learnedAt) or fact.observedAt or 0,
        provenance = normalizedProvenance,
        sourceActorID = actorID(specification.sourceActorID),
        source = tostring(specification.source or specification.acquisitionPath
            or normalizedProvenance),
        acquisitionPath = tostring(specification.acquisitionPath
            or normalizedProvenance),
        confidence = confidence(specification.confidence
            or fact.confidence or 0),
        firstLearnedAt = tonumber(specification.firstLearnedAt)
            or tonumber(specification.learnedAt) or fact.observedAt or 0,
    }
    existing = entry.refs[fact.factID]
    if existing then
        if ref.confidence < confidence(existing.confidence)
            and tostring(existing.provenance) ~= "told"
        then
            state.metrics.deduped = state.metrics.deduped + 1
            return copy(existing), "deduped"
        end
        ref.firstLearnedAt = existing.firstLearnedAt or ref.firstLearnedAt
        entry.refs[fact.factID] = ref
        state.metrics.deduped = state.metrics.deduped + 1
        return copy(ref), "updated"
    end
    entry.refs[fact.factID] = ref
    entry.order[#entry.order + 1] = fact.factID
    state.metrics.acquired = state.metrics.acquired + 1
    while #entry.order > state.maxRefs do
        entry.refs[table.remove(entry.order, 1)] = nil
    end
    return copy(ref), "acquired"
end

local function candidateScore(fact, ref, now)
    local age = math.max(0, (tonumber(now) or 0)
        - (tonumber(ref.learnedAt) or tonumber(fact.observedAt) or 0))
    local recency = math.max(0, 1 - age / 168)
    local provenance = Knowledge.PROVENANCE_WEIGHT[ref.provenance] or 0
    return provenance * 40 + confidence(ref.confidence) * 40
        + (tonumber(fact.severity) or 0) * 15 + recency * 5
end

function Knowledge.Select(state, ledger, id, options)
    options = type(options) == "table" and options or {}
    local entry = state.byActor[actorID(id) or ""]
    local output = {}
    local maximum = math.max(1, math.floor(tonumber(options.max)
        or Knowledge.DEFAULT_SHARE_LIMIT))
    if not entry then return output end
    for index = 1, #entry.order do
        local ref = entry.refs[entry.order[index]]
        local fact = ref and Ledger.Get(ledger, ref.factID) or nil
        if fact and fact.shareable ~= false
            and not Fact.IsExpired(fact, options.now)
            and (not options.kind or fact.kind == options.kind)
            and (not options.locationID or tostring(fact.location
                and fact.location.id or fact.location or "")
                == tostring(options.locationID))
        then
            output[#output + 1] = {
                fact = fact,
                reference = copy(ref),
                score = candidateScore(fact, ref, options.now),
                why = {
                    factID = fact.factID,
                    producer = fact.producer,
                    acquisitionPath = ref.acquisitionPath,
                    provenance = ref.provenance,
                    confidence = confidence(ref.confidence),
                },
            }
        end
    end
    table.sort(output, function(left, right)
        if left.score == right.score then
            return left.fact.factID < right.fact.factID
        end
        return left.score > right.score
    end)
    while #output > maximum do table.remove(output) end
    return output
end

function Knowledge.Share(state, ledger, fromID, toID, options)
    options = type(options) == "table" and options or {}
    if options.authorized ~= true then return nil, "propagation_authorization_required" end
    if not actorID(fromID) or not actorID(toID) or tostring(fromID) == tostring(toID) then
        return nil, "propagation_actor_invalid"
    end
    local selected = Knowledge.Select(state, ledger, fromID, {
        max = options.max or Knowledge.DEFAULT_SHARE_LIMIT,
        now = options.now,
        kind = options.kind,
        locationID = options.locationID,
    })
    local transferred = {}
    for index = 1, #selected do
        local item = selected[index]
        local cooldownKey = tostring(fromID) .. ":" .. tostring(toID)
            .. ":" .. item.fact.factID
        local last = state.runtime.cooldowns[cooldownKey]
        if not last or (tonumber(options.now) or 0) - last >= (tonumber(options.cooldown) or 1) then
            local ref = Knowledge.Acquire(state, ledger, toID, item.fact.factID, {
                authorized = true,
                provenance = options.provenance or "told",
                sourceActorID = fromID,
                source = options.source or "conversation",
                acquisitionPath = options.acquisitionPath or "conversation",
                confidence = math.min(confidence(item.reference.confidence),
                    confidence(options.confidence or 0.85)),
                learnedAt = options.now,
            })
            if ref then
                state.runtime.cooldowns[cooldownKey] = tonumber(options.now) or 0
                transferred[#transferred + 1] = {
                    factID = item.fact.factID,
                    fromActorID = tostring(fromID),
                    toActorID = tostring(toID),
                    provenance = ref.provenance,
                    confidence = ref.confidence,
                    reason = "opportunistic_share",
                }
                state.metrics.shared = state.metrics.shared + 1
            end
        end
    end
    return transferred
end

function Knowledge.BuildContext(state, ledger, id, options)
    options = type(options) == "table" and options or {}
    local candidates = Knowledge.Select(state, ledger, id, options)
    local context = {
        worldKnowledge = { candidates = {}, actorID = tostring(id or "") },
        npcGossip = { statements = {}, factRefs = {} },
    }
    for index = 1, #candidates do
        local item = candidates[index]
        local line = type(options.renderFact) == "function"
            and options.renderFact(item.fact, item.reference, item) or nil
        context.worldKnowledge.candidates[#context.worldKnowledge.candidates + 1] = {
            factID = item.fact.factID,
            producer = item.fact.producer,
            provenance = item.reference.provenance,
            confidence = item.reference.confidence,
            score = item.score,
            why = copy(item.why),
        }
        if type(line) == "string" and line ~= "" then
            context.npcGossip.statements[#context.npcGossip.statements + 1] = line
            context.npcGossip.factRefs[#context.npcGossip.factRefs + 1] = item.fact.factID
        end
    end
    return context
end

function Knowledge.Explain(state, ledger, id, factID, now)
    local ref = Knowledge.Get(state, id, factID)
    local fact = ref and Ledger.Get(ledger, factID) or nil
    if not ref or not fact then return nil, "knowledge_not_found" end
    return {
        factID = fact.factID,
        kind = fact.kind,
        producer = fact.producer,
        occurredAt = fact.occurredAt,
        learnedAt = ref.learnedAt,
        acquisitionPath = ref.acquisitionPath,
        source = ref.source,
        sourceActorID = ref.sourceActorID,
        provenance = ref.provenance,
        confidence = ref.confidence,
        ranking = Knowledge.Select(state, ledger, id, { now = now, max = 64 }),
    }
end

function Knowledge.ToPayload(state, options)
    local output = {
        schema = Knowledge.SCHEMA,
        schemaVersion = Knowledge.SCHEMA_VERSION,
        byActor = {},
    }
    for id, entry in pairs(state.byActor) do
        output.byActor[id] = { refs = {} }
        for index = 1, #entry.order do
            local ref = entry.refs[entry.order[index]]
            if ref then output.byActor[id].refs[#output.byActor[id].refs + 1] = copy(ref) end
        end
    end
    return output
end

function Knowledge.FromPayload(payload, options)
    if type(payload) ~= "table"
        or payload.schema ~= Knowledge.SCHEMA
        or tonumber(payload.schemaVersion) ~= Knowledge.SCHEMA_VERSION
    then return nil, "knowledge_schema_mismatch" end
    return Knowledge.NewState(payload, options)
end

return Knowledge
