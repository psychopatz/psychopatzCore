PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.WorldLoot = PsychopatzCore.WorldLoot or {}

local Metrics = PsychopatzCore.WorldLoot.Metrics or { values = {} }
PsychopatzCore.WorldLoot.Metrics = Metrics

function Metrics.Increment(name, amount)
    name = tostring(name or "unknown")
    amount = tonumber(amount) or 1
    Metrics.values[name] = (Metrics.values[name] or 0) + amount
    local profiler = PsychopatzCore.Profiler
    if profiler and profiler.IsRunning and profiler.IsRunning() then
        profiler.Increment("WorldLoot." .. name, amount)
    end
end

function Metrics.SetGauge(name, value)
    name = tostring(name or "unknown")
    value = tonumber(value) or 0
    Metrics.values[name] = value
    local profiler = PsychopatzCore.Profiler
    if profiler and profiler.IsRunning and profiler.IsRunning() then
        profiler.SetGauge("WorldLoot." .. name, value)
    end
end

function Metrics.ObserveMilliseconds(name, value)
    name = tostring(name or "unknown")
    value = math.max(0, tonumber(value) or 0)
    Metrics.values[name .. "LastMs"] = value
    Metrics.values[name .. "TotalMs"] =
        (Metrics.values[name .. "TotalMs"] or 0) + value
    Metrics.values[name .. "Count"] =
        (Metrics.values[name .. "Count"] or 0) + 1
    Metrics.values[name .. "MaxMs"] = math.max(
        tonumber(Metrics.values[name .. "MaxMs"]) or 0, value)
    local profiler = PsychopatzCore.Profiler
    if profiler and profiler.IsRunning and profiler.IsRunning() then
        profiler.SetGauge("WorldLoot." .. name .. "LastMs", value)
        profiler.SetGauge("WorldLoot." .. name .. "MaxMs",
            Metrics.values[name .. "MaxMs"])
    end
end

function Metrics.Snapshot()
    local output = {}
    for key, value in pairs(Metrics.values) do output[key] = value end
    return output
end

return Metrics
