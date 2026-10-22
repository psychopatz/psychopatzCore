local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Fact = {}

Fact.SCHEMA = "PsychopatzCore.WorldFact"
Fact.SCHEMA_VERSION = 1
Fact.MAX_ID = 128
Fact.MAX_KIND = 64
Fact.MAX_TEXT = 160
Fact.MAX_PAYLOAD_KEYS = 12
Fact.RETENTION = {
    ephemeral = true,
    historical = true,
    derived_current = true,
}
Fact.PROVENANCE = {
    experienced = true,
    witnessed = true,
    faction = true,
    public = true,
    environmental = true,
    told = true,
    radio = true,
    inferred = true,
}

local function text(value, limit)
    if type(value) ~= "string" and type(value) ~= "number" then return nil end
    value = tostring(value)
    if value == "" or #value > (limit or Fact.MAX_TEXT)
        or string.match(value, "[%c]")
    then return nil end
    return value
end

local function id(value)
    value = text(value, Fact.MAX_ID)
    if not value or not string.match(value, "^[%w_%.:%-]+$") then return nil end
    return value
end

local function number(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return value
end

local function bounded(value, low, high, fallback)
    return math.max(low, math.min(high, number(value, fallback)))
end

local function copyPrimitive(value, depth)
    local output
    local count
    local key
    local child
    local normalized
    depth = depth or 0
    if type(value) == "string" or type(value) == "number"
        or type(value) == "boolean"
    then
        if type(value) == "string" then return text(value) end
        if type(value) == "number" then return number(value, nil) end
        return value
    end
    if type(value) ~= "table" or depth >= 2 then return nil end
    output = {}
    count = 0
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then return nil end
        count = count + 1
        if count > Fact.MAX_PAYLOAD_KEYS then return nil end
        normalized = copyPrimitive(child, depth + 1)
        if normalized == nil and child ~= nil then return nil end
        output[key] = normalized
    end
    return output
end

local function reference(value)
    if value == nil then return nil end
    if type(value) == "string" or type(value) == "number" then
        return id(value)
    end
    if type(value) ~= "table" then return nil end
    local output = {}
    for key, child in pairs(value) do
        if key ~= "id" and key ~= "kind" and key ~= "name"
            and key ~= "region" and key ~= "factionID"
        then
            return nil
        end
        if key == "id" or key == "kind" or key == "factionID" then
            output[key] = id(child)
        else
            output[key] = text(child, Fact.MAX_TEXT)
        end
        if output[key] == nil then return nil end
    end
    return output
end

function Fact.StableID(spec)
    spec = type(spec) == "table" and spec or {}
    local producer = id(spec.producer or spec.source or "unknown") or "unknown"
    local kind = id(spec.kind or "unknown") or "unknown"
    local event = id(spec.eventID or spec.eventId or spec.key
        or tostring(spec.occurredAt or 0)) or "event"
    local subject = spec.subject
    if type(subject) == "table" then subject = subject.id or subject.kind end
    subject = id(subject or "world") or "world"
    return table.concat({ "fact", producer, kind, subject, event }, ":")
end

function Fact.New(spec)
    local output
    local payload
    local reason
    spec = type(spec) == "table" and spec or {}
    local factID = id(spec.factID or spec.id) or Fact.StableID(spec)
    local kind = id(spec.kind, Fact.MAX_KIND)
    local retention = text(spec.retention, 32) or "historical"
    if not kind then return nil, "fact_kind_required" end
    if not Fact.RETENTION[retention] then return nil, "fact_retention_invalid" end
    if spec.payload ~= nil then
        payload = copyPrimitive(spec.payload)
        if payload == nil then return nil, "fact_payload_invalid" end
    end
    output = {
        schema = Fact.SCHEMA,
        schemaVersion = Fact.SCHEMA_VERSION,
        factID = factID,
        id = factID,
        kind = kind,
        subject = reference(spec.subject),
        object = reference(spec.object),
        location = reference(spec.location),
        cause = reference(spec.cause),
        occurredAt = number(spec.occurredAt, 0),
        observedAt = number(spec.observedAt, spec.occurredAt or 0),
        severity = bounded(spec.severity, 0, 1, 0),
        retention = retention,
        expiresAt = spec.expiresAt ~= nil and number(spec.expiresAt, nil) or nil,
        producer = id(spec.producer or spec.source or "unknown") or "unknown",
        revision = math.max(1, math.floor(number(spec.revision, 1))),
        shareable = spec.shareable ~= false,
        payload = payload,
    }
    if spec.provenance ~= nil and not Fact.PROVENANCE[spec.provenance] then
        return nil, "fact_provenance_invalid"
    end
    output.provenance = spec.provenance
    if spec.confidence ~= nil then
        output.confidence = bounded(spec.confidence, 0, 1, 0)
    end
    return output
end

function Fact.Clone(value)
    return Util.clone(value)
end

function Fact.IsExpired(fact, now)
    return type(fact) == "table" and fact.expiresAt ~= nil
        and number(now, 0) >= number(fact.expiresAt, math.huge)
end

function Fact.ShouldPersist(fact, options)
    if type(fact) ~= "table" or fact.retention == "ephemeral" then return false end
    if fact.retention == "derived_current" then
        return type(options) == "table" and options.persistDerived == true
    end
    return true
end

return Fact
