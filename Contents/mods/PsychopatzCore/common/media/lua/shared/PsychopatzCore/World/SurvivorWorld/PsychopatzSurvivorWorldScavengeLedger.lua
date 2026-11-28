-- Bounded, zero-tick lazy-regeneration scavenge ledger for building clusters & clearings.
-- Shared by PsychopatzCore, Project Hoomans, and DynamicTrading (DTAbstract).
-- Uses integer-packed 40-tile cluster keys (zero string GC churn) and O(1) lazy
-- timestamp decay so scavengers naturally branch out house-to-house instead of
-- looping into exhausted buildings, with ~1.5 KB max ModData footprint.

local Ledger = {}

Ledger.SCHEMA_VERSION = 1
Ledger.MAX_ENTRIES = 64
Ledger.CLUSTER_SIZE = 40
Ledger.REGEN_HOURS = 168 -- 7 in-game days
Ledger.EXHAUSTED_THRESHOLD = 0.85
Ledger.CLEANUP_EPSILON = 0.01

local COORD_OFFSET = 32768
local COORD_STRIDE = 65536

Ledger.State = Ledger.State or {
    entries = {},
    count = 0,
    revision = 1,
}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function currentWorldHours(nowHours)
    local h = tonumber(nowHours)
    if h ~= nil and h == h and h ~= math.huge and h ~= -math.huge then
        return h
    end
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getWorldAgeHours) == "function" then
            return finite(gt:getWorldAgeHours(), 0)
        end
    end
    return 0
end

function Ledger.PackClusterKey(x, y)
    local size = Ledger.CLUSTER_SIZE
    local cx = math.floor(finite(x, 0) / size)
    local cy = math.floor(finite(y, 0) / size)
    return (cx + COORD_OFFSET) * COORD_STRIDE + (cy + COORD_OFFSET)
end

function Ledger.UnpackClusterKey(key)
    key = math.floor(finite(key, 0))
    local cy = (key % COORD_STRIDE) - COORD_OFFSET
    local cx = math.floor(key / COORD_STRIDE) - COORD_OFFSET
    local size = Ledger.CLUSTER_SIZE
    return (cx + 0.5) * size, (cy + 0.5) * size
end

function Ledger.Reset()
    Ledger.State.entries = {}
    Ledger.State.count = 0
    Ledger.State.revision = (tonumber(Ledger.State.revision) or 0) + 1
    return true
end

function Ledger.GetRevision()
    return tonumber(Ledger.State.revision) or 1
end

function Ledger.EffectiveDepletion(entry, nowHours)
    if type(entry) ~= "table" then return 0 end
    local d = math.max(0, math.min(1, finite(entry.d, 0)))
    if d <= 0 then return 0 end
    local regen = math.max(1, finite(Ledger.REGEN_HOURS, 168))
    local elapsed = math.max(0, currentWorldHours(nowHours) - finite(entry.t, 0))
    local eff = d - (elapsed / regen)
    if eff <= Ledger.CLEANUP_EPSILON then
        return 0
    end
    return math.min(1, eff)
end

function Ledger.GetDepletionByKey(key, nowHours)
    key = tonumber(key)
    if not key then return 0 end
    local entry = Ledger.State.entries[key]
    if not entry then return 0 end
    local eff = Ledger.EffectiveDepletion(entry, nowHours)
    if eff <= 0 then
        Ledger.State.entries[key] = nil
        Ledger.State.count = math.max(0, (Ledger.State.count or 1) - 1)
        return 0
    end
    return eff
end

function Ledger.GetDepletion(x, y, nowHours)
    return Ledger.GetDepletionByKey(Ledger.PackClusterKey(x, y), nowHours)
end

function Ledger.IsExhaustedByKey(key, nowHours)
    return Ledger.GetDepletionByKey(key, nowHours) >= Ledger.EXHAUSTED_THRESHOLD
end

function Ledger.IsExhausted(x, y, nowHours)
    return Ledger.GetDepletion(x, y, nowHours) >= Ledger.EXHAUSTED_THRESHOLD
end

