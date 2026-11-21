-- Bounded spatial ShockingEventBus for AI reactivity without per-tick world scans.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ShockingEventBus = PsychopatzCore.ShockingEventBus or {}

local Bus = PsychopatzCore.ShockingEventBus

Bus.MAX_EVENTS = 128
Bus.CELL_SIZE = 32
Bus.DEFAULT_TTL_MS = 15000
Bus.DEFAULT_DEDUP_WINDOW_MS = 1000
Bus.DEFAULT_QUERY_LIMIT = 16

Bus._eventsOrder = Bus._eventsOrder or {}
Bus._head = Bus._head or 1
Bus._tail = Bus._tail or 0
Bus._activeCount = Bus._activeCount or 0
Bus._byId = Bus._byId or {}
Bus._cells = Bus._cells or {}
Bus._dedupIndex = Bus._dedupIndex or {}
Bus._listeners = Bus._listeners or {}
Bus._sequence = Bus._sequence or 0
Bus._stats = Bus._stats or {
    emitted = 0,
    deduplicated = 0,
    evicted = 0,
    expired = 0,
    delivered = 0,
}

local function isEmpty(tbl)
    for _ in pairs(tbl) do
        return false
    end
    return true
end

local function nowMs()
    if PsychopatzCore.Time and type(PsychopatzCore.Time.NowMs) == "function" then
        return tonumber(PsychopatzCore.Time.NowMs()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function cellCoords(x, y, radius)
    local size = Bus.CELL_SIZE
    local minCx = math.floor((x - radius) / size)
    local maxCx = math.floor((x + radius) / size)
    local minCy = math.floor((y - radius) / size)
    local maxCy = math.floor((y + radius) / size)
    return minCx, maxCx, minCy, maxCy
end

local function compactQueue()
    if Bus._head <= 128 or Bus._head <= Bus._tail / 2 then
        return
    end
    local compacted = {}
    local idx = 0
    for i = Bus._head, Bus._tail do
        local evId = Bus._eventsOrder[i]
        if evId and Bus._byId[evId] ~= nil then
            idx = idx + 1
            compacted[idx] = evId
        end
    end
    Bus._eventsOrder = compacted
    Bus._head = 1
    Bus._tail = idx
end

local function removeEvent(event)
    if type(event) ~= "table" or not event.id then return false end
    local id = event.id
    if Bus._byId[id] == nil then return false end
    local cellKeys = event.cellKeys or {}
    for i = 1, #cellKeys do
        local cKey = cellKeys[i]
        local bucket = Bus._cells[cKey]
        if bucket then
            bucket[id] = nil
            if isEmpty(bucket) then
                Bus._cells[cKey] = nil
            end
        end
    end
    if event.dedupKey and Bus._dedupIndex[event.dedupKey]
        and Bus._dedupIndex[event.dedupKey].eventId == id
    then
        Bus._dedupIndex[event.dedupKey] = nil
    end
    Bus._byId[id] = nil
    Bus._activeCount = math.max(0, (tonumber(Bus._activeCount) or 0) - 1)
    return true
end

local function popOldestActive()
    while Bus._head <= Bus._tail do
        local evId = Bus._eventsOrder[Bus._head]
        Bus._eventsOrder[Bus._head] = nil
        Bus._head = Bus._head + 1
        local ev = evId and Bus._byId[evId] or nil
        if ev then
            removeEvent(ev)
            compactQueue()
            return ev
        end
    end
    Bus._eventsOrder = {}
    Bus._head = 1
    Bus._tail = 0
    return nil
end

local function deliverTo(list, event)
    if type(list) ~= "table" or #list == 0 then return 0 end
    local snapshot = {}
    for i = 1, #list do
        snapshot[i] = list[i]
    end
    local count = 0
    for i = 1, #snapshot do
        local fn = snapshot[i][1]
        if type(fn) == "function" then
            fn(event)
            count = count + 1
        end
    end
    return count
end

---Emits a spatial shocking event, enforcing dedup window and MAX_EVENTS capacity.
function Bus.Emit(spec)
    if type(spec) ~= "table" then return nil, "INVALID_EVENT_SPEC" end
    local eventType = tostring(spec.eventType or "")
    if eventType == "" then return nil, "EVENT_TYPE_REQUIRED" end
    local x = tonumber(spec.x)
    local y = tonumber(spec.y)
    if x == nil or y == nil then return nil, "EVENT_COORDINATES_REQUIRED" end

    local z = tonumber(spec.z) or 0
    local radius = math.max(1, tonumber(spec.radius) or 18)
    local severity = tonumber(spec.severity) or 50
    local ttlMs = math.max(1, tonumber(spec.ttlMs) or Bus.DEFAULT_TTL_MS)
    local at = tonumber(spec.at) or nowMs()
    local dedupWindowMs = math.max(0, tonumber(spec.dedupWindowMs) or Bus.DEFAULT_DEDUP_WINDOW_MS)

    local dKey = nil
    if spec.dedupKey ~= nil and tostring(spec.dedupKey) ~= "" then
        dKey = eventType .. "|" .. tostring(spec.dedupKey)
        local dEntry = Bus._dedupIndex[dKey]
        if dEntry then
            local existing = Bus._byId[dEntry.eventId]
            if existing and at < (tonumber(dEntry.dedupUntil) or 0)
                and at < (tonumber(existing.expiresAt) or 0)
            then
                existing.lastAt = at
                existing.expiresAt = math.max(existing.expiresAt, at + ttlMs)
                existing.severity = math.max(tonumber(existing.severity) or 0, severity)
                dEntry.dedupUntil = at + dedupWindowMs
                Bus._stats.deduplicated = Bus._stats.deduplicated + 1
                return existing, "deduplicated"
            end
            Bus._dedupIndex[dKey] = nil
        end
    end

    -- Lazily prune any expired oldest events first before counting capacity.
    while Bus._head <= Bus._tail do
        local headId = Bus._eventsOrder[Bus._head]
        local headEv = headId and Bus._byId[headId] or nil
        if not headEv then
            Bus._eventsOrder[Bus._head] = nil
            Bus._head = Bus._head + 1
        elseif (tonumber(headEv.expiresAt) or 0) <= at then
            popOldestActive()
            Bus._stats.expired = Bus._stats.expired + 1
        else
            break
        end
    end

    while Bus._activeCount >= Bus.MAX_EVENTS do
        if not popOldestActive() then break end
        Bus._stats.evicted = Bus._stats.evicted + 1
    end

    Bus._sequence = Bus._sequence + 1
    local id = "shock:" .. tostring(Bus._sequence)
    local event = {
        id = id,
        eventType = eventType,
        x = x,
        y = y,
        z = z,
        radius = radius,
        severity = severity,
        sourceId = spec.sourceId,
        targetId = spec.targetId,
        payload = spec.payload,
        dedupKey = dKey,
        emittedAt = at,
        lastAt = at,
        expiresAt = at + ttlMs,
        cellKeys = {},
    }

    local minCx, maxCx, minCy, maxCy = cellCoords(x, y, radius)
    for cx = minCx, maxCx do
        for cy = minCy, maxCy do
            local cKey = tostring(cx) .. ":" .. tostring(cy)
            local bucket = Bus._cells[cKey]
            if not bucket then
                bucket = {}
                Bus._cells[cKey] = bucket
            end
            bucket[id] = true
            event.cellKeys[#event.cellKeys + 1] = cKey
        end
    end

    Bus._byId[id] = event
    Bus._tail = Bus._tail + 1
    Bus._eventsOrder[Bus._tail] = id
    Bus._activeCount = Bus._activeCount + 1
    if dKey and dedupWindowMs > 0 then
        Bus._dedupIndex[dKey] = {
            eventId = id,
            dedupUntil = at + dedupWindowMs,
        }
    end
    Bus._stats.emitted = Bus._stats.emitted + 1

    local delivered = deliverTo(Bus._listeners[eventType], event)
    if eventType ~= "*" then
        delivered = delivered + deliverTo(Bus._listeners["*"], event)
    end
    Bus._stats.delivered = Bus._stats.delivered + delivered

    return event, "emitted"
end

---Queries active shocking events near `(x, y, z)` bounded by spatial cells and `limit`.
function Bus.QueryNear(x, y, z, maxRadius, opts)
    local qx = tonumber(x)
    local qy = tonumber(y)
    if qx == nil or qy == nil then return {} end
    local qz = tonumber(z) or 0
    local radius = math.max(1, tonumber(maxRadius) or 32)
    opts = type(opts) == "table" and opts or {}

    local currentAt = tonumber(opts.at) or nowMs()
    local maxZDelta = tonumber(opts.maxZDelta) or 1
    local limit = math.max(1, math.floor(tonumber(opts.limit) or Bus.DEFAULT_QUERY_LIMIT))
    local ignoreEventRadius = opts.ignoreEventRadius == true
    local filterType = opts.eventType and tostring(opts.eventType) or nil
    local radiusSq = radius * radius

    local seen = {}
    local matches = {}
    local minCx, maxCx, minCy, maxCy = cellCoords(qx, qy, radius)
    for cx = minCx, maxCx do
        for cy = minCy, maxCy do
            local cKey = tostring(cx) .. ":" .. tostring(cy)
            local bucket = Bus._cells[cKey]
            if bucket then
                local bucketIds = {}
                for evId in pairs(bucket) do
                    bucketIds[#bucketIds + 1] = evId
                end
                for i = 1, #bucketIds do
                    local evId = bucketIds[i]
                    if not seen[evId] then
                        seen[evId] = true
                        local ev = Bus._byId[evId]
                        if ev then
                            if (tonumber(ev.expiresAt) or 0) <= currentAt then
                                removeEvent(ev)
                                Bus._stats.expired = Bus._stats.expired + 1
                            elseif (filterType == nil or ev.eventType == filterType)
                                and math.abs((tonumber(ev.z) or 0) - qz) <= maxZDelta
                            then
                                local dx = ev.x - qx
                                local dy = ev.y - qy
                                local distSq = dx * dx + dy * dy
                                local evRadius = tonumber(ev.radius) or 18
                                if distSq <= radiusSq
                                    and (ignoreEventRadius or distSq <= evRadius * evRadius)
                                then
                                    matches[#matches + 1] = ev
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(matches, function(a, b)
        local sevA = tonumber(a.severity) or 0
        local sevB = tonumber(b.severity) or 0
        if sevA ~= sevB then return sevA > sevB end
        local tA = tonumber(a.emittedAt) or 0
        local tB = tonumber(b.emittedAt) or 0
        if tA ~= tB then return tA > tB end
        return tostring(a.id) < tostring(b.id)
    end)

    if #matches > limit then
        local trimmed = {}
        for i = 1, limit do
            trimmed[i] = matches[i]
        end
        return trimmed
    end
    return matches
end

function Bus.Prune(at)
    local currentAt = tonumber(at) or nowMs()
    local expiredIds = {}
    for evId, ev in pairs(Bus._byId) do
        if (tonumber(ev.expiresAt) or 0) <= currentAt then
            expiredIds[#expiredIds + 1] = evId
        end
    end
    for i = 1, #expiredIds do
        local ev = Bus._byId[expiredIds[i]]
        if ev and removeEvent(ev) then
            Bus._stats.expired = Bus._stats.expired + 1
        end
    end
    local expiredDedup = {}
    for dKey, entry in pairs(Bus._dedupIndex) do
        if Bus._byId[entry.eventId] == nil
            or (tonumber(entry.dedupUntil) or 0) <= currentAt
        then
            expiredDedup[#expiredDedup + 1] = dKey
        end
    end
    for i = 1, #expiredDedup do
        Bus._dedupIndex[expiredDedup[i]] = nil
    end
    compactQueue()
    return #expiredIds
end

function Bus.Subscribe(eventType, listener, ownerToken)
    if type(eventType) ~= "string" or eventType == ""
        or type(listener) ~= "function"
    then
        return false
    end
    local list = Bus._listeners[eventType]
    if not list then
        list = {}
        Bus._listeners[eventType] = list
    end
    for i = 1, #list do
        if list[i][1] == listener and list[i][2] == ownerToken then
            return true
        end
    end
    list[#list + 1] = { listener, ownerToken }
    return true
end

function Bus.Unsubscribe(eventType, listener)
    local list = Bus._listeners[eventType]
    if not list then return false end
    for i = #list, 1, -1 do
        if list[i][1] == listener then
            table.remove(list, i)
            if #list == 0 then Bus._listeners[eventType] = nil end
            return true
        end
    end
    return false
end

function Bus.ClearOwner(ownerToken)
    local removed = 0
    for eventType, list in pairs(Bus._listeners) do
        for i = #list, 1, -1 do
            if list[i][2] == ownerToken then
                table.remove(list, i)
                removed = removed + 1
            end
        end
        if #list == 0 then Bus._listeners[eventType] = nil end
    end
    return removed
end

function Bus.GetStats()
    return {
        activeCount = Bus._activeCount,
        emitted = Bus._stats.emitted,
        deduplicated = Bus._stats.deduplicated,
        evicted = Bus._stats.evicted,
        expired = Bus._stats.expired,
        delivered = Bus._stats.delivered,
    }
end

function Bus.Reset()
    Bus._eventsOrder = {}
    Bus._head = 1
    Bus._tail = 0
    Bus._activeCount = 0
    Bus._byId = {}
    Bus._cells = {}
    Bus._dedupIndex = {}
    Bus._listeners = {}
    Bus._sequence = 0
    Bus._stats = {
        emitted = 0,
        deduplicated = 0,
        evicted = 0,
        expired = 0,
        delivered = 0,
    }
end

return Bus
