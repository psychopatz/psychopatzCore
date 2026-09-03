local Profiler = PsychopatzCore and PsychopatzCore.Profiler
if not Profiler then return nil end
local Internal = Profiler.Internal

local function addWarning(key, message, metricName, value)
    local state = Internal.GetState()
    if state.warningByKey[key] then
        local warning = state.warningByKey[key]
        warning.count, warning.lastAt, warning.value = warning.count + 1, Internal.NowMs(), value
        return
    end
    local warning = {
        key = key, message = message, metric = metricName, value = value,
        count = 1, firstAt = Internal.NowMs(), lastAt = Internal.NowMs(),
    }
    state.warningByKey[key] = warning
    state.warnings[#state.warnings + 1] = warning
    if #state.warnings > state.maxWarnings then
        local removed = table.remove(state.warnings, 1)
        state.warningByKey[removed.key] = nil
    end
end

local function sampleMetric(metric, elapsedSec)
    local sampleValue
    if metric.kind == "timer" then
        metric.callsPerSec, metric.msPerSec = metric.intervalCalls / elapsedSec, metric.intervalMs / elapsedSec
        metric.selfMsPerSec = metric.intervalSelfMs / elapsedSec
        local average = metric.intervalCalls > 0 and metric.intervalMs / metric.intervalCalls or 0
        local selfAverage = metric.intervalCalls > 0
            and metric.intervalSelfMs / metric.intervalCalls or 0
        metric.movingAverageMs = metric.movingAverageMs == 0 and average or metric.movingAverageMs * 0.8 + average * 0.2
        metric.movingAverageSelfMs = metric.movingAverageSelfMs == 0
            and selfAverage or metric.movingAverageSelfMs * 0.8 + selfAverage * 0.2
        metric.intervalCalls, metric.intervalMs, metric.intervalSelfMs = 0, 0, 0
        sampleValue = metric.msPerSec
        if metric.warningRate and metric.callsPerSec > metric.warningRate then
            addWarning("rate:" .. metric.name, "Unusual callback rate", metric.name, metric.callsPerSec)
        end
    elseif metric.kind == "rate" then
        metric.perSec, metric.intervalValue = metric.intervalValue / elapsedSec, 0
        if metric.perSec > metric.peak then metric.peak = metric.perSec end
        sampleValue = metric.perSec
        if metric.warningRate and metric.perSec > metric.warningRate then
            addWarning("rate:" .. metric.name, "Unusual event rate", metric.name, metric.perSec)
        end
    else
        sampleValue = metric.value
        if metric.warningValue and metric.value > metric.warningValue then
            addWarning("value:" .. metric.name, "Metric exceeded its warning threshold", metric.name, metric.value)
        end
    end
    if metric.history then
        Internal.RingPush(metric.history, sampleValue)
        if metric.kind == "gauge" and metric.growthThreshold and metric.history.count >= 60 then
            local previous = Internal.RingGetAgo(metric.history, math.min(metric.history.count - 1, 59))
            if previous and sampleValue - previous >= metric.growthThreshold then
                addWarning("growth:" .. metric.name, "Possible continuous growth", metric.name, sampleValue - previous)
            end
        end
    end
end

function Profiler.Sample(forceElapsedMs)
    local state = Internal.GetState()
    if not state then return false end
    local at = Internal.NowMs()
    local elapsedMs = tonumber(forceElapsedMs) or (at - state.lastSampleAt)
    if elapsedMs < state.sampleIntervalMs and forceElapsedMs == nil then return false end
    state.lastSampleAt = at
    local samplingStarted = at
    for _, entry in pairs(state.samplers) do entry.callback(Profiler) end
    local elapsedSec = math.max(0.001, elapsedMs / 1000)
    if state.capture.performance then
        for index = 1, #state.metricOrder do
            sampleMetric(state.metrics[state.metricOrder[index]], elapsedSec)
        end
    end
    if state.mode == Profiler.MODE_DETAILED then
        Profiler.SetGauge("PsychopatzCore.Profiler.Sampling", math.max(0, Internal.NowMs() - samplingStarted))
        if state.snapshotEnabled and state.adapter.writeSnapshot then
            local snapshotStarted = Internal.NowMs()
            state.adapter.writeSnapshot(Profiler.EncodeSnapshot(Profiler.BuildSnapshot()))
            Profiler.SetGauge("PsychopatzCore.Profiler.Snapshot", math.max(0, Internal.NowMs() - snapshotStarted))
        end
    end
    return true
end

function Profiler.GetGrowth(name, seconds)
    local state = Internal.GetState()
    if not state then return nil end
    local metric = state.metrics[name]
    if not metric or not metric.history then return nil end
    local current = Internal.RingGetAgo(metric.history, 0)
    local old = Internal.RingGetAgo(metric.history,
        math.floor((tonumber(seconds) or 0) * 1000 / state.sampleIntervalMs))
    return current and old and current - old or nil
end

function Profiler.ResetPeaks()
    local state = Internal.GetState()
    if not state then return false end
    for _, metric in pairs(state.metrics) do
        if metric.kind == "timer" then
            metric.peakMs, metric.selfPeakMs, metric.spikeCount = 0, 0, 0
        else
            metric.peak = metric.value or 0
        end
    end
    return true
end

function Profiler.ResetHistories()
    local state = Internal.GetState()
    if not state then return false end
    for _, metric in pairs(state.metrics) do
        if metric.history then metric.history = Internal.NewRing(state.historyCapacity) end
    end
    return true
end

function Profiler.ResetWarnings()
    local state = Internal.GetState()
    if not state then return false end
    state.warnings, state.warningByKey = {}, {}
    return true
end

function Profiler.GetMetrics(kind, namespace)
    local result = {}
    local state = Internal.GetState()
    if not state then return result end
    for index = 1, #state.metricOrder do
        local metric = state.metrics[state.metricOrder[index]]
        if (not kind or metric.kind == kind) and (not namespace or metric.namespace == namespace) then
            result[#result + 1] = metric
        end
    end
    return result
end

function Profiler.GetWarnings()
    local state = Internal.GetState()
    return state and state.warnings or {}
end

return Profiler
