-- Core normalized vanilla world-event observation pipeline.
-- Routes normalized observations into PsychopatzCore.ScopedWorldEvents and
-- PsychopatzCore.WorldKnowledge using single location resolution, strict global
-- scope enforcement, ephemeral filtering, and bounded dedupe/fingerprints.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero per-tick polling.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local ScopedWorldEvents = require "PsychopatzCore/WorldEvents/PsychopatzScopedWorldEvents"
local WorldKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"
local Fact = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFact"
local Location = require "PsychopatzCore/WorldEvents/PsychopatzWorldEventLocation"

PsychopatzCore = PsychopatzCore or {}
local Observer = PsychopatzCore.VanillaEventObserver or {}
PsychopatzCore.VanillaEventObserver = Observer

Observer.SCHEMA = "PsychopatzCore.VanillaEventObserver"
Observer.SCHEMA_VERSION = 1
Observer.MAX_COOLDOWN_KEYS = 128
Observer.MAX_DISCOVERY_FINGERPRINTS = 256
Observer.MAX_EPHEMERAL_LISTENERS = 16
Observer.MAX_EPISODE_SAMPLES = 5

Observer.RETENTION = {
    ephemeral = true,
    historical = true,
    derived_current = true,
}

Observer.PHASES = {
    start = true,
    update = true,
    ["end"] = true,
    discovery = true,
    transition = true,
    instant = true,
}

-- Automatic global vanilla events are restricted exclusively to utility state transitions.
Observer.AUTOMATIC_GLOBAL_SEMANTIC_TYPES = {
    ["utility.electricity_cutoff"] = true,
    ["utility.electricity_restored"] = true,
    ["utility.water_cutoff"] = true,
    ["utility.water_restored"] = true,
}

local function finite(value, fallback)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return fallback
    end
    return num
end

local function clamp(value, low, high, fallback)
    local num = finite(value, fallback)
    if num == nil then return nil end
    return math.max(low, math.min(high, num))
end

local function safeID(value, limit)
    if type(value) ~= "string" and type(value) ~= "number" then return nil end
    local text = tostring(value)
    if text == "" or #text > (limit or 128) or string.match(text, "[%c]") then
        return nil
    end
    if not string.match(text, "^[%w_%-%.:]+$") then
        return nil
    end
    return text
end

local function safeText(value, limit)
    if type(value) ~= "string" and type(value) ~= "number" then return nil end
    local text = tostring(value)
    if text == "" or #text > (limit or 160) or string.match(text, "[%c]") then
        return nil
    end
    return text
end

local function flatPayload(raw)
    if type(raw) ~= "table" then return nil end
    local out = {}
    local count = 0
    local keys = {}
    for key in pairs(raw) do
        if type(key) == "string" or type(key) == "number" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for i = 1, #keys do
        local key = keys[i]
        local val = raw[key]
        local kind = type(val)
        if kind == "string" then
            val = safeText(val, 160)
        elseif kind == "number" then
            val = finite(val, nil)
        elseif kind ~= "boolean" then
            val = nil
        end
        if val ~= nil then
            count = count + 1
            if count > Fact.MAX_PAYLOAD_KEYS then break end
            out[key] = val
        end
    end
    return out
end

