-- Bounded scope-indexed world-event registry and effect aggregator.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero per-tick polling.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Fact = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFact"

PsychopatzCore = PsychopatzCore or {}
local ScopedWorldEvents = PsychopatzCore.ScopedWorldEvents or {}
PsychopatzCore.ScopedWorldEvents = ScopedWorldEvents

ScopedWorldEvents.SCHEMA = "PsychopatzCore.ScopedWorldEvents"
ScopedWorldEvents.SCHEMA_VERSION = 1
ScopedWorldEvents.MODDATA_KEY = "PsychopatzCore.ScopedWorldEvents"
ScopedWorldEvents.MAX_ACTIVE_EVENTS = 32
ScopedWorldEvents.MAX_HISTORY = 64
ScopedWorldEvents.MAX_AFFECTED_SETTLEMENTS = 32
ScopedWorldEvents.MAX_SEMANTIC_TAGS = 16
ScopedWorldEvents.MAX_EFFECT_KEYS = 24
ScopedWorldEvents.MAX_METADATA_KEYS = 16
ScopedWorldEvents.MAX_ID_LENGTH = 128
ScopedWorldEvents.MAX_SOURCE_LENGTH = 96
ScopedWorldEvents.MAX_LISTENERS = 32

ScopedWorldEvents.SCOPES = {
    global = true,
    region = true,
    faction = true,
    settlement = true,
    local_area = true,
}

ScopedWorldEvents.EFFECT_SPECS = {
    foodAvailabilityPressure = { mode = "additive", neutral = 0, min = -1, max = 2 },
    scavengingYieldMultiplier = { mode = "multiplier", neutral = 1, min = 0.1, max = 4 },
    hostileActivityMultiplier = { mode = "multiplier", neutral = 1, min = 0.1, max = 4 },
    travelRisk = { mode = "additive", neutral = 0, min = -1, max = 2 },
    moralePressure = { mode = "additive", neutral = 0, min = -2, max = 2 },
    medicalDemand = { mode = "additive", neutral = 0, min = -1, max = 2 },
    tradeScarcity = { mode = "additive", neutral = 0, min = -1, max = 2 },
    caravanRisk = { mode = "additive", neutral = 0, min = -1, max = 2 },
}

local function isEmpty(tbl)
    for _ in pairs(tbl) do return false end
    return true
end

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

local function safeText(value, limit)
    if type(value) ~= "string" and type(value) ~= "number" then return nil end
    local text = tostring(value)
    if text == "" or #text > (limit or ScopedWorldEvents.MAX_ID_LENGTH)
        or string.match(text, "[%c]")
    then
        return nil
    end
    return text
end

local function safeID(value, limit)
    local text = safeText(value, limit or ScopedWorldEvents.MAX_ID_LENGTH)
    if not text or not string.match(text, "^[%w_%-%.:]+$") then return nil end
    return text
end

local function effectSpecFor(key)
    local known = ScopedWorldEvents.EFFECT_SPECS[key]
    if known then return known end
    if string.sub(key, -10) == "Multiplier" then
        return { mode = "multiplier", neutral = 1, min = 0.1, max = 4 }
    end
    return { mode = "additive", neutral = 0, min = -2, max = 2 }
end

