local Profiler = PsychopatzCore and PsychopatzCore.Profiler
if not Profiler then return nil end
local Internal = Profiler.Internal

function Profiler.BuildSnapshot()
    local state = Internal.GetState()
    if not state then return nil end
    local snapshot = {
        profilerVersion = Profiler.VERSION, timestamp = Internal.NowMs(), mode = state.mode,
        source = { type = state.sourceType }, namespaces = {}, warnings = {},
        runtime = {
            id = state.runtime.id,
            configFingerprint = state.runtime.configFingerprint,
            capture = state.runtime.capture or state.capture,
        },
    }
    for name, metadata in pairs(state.namespaces) do
        snapshot.namespaces[name] = {
            displayName = metadata.displayName, timers = {}, counters = {}, gauges = {}, rates = {},
        }
    end
    for index = 1, #state.metricOrder do
        local metric = state.metrics[state.metricOrder[index]]
        local namespace = snapshot.namespaces[metric.namespace]
        if not namespace then
            namespace = { displayName = metric.namespace, timers = {}, counters = {}, gauges = {}, rates = {} }
            snapshot.namespaces[metric.namespace] = namespace
        end
        if metric.kind == "timer" then
            namespace.timers[metric.path] = {
                calls = metric.calls, callsPerSec = metric.callsPerSec,
                lastMs = metric.lastMs, averageMs = metric.averageMs,
                movingAverageMs = metric.movingAverageMs, peakMs = metric.peakMs,
                totalMs = metric.totalMs, msPerSec = metric.msPerSec, spikeCount = metric.spikeCount,
            }
        elseif metric.kind == "rate" then
            namespace.rates[metric.path] = { perSec = metric.perSec, total = metric.total, peak = metric.peak }
        else
            namespace[metric.kind .. "s"][metric.path] = { value = metric.value, peak = metric.peak }
        end
    end
    for index = 1, #state.warnings do
        local warning = state.warnings[index]
        snapshot.warnings[index] = {
            message = warning.message, metric = warning.metric, value = warning.value, count = warning.count,
        }
    end
    local now = Internal.NowMs()
    for id, provider in pairs(state.snapshotProviders or {}) do
        if provider.lastAt == nil or provider.intervalMs == 0
            or now - provider.lastAt >= provider.intervalMs
        then
            local ok, value = pcall(provider.callback)
            provider.lastAt = now
            if ok and type(value) == "table" then provider.lastValue = value end
        end
        if type(provider.lastValue) == "table" then
            snapshot.diagnostics = snapshot.diagnostics or {}
            snapshot.diagnostics[id] = provider.lastValue
        end
    end
    return snapshot
end

local function jsonEscape(value)
    return string.gsub(string.gsub(string.gsub(string.gsub(
        tostring(value), "\\", "\\\\"), '"', '\\"'), "\n", "\\n"), "\r", "\\r")
end

local function isArray(value)
    local count = 0
    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
        if key > count then count = key end
    end
    for index = 1, count do if value[index] == nil then return false end end
    return true, count
end

local function encode(value)
    local kind = type(value)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return value and "true" or "false" end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then return "null" end
        return tostring(value)
    end
    if kind == "string" then return '"' .. jsonEscape(value) .. '"' end
    if kind ~= "table" then return '"' .. jsonEscape(tostring(value)) .. '"' end
    local array, count = isArray(value)
    local parts = {}
    if array then
        for index = 1, count do parts[#parts + 1] = encode(value[index]) end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    for key, item in pairs(value) do parts[#parts + 1] = '"' .. jsonEscape(key) .. '":' .. encode(item) end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
end

function Profiler.EncodeSnapshot(snapshot)
    return encode(snapshot)
end

function Profiler.ExportSnapshot()
    local state = Internal.GetState()
    if not state or not state.adapter.writeSnapshot then return false end
    return state.adapter.writeSnapshot(Profiler.EncodeSnapshot(Profiler.BuildSnapshot())) ~= false
end

return Profiler
