-- Optional, in-memory runtime diagnostics for consuming mods.
--
-- The disabled path is intentionally only a boolean check.  In particular, do
-- not build or copy diagnostic payloads before calling Record: this module is
-- used by systems that run every frame and must remain free when diagnostics
-- are not requested.
PsychopatzCore = PsychopatzCore or {}

local Trace = PsychopatzCore.DebugTrace or {}
PsychopatzCore.DebugTrace = Trace

local MAX_COPY_DEPTH = 8

Trace.enabled = Trace.enabled == true
Trace.maxEntries = tonumber(Trace.maxEntries) or 200
Trace.entries = Trace.entries or {}
Trace.revision = tonumber(Trace.revision) or 0
Trace.nextID = tonumber(Trace.nextID) or 0

local function boundedString(value, limit)
    local text = tostring(value or "")
    if #text <= limit then return text end
    return string.sub(text, 1, limit - 1) .. "…"
end

local function copyValue(value, depth, seen)
    local valueType = type(value)
    if valueType == "string" then return boundedString(value, 6000) end
    if valueType == "number" or valueType == "boolean" then return value end
    if value == nil then return nil end
    if valueType ~= "table" then return boundedString(value, 160) end
    if depth >= MAX_COPY_DEPTH then return "[depth-limit]" end
    if seen[value] then return "[cycle]" end

    seen[value] = true
    local result = {}
    local count = 0
    for key, child in pairs(value) do
        count = count + 1
        if count > 64 then
            result["[truncated]"] = "64+ entries"
            break
        end
        local safeKey = type(key) == "string" and boundedString(key, 160)
            or tostring(key)
        result[safeKey] = copyValue(child, depth + 1, seen)
    end
    seen[value] = nil
    return result
end

function Trace.IsEnabled()
    return Trace.enabled == true
end

function Trace.SetEnabled(enabled)
    local nextEnabled = enabled == true
    if Trace.enabled == nextEnabled then return Trace.enabled end
    Trace.enabled = nextEnabled
    if not nextEnabled then
        Trace.entries = {}
        Trace.revision = Trace.revision + 1
    end
    return Trace.enabled
end

function Trace.SetMaxEntries(value)
    Trace.maxEntries = math.max(1, math.floor(tonumber(value) or 200))
    while #Trace.entries > Trace.maxEntries do
        table.remove(Trace.entries, 1)
    end
    Trace.revision = Trace.revision + 1
end

function Trace.Clear()
    if #Trace.entries == 0 then return false end
    Trace.entries = {}
    Trace.revision = Trace.revision + 1
    return true
end

function Trace.GetRevision()
    return Trace.revision
end

function Trace.GetEntries()
    return Trace.entries
end

function Trace.Record(definition)
    -- Keep this as the first operation.  Callers may pass a large live game
    -- table and must not pay for a copy while capture is off.
    if not Trace.enabled or type(definition) ~= "table" then return false end

    Trace.nextID = Trace.nextID + 1
    local entry = {
        id = Trace.nextID,
        timestamp = getTimeInMillis and getTimeInMillis() or 0,
        source = boundedString(definition.source or "unknown", 160),
        event = boundedString(definition.event or definition.phase or "event", 200),
        requestID = boundedString(definition.requestID or definition.request_id or "", 240),
        data = copyValue(definition.data or definition.payload or {}, 0, {}),
    }
    Trace.entries[#Trace.entries + 1] = entry
    while #Trace.entries > Trace.maxEntries do
        table.remove(Trace.entries, 1)
    end
    Trace.revision = Trace.revision + 1
    return true
end

return Trace