local function normalizeTags(raw)
    local seen = {}
    local list = {}
    if type(raw) ~= "table" then return list end
    for key, val in pairs(raw) do
        local tag = nil
        if type(key) == "number" then
            tag = safeID(val, 64)
        elseif val == true then
            tag = safeID(key, 64)
        end
        if tag and not seen[tag] then
            seen[tag] = true
            list[#list + 1] = tag
        end
    end
    table.sort(list)
    while #list > ScopedWorldEvents.MAX_SEMANTIC_TAGS do
        table.remove(list)
    end
    return list
end

local function normalizeEffects(raw)
    local out = {}
    if type(raw) ~= "table" then return out end
    local keys = {}
    for key in pairs(raw) do
        local name = safeID(key, 64)
        if name then keys[#keys + 1] = name end
    end
    table.sort(keys)
    for index = 1, math.min(#keys, ScopedWorldEvents.MAX_EFFECT_KEYS) do
        local key = keys[index]
        local spec = effectSpecFor(key)
        local val = clamp(raw[key], spec.min, spec.max, nil)
        if val ~= nil then out[key] = val end
    end
    return out
end

local function normalizeMetadata(raw, depth)
    if raw == nil then return nil end
    depth = depth or 0
    local kind = type(raw)
    if kind == "boolean" then return raw end
    if kind == "number" then return finite(raw, nil) end
    if kind == "string" then return safeText(raw, 160) end
    if kind ~= "table" or depth >= 2 then return nil end
    local out = {}
    local count = 0
    for key, child in pairs(raw) do
        if type(key) == "string" or type(key) == "number" then
            count = count + 1
            if count > ScopedWorldEvents.MAX_METADATA_KEYS then break end
            local norm = normalizeMetadata(child, depth + 1)
            if norm ~= nil then out[key] = norm end
        end
    end
    return out
end

local function addUniqueID(seen, list, candidate)
    local id = safeID(candidate)
    if id and not seen[id] then
        seen[id] = true
        list[#list + 1] = id
    end
end

local function collectSettlementsFromCommunities(seen, list, communities, scope, scopeID, spec)
    for key, comm in pairs(communities) do
        if type(comm) == "table" then
            local cid = comm.id or comm.communityID or (type(key) == "string" and key or nil)
            if scope == "region" and comm.regionID == scopeID then
                addUniqueID(seen, list, cid)
            elseif scope == "faction" and comm.factionID == scopeID then
                addUniqueID(seen, list, cid)
            elseif scope == "local_area" and spec.x ~= nil and spec.y ~= nil
                and spec.radius ~= nil and type(comm.home) == "table"
            then
                local dx = (tonumber(comm.home.x) or 0) - tonumber(spec.x)
                local dy = (tonumber(comm.home.y) or 0) - tonumber(spec.y)
                local rad = math.max(0, tonumber(spec.radius) or 0)
                if dx * dx + dy * dy <= rad * rad then
                    addUniqueID(seen, list, cid)
                end
            end
        end
    end
end

local function resolveAffectedSettlements(registry, scope, scopeID, spec, opts)
    local seen = {}
    local list = {}
    if type(spec.affectedSettlements) == "table" then
        for key, val in pairs(spec.affectedSettlements) do
            if type(key) == "number" then
                addUniqueID(seen, list, val)
            elseif val == true then
                addUniqueID(seen, list, key)
            end
        end
    end
    if scope == "settlement" and scopeID then
        addUniqueID(seen, list, scopeID)
    end
    local resolver = (type(opts) == "table" and type(opts.resolveSettlements) == "function"
        and opts.resolveSettlements) or registry._settlementResolver
    if type(resolver) == "function" then
        local resolved = resolver(scope, scopeID, spec)
        if type(resolved) == "table" then
            for key, val in pairs(resolved) do
                if type(key) == "number" then
                    addUniqueID(seen, list, val)
                elseif val == true then
                    addUniqueID(seen, list, key)
                end
            end
        end
    elseif type(opts) == "table" then
        local communities = opts.communities or opts.settlements
        if type(communities) == "table" then
            collectSettlementsFromCommunities(seen, list, communities, scope, scopeID, spec)
        end
    end
    table.sort(list)
    while #list > ScopedWorldEvents.MAX_AFFECTED_SETTLEMENTS do
        table.remove(list)
    end
    return list
end

local function stableEventID(eventType, scope, scopeID, startsAt, source)
    return table.concat({
        "wev",
        eventType,
        scope,
        scopeID or "global",
        tostring(startsAt),
        tostring(Util.hash(source .. ":" .. eventType .. ":" .. tostring(scopeID or "global"))),
    }, ":")
end

local function buildEvent(registry, spec, opts)
    if type(spec) ~= "table" then return nil, "event_spec_required" end
    local eventType = safeID(spec.eventType, 64)
    if not eventType then return nil, "event_type_required" end
    local scope = tostring(spec.scope or "")
    if not ScopedWorldEvents.SCOPES[scope] then return nil, "event_scope_invalid" end

    local rawScopeID = spec.scopeID or spec.scopeId
    if not rawScopeID then
        if scope == "region" then rawScopeID = spec.regionID or spec.regionId
        elseif scope == "faction" then rawScopeID = spec.factionID or spec.factionId
        elseif scope == "settlement" then rawScopeID = spec.settlementID or spec.settlementId
        elseif scope == "local_area" then rawScopeID = spec.localAreaID or spec.locationID
        end
    end
    local scopeID = safeID(rawScopeID)
    if scope == "global" then
        scopeID = scopeID or "global"
    elseif not scopeID then
        return nil, "event_scope_id_required"
    end

    local provenance = spec.provenance ~= nil and tostring(spec.provenance) or "public"
    if not Fact.PROVENANCE[provenance] then return nil, "event_provenance_invalid" end

    local startsAt = math.max(0, finite(spec.startsAt, 0))
    local endsAt = nil
    if spec.endsAt ~= nil then
        endsAt = finite(spec.endsAt, nil)
        if endsAt == nil then return nil, "event_ends_at_invalid" end
        if endsAt < startsAt then endsAt = startsAt end
    end

    local source = safeText(spec.source, ScopedWorldEvents.MAX_SOURCE_LENGTH) or "unknown"
    local eventID = safeID(spec.eventID or spec.eventId or spec.id)
        or stableEventID(eventType, scope, scopeID, startsAt, source)

    return {
        eventID = eventID,
        eventType = eventType,
        semanticTags = normalizeTags(spec.semanticTags),
        scope = scope,
        scopeID = scopeID,
        affectedSettlements = resolveAffectedSettlements(registry, scope, scopeID, spec, opts),
        startsAt = startsAt,
        endsAt = endsAt,
        severity = clamp(spec.severity, 0, 1, 0.5),
        source = source,
        provenance = provenance,
        effects = normalizeEffects(spec.effects),
        metadata = normalizeMetadata(spec.metadata),
    }
end

local function addToBucket(map, key, eventID)
    if not key then return end
    local bucket = map[key]
    if not bucket then
        bucket = {}
        map[key] = bucket
    end
    bucket[eventID] = true
end

local function removeFromBucket(map, key, eventID)
    local bucket = key and map[key]
    if not bucket then return end
    bucket[eventID] = nil
    if isEmpty(bucket) then map[key] = nil end
end

local function indexEvent(reg, ev)
    local id = ev.eventID
    if ev.scope == "global" then
        reg._byScopeGlobal[id] = true
    elseif ev.scope == "region" then
        addToBucket(reg._byRegion, ev.scopeID, id)
    elseif ev.scope == "faction" then
        addToBucket(reg._byFaction, ev.scopeID, id)
    elseif ev.scope == "local_area" then
        addToBucket(reg._byLocalArea, ev.scopeID, id)
    end
    for i = 1, #ev.affectedSettlements do
        addToBucket(reg._bySettlement, ev.affectedSettlements[i], id)
    end
    for i = 1, #ev.semanticTags do
        addToBucket(reg._byEffectTag, ev.semanticTags[i], id)
    end
    for key in pairs(ev.effects) do
        addToBucket(reg._byEffectTag, key, id)
    end
end

local function unindexEvent(reg, ev)
    local id = ev.eventID
    reg._byScopeGlobal[id] = nil
    if ev.scope == "region" then
        removeFromBucket(reg._byRegion, ev.scopeID, id)
    elseif ev.scope == "faction" then
        removeFromBucket(reg._byFaction, ev.scopeID, id)
    elseif ev.scope == "local_area" then
        removeFromBucket(reg._byLocalArea, ev.scopeID, id)
    end
    for i = 1, #ev.affectedSettlements do
        removeFromBucket(reg._bySettlement, ev.affectedSettlements[i], id)
    end
    for i = 1, #ev.semanticTags do
        removeFromBucket(reg._byEffectTag, ev.semanticTags[i], id)
    end
    for key in pairs(ev.effects) do
        removeFromBucket(reg._byEffectTag, key, id)
    end
end

local function pushHistory(reg, ev, reason, nowHours)
    local entry = Util.clone(ev)
    entry.archiveReason = reason
    entry.archivedAt = nowHours
    reg._history[#reg._history + 1] = entry
    while #reg._history > reg.maxHistory do
        table.remove(reg._history, 1)
    end
end

local function dispatchListeners(list, event, meta)
    if not list or #list == 0 then return 0 end
    local snapshot = {}
    for i = 1, #list do snapshot[i] = list[i] end
    local delivered = 0
    for i = 1, #snapshot do
        local sub = snapshot[i]
        if not sub.excludeSource or sub.excludeSource ~= event.source then
            sub.fn(Util.clone(event), meta)
            delivered = delivered + 1
        end
    end
    return delivered
end

local function removeActive(reg, eventID, reason, nowHours, notify)
    local ev = reg._activeByID[eventID]
    if not ev then return nil end
    reg._activeByID[eventID] = nil
    unindexEvent(reg, ev)
    for i = 1, #reg._activeOrder do
        if reg._activeOrder[i] == eventID then
            table.remove(reg._activeOrder, i)
            break
        end
    end
    pushHistory(reg, ev, reason, nowHours)
    if notify ~= false then
        dispatchListeners(reg._listeners.expired, ev, {
            reason = reason,
            nowHours = nowHours,
            source = ev.source,
        })
    end
    return ev
end

local function isEventActiveAt(ev, nowHours)
    if nowHours == nil then return true end
    local t = finite(nowHours, nil)
    if t == nil then return true end
    if t < ev.startsAt then return false end
    if ev.endsAt ~= nil and t >= ev.endsAt then return false end
    return true
end

local function addListener(reg, kind, listener, opts)
    if type(listener) ~= "function" then return nil, "listener_required" end
    opts = type(opts) == "table" and opts or {}
    local list = reg._listeners[kind]
    local owner = opts.owner
    local subID = safeID(opts.id)
    for i = 1, #list do
        local existing = list[i]
        if (subID and existing.id == subID)
            or (existing.fn == listener and existing.owner == owner)
        then
            existing.excludeSource = opts.excludeSource
            return existing.token
        end
    end
    if #list >= ScopedWorldEvents.MAX_LISTENERS then
        return nil, "listener_capacity_exceeded"
    end
    reg._nextListenerToken = reg._nextListenerToken + 1
    local token = reg._nextListenerToken
    list[#list + 1] = {
        token = token,
        id = subID,
        owner = owner,
        excludeSource = opts.excludeSource,
        fn = listener,
    }
    return token
end

local Registry = {}
Registry.__index = Registry

function Registry:Register(spec, opts)
    opts = type(opts) == "table" and opts or {}
    local ev, err = buildEvent(self, spec, opts)
    if not ev then return nil, err end

    local existing = self._activeByID[ev.eventID]
    if existing then
        unindexEvent(self, existing)
        self._activeByID[ev.eventID] = ev
        indexEvent(self, ev)
        self._metrics.updated = self._metrics.updated + 1
        if opts.notify ~= false then
            dispatchListeners(self._listeners.registered, ev, {
                action = "updated",
                source = ev.source,
            })
        end
        return Util.clone(ev), "updated"
    end

    local nowHours = finite(opts.nowHours or opts.now, nil)
    if #self._activeOrder >= self.maxActive and nowHours ~= nil then
        self:PruneExpired(nowHours, { notify = opts.notify })
    end
    while #self._activeOrder >= self.maxActive do
        local oldestID = self._activeOrder[1]
        if oldestID and removeActive(self, oldestID, "evicted", nowHours, opts.notify) then
            self._metrics.evicted = self._metrics.evicted + 1
        else
            break
        end
    end

    self._activeByID[ev.eventID] = ev
    self._activeOrder[#self._activeOrder + 1] = ev.eventID
    indexEvent(self, ev)
    self._metrics.registered = self._metrics.registered + 1

    if opts.notify ~= false then
        dispatchListeners(self._listeners.registered, ev, {
            action = "registered",
            source = ev.source,
        })
    end
    return Util.clone(ev), "registered"
end

function Registry:Remove(eventID, opts)
    opts = type(opts) == "table" and opts or {}
    local id = safeID(eventID)
    if not id or not self._activeByID[id] then return false, "event_not_found" end
    local removed = removeActive(self, id, opts.reason or "removed",
        finite(opts.nowHours or opts.now, nil), opts.notify)
    self._metrics.removed = self._metrics.removed + 1
    return true, Util.clone(removed)
end

function Registry:Get(eventID)
    local id = safeID(eventID)
    local ev = id and self._activeByID[id] or nil
    return ev and Util.clone(ev) or nil
end

function Registry:PruneExpired(nowHours, opts)
    local t = finite(nowHours, nil)
    if t == nil then return 0, {} end
    opts = type(opts) == "table" and opts or {}
    local expiredIDs = {}
    for i = 1, #self._activeOrder do
        local id = self._activeOrder[i]
        local ev = self._activeByID[id]
        if ev and ev.endsAt ~= nil and t >= ev.endsAt then
            expiredIDs[#expiredIDs + 1] = id
        end
    end
    local pruned = {}
    for i = 1, #expiredIDs do
        local ev = removeActive(self, expiredIDs[i], "expired", t, opts.notify)
        if ev then
            self._metrics.expired = self._metrics.expired + 1
            pruned[#pruned + 1] = Util.clone(ev)
        end
    end
    return #pruned, pruned
end

local function normalizeQueryFilter(opts)
    opts = type(opts) == "table" and opts or {}
    local scope = opts.scope
    local regionID = opts.regionID or (scope == "region" and opts.scopeID or nil)
    local factionID = opts.factionID or (scope == "faction" and opts.scopeID or nil)
    local settlementID = opts.settlementID or (scope == "settlement" and opts.scopeID or nil)
    local localAreaID = opts.localAreaID or (scope == "local_area" and opts.scopeID or nil)
    local globalOnly = opts.global == true
        and not regionID and not factionID and not settlementID and not localAreaID
    local includeGlobal = (opts.global ~= false) and (opts.includeGlobal ~= false)
        and (opts.exactScope ~= true)
    return {
        scope = scope,
        regionID = safeID(regionID),
        factionID = safeID(factionID),
        settlementID = safeID(settlementID),
        localAreaID = safeID(localAreaID),
        effectTag = safeID(opts.effectTag, 64),
        eventType = safeID(opts.eventType, 64),
        source = opts.source,
        globalOnly = globalOnly,
        includeGlobal = includeGlobal,
    }
end

function Registry:QueryActive(opts, nowHours)
    local f = normalizeQueryFilter(opts)
    local candidates = {}
    local seen = {}

    local function collectBucket(bucket)
        if not bucket then return end
        for id in pairs(bucket) do
            if not seen[id] then
                seen[id] = true
                candidates[#candidates + 1] = id
            end
        end
    end

    if f.globalOnly then
        collectBucket(self._byScopeGlobal)
    elseif f.settlementID then
        collectBucket(self._bySettlement[f.settlementID])
        if f.includeGlobal then collectBucket(self._byScopeGlobal) end
    elseif f.regionID then
        collectBucket(self._byRegion[f.regionID])
        if f.includeGlobal then collectBucket(self._byScopeGlobal) end
    elseif f.factionID then
        collectBucket(self._byFaction[f.factionID])
        if f.includeGlobal then collectBucket(self._byScopeGlobal) end
    elseif f.localAreaID then
        collectBucket(self._byLocalArea[f.localAreaID])
        if f.includeGlobal then collectBucket(self._byScopeGlobal) end
    elseif f.effectTag then
        collectBucket(self._byEffectTag[f.effectTag])
    else
        for i = 1, #self._activeOrder do
            candidates[i] = self._activeOrder[i]
        end
    end

    local results = {}
    local tagBucket = f.effectTag and self._byEffectTag[f.effectTag] or nil
    local regBucket = f.regionID and self._byRegion[f.regionID] or nil
    local facBucket = f.factionID and self._byFaction[f.factionID] or nil
    local areaBucket = f.localAreaID and self._byLocalArea[f.localAreaID] or nil

    for i = 1, #candidates do
        local id = candidates[i]
        local ev = self._activeByID[id]
        if ev and isEventActiveAt(ev, nowHours) then
            local isGlobal = ev.scope == "global"
            local pass = true
            if f.scope and ev.scope ~= f.scope and not (isGlobal and f.includeGlobal) then
                pass = false
            end
            if pass and f.effectTag and (not tagBucket or not tagBucket[id]) then
                pass = false
            end
            if pass and f.regionID and not (isGlobal and f.includeGlobal)
                and (not regBucket or not regBucket[id])
            then
                pass = false
            end
            if pass and f.factionID and not (isGlobal and f.includeGlobal)
                and (not facBucket or not facBucket[id])
            then
                pass = false
            end
            if pass and f.localAreaID and not (isGlobal and f.includeGlobal)
                and (not areaBucket or not areaBucket[id])
            then
                pass = false
            end
            if pass and f.eventType and ev.eventType ~= f.eventType then
                pass = false
            end
            if pass and f.source and ev.source ~= f.source then
                pass = false
            end
            if pass then
                results[#results + 1] = Util.clone(ev)
            end
        end
    end

    table.sort(results, function(a, b)
        if a.startsAt == b.startsAt then return a.eventID < b.eventID end
        return a.startsAt < b.startsAt
    end)
    return results
end

function Registry:AggregateEffects(opts, nowHours)
    local matched = self:QueryActive(opts, nowHours)
    local combined = {}
    for key, spec in pairs(ScopedWorldEvents.EFFECT_SPECS) do
        combined[key] = spec.neutral
    end
    local eventIDs = {}
    local maxSeverity = 0
    for i = 1, #matched do
        local ev = matched[i]
        eventIDs[#eventIDs + 1] = ev.eventID
        if ev.severity > maxSeverity then maxSeverity = ev.severity end
        for key, val in pairs(ev.effects) do
            local spec = effectSpecFor(key)
            if spec.mode == "multiplier" then
                combined[key] = (combined[key] or spec.neutral) * val
            else
                combined[key] = (combined[key] or spec.neutral) + val
            end
        end
    end
    for key, val in pairs(combined) do
        local spec = effectSpecFor(key)
        combined[key] = clamp(val, spec.min, spec.max, spec.neutral)
    end
    return {
        effects = combined,
        eventCount = #matched,
        eventIDs = eventIDs,
        maxSeverity = maxSeverity,
    }
end

function Registry:GetHistory(limit)
    local maximum = math.max(0, math.floor(tonumber(limit) or #self._history))
    local out = {}
    for i = #self._history, math.max(1, #self._history - maximum + 1), -1 do
        out[#out + 1] = Util.clone(self._history[i])
    end
    return out
end

function Registry:GetStats()
    return {
        activeCount = #self._activeOrder,
        historyCount = #self._history,
        maxActive = self.maxActive,
        maxHistory = self.maxHistory,
        metrics = Util.clone(self._metrics),
    }
end

function Registry:OnEventRegistered(listener, opts)
    return addListener(self, "registered", listener, opts)
end

function Registry:OnEventExpired(listener, opts)
    return addListener(self, "expired", listener, opts)
end

function Registry:OnStateLoaded(listener, opts)
    return addListener(self, "state_loaded", listener, opts)
end

function Registry:Unsubscribe(tokenOrListener)
    local removed = 0
    for _, kind in ipairs({ "registered", "expired", "state_loaded" }) do
        local list = self._listeners[kind]
        for i = #list, 1, -1 do
            if list[i].token == tokenOrListener or list[i].fn == tokenOrListener then
                table.remove(list, i)
                removed = removed + 1
            end
        end
    end
    return removed
end

function Registry:ClearListeners(owner)
    local removed = 0
    for _, kind in ipairs({ "registered", "expired", "state_loaded" }) do
        local list = self._listeners[kind]
        for i = #list, 1, -1 do
            if owner == nil or list[i].owner == owner then
                table.remove(list, i)
                removed = removed + 1
            end
        end
    end
    return removed
end

function Registry:ToPayload()
    local events = {}
    for i = 1, #self._activeOrder do
        local ev = self._activeByID[self._activeOrder[i]]
        if ev then events[#events + 1] = Util.clone(ev) end
    end
    return {
        schema = ScopedWorldEvents.SCHEMA,
        schemaVersion = ScopedWorldEvents.SCHEMA_VERSION,
        events = events,
        history = Util.clone(self._history),
    }
end

function Registry:LoadPayload(payload, opts)
    opts = type(opts) == "table" and opts or {}
    if type(payload) ~= "table"
        or payload.schema ~= ScopedWorldEvents.SCHEMA
        or tonumber(payload.schemaVersion) ~= ScopedWorldEvents.SCHEMA_VERSION
    then
        return false, "scoped_world_events_schema_mismatch"
    end
    local nowHours = finite(opts.nowHours or opts.now, nil)
    self._activeByID = {}
    self._activeOrder = {}
    self._byScopeGlobal = {}
    self._byRegion = {}
    self._byFaction = {}
    self._bySettlement = {}
    self._byLocalArea = {}
    self._byEffectTag = {}
    self._history = {}

    local hist = type(payload.history) == "table" and payload.history or {}
    local startIdx = math.max(1, #hist - self.maxHistory + 1)
    for i = startIdx, #hist do
        if type(hist[i]) == "table" then
            self._history[#self._history + 1] = Util.clone(hist[i])
        end
    end

    local events = type(payload.events) == "table" and payload.events or {}
    for i = 1, #events do
        local built = buildEvent(self, events[i], opts)
        if built then
            if nowHours ~= nil and built.endsAt ~= nil and nowHours >= built.endsAt then
                pushHistory(self, built, "expired_on_load", nowHours)
                self._metrics.expired = self._metrics.expired + 1
            else
                self:Register(built, { notify = false, nowHours = nowHours })
            end
        end
    end

    if opts.notify ~= false then
        dispatchListeners(self._listeners.state_loaded, {
            source = "PsychopatzCore.Persistence",
            activeCount = #self._activeOrder,
            historyCount = #self._history,
            nowHours = nowHours,
            activeEvents = self:QueryActive(nil, nowHours),
        }, {
            action = "loaded",
            nowHours = nowHours,
        })
    end
    return true
end

function ScopedWorldEvents.NewRegistry(options)
    options = type(options) == "table" and options or {}
    local reg = {
        maxActive = math.max(1, math.min(ScopedWorldEvents.MAX_ACTIVE_EVENTS,
            math.floor(tonumber(options.maxActive) or ScopedWorldEvents.MAX_ACTIVE_EVENTS))),
        maxHistory = math.max(1, math.min(ScopedWorldEvents.MAX_HISTORY,
            math.floor(tonumber(options.maxHistory) or ScopedWorldEvents.MAX_HISTORY))),
        _settlementResolver = options.settlementResolver,
        _activeByID = {},
        _activeOrder = {},
        _byScopeGlobal = {},
        _byRegion = {},
        _byFaction = {},
        _bySettlement = {},
        _byLocalArea = {},
        _byEffectTag = {},
        _history = {},
        _listeners = { registered = {}, expired = {}, state_loaded = {} },
        _nextListenerToken = 0,
        _metrics = { registered = 0, updated = 0, expired = 0, evicted = 0, removed = 0 },
    }
    return setmetatable(reg, Registry)
end

ScopedWorldEvents._default = ScopedWorldEvents._default or ScopedWorldEvents.NewRegistry()

function ScopedWorldEvents.Reset(options)
    ScopedWorldEvents._default = ScopedWorldEvents.NewRegistry(options)
    return ScopedWorldEvents._default
end

function ScopedWorldEvents.Register(spec, opts)
    return ScopedWorldEvents._default:Register(spec, opts)
end

function ScopedWorldEvents.Remove(eventID, opts)
    return ScopedWorldEvents._default:Remove(eventID, opts)
end

function ScopedWorldEvents.Get(eventID)
    return ScopedWorldEvents._default:Get(eventID)
end

function ScopedWorldEvents.QueryActive(opts, nowHours)
    return ScopedWorldEvents._default:QueryActive(opts, nowHours)
end

function ScopedWorldEvents.AggregateEffects(opts, nowHours)
    return ScopedWorldEvents._default:AggregateEffects(opts, nowHours)
end

function ScopedWorldEvents.PruneExpired(nowHours, opts)
    return ScopedWorldEvents._default:PruneExpired(nowHours, opts)
end

function ScopedWorldEvents.GetHistory(limit)
    return ScopedWorldEvents._default:GetHistory(limit)
end

function ScopedWorldEvents.GetStats()
    return ScopedWorldEvents._default:GetStats()
end

function ScopedWorldEvents.OnEventRegistered(listener, opts)
    return ScopedWorldEvents._default:OnEventRegistered(listener, opts)
end

function ScopedWorldEvents.OnEventExpired(listener, opts)
    return ScopedWorldEvents._default:OnEventExpired(listener, opts)
end

function ScopedWorldEvents.OnStateLoaded(listener, opts)
    return ScopedWorldEvents._default:OnStateLoaded(listener, opts)
end

function ScopedWorldEvents.Unsubscribe(tokenOrListener)
    return ScopedWorldEvents._default:Unsubscribe(tokenOrListener)
end

function ScopedWorldEvents.ClearListeners(owner)
    return ScopedWorldEvents._default:ClearListeners(owner)
end

function ScopedWorldEvents.ToPayload()
    return ScopedWorldEvents._default:ToPayload()
end

function ScopedWorldEvents.LoadPayload(payload, opts)
    return ScopedWorldEvents._default:LoadPayload(payload, opts)
end

local function currentWorldHours(opts)
    if type(opts) == "table" and finite(opts.nowHours or opts.now, nil) ~= nil then
        return finite(opts.nowHours or opts.now, nil)
    end
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getWorldAgeHours) == "function" then
            return finite(gt:getWorldAgeHours(), nil)
        end
    end
    return nil
end

local function persistenceAllowed(opts)
    if type(opts) == "table" and opts.force == true then return true end
    local role = PsychopatzCore and PsychopatzCore.RuntimeRole or nil
    if role and type(role.AllowsServerCode) == "function" then
        return role.AllowsServerCode()
    end
    return true
end

function ScopedWorldEvents.SaveToModData(opts)
    opts = type(opts) == "table" and opts or {}
    if not persistenceAllowed(opts) then
        return false, "server_authority_required"
    end
    local store = type(opts.modData) == "table" and opts.modData or nil
    if not store and type(ModData) == "table" and type(ModData.getOrCreate) == "function" then
        store = ModData.getOrCreate(ScopedWorldEvents.MODDATA_KEY)
    end
    if type(store) ~= "table" then
        return false, "moddata_unavailable"
    end
    local nowHours = currentWorldHours(opts)
    if nowHours ~= nil then
        ScopedWorldEvents.PruneExpired(nowHours, { notify = false })
    end
    store.schema = ScopedWorldEvents.SCHEMA
    store.schemaVersion = ScopedWorldEvents.SCHEMA_VERSION
    store.scopedPayload = ScopedWorldEvents.ToPayload()
    local observer = opts.observer or (PsychopatzCore and PsychopatzCore.VanillaEventObserver or nil)
    if type(observer) == "table" and type(observer.ToPayload) == "function" then
        store.observerPayload = observer.ToPayload()
    end
    return true, store
end

function ScopedWorldEvents.LoadFromModData(opts)
    opts = type(opts) == "table" and opts or {}
    local store = type(opts.modData) == "table" and opts.modData or nil
    if not store and type(ModData) == "table" then
        if type(ModData.get) == "function" then
            store = ModData.get(ScopedWorldEvents.MODDATA_KEY)
        elseif type(ModData.getOrCreate) == "function" then
            store = ModData.getOrCreate(ScopedWorldEvents.MODDATA_KEY)
        end
    end
    if type(store) ~= "table" or type(store.scopedPayload) ~= "table" then
        return false, "scoped_world_events_moddata_empty"
    end
    local nowHours = currentWorldHours(opts)
    local observer = opts.observer or (PsychopatzCore and PsychopatzCore.VanillaEventObserver or nil)
    if type(store.observerPayload) == "table"
        and type(observer) == "table"
        and type(observer.LoadPayload) == "function"
    then
        observer.LoadPayload(store.observerPayload, nowHours)
    end
    return ScopedWorldEvents.LoadPayload(store.scopedPayload, {
        nowHours = nowHours,
        notify = opts.notify,
    })
end

function ScopedWorldEvents.InstallPersistenceHooks()
    if ScopedWorldEvents._persistenceHooksInstalled then return true end
    if type(Events) ~= "table" then return false, "events_unavailable" end
    if not persistenceAllowed() then return false, "server_authority_required" end
    ScopedWorldEvents._persistenceHooksInstalled = true
    if type(Events.OnInitGlobalModData) == "table"
        and type(Events.OnInitGlobalModData.Add) == "function"
    then
        Events.OnInitGlobalModData.Add(function()
            ScopedWorldEvents.LoadFromModData()
        end)
    end
    if type(Events.OnSave) == "table" and type(Events.OnSave.Add) == "function" then
        Events.OnSave.Add(function()
            ScopedWorldEvents.SaveToModData()
        end)
    end
    return true
end

ScopedWorldEvents.InstallPersistenceHooks()

return ScopedWorldEvents