local function evictIfFull(nowHours)
    local entries = Ledger.State.entries
    local count = 0
    local lowestKey = nil
    local lowestEff = math.huge
    local lowestTime = math.huge
    local toDelete = {}

    for k, entry in pairs(entries) do
        local eff = Ledger.EffectiveDepletion(entry, nowHours)
        if eff <= 0 then
            toDelete[#toDelete + 1] = k
        else
            count = count + 1
            local t = finite(entry.t, 0)
            if eff < lowestEff or (eff == lowestEff and t < lowestTime) then
                lowestEff = eff
                lowestTime = t
                lowestKey = k
            end
        end
    end

    for i = 1, #toDelete do
        entries[toDelete[i]] = nil
    end

    if count >= Ledger.MAX_ENTRIES and lowestKey ~= nil then
        entries[lowestKey] = nil
        count = count - 1
    end

    Ledger.State.count = count
end

function Ledger.RecordScavengeByKey(key, amount, nowHours)
    key = tonumber(key)
    if not key then return 0 end
    local now = currentWorldHours(nowHours)
    local delta = math.max(0, math.min(1, finite(amount, 0.45)))
    local existing = Ledger.State.entries[key]
    local prevEff = existing and Ledger.EffectiveDepletion(existing, now) or 0
    local wasExhausted = prevEff >= Ledger.EXHAUSTED_THRESHOLD

    if not existing then
        if (Ledger.State.count or 0) >= Ledger.MAX_ENTRIES then
            evictIfFull(now)
        end
        Ledger.State.count = (Ledger.State.count or 0) + 1
    end

    local nextD = math.max(0, math.min(1, prevEff + delta))
    if nextD <= Ledger.CLEANUP_EPSILON then
        if Ledger.State.entries[key] then
            Ledger.State.entries[key] = nil
            Ledger.State.count = math.max(0, (Ledger.State.count or 1) - 1)
        end
        if wasExhausted then
            Ledger.State.revision = (tonumber(Ledger.State.revision) or 0) + 1
        end
        return 0
    end

    Ledger.State.entries[key] = { d = nextD, t = now }
    local isExhausted = nextD >= Ledger.EXHAUSTED_THRESHOLD
    if wasExhausted ~= isExhausted then
        Ledger.State.revision = (tonumber(Ledger.State.revision) or 0) + 1
    end
    return nextD
end

function Ledger.RecordScavenge(x, y, amount, nowHours)
    return Ledger.RecordScavengeByKey(Ledger.PackClusterKey(x, y), amount, nowHours)
end

function Ledger.ExportSnapshot(nowHours)
    local now = currentWorldHours(nowHours)
    local out = {}
    local count = 0
    for k, entry in pairs(Ledger.State.entries) do
        local eff = Ledger.EffectiveDepletion(entry, now)
        if eff > 0 then
            out[k] = {
                d = math.floor(eff * 1000 + 0.5) / 1000,
                t = now,
            }
            count = count + 1
        end
    end
    Ledger.State.entries = out
    Ledger.State.count = count
    return {
        schemaVersion = Ledger.SCHEMA_VERSION,
        revision = Ledger.GetRevision(),
        entries = out,
    }
end

function Ledger.RestoreSnapshot(snapshot, nowHours)
    Ledger.State.entries = {}
    Ledger.State.count = 0
    if type(snapshot) ~= "table" or type(snapshot.entries) ~= "table" then
        Ledger.State.revision = (tonumber(Ledger.State.revision) or 0) + 1
        return false
    end
    local now = currentWorldHours(nowHours)
    local restored = 0
    for k, entry in pairs(snapshot.entries) do
        local keyNum = tonumber(k)
        if keyNum and type(entry) == "table" and restored < Ledger.MAX_ENTRIES then
            local eff = Ledger.EffectiveDepletion(entry, now)
            if eff > 0 then
                Ledger.State.entries[keyNum] = {
                    d = eff,
                    t = finite(entry.t, now),
                }
                restored = restored + 1
            end
        end
    end
    Ledger.State.count = restored
    Ledger.State.revision = math.max(
        (tonumber(Ledger.State.revision) or 0) + 1,
        tonumber(snapshot.revision) or 1
    )
    return true
end

function Ledger.GetStats(nowHours)
    local now = currentWorldHours(nowHours)
    local active = 0
    local exhausted = 0
    for _, entry in pairs(Ledger.State.entries) do
        local eff = Ledger.EffectiveDepletion(entry, now)
        if eff > 0 then
            active = active + 1
            if eff >= Ledger.EXHAUSTED_THRESHOLD then
                exhausted = exhausted + 1
            end
        end
    end
    return {
        count = active,
        exhaustedCount = exhausted,
        maxEntries = Ledger.MAX_ENTRIES,
        regenHours = Ledger.REGEN_HOURS,
        revision = Ledger.GetRevision(),
    }
end

return Ledger
