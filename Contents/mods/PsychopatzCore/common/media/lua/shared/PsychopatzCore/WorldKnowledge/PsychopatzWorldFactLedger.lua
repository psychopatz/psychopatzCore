local Fact = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFact"
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Ledger = {}
Ledger.SCHEMA = "PsychopatzCore.WorldFactLedger"
Ledger.SCHEMA_VERSION = 1
Ledger.DEFAULT_MAX_FACTS = 256

local function copy(value)
    return type(value) == "table" and Util.clone(value) or value
end

function Ledger.New(source, options)
    source = type(source) == "table" and source or {}
    options = type(options) == "table" and options or {}
    local state = {
        schema = Ledger.SCHEMA,
        schemaVersion = Ledger.SCHEMA_VERSION,
        revision = math.max(0, math.floor(tonumber(source.revision) or 0)),
        maxFacts = math.max(1, math.floor(tonumber(options.maxFacts
            or source.maxFacts) or Ledger.DEFAULT_MAX_FACTS)),
        facts = {},
        order = {},
        metrics = { added = 0, deduped = 0, evicted = 0, expired = 0 },
    }
    for index = 1, #(source.facts or {}) do
        local fact = Fact.New(source.facts[index])
        if fact then
            state.facts[fact.factID] = fact
            state.order[#state.order + 1] = fact.factID
        end
    end
    while #state.order > state.maxFacts do
        state.facts[table.remove(state.order, 1)] = nil
    end
    return state
end

local function removeID(state, factID, metric)
    local index
    if not state.facts[factID] then return false end
    state.facts[factID] = nil
    for index = 1, #state.order do
        if state.order[index] == factID then
            table.remove(state.order, index)
            break
        end
    end
    if metric then state.metrics[metric] = (state.metrics[metric] or 0) + 1 end
    return true
end

function Ledger.Get(state, factID)
    local fact = state and state.facts and state.facts[tostring(factID or "")]
    return fact and copy(fact) or nil
end

function Ledger.Add(state, specification, options)
    options = type(options) == "table" and options or {}
    local fact, reason = Fact.New(specification)
    local existing
    if not fact then return nil, reason end
    existing = state.facts[fact.factID]
    if existing then
        if fact.revision > (tonumber(existing.revision) or 1)
            or fact.observedAt > (tonumber(existing.observedAt) or 0)
        then
            state.facts[fact.factID] = fact
            state.revision = state.revision + 1
            return copy(fact), "updated"
        end
        state.metrics.deduped = state.metrics.deduped + 1
        return copy(existing), "deduped"
    end
    state.facts[fact.factID] = fact
    state.order[#state.order + 1] = fact.factID
    state.revision = state.revision + 1
    state.metrics.added = state.metrics.added + 1
    while #state.order > state.maxFacts do
        removeID(state, state.order[1], "evicted")
    end
    if options.now ~= nil then Ledger.Expire(state, options.now) end
    return copy(fact), "added"
end

function Ledger.Expire(state, now)
    local removed = 0
    local index = 1
    while index <= #state.order do
        local factID = state.order[index]
        if Fact.IsExpired(state.facts[factID], now) then
            removeID(state, factID, "expired")
            removed = removed + 1
        else
            index = index + 1
        end
    end
    return removed
end

local function matches(fact, filters)
    local function refID(value)
        return type(value) == "table" and tostring(value.id or "") or tostring(value or "")
    end
    if filters.kind and fact.kind ~= filters.kind then return false end
    if filters.producer and fact.producer ~= filters.producer then return false end
    if filters.retention and fact.retention ~= filters.retention then return false end
    if filters.shareable ~= nil and fact.shareable ~= filters.shareable then return false end
    if filters.subjectID and refID(fact.subject) ~= tostring(filters.subjectID) then return false end
    if filters.locationID and refID(fact.location) ~= tostring(filters.locationID) then return false end
    if filters.now and Fact.IsExpired(fact, filters.now) then return false end
    return true
end

function Ledger.Query(state, filters)
    filters = type(filters) == "table" and filters or {}
    local output = {}
    local maximum = math.max(1, math.floor(tonumber(filters.max) or 32))
    for index = #state.order, 1, -1 do
        local fact = state.facts[state.order[index]]
        if fact and matches(fact, filters) then
            output[#output + 1] = copy(fact)
            if #output >= maximum then break end
        end
    end
    return output
end

function Ledger.ToPayload(state, options)
    options = type(options) == "table" and options or {}
    local output = {
        schema = Ledger.SCHEMA,
        schemaVersion = Ledger.SCHEMA_VERSION,
        revision = state.revision,
        facts = {},
    }
    for index = 1, #state.order do
        local fact = state.facts[state.order[index]]
        if Fact.ShouldPersist(fact, options) then
            output.facts[#output.facts + 1] = copy(fact)
        end
    end
    return output
end

function Ledger.FromPayload(payload, options)
    if type(payload) ~= "table"
        or payload.schema ~= Ledger.SCHEMA
        or tonumber(payload.schemaVersion) ~= Ledger.SCHEMA_VERSION
    then return nil, "ledger_schema_mismatch" end
    return Ledger.New(payload, options)
end

return Ledger