local function recordBoundedLRU(map, order, key, value, maxEntries)
    if map[key] ~= nil then
        for i = 1, #order do
            if order[i] == key then
                table.remove(order, i)
                break
            end
        end
    end
    map[key] = value
    order[#order + 1] = key
    while #order > maxEntries do
        local evicted = table.remove(order, 1)
        if evicted ~= nil then
            map[evicted] = nil
        end
    end
end

local InstanceMethods = {}
InstanceMethods.__index = InstanceMethods

function InstanceMethods:OnEphemeral(listener, opts)
    if type(listener) ~= "function" then return nil, "listener_required" end
    opts = type(opts) == "table" and opts or {}
    local id = safeID(opts.id, 96)
    for i = 1, #self._ephemeralListeners do
        local existing = self._ephemeralListeners[i]
        if (id and existing.id == id) or existing.fn == listener then
            return existing.token
        end
    end
    if #self._ephemeralListeners >= Observer.MAX_EPHEMERAL_LISTENERS then
        return nil, "ephemeral_listener_capacity_exceeded"
    end
    self._nextListenerToken = self._nextListenerToken + 1
    local token = self._nextListenerToken
    self._ephemeralListeners[#self._ephemeralListeners + 1] = {
        token = token,
        id = id,
        fn = listener,
    }
    return token
end

function InstanceMethods:UnsubscribeEphemeral(tokenOrFn)
    local removed = 0
    for i = #self._ephemeralListeners, 1, -1 do
        local entry = self._ephemeralListeners[i]
        if entry.token == tokenOrFn or entry.fn == tokenOrFn then
            table.remove(self._ephemeralListeners, i)
            removed = removed + 1
        end
    end
    return removed
end

function InstanceMethods:HasDiscoveryFingerprint(fingerprint)
    local fp = safeID(fingerprint, 128)
    return fp ~= nil and self._discoveries[fp] == true
end

function InstanceMethods:MarkDiscoveryFingerprint(fingerprint)
    local fp = safeID(fingerprint, 128)
    if not fp then return false end
    recordBoundedLRU(
        self._discoveries,
        self._discoveryOrder,
        fp,
        true,
        self.maxDiscoveries
    )
    return true
end

function InstanceMethods:GetUtilityState(key)
    return self._utilityWatermarks[tostring(key or "")]
end

function InstanceMethods:SetUtilityState(key, stateTable)
    local k = safeID(key, 64)
    if not k or type(stateTable) ~= "table" then return false end
    self._utilityWatermarks[k] = Util.clone(stateTable)
    return true
end

function InstanceMethods:GetHelicopterState()
    return self._helicopterState and Util.clone(self._helicopterState) or {
        active = false,
        episodeSeq = 0,
    }
end

function InstanceMethods:SetHelicopterState(stateTable)
    if type(stateTable) ~= "table" then return false end
    self._helicopterState = Util.clone(stateTable)
    return true
end

function InstanceMethods:GetStats()
    return {
        observed = self._metrics.observed,
        registered = self._metrics.registered,
        ephemeral = self._metrics.ephemeral,
        deduped = self._metrics.deduped,
        rejected = self._metrics.rejected,
        discoveryCount = #self._discoveryOrder,
        cooldownCount = #self._cooldownOrder,
    }
end

function InstanceMethods:ToPayload()
    local discoveries = {}
    for i = 1, #self._discoveryOrder do
        discoveries[i] = self._discoveryOrder[i]
    end
    local cooldowns = {}
    for i = 1, #self._cooldownOrder do
        local k = self._cooldownOrder[i]
        if self._cooldowns[k] ~= nil then
            cooldowns[#cooldowns + 1] = { key = k, untilAt = self._cooldowns[k] }
        end
    end
    return {
        schema = Observer.SCHEMA,
        schemaVersion = Observer.SCHEMA_VERSION,
        utilityWatermarks = Util.clone(self._utilityWatermarks),
        helicopterState = Util.clone(self._helicopterState),
        discoveries = discoveries,
        cooldowns = cooldowns,
    }
end

function InstanceMethods:LoadPayload(payload, nowHours)
    if type(payload) ~= "table"
        or payload.schema ~= Observer.SCHEMA
        or tonumber(payload.schemaVersion) ~= Observer.SCHEMA_VERSION
    then
        return false, "vanilla_event_observer_schema_mismatch"
    end
    self._utilityWatermarks = type(payload.utilityWatermarks) == "table"
        and Util.clone(payload.utilityWatermarks) or {}
    self._helicopterState = type(payload.helicopterState) == "table"
        and Util.clone(payload.helicopterState) or { active = false, episodeSeq = 0 }

    self._discoveries = {}
    self._discoveryOrder = {}
    local discoveries = type(payload.discoveries) == "table" and payload.discoveries or {}
    local startIdx = math.max(1, #discoveries - self.maxDiscoveries + 1)
    for i = startIdx, #discoveries do
        self:MarkDiscoveryFingerprint(discoveries[i])
    end

    self._cooldowns = {}
    self._cooldownOrder = {}
    local now = finite(nowHours, nil)
    local cooldowns = type(payload.cooldowns) == "table" and payload.cooldowns or {}
    for i = 1, #cooldowns do
        local row = cooldowns[i]
        local k = type(row) == "table" and safeID(row.key, 128) or nil
        local untilAt = type(row) == "table" and finite(row.untilAt, nil) or nil
        if k and untilAt and (now == nil or untilAt > now) then
            recordBoundedLRU(self._cooldowns, self._cooldownOrder, k, untilAt, self.maxCooldowns)
        end
    end
    return true
end

function InstanceMethods:Observe(input, opts)
    self._metrics.observed = self._metrics.observed + 1
    opts = type(opts) == "table" and opts or {}
    if type(input) ~= "table" then
        self._metrics.rejected = self._metrics.rejected + 1
        return nil, "observation_table_required"
    end

    local semanticType = safeID(input.semanticType, 64)
    local sourceKind = safeID(input.sourceKind, 64) or "vanilla"
    local phase = tostring(input.phase or "instant")
    local retention = tostring(input.retention or "historical")
    local provenance = tostring(input.provenance or "environmental")
    if not semanticType then
        self._metrics.rejected = self._metrics.rejected + 1
        return nil, "observation_semantic_type_required"
    end
    if not Observer.PHASES[phase] then
        self._metrics.rejected = self._metrics.rejected + 1
        return nil, "observation_phase_invalid"
    end
    if not Observer.RETENTION[retention] then
        self._metrics.rejected = self._metrics.rejected + 1
        return nil, "observation_retention_invalid"
    end
    if not Fact.PROVENANCE[provenance] then
        self._metrics.rejected = self._metrics.rejected + 1
        return nil, "observation_provenance_invalid"
    end

    local occurredAt = math.max(0, finite(input.occurredAt, 0))
    local observedAt = math.max(occurredAt, finite(input.observedAt, occurredAt))
    local isAllowedGlobal = Observer.AUTOMATIC_GLOBAL_SEMANTIC_TYPES[semanticType] == true

    -- Enforce global scope invariant before doing any persistence or side effects.
    if input.scope == "global" and not isAllowedGlobal then
        self._metrics.rejected = self._metrics.rejected + 1
        return nil, "global_scope_forbidden_for_semantic_type"
    end

    local locRef = nil
    local scope = input.scope and tostring(input.scope) or nil
    local scopeID = safeID(input.scopeID)
    local affectedSettlements = {}

    if scope == "global" then
        scopeID = scopeID or "global"
    else
        locRef = input.locationRef
        if type(locRef) ~= "table" and (input.x ~= nil or input.y ~= nil
            or input.settlementID or input.regionID or input.localAreaID or input.factionID)
        then
            local locErr
            locRef, locErr = Location.Resolve(input.x, input.y, input.z, {
                settlementID = input.settlementID,
                factionID = input.factionID,
                regionID = input.regionID,
                localAreaID = input.localAreaID,
                zoneID = input.zoneID,
                label = input.locationLabel,
                kind = input.locationKind,
                zonesApi = opts.zonesApi or input.zonesApi,
                resolveLocation = opts.resolveLocation or input.resolveLocation,
            })
            if not locRef then
                self._metrics.rejected = self._metrics.rejected + 1
                return nil, locErr or "location_resolution_failed"
            end
        end

        if scope == nil and type(locRef) == "table" then
            scope, scopeID = Location.ResolveScope(locRef, input.preferredScope)
        elseif scope ~= nil and not scopeID and type(locRef) == "table" then
            local _, resolvedID = Location.ResolveScope(locRef, scope)
            scopeID = resolvedID
        end

        if scope == nil then
            if isAllowedGlobal then
                scope = "global"
                scopeID = "global"
            else
                self._metrics.rejected = self._metrics.rejected + 1
                return nil, "non_global_scope_required"
            end
        elseif not scopeID then
            self._metrics.rejected = self._metrics.rejected + 1
            return nil, "scope_id_required"
        end
    end

    if type(locRef) == "table" and locRef.settlementID then
        affectedSettlements[1] = locRef.settlementID
    end

    local vanillaSourceID = safeText(input.vanillaSourceID or input.sourceID, 64)
    local normalized = {
        schema = Observer.SCHEMA,
        schemaVersion = Observer.SCHEMA_VERSION,
        semanticType = semanticType,
        sourceKind = sourceKind,
        vanillaSourceID = vanillaSourceID,
        phase = phase,
        retention = retention,
        provenance = provenance,
        severity = clamp(input.severity, 0, 1, 0.5),
        salience = clamp(input.salience, 0, 1, 0.5),
        scope = scope,
        scopeID = scopeID,
        occurredAt = occurredAt,
        observedAt = observedAt,
        locationRef = locRef and Util.clone(locRef) or nil,
        affectedSettlements = affectedSettlements,
    }

    -- 1. Ephemeral events never persist into ScopedWorldEvents or WorldKnowledge.
    if retention == "ephemeral" then
        self._metrics.ephemeral = self._metrics.ephemeral + 1
        for i = 1, #self._ephemeralListeners do
            self._ephemeralListeners[i].fn(Util.clone(normalized))
        end
        return {
            ok = true,
            status = "ephemeral",
            observation = normalized,
        }
    end

    -- 2. Discovery fingerprint dedupe (one-shot stories / exact discoveries).
    local fingerprint = safeID(input.fingerprint, 128)
    if fingerprint then
        if self._discoveries[fingerprint] == true then
            self._metrics.deduped = self._metrics.deduped + 1
            return {
                ok = true,
                status = "deduped",
                reason = "discovery_fingerprint_exists",
                observation = normalized,
            }
        end
    end

    -- 3. Bounded cooldown window per bucket/semanticType/phase.
    local cooldownHours = finite(input.cooldownHours, 0)
    local cooldownKey = safeID(input.cooldownKey
        or (semanticType .. ":" .. scopeID .. ":" .. phase), 128)
    if cooldownHours > 0 and cooldownKey then
        local blockedUntil = self._cooldowns[cooldownKey]
        if blockedUntil ~= nil and observedAt < blockedUntil then
            self._metrics.deduped = self._metrics.deduped + 1
            return {
                ok = true,
                status = "deduped",
                reason = "cooldown_active",
                observation = normalized,
            }
        end
        recordBoundedLRU(
            self._cooldowns,
            self._cooldownOrder,
            cooldownKey,
            observedAt + cooldownHours,
            self.maxCooldowns
        )
    end

    if fingerprint then
        self:MarkDiscoveryFingerprint(fingerprint)
    end

    local scopedReg = opts.scopedRegistry or ScopedWorldEvents._default
    local wkgPublish = opts.publishFact or WorldKnowledge.Publish
    local eventID = safeID(input.eventID) or safeID(
        "core:" .. semanticType .. ":" .. scopeID .. ":" .. tostring(math.floor(occurredAt * 100))
    )
    local factID = safeID(input.factID) or safeID("fact:core:" .. semanticType .. ":" .. (scopeID or "global")
        .. ":" .. (input.factKey or tostring(math.floor(occurredAt * 100))))

    -- 4. Route to ScopedWorldEvents when episodic/stateful (or close active episode).
    local scopedResult = nil
    local scopedStatus = nil
    if phase == "end" then
        local removed, rmResult = scopedReg:Remove(eventID, {
            reason = input.endReason or "episode_ended",
            nowHours = observedAt,
            notify = opts.notify,
        })
        scopedResult = rmResult
        scopedStatus = removed and "ended" or "not_active"
    elseif input.registerScoped ~= false then
        local duration = finite(input.durationHours, nil)
        local endsAt = finite(input.endsAt, nil)
        if endsAt == nil and duration ~= nil and duration > 0 then
            endsAt = occurredAt + duration
        end
        local meta = flatPayload(input.metadata) or {}
        if vanillaSourceID then meta.vanillaSourceID = vanillaSourceID end
        if locRef and locRef.label then meta.locationLabel = locRef.label end
        meta.semanticType = semanticType

        scopedResult, scopedStatus = scopedReg:Register({
            eventID = eventID,
            eventType = input.scopedEventType or string.gsub(semanticType, "%.", "_"),
            semanticTags = input.semanticTags or { sourceKind, semanticType },
            scope = scope,
            scopeID = scopeID,
            affectedSettlements = affectedSettlements,
            startsAt = occurredAt,
            endsAt = endsAt,
            severity = normalized.severity,
            source = input.source or "PsychopatzCore.VanillaEvents",
            provenance = provenance,
            effects = input.effects,
            metadata = meta,
        }, {
            nowHours = observedAt,
            notify = opts.notify,
            communities = opts.communities,
            resolveSettlements = opts.resolveSettlements,
        })
    end

    -- 5. Publish canonical fact into PsychopatzCore.WorldKnowledge.
    local factResult = nil
    local factStatus = nil
    if input.publishFact ~= false then
        local factPayload = flatPayload(input.payload) or {}
        if vanillaSourceID then factPayload.vanillaSourceID = vanillaSourceID end
        factPayload.semanticType = semanticType
        factPayload.scope = scope
        factPayload.scopeID = scopeID
        if locRef and locRef.label then factPayload.locationLabel = locRef.label end
        if input.phase then factPayload.phase = phase end
        factPayload = flatPayload(factPayload) or {}

        local factTTL = finite(input.factTTLHours, nil)
        local expiresAt = finite(input.factExpiresAt, nil)
        if expiresAt == nil and factTTL ~= nil and factTTL > 0 then
            expiresAt = occurredAt + factTTL
        end

        factResult, factStatus = wkgPublish({
            factID = factID,
            kind = input.factKind or semanticType,
            subject = input.subject or { id = scopeID, kind = scope },
            object = input.object,
            location = Location.ToFactReference(locRef),
            occurredAt = occurredAt,
            observedAt = observedAt,
            severity = normalized.severity,
            retention = retention,
            expiresAt = expiresAt,
            producer = "core:vanilla_event",
            revision = math.max(1, math.floor(finite(input.revision, 1))),
            shareable = input.shareable ~= false,
            provenance = input.factProvenance,
            confidence = clamp(input.confidence, 0, 1, provenance == "witnessed" and 0.95 or 0.75),
            payload = factPayload,
        }, { now = observedAt })
    end

    self._metrics.registered = self._metrics.registered + 1
    return {
        ok = true,
        status = scopedStatus or factStatus or "observed",
        eventID = eventID,
        factID = factResult and factResult.factID or factID,
        scopedEvent = scopedResult,
        fact = factResult,
        factStatus = factStatus,
        observation = normalized,
    }
end

function Observer.New(options)
    options = type(options) == "table" and options or {}
    local instance = {
        maxCooldowns = math.max(16, math.floor(tonumber(options.maxCooldowns) or Observer.MAX_COOLDOWN_KEYS)),
        maxDiscoveries = math.max(16, math.floor(tonumber(options.maxDiscoveries) or Observer.MAX_DISCOVERY_FINGERPRINTS)),
        _cooldowns = {},
        _cooldownOrder = {},
        _discoveries = {},
        _discoveryOrder = {},
        _utilityWatermarks = {},
        _helicopterState = { active = false, episodeSeq = 0 },
        _ephemeralListeners = {},
        _nextListenerToken = 0,
        _metrics = {
            observed = 0,
            registered = 0,
            ephemeral = 0,
            deduped = 0,
            rejected = 0,
        },
    }
    return setmetatable(instance, InstanceMethods)
end

Observer._default = Observer.New()

function Observer.Reset(options)
    Observer._default = Observer.New(options)
    return Observer._default
end

function Observer.Observe(input, opts)
    return Observer._default:Observe(input, opts)
end

function Observer.OnEphemeral(listener, opts)
    return Observer._default:OnEphemeral(listener, opts)
end

function Observer.UnsubscribeEphemeral(tokenOrFn)
    return Observer._default:UnsubscribeEphemeral(tokenOrFn)
end

function Observer.HasDiscoveryFingerprint(fingerprint)
    return Observer._default:HasDiscoveryFingerprint(fingerprint)
end

function Observer.MarkDiscoveryFingerprint(fingerprint)
    return Observer._default:MarkDiscoveryFingerprint(fingerprint)
end

function Observer.GetUtilityState(key)
    return Observer._default:GetUtilityState(key)
end

function Observer.SetUtilityState(key, stateTable)
    return Observer._default:SetUtilityState(key, stateTable)
end

function Observer.GetHelicopterState()
    return Observer._default:GetHelicopterState()
end

function Observer.SetHelicopterState(stateTable)
    return Observer._default:SetHelicopterState(stateTable)
end

function Observer.GetStats()
    return Observer._default:GetStats()
end

function Observer.ToPayload()
    return Observer._default:ToPayload()
end

function Observer.LoadPayload(payload, nowHours)
    return Observer._default:LoadPayload(payload, nowHours)
end

return Observer
