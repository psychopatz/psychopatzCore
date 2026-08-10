-- Generic profiler entry point. PZ-specific clocks, events, files, UI, and
-- networking are supplied by versioned adapters.
PsychopatzCore = PsychopatzCore or {}

local Bootstrap = PsychopatzCore.ProfilerBootstrap
if not Bootstrap or not Bootstrap.IsEnabled() then return nil end

local Profiler = PsychopatzCore.Profiler or {}
PsychopatzCore.Profiler = Profiler
Profiler.Internal = Profiler.Internal or {}

local Internal = Profiler.Internal
local state = nil

Profiler.VERSION = 1
Profiler.MODE_BASIC = "BASIC"
Profiler.MODE_DETAILED = "DETAILED"

function Internal.GetState()
    return state
end

function Internal.NowMs()
    return state.adapter.nowMs()
end

function Internal.SplitName(name)
    name = tostring(name or "")
    local separator = string.find(name, ".", 1, true)
    if not separator or separator == 1 or separator == #name then return nil, nil end
    return string.sub(name, 1, separator - 1), string.sub(name, separator + 1)
end

function Internal.GetMetric(name, kind)
    if not state then return nil end
    local metric = state.metrics[name]
    if metric then return metric.kind == kind and metric or nil end
    local namespace, path = Internal.SplitName(name)
    if not namespace then return nil end
    metric = { name = name, namespace = namespace, path = path, kind = kind }
    if kind == "timer" then
        metric.calls, metric.totalMs, metric.lastMs, metric.averageMs = 0, 0, 0, 0
        metric.peakMs, metric.spikeCount = 0, 0
        metric.intervalCalls, metric.intervalMs = 0, 0
        metric.callsPerSec, metric.msPerSec, metric.movingAverageMs = 0, 0, 0
        metric.stack, metric.stackDepth = {}, 0
    elseif kind == "counter" or kind == "gauge" then
        metric.value, metric.peak = 0, 0
    elseif kind == "rate" then
        metric.intervalValue, metric.perSec, metric.total, metric.peak = 0, 0, 0, 0
    end
    if state.mode == Profiler.MODE_DETAILED then metric.history = Internal.NewRing(state.historyCapacity) end
    state.metrics[name] = metric
    state.metricOrder[#state.metricOrder + 1] = name
    return metric
end

function Profiler.IsRunning()
    return state ~= nil
end

function Profiler.GetMode()
    return state and state.mode or "OFF"
end

function Profiler.GetState()
    return state
end

function Profiler.Start(mode, adapter, options)
    if state then return Profiler end
    options = options or {}
    mode = mode == Profiler.MODE_DETAILED and Profiler.MODE_DETAILED or Profiler.MODE_BASIC
    assert(adapter and type(adapter.nowMs) == "function", "profiler adapter requires nowMs")
    state = {
        mode = mode, adapter = adapter, metrics = {}, metricOrder = {}, namespaces = {},
        samplers = {}, snapshotProviders = {}, stopHooks = {}, warnings = {}, warningByKey = {},
        maxWarnings = math.max(1, math.floor(tonumber(options.maxWarnings) or 100)),
        historyCapacity = math.max(2, math.floor(tonumber(options.historyCapacity) or 300)),
        sampleIntervalMs = math.max(100, math.floor(tonumber(options.sampleIntervalMs) or 1000)),
        lastSampleAt = adapter.nowMs(),
        snapshotEnabled = mode == Profiler.MODE_DETAILED and options.snapshotEnabled ~= false,
        sourceType = adapter.sourceType and adapter.sourceType() or "unknown",
    }
    state.sampleCallback = function() Profiler.Sample() end
    if adapter.addSampleCallback then adapter.addSampleCallback(state.sampleCallback) end
    return Profiler
end

function Profiler.Stop()
    if not state then return false end
    local old = state
    state = nil
    for _, callback in pairs(old.stopHooks) do callback() end
    if old.adapter.removeSampleCallback and old.sampleCallback then old.adapter.removeSampleCallback(old.sampleCallback) end
    if old.adapter.onStop then old.adapter.onStop() end
    return true
end

function Profiler.RegisterNamespace(name, metadata)
    if not state then return false end
    name = tostring(name or "")
    if name == "" or string.find(name, ".", 1, true) then return false end
    state.namespaces[name] = { displayName = tostring(metadata and metadata.displayName or name) }
    return true
end

function Profiler.ConfigureMetric(name, options)
    if not state then return false end
    local metric = state.metrics[tostring(name or "")]
    if not metric then return false end
    options = options or {}
    metric.warningRate, metric.warningValue = tonumber(options.warningRate), tonumber(options.warningValue)
    metric.spikeMs, metric.growthThreshold = tonumber(options.spikeMs), tonumber(options.growthThreshold)
    return true
end

function Profiler.Begin(name)
    local metric = Internal.GetMetric(name, "timer")
    if not metric then return nil end
    metric.stackDepth = metric.stackDepth + 1
    metric.stack[metric.stackDepth] = Internal.NowMs()
    return metric.stackDepth
end

function Profiler.Finish(name)
    if not state then return nil end
    local metric = state.metrics[name]
    if not metric or metric.kind ~= "timer" or metric.stackDepth == 0 then return nil end
    local startedAt = metric.stack[metric.stackDepth]
    metric.stack[metric.stackDepth], metric.stackDepth = nil, metric.stackDepth - 1
    local elapsed = math.max(0, Internal.NowMs() - startedAt)
    metric.calls, metric.totalMs, metric.lastMs = metric.calls + 1, metric.totalMs + elapsed, elapsed
    metric.averageMs = metric.totalMs / metric.calls
    metric.intervalCalls, metric.intervalMs = metric.intervalCalls + 1, metric.intervalMs + elapsed
    if elapsed > metric.peakMs then metric.peakMs = elapsed end
    local spikeLimit = metric.spikeMs or math.max(5, metric.movingAverageMs * 4)
    if metric.calls > 5 and elapsed > spikeLimit then metric.spikeCount = metric.spikeCount + 1 end
    return elapsed
end

function Profiler.Wrap(name, callback)
    if not state then return callback end
    assert(type(callback) == "function", "profiler wrap requires a function")
    Internal.GetMetric(name, "timer")
    return function(...)
        Profiler.Begin(name)
        local a, b, c, d, e, f, g, h = callback(...)
        Profiler.Finish(name)
        return a, b, c, d, e, f, g, h
    end
end


function Profiler.Increment(name, amount)
    local metric = Internal.GetMetric(name, "counter")
    if not metric then return nil end
    metric.value = metric.value + (tonumber(amount) or 1)
    if metric.value > metric.peak then metric.peak = metric.value end
    return metric.value
end

function Profiler.Decrement(name, amount)
    return Profiler.Increment(name, -(tonumber(amount) or 1))
end

function Profiler.SetGauge(name, value)
    local metric = Internal.GetMetric(name, "gauge")
    if not metric then return nil end
    metric.value = tonumber(value) or 0
    if metric.value > metric.peak then metric.peak = metric.value end
    return metric.value
end

function Profiler.RecordRate(name, amount)
    local metric = Internal.GetMetric(name, "rate")
    if not metric then return nil end
    amount = tonumber(amount) or 1
    metric.intervalValue, metric.total = metric.intervalValue + amount, metric.total + amount
    return metric.total
end

function Profiler.RegisterSampler(id, callback)
    if not state or type(callback) ~= "function" then return false end
    state.samplers[tostring(id or callback)] = callback
    return true
end

function Profiler.UnregisterSampler(id)
    if not state then return false end
    state.samplers[tostring(id or "")] = nil
    return true
end

function Profiler.RegisterSnapshotProvider(id, callback)
    if not state or type(callback) ~= "function" then return false end
    state.snapshotProviders[tostring(id or callback)] = callback
    return true
end

function Profiler.UnregisterSnapshotProvider(id)
    if not state then return false end
    state.snapshotProviders[tostring(id or "")] = nil
    return true
end

function Profiler.RegisterStopHook(id, callback)
    if not state or type(callback) ~= "function" then return false end
    state.stopHooks[tostring(id or callback)] = callback
    return true
end

require "PsychopatzCore/Profiler/PsychopatzProfiler_History"
require "PsychopatzCore/Profiler/PsychopatzProfiler_Analysis"
require "PsychopatzCore/Profiler/PsychopatzProfiler_Snapshot"

Profiler.SplitName = Internal.SplitName
Profiler.NewRing = Internal.NewRing
Profiler.RingPush = Internal.RingPush
Profiler.RingGetAgo = Internal.RingGetAgo

return Profiler
