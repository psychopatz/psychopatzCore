-- Canonical, bounded, ModData-serializable World Events ledger for
-- PsychopatzCore SurvivorWorld. Shared by ProjectHoomans (aftermath, SOS),
-- DynamicTrading (DTAbstract), and any future Events / Roaming Horde mods.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Events = {}

Events.SCHEMA_VERSION = 1
Events.MAX_ACTIVE_EVENTS = 32
Events.DEFAULT_TTL_HOURS = 48

Events._events = Events._events or {}
Events._order = Events._order or {}
Events._subscribers = Events._subscribers or {}
Events._serial = Events._serial or 0

local function cloneTable(t)
    if type(t) ~= "table" then return t end
    if Util and type(Util.clone) == "function" then
        return Util.clone(t)
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == "table" and cloneTable(v) or v
    end
    return copy
end

local function notify(event, lifecycle)
    local kind = tostring(event and event.kind or "")
    local buckets = { Events._subscribers[kind], Events._subscribers["*"] }
    for b = 1, #buckets do
        local list = buckets[b]
        if type(list) == "table" then
            for i = 1, #list do
                pcall(list[i], event, lifecycle)
            end
        end
    end
end

function Events.Subscribe(kindOrWildcard, handler)
    local key = tostring(kindOrWildcard or "*")
    if key == "" or type(handler) ~= "function" then return false end
    Events._subscribers[key] = Events._subscribers[key] or {}
    Events._subscribers[key][#Events._subscribers[key] + 1] = handler
    return true
end

function Events.PruneExpired(nowHours)
    nowHours = tonumber(nowHours)
    if not nowHours then return 0 end
    local kept = {}
    local removed = 0
    for i = 1, #Events._order do
        local id = Events._order[i]
        local ev = Events._events[id]
        if ev and (tonumber(ev.expiresAt) or 0) > nowHours and ev.active ~= false then
            kept[#kept + 1] = id
        else
            if ev then
                ev.active = false
                notify(ev, "expired")
            end
            Events._events[id] = nil
            removed = removed + 1
        end
    end
    Events._order = kept
    return removed
end

function Events.Publish(spec, nowHours)
    if type(spec) ~= "table" then return nil, "spec_required" end
    local x = tonumber(spec.x)
    local y = tonumber(spec.y)
    if x == nil or y == nil then return nil, "coords_required" end
    local now = tonumber(nowHours) or tonumber(spec.createdAt) or 0
    Events.PruneExpired(now)

    local id = tostring(spec.id or "")
    if id == "" then
        Events._serial = Events._serial + 1
        id = "swevt_" .. tostring(Events._serial)
    end
    local ttl = math.max(0.5, tonumber(spec.ttlHours) or Events.DEFAULT_TTL_HOURS)
    local expiresAt = tonumber(spec.expiresAt) or (now + ttl)
    local existed = Events._events[id] ~= nil

    local ev = {
        schemaVersion = Events.SCHEMA_VERSION,
        id = id,
        kind = tostring(spec.kind or "WORLD_EVENT"),
        ownerMod = tostring(spec.ownerMod or "PsychopatzCore"),
        x = math.floor(x + 0.5),
        y = math.floor(y + 0.5),
        z = tonumber(spec.z) or 0,
        radius = math.max(0, tonumber(spec.radius) or 48),
        severity = tonumber(spec.severity) or 1,
        createdAt = now,
        expiresAt = expiresAt,
        active = true,
        summary = tostring(spec.summary or ""),
        tags = cloneTable(type(spec.tags) == "table" and spec.tags or {}),
        payload = cloneTable(type(spec.payload) == "table" and spec.payload or {}),
    }

    Events._events[id] = ev
    if not existed then
        Events._order[#Events._order + 1] = id
    end
    while #Events._order > Events.MAX_ACTIVE_EVENTS do
        local oldestId = table.remove(Events._order, 1)
        if oldestId and oldestId ~= id then
            Events._events[oldestId] = nil
        end
    end
    notify(ev, existed and "updated" or "published")
    return cloneTable(ev)
end

function Events.Cancel(id, reason)
    id = tostring(id or "")
    local ev = Events._events[id]
    if not ev then return false end
    ev.active = false
    ev.cancelReason = tostring(reason or "cancelled")
    Events._events[id] = nil
    for i = 1, #Events._order do
        if Events._order[i] == id then
            table.remove(Events._order, i)
            break
        end
    end
    notify(ev, "cancelled")
    return true
end

function Events.Get(id)
    local ev = Events._events[tostring(id or "")]
    return ev and cloneTable(ev) or nil
end

function Events.List(filter)
    filter = type(filter) == "table" and filter or nil
    local out = {}
    for i = 1, #Events._order do
        local ev = Events._events[Events._order[i]]
        if ev and ev.active ~= false then
            local match = true
            if filter then
                if filter.kind and ev.kind ~= tostring(filter.kind) then match = false end
                if filter.ownerMod and ev.ownerMod ~= tostring(filter.ownerMod) then match = false end
            end
            if match then
                out[#out + 1] = cloneTable(ev)
            end
        end
    end
    return out
end

function Events.QueryNear(x, y, radius, filter)
    x = tonumber(x)
    y = tonumber(y)
    radius = math.max(0, tonumber(radius) or 100)
    if x == nil or y == nil then return {} end
    local out = {}
    local list = Events.List(filter)
    for i = 1, #list do
        local ev = list[i]
        local dx = ev.x - x
        local dy = ev.y - y
        local r = radius + (tonumber(ev.radius) or 0)
        if (dx * dx + dy * dy) <= (r * r) then
            out[#out + 1] = ev
        end
    end
    return out
end

-- Compact, ModData-safe export/restore for save/reload durability.
function Events.ExportSnapshot()
    return {
        schemaVersion = Events.SCHEMA_VERSION,
        serial = Events._serial,
        events = Events.List(),
    }
end

function Events.RestoreSnapshot(snapshot, nowHours)
    Events._events = {}
    Events._order = {}
    if type(snapshot) ~= "table" then return 0 end
    Events._serial = math.max(0, math.floor(tonumber(snapshot.serial) or 0))
    local list = type(snapshot.events) == "table" and snapshot.events or {}
    local restored = 0
    for i = 1, math.min(#list, Events.MAX_ACTIVE_EVENTS) do
        local ev = list[i]
        if type(ev) == "table" and ev.id and tonumber(ev.x) and tonumber(ev.y) then
            if not tonumber(nowHours) or (tonumber(ev.expiresAt) or 0) > tonumber(nowHours) then
                local id = tostring(ev.id)
                Events._events[id] = cloneTable(ev)
                Events._events[id].active = true
                Events._order[#Events._order + 1] = id
                restored = restored + 1
            end
        end
    end
    return restored
end

function Events.Reset()
    Events._events = {}
    Events._order = {}
    Events._subscribers = {}
    Events._serial = 0
end

return Events
